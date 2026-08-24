import { withSupabase } from 'npm:@supabase/server@1.4.1'
import type { SupabaseClient } from 'npm:@supabase/supabase-js@2.112.3'
import {
  ANALYSIS_CONTRACT_VERSION,
  type AnalysisItem,
  type AnalyzeMealResponse,
  DETERMINISTIC_PIPELINE_VERSION,
  TEXT_EXTRACTION_PIPELINE_VERSION,
  VISION_PIPELINE_VERSION,
} from '../_shared/contracts.ts'
import { errorResponse, jsonHeaders, jsonResponse, redactedLog } from '../_shared/http.ts'
import {
  aliasLookupKeys,
  analyzeDeterministically,
  type CatalogAlias,
  type CatalogFood,
  type CatalogPortion,
  type DeterministicAnalysis,
} from './deterministic.ts'
import {
  extractFoodsFromText,
  extractionPhrases,
  type TextExtraction,
  TextExtractionError,
  type TextExtractionFailureReason,
} from './text-extraction.ts'
import { parseAnalyzeMealRequest, RequestValidationError } from './request.ts'
import { applyVisionEvidence, reconcileModalities, remainingUnmatchedText } from './reconcile.ts'
import { estimateUnmatchedFoods, type MacroEstimateResult } from './estimate.ts'
import {
  extractFoodsFromPhoto,
  extractVisionWithTextFallback,
  VisionProviderError,
} from './vision.ts'
import {
  CANDIDATE_SELECTION_PROMPT_VERSION,
  type CandidateSelectionResult,
  type RetrievalCandidate,
  selectCatalogCandidates,
} from './candidate-selector.ts'
import { hybridSearch } from '../search-food-catalog/hybrid.ts'
import { sha256 } from '../_shared/embeddings.ts'

const MAX_CATALOG_ALIAS_ROWS = 500
const ALIAS_LOOKUP_BATCH_SIZE = 100

// Uncalibrated heuristics for "which food is this?" on the LLM path. A top-2
// retrieval-score gap this small means retrieval could not separate the
// candidates, and 0.82 mirrors the vision identity gate in reconcile.ts.
const IDENTITY_SCORE_GAP = 0.05
const IDENTITY_CONFIDENCE_GATE = 0.82
const MAX_IDENTITY_ALTERNATIVES = 3

function chunk<T>(values: T[], size: number): T[][] {
  const batches: T[][] = []
  for (let index = 0; index < values.length; index += size) {
    batches.push(values.slice(index, index + size))
  }
  return batches
}

interface RunRow {
  id: string
  trace_id: string
  status: string
  output: AnalyzeMealResponse | null
}

interface SupabaseContext {
  supabase: SupabaseClient
  supabaseAdmin: SupabaseClient
  userClaims?: Record<string, unknown>
}

class AnalysisBudgetExceededError extends Error {
  constructor() {
    super('Daily analysis cost budget is exhausted')
    this.name = 'AnalysisBudgetExceededError'
  }
}

export default {
  fetch: withSupabase({ auth: 'user' }, async (request: Request, rawContext: unknown) => {
    const context = rawContext as SupabaseContext
    if (request.method === 'OPTIONS') return new Response('ok', { headers: jsonHeaders })

    const requestTraceId = crypto.randomUUID()
    if (request.method !== 'POST') {
      return errorResponse(
        'METHOD_NOT_ALLOWED',
        'Only POST is supported',
        requestTraceId,
        405,
      )
    }

    let body
    try {
      body = parseAnalyzeMealRequest(await request.json())
    } catch (error) {
      const validation = error instanceof RequestValidationError ? error : null
      return errorResponse(
        'INVALID_REQUEST',
        validation?.message ?? 'Body must be valid JSON',
        requestTraceId,
        400,
        false,
        validation?.field ? { field: validation.field } : undefined,
      )
    }

    const userId = userIdFromClaims(context.userClaims)
    if (!userId) {
      return errorResponse(
        'INTERNAL_ERROR',
        'Authenticated user is unavailable',
        requestTraceId,
        500,
      )
    }
    if (body.photo && !body.photo.path.startsWith(`${userId}/${body.clientRequestId}/`)) {
      return errorResponse(
        'FORBIDDEN',
        'Photo path does not belong to this request',
        requestTraceId,
        403,
      )
    }

    const startedAt = performance.now()
    let run: RunRow | null = null
    try {
      run = await findRun(context, userId, body.clientRequestId)
      if (run?.output && ['needs_review', 'completed'].includes(run.status)) {
        redactedLog('info', 'analysis_replayed', {
          traceId: run.trace_id,
          analysisRunId: run.id,
          userId,
        })
        return jsonResponse({ ...run.output, replayed: true })
      }

      run ??= await createRun(context, {
        userId,
        clientRequestId: body.clientRequestId,
        traceId: requestTraceId,
        input: body.input || '[photo]',
        inputKind: body.inputKind ?? 'text',
        imagePath: body.photo?.path ?? null,
      })

      if (body.photo) await enforceAnalysisBudget(context, userId)
      const visionAttempt = body.photo
        ? await extractVisionWithTextFallback(
          body.input,
          () =>
            extractFoodsFromPhoto(
              context.supabaseAdmin,
              body.photo!,
              body.locale ?? 'tr-TR',
              body.input,
            ),
        )
        : { extraction: null, fallbackReason: null }
      const vision = visionAttempt.extraction
      const catalog = await loadCatalog(context, body.locale ?? 'tr-TR', [
        body.input,
        ...(vision ? [vision.normalizedDescription] : []),
      ])
      const textOutcome = await resolveTextAnalysis(context, {
        input: body.input,
        locale: body.locale ?? 'tr-TR',
        catalog,
      })
      const visionAnalysis = vision
        ? applyVisionEvidence(
          analyzeDeterministically(vision.normalizedDescription, catalog),
          vision.foods,
        )
        : null
      const analysis = reconcileModalities(textOutcome.analysis, visionAnalysis)
      let grounding: GroundingOutcome | null = null
      let groundingFailure: GroundingUnavailableError | null = null
      try {
        grounding = await groundUnmatchedItems(context, {
          queries: analysis.unmatchedText,
          locale: body.locale ?? 'tr-TR',
          existingFoodIds: new Set(
            analysis.items.map((item) => item.foodId).filter((id): id is string => id !== null),
          ),
        })
      } catch (error) {
        // Deterministic matches are still worth returning, so an outage only
        // becomes fatal when nothing else resolved.
        if (!(error instanceof GroundingUnavailableError)) throw error
        groundingFailure = error
      }
      if (grounding) {
        const groundedItems = grounding.items
        analysis.items.push(...groundedItems)
        // Partial grounding no longer clears the whole unmatched list: with
        // "menemen ve ayran" and only menemen grounded, ayran must stay
        // visible to the client instead of being silently dropped.
        analysis.unmatchedText = remainingUnmatchedText(analysis.unmatchedText, groundedItems)
      }
      // AI estimate fallback: unmatched foods get a server-recorded,
      // bounds-checked estimate instead of nothing. A *provider* outage still
      // skips this — the estimator calls the same provider, so it would only
      // add latency before the same 503. A *retrieval* failure does not: the
      // catalog side broke while the provider is healthy, and letting a
      // labelled estimate rescue the request beats failing the whole meal.
      const estimation = analysis.unmatchedText.length > 0 &&
          groundingFailure?.kind !== 'provider'
        ? await tryEstimateFallback(context, userId, {
          locale: body.locale ?? 'tr-TR',
          texts: analysis.unmatchedText,
        })
        : null
      if (estimation && estimation.items.length > 0) {
        analysis.items.push(...estimation.items)
        analysis.unmatchedText = remainingUnmatchedText(analysis.unmatchedText, estimation.items)
      }
      analysis.items.forEach((item, index) => item.itemKey = `item-${index + 1}`)
      const unmatchedItems = analysis.unmatchedText.map((text, index) => ({
        itemKey: `unmatched-${index + 1}`,
        text,
      }))
      if (analysis.items.length === 0) {
        if (groundingFailure) {
          // A broken catalog/retrieval step is our bug, not a provider outage
          // and not the user's connection. Reporting both as 503 hid real
          // server faults behind a "check your connection" message.
          const retrievalFault = groundingFailure.kind === 'retrieval'
          await markRunFailed(
            context,
            run.id,
            retrievalFault ? 'INTERNAL_ERROR' : 'PROVIDER_UNAVAILABLE',
            groundingFailure.message,
            visionAttempt.fallbackReason,
          )
          return errorResponse(
            retrievalFault ? 'INTERNAL_ERROR' : 'PROVIDER_UNAVAILABLE',
            retrievalFault
              ? 'Analiz şu anda tamamlanamadı, lütfen tekrar deneyin'
              : 'Analiz servisi şu anda yanıt vermiyor, lütfen tekrar deneyin',
            run.trace_id,
            retrievalFault ? 500 : 503,
          )
        }
        await markRunFailed(
          context,
          run.id,
          'NO_MATCH',
          'No catalog-grounded food was found',
          visionAttempt.fallbackReason,
        )
        return errorResponse(
          'NO_MATCH',
          'Yiyeceği katalogda güvenle eşleştiremedik',
          run.trace_id,
          422,
          false,
          { unmatchedText: analysis.unmatchedText, unmatchedItems },
        )
      }

      // Estimate rows must exist before the client can commit against their
      // ids, and only now are the final item keys known.
      if (estimation && estimation.items.length > 0) {
        await persistEstimates(context, run.id, estimation)
      }

      const output: AnalyzeMealResponse = {
        contractVersion: ANALYSIS_CONTRACT_VERSION,
        analysisRunId: run.id,
        traceId: run.trace_id,
        status: 'needs_review',
        normalizedInput: analysis.normalizedInput,
        items: analysis.items,
        unmatchedText: analysis.unmatchedText,
        unmatchedItems,
        pipeline: {
          extraction: vision
            ? VISION_PIPELINE_VERSION
            : textOutcome.extraction
            ? TEXT_EXTRACTION_PIPELINE_VERSION
            : DETERMINISTIC_PIPELINE_VERSION,
          retrieval: 'hybrid-rrf-v1',
          model: grounding?.selection.model ?? vision?.model ??
            textOutcome.extraction?.model ?? estimation?.result.model ?? null,
          ...(grounding
            ? { promptVersion: grounding.selection.promptVersion }
            : vision
            ? { promptVersion: vision.promptVersion }
            : textOutcome.extraction
            ? { promptVersion: textOutcome.extraction.promptVersion }
            : estimation
            ? { promptVersion: estimation.result.promptVersion }
            : {}),
        },
        replayed: false,
      }
      await persistResult(
        context,
        run.id,
        output,
        Math.round(performance.now() - startedAt),
        grounding,
        vision,
        visionAttempt.fallbackReason,
        estimation,
        textOutcome.extraction,
      )

      redactedLog('info', 'analysis_completed', {
        traceId: run.trace_id,
        analysisRunId: run.id,
        userId,
        inputLength: body.input.length,
        hasPhoto: Boolean(body.photo),
        visionModel: vision?.model ?? null,
        visionFallbackReason: visionAttempt.fallbackReason,
        itemCount: output.items.length,
        unmatchedCount: output.unmatchedText.length,
        latencyMs: Math.round(performance.now() - startedAt),
      })
      return jsonResponse(output)
    } catch (error) {
      const budgetFailure = error instanceof AnalysisBudgetExceededError
      const providerFailure = error instanceof VisionProviderError
      const errorCode = budgetFailure
        ? 'RATE_LIMITED'
        : providerFailure
        ? 'PROVIDER_UNAVAILABLE'
        : 'INTERNAL_ERROR'
      if (run) await markRunFailed(context, run.id, errorCode, safeErrorMessage(error))
      redactedLog('error', 'analysis_failed', {
        traceId: run?.trace_id ?? requestTraceId,
        analysisRunId: run?.id ?? null,
        userId,
        errorType: error instanceof Error ? error.name : 'UnknownError',
      })
      return errorResponse(
        errorCode,
        budgetFailure
          ? 'Günlük analiz limiti doldu, lütfen daha sonra tekrar deneyin'
          : providerFailure
          ? 'Fotoğraf analizi şu anda kullanılamıyor, lütfen tekrar deneyin'
          : 'Analiz şu anda tamamlanamadı',
        run?.trace_id ?? requestTraceId,
        budgetFailure ? 429 : providerFailure ? 503 : 500,
        !budgetFailure,
      )
    }
  }),
}

async function findRun(
  context: SupabaseContext,
  userId: string,
  clientRequestId: string,
): Promise<RunRow | null> {
  const { data, error } = await context.supabaseAdmin
    .from('analysis_runs')
    .select('id,trace_id,status,output')
    .eq('user_id', userId)
    .eq('client_request_id', clientRequestId)
    .maybeSingle()
  if (error) throw error
  return data as RunRow | null
}

async function createRun(
  context: SupabaseContext,
  input: {
    userId: string
    clientRequestId: string
    traceId: string
    input: string
    inputKind: string
    imagePath: string | null
  },
): Promise<RunRow> {
  const { data, error } = await context.supabaseAdmin
    .from('analysis_runs')
    .upsert({
      user_id: input.userId,
      client_request_id: input.clientRequestId,
      trace_id: input.traceId,
      raw_input: input.input,
      input_kind: input.inputKind,
      image_path: input.imagePath,
      status: 'running',
      retrieval_version: 'hybrid-rrf-v1',
    }, { onConflict: 'user_id,client_request_id', ignoreDuplicates: true })
    .select('id,trace_id,status,output')
    .maybeSingle()
  if (error) throw error
  if (data) return data as RunRow

  const replay = await findRun(context, input.userId, input.clientRequestId)
  if (!replay) throw new Error('Analysis run could not be created')
  if (replay.status === 'running') {
    throw new Error('Concurrent analysis is already running')
  }
  return replay
}

async function loadCatalog(
  context: SupabaseContext,
  locale: 'tr-TR' | 'en-US',
  texts: string[],
): Promise<CatalogFood[]> {
  // The catalog holds tens of thousands of foods, so a full-table read is both
  // slow and silently truncated by the API row cap. Only the aliases that the
  // typed phrases could still match are fetched.
  const lookupKeys = aliasLookupKeys(texts)
  if (lookupKeys.length === 0) return []

  // Batched so a long meal description cannot grow the request URL past the
  // gateway header limit.
  const aliasBatches = await Promise.all(
    chunk(lookupKeys, ALIAS_LOOKUP_BATCH_SIZE).map((keys) =>
      context.supabaseAdmin
        .from('food_aliases')
        .select('food_id,alias,priority')
        .eq('locale', locale)
        .in('alias', keys)
        .limit(MAX_CATALOG_ALIAS_ROWS)
    ),
  )
  for (const batch of aliasBatches) {
    if (batch.error) throw batch.error
  }
  const aliasRows = aliasBatches.flatMap((batch) => batch.data ?? [])

  const foodIds = [...new Set(aliasRows.map((row) => String(row.food_id)))]
  if (foodIds.length === 0) return []

  const [foodsResult, portionsResult] = await Promise.all([
    context.supabaseAdmin.from('foods').select(
      'id,canonical_name,calories_per_100g,protein_per_100g,carbs_per_100g,fat_per_100g',
    ).eq('is_active', true).in('id', foodIds),
    context.supabaseAdmin.from('food_portions').select(
      'food_id,label,grams,is_default,size_class,reference_image_path',
    ).eq('locale', locale).in('food_id', foodIds),
  ])
  for (const result of [foodsResult, portionsResult]) {
    if (result.error) throw result.error
  }

  const aliasesByFood = groupByFood<CatalogAlias>(aliasRows, (row) => ({
    value: String(row.alias),
    priority: Number(row.priority),
  }))
  const portionsByFood = groupByFood<CatalogPortion>(portionsResult.data, (row) => {
    const imagePath = String(row.reference_image_path ?? '').trim()
    return {
      label: String(row.label),
      grams: Number(row.grams),
      isDefault: Boolean(row.is_default),
      sizeClass: normalizeSizeClass(row.size_class),
      ...(imagePath
        ? {
          imageUrl: context.supabaseAdmin.storage
            .from('food-portion-references')
            .getPublicUrl(imagePath).data.publicUrl,
        }
        : {}),
    }
  })

  return (foodsResult.data ?? []).map((row: Record<string, unknown>) => ({
    id: String(row.id),
    canonicalName: String(row.canonical_name),
    nutritionPer100g: {
      calories: Number(row.calories_per_100g),
      protein: Number(row.protein_per_100g),
      carbs: Number(row.carbs_per_100g),
      fat: Number(row.fat_per_100g),
    },
    aliases: aliasesByFood.get(String(row.id)) ?? [],
    portions: portionsByFood.get(String(row.id)) ?? [],
  })).filter((food: CatalogFood) => food.aliases.length > 0 && food.portions.length > 0)
}

/**
 * Catalog portions for foods we already know the id of.
 *
 * Retrieval only carries the single default portion, so a grounded item used to
 * reach the client with one option — and the portion sheet then synthesised
 * "small/regular/large" as ×0.5/×1/×1.5 around the model's own gram guess. The
 * catalog has real household portions (FNDDS gram weights survived the import),
 * and a measured "1 kase / 1 tabak" beats a multiple of a guess, especially for
 * the amorphous foods where portion error is worst.
 */
async function loadPortionsForFoods(
  context: SupabaseContext,
  locale: 'tr-TR' | 'en-US',
  foodIds: string[],
): Promise<Map<string, CatalogPortion[]>> {
  if (foodIds.length === 0) return new Map()
  const { data, error } = await context.supabaseAdmin.from('food_portions').select(
    'food_id,label,grams,is_default,size_class,reference_image_path',
  ).eq('locale', locale).in('food_id', [...new Set(foodIds)])
  if (error) throw error
  return groupByFood<CatalogPortion>(data, (row) => {
    const imagePath = String(row.reference_image_path ?? '').trim()
    return {
      label: String(row.label),
      grams: Number(row.grams),
      isDefault: Boolean(row.is_default),
      sizeClass: normalizeSizeClass(row.size_class),
      ...(imagePath
        ? {
          imageUrl: context.supabaseAdmin.storage
            .from('food-portion-references')
            .getPublicUrl(imagePath).data.publicUrl,
        }
        : {}),
    }
  })
}

interface TextAnalysisOutcome {
  analysis: DeterministicAnalysis
  extraction: TextExtraction | null
  extractionFailureReason: TextExtractionFailureReason | null
}

/**
 * Resolves free text into catalog-matched items.
 *
 * The deterministic matcher runs first and, when it already explains the whole
 * sentence, nothing else runs: that path stays free, fast, and is what the
 * deterministic regression suite covers.
 *
 * Anything left over used to be treated as food, one token at a time. That is
 * the bug behind "2 yumurta yedim kanka" producing `yedim` and `kanka` as
 * unmatched foods — an open-ended set of Turkish verbs, fillers and time words
 * can never be closed by a stopword list. So leftovers now mean "this sentence
 * needs a language model", and the model returns identity and amount only. The
 * extracted names are re-rendered into clean phrases and pushed back through
 * the same matcher, which keeps portion handling in exactly one place.
 */
async function resolveTextAnalysis(
  context: SupabaseContext,
  input: {
    input: string
    locale: 'tr-TR' | 'en-US'
    catalog: CatalogFood[]
  },
): Promise<TextAnalysisOutcome> {
  const direct = analyzeDeterministically(input.input, input.catalog)
  const apiKey = Deno.env.get('OPENAI_API_KEY')?.trim()
  if (!input.input.trim() || direct.unmatchedText.length === 0 || !apiKey) {
    return { analysis: direct, extraction: null, extractionFailureReason: null }
  }

  let extraction: TextExtraction
  try {
    const userId = userIdFromClaims(context.userClaims)
    if (!userId) throw new Error('Authenticated user is unavailable')
    // The text path now spends provider tokens, so it has to answer to the
    // same budget the photo path does.
    await enforceAnalysisBudget(context, userId)
    extraction = await extractFoodsFromText({
      apiKey,
      locale: input.locale,
      input: input.input,
    })
  } catch (error) {
    if (error instanceof AnalysisBudgetExceededError) throw error
    const detail = providerErrorDetail(error)
    redactedLog('info', 'text_extraction_fallback', {
      errorType: detail.type,
      errorCode: detail.code,
      errorMessage: detail.message,
    })
    // Degrade to the deterministic result rather than failing the request: a
    // partially understood meal still beats an error screen.
    return {
      analysis: direct,
      extraction: null,
      extractionFailureReason: error instanceof TextExtractionError
        ? error.reason
        : 'provider_error',
    }
  }

  if (extraction.foods.length === 0) {
    // The model read the sentence and found nothing edible in it. That is an
    // answer, not a failure, and it must not leave stray tokens behind.
    return {
      analysis: { normalizedInput: direct.normalizedInput, items: [], unmatchedText: [] },
      extraction,
      extractionFailureReason: null,
    }
  }

  const phrases = extraction.foods.flatMap(extractionPhrases)
  // The first catalog load was scoped to the raw sentence, so it cannot contain
  // aliases for names the model produced instead — a decomposed dish brings in
  // "tavuk göğsü" that "kaşarlı tavuklu makarna" never looked up.
  const extractedCatalog = await loadCatalog(
    context,
    input.locale,
    phrases.map((phrase) => phrase.matchPhrase),
  )
  const catalog = mergeCatalogs(input.catalog, extractedCatalog)

  const items: AnalysisItem[] = []
  const unmatchedText: string[] = []
  for (const phrase of phrases) {
    const matched = analyzeDeterministically(phrase.matchPhrase, catalog)
    if (matched.items.length > 0) items.push(...matched.items)
    else if (!unmatchedText.includes(phrase.name)) unmatchedText.push(phrase.name)
  }

  return {
    analysis: {
      normalizedInput: direct.normalizedInput,
      items: items.map((item, index) => ({ ...item, itemKey: `item-${index + 1}` })),
      unmatchedText,
    },
    extraction,
    extractionFailureReason: null,
  }
}

function mergeCatalogs(left: CatalogFood[], right: CatalogFood[]): CatalogFood[] {
  const byId = new Map(left.map((food) => [food.id, food]))
  for (const food of right) byId.set(food.id, food)
  return [...byId.values()]
}

async function persistResult(
  context: SupabaseContext,
  runId: string,
  output: AnalyzeMealResponse,
  latencyMs: number,
  grounding: GroundingOutcome | null,
  vision: { inputTokens: number; outputTokens: number; attempts: number } | null,
  visionFallbackReason: string | null,
  estimation: EstimationOutcome | null,
  textExtraction: TextExtraction | null,
): Promise<void> {
  // Estimate items live in analysis_estimates, not in the catalog-grounded
  // candidate set the commit RPC re-validates food ids against.
  const candidates = output.items.filter((item) => item.foodId !== null).map((item) => ({
    analysis_run_id: runId,
    item_key: item.itemKey,
    food_id: item.foodId,
    rank: 1,
    retrieval_score: item.confidence,
    selected: true,
    rationale: {
      method: item.matchMethod,
      needsClarification: item.needsClarification,
      clarificationReason: item.clarificationReason ?? null,
    },
  }))
  // A re-run that resolves fewer items must not leave stale candidate rows
  // behind: the commit RPC trusts this table, so leftovers from a previous
  // attempt would stay committable. Candidates are only read after the run
  // completes, so delete-then-insert needs no transaction here.
  const { error: clearError } = await context.supabaseAdmin
    .from('analysis_candidates')
    .delete()
    .eq('analysis_run_id', runId)
  if (clearError) throw clearError
  if (candidates.length > 0) {
    const { error: candidateError } = await context.supabaseAdmin
      .from('analysis_candidates')
      .insert(candidates)
    if (candidateError) throw candidateError
  }

  // Text extraction is a paid provider call on the text path, so it has to be
  // counted here or the cost dashboard under-reports every text-only analysis.
  const inputTokens = (grounding?.selection.inputTokens ?? 0) + (vision?.inputTokens ?? 0) +
    (estimation?.result.inputTokens ?? 0) + (textExtraction?.inputTokens ?? 0)
  const outputTokens = (grounding?.selection.outputTokens ?? 0) + (vision?.outputTokens ?? 0) +
    (estimation?.result.outputTokens ?? 0) + (textExtraction?.outputTokens ?? 0)
  const embeddingTokens = grounding?.embeddingPromptTokens ?? 0
  const attempts = (grounding?.selection.attempts ?? 0) + (vision?.attempts ?? 0) +
    (estimation?.result.attempts ?? 0) + (textExtraction?.attempts ?? 0)

  const { error: runError } = await context.supabaseAdmin
    .from('analysis_runs')
    .update({
      status: 'needs_review',
      output,
      model_name: grounding?.selection.model ?? output.pipeline.model,
      prompt_version: grounding?.selection.promptVersion ?? output.pipeline.promptVersion ?? null,
      retrieval_version: 'hybrid-rrf-v1',
      latency_ms: latencyMs,
      provider_input_tokens: inputTokens,
      provider_output_tokens: outputTokens,
      embedding_input_tokens: embeddingTokens,
      provider_attempts: attempts || null,
      vision_fallback_reason: visionFallbackReason,
      retrieval_cache_hit: grounding?.cacheHit ?? null,
      response_cache_hit: grounding?.selection.cacheHit ?? null,
      estimate_item_count: estimation?.items.length ?? 0,
      estimated_cost_micros: estimateCostMicros({ inputTokens, outputTokens, embeddingTokens }),
      completed_at: new Date().toISOString(),
      error_code: null,
      error_detail: null,
    })
    .eq('id', runId)
  if (runError) throw runError
}

interface GroundingResult {
  candidates: RetrievalCandidate[]
  selection: CandidateSelectionResult
  cacheHit: boolean
  embeddingPromptTokens: number
}

interface GroundingOutcome {
  items: AnalysisItem[]
  selection: CandidateSelectionResult
  cacheHit: boolean
  embeddingPromptTokens: number
}

/**
 * Grounds each unmatched food separately.
 *
 * These used to be joined into one query string, so "ayran" and "pilav" became
 * the single search "ayran pilav" and retrieval had to rank one blended query
 * against two different foods. One search per food is what the retrieval and
 * the allow-listed selector were both designed for.
 *
 * Items are built per query and only the telemetry is merged. Pooling the
 * candidates first would let one food's runner-ups become another food's
 * identity alternatives, and the "are the top two nearly tied?" ambiguity check
 * would compare scores across unrelated searches.
 */
async function groundUnmatchedItems(
  context: SupabaseContext,
  input: {
    queries: string[]
    locale: 'tr-TR' | 'en-US'
    existingFoodIds: Set<string>
  },
): Promise<GroundingOutcome | null> {
  const claimedFoodIds = new Set(input.existingFoodIds)
  const resolved: Array<{ selection: CandidateSelectionResult; candidates: RetrievalCandidate[] }> =
    []
  const merged: GroundingOutcome = {
    items: [],
    selection: {
      selections: [],
      noMatch: true,
      model: '',
      promptVersion: CANDIDATE_SELECTION_PROMPT_VERSION,
      inputTokens: 0,
      outputTokens: 0,
      attempts: 0,
      cacheHit: true,
    },
    cacheHit: true,
    embeddingPromptTokens: 0,
  }
  let grounded = false

  for (const query of input.queries) {
    const result = await groundUnmatchedText(context, {
      query,
      locale: input.locale,
      existingFoodIds: claimedFoodIds,
    })
    if (!result) continue
    grounded = true
    for (const selection of result.selection.selections) claimedFoodIds.add(selection.candidateId)
    resolved.push({ selection: result.selection, candidates: result.candidates })
    merged.selection.selections.push(...result.selection.selections)
    merged.selection.noMatch = merged.selection.noMatch && result.selection.noMatch
    merged.selection.model = merged.selection.model || result.selection.model
    merged.selection.inputTokens += result.selection.inputTokens
    merged.selection.outputTokens += result.selection.outputTokens
    merged.selection.attempts += result.selection.attempts
    merged.selection.cacheHit = merged.selection.cacheHit && result.selection.cacheHit
    merged.cacheHit = merged.cacheHit && result.cacheHit
    merged.embeddingPromptTokens += result.embeddingPromptTokens
  }

  if (!grounded) return null

  // One query for every grounded food, after all selections are known, so the
  // portion sheet can offer real catalog portions instead of multiples of the
  // model's gram guess.
  const portionsByFood = await loadPortionsForFoods(
    context,
    input.locale,
    merged.selection.selections.map((selection) => selection.candidateId),
  )
  for (const entry of resolved) {
    merged.items.push(...toAnalysisItems(entry.selection, entry.candidates, portionsByFood))
  }

  return merged
}

async function groundUnmatchedText(
  context: SupabaseContext,
  input: {
    query: string
    locale: 'tr-TR' | 'en-US'
    existingFoodIds: Set<string>
  },
): Promise<GroundingResult | null> {
  if (input.query.trim().length < 2) return null
  const apiKey = Deno.env.get('OPENAI_API_KEY')?.trim()
  if (!apiKey) return null
  const userId = userIdFromClaims(context.userClaims)
  if (!userId) throw new Error('Authenticated user is unavailable')
  await enforceAnalysisBudget(context, userId)

  // Retrieval and selection fail for different reasons and must not collapse
  // into one error class: retrieval is our Postgres/embedding side, selection
  // is the model provider. Reporting a broken RPC as "provider unavailable"
  // sent users a retry message for a fault retrying could never clear.
  let candidates: RetrievalCandidate[]
  let retrievalCacheHit: boolean
  let embeddingPromptTokens: number
  try {
    const retrieval = await hybridSearch(context.supabase, context.supabaseAdmin, {
      query: input.query,
      locale: input.locale,
      limit: 10,
      openAiApiKey: apiKey,
    })
    candidates = retrieval.rows.map(toRetrievalCandidate).filter((candidate) =>
      candidate !== null && !input.existingFoodIds.has(candidate.foodId)
    ) as RetrievalCandidate[]
    retrievalCacheHit = retrieval.cacheHit
    embeddingPromptTokens = retrieval.embeddingPromptTokens
  } catch (error) {
    const detail = providerErrorDetail(error)
    redactedLog('error', 'candidate_retrieval_failed', {
      errorType: detail.type,
      errorCode: detail.code,
      errorMessage: detail.message,
    })
    throw new GroundingUnavailableError(detail.message, 'retrieval')
  }

  // No acceptable candidate is a product outcome ("not in the catalog"), not a
  // failure. It falls through to the estimate path and then to NO_MATCH.
  if (candidates.length === 0) return null

  try {
    const selection = await cachedCandidateSelection(context.supabaseAdmin, {
      apiKey,
      locale: input.locale,
      input: input.query,
      candidates,
    })
    return { candidates, selection, cacheHit: retrievalCacheHit, embeddingPromptTokens }
  } catch (error) {
    if (error instanceof AnalysisBudgetExceededError) throw error
    const detail = providerErrorDetail(error)
    redactedLog('info', 'candidate_selection_fallback', {
      errorType: detail.type,
      errorCode: detail.code,
      errorMessage: detail.message,
    })
    // A provider outage is not the same as "this food is not in the catalog".
    // Telling them apart keeps a broken grounding step from being reported to
    // the user as their own vague description.
    throw new GroundingUnavailableError(detail.message, 'provider')
  }
}

export type GroundingFailureKind = 'provider' | 'retrieval'

export class GroundingUnavailableError extends Error {
  constructor(detail: string, readonly kind: GroundingFailureKind = 'provider') {
    super(`Candidate grounding is unavailable (${kind}): ${detail}`)
    this.name = 'GroundingUnavailableError'
  }
}

async function enforceAnalysisBudget(
  context: SupabaseContext,
  userId: string,
): Promise<void> {
  const userLimit = positiveIntegerEnv('ANALYSIS_USER_DAILY_BUDGET_MICROS', 100_000)
  const globalLimit = positiveIntegerEnv('ANALYSIS_GLOBAL_DAILY_BUDGET_MICROS', 2_000_000)
  const requestReserve = positiveIntegerEnv('ANALYSIS_REQUEST_RESERVE_MICROS', 20_000)
  const { data, error } = await context.supabaseAdmin.rpc('analysis_cost_budget_check', {
    p_user_id: userId,
    p_user_limit_micros: userLimit,
    p_global_limit_micros: globalLimit,
    p_request_reserve_micros: requestReserve,
  })
  if (error) throw error
  if ((data as { allowed?: unknown } | null)?.allowed !== true) {
    throw new AnalysisBudgetExceededError()
  }
}

function positiveIntegerEnv(name: string, fallback: number): number {
  const parsed = Number(Deno.env.get(name))
  return Number.isSafeInteger(parsed) && parsed > 0 ? parsed : fallback
}

function estimateCostMicros(input: {
  inputTokens: number
  outputTokens: number
  embeddingTokens: number
}): number {
  // Versioned 2026-08-18 standard prices per 1M tokens:
  // gpt-5.4-nano input $0.20, output $1.25; text-embedding-3-small $0.02.
  return Math.round(
    input.inputTokens * 0.20 + input.outputTokens * 1.25 + input.embeddingTokens * 0.02,
  )
}

async function cachedCandidateSelection(
  client: SupabaseClient,
  input: {
    apiKey: string
    locale: 'tr-TR' | 'en-US'
    input: string
    candidates: RetrievalCandidate[]
  },
): Promise<CandidateSelectionResult> {
  const model = Deno.env.get('OPENAI_SELECTION_MODEL')?.trim() || 'gpt-5.4-nano'
  const normalized = input.input.normalize('NFKC').trim().replace(/\s+/g, ' ')
    .toLocaleLowerCase(input.locale)
  const queryHash = await sha256(normalized)
  const candidateFingerprint = await sha256(JSON.stringify(
    input.candidates.map((candidate) => ({
      id: candidate.foodId,
      score: candidate.score,
      grams: candidate.defaultGrams,
    })).sort((left, right) => left.id.localeCompare(right.id)),
  ))
  const secretSalt = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')?.trim() || 'local-development'
  const cacheKey = await sha256(
    `${secretSalt}|${input.locale}|${model}|${CANDIDATE_SELECTION_PROMPT_VERSION}|${queryHash}|${candidateFingerprint}`,
  )
  const { data: cached } = await client.from('ai_selection_cache')
    .select('selection,hit_count').eq('cache_key', cacheKey)
    .gt('expires_at', new Date().toISOString()).maybeSingle()
  const restored = restoreCachedSelection(cached?.selection, input.candidates, model)
  if (restored) {
    await client.from('ai_selection_cache').update({
      hit_count: Number(cached?.hit_count ?? 0) + 1,
    }).eq('cache_key', cacheKey)
    return restored
  }

  const selection = await selectCatalogCandidates({ ...input, model })
  await client.from('ai_selection_cache').upsert({
    cache_key: cacheKey,
    query_hash: queryHash,
    locale: input.locale,
    model,
    prompt_version: CANDIDATE_SELECTION_PROMPT_VERSION,
    candidate_fingerprint: candidateFingerprint,
    selection: {
      selections: selection.selections,
      noMatch: selection.noMatch,
    },
    expires_at: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
  })
  return selection
}

function restoreCachedSelection(
  value: unknown,
  candidates: RetrievalCandidate[],
  model: string,
): CandidateSelectionResult | null {
  if (typeof value !== 'object' || value === null) return null
  const row = value as Record<string, unknown>
  if (!Array.isArray(row.selections) || typeof row.noMatch !== 'boolean') return null
  const allowedIds = new Set(candidates.map((candidate) => candidate.foodId))
  const selections = row.selections.flatMap((entry) => {
    if (typeof entry !== 'object' || entry === null) return []
    const item = entry as Record<string, unknown>
    const candidateId = typeof item.candidateId === 'string' ? item.candidateId : ''
    const sourceText = typeof item.sourceText === 'string' ? item.sourceText.trim() : ''
    const estimatedGrams = Number(item.estimatedGrams)
    const confidence = Number(item.confidence)
    if (
      !allowedIds.has(candidateId) || !sourceText || !Number.isFinite(estimatedGrams) ||
      estimatedGrams < 1 || estimatedGrams > 3000 || !Number.isFinite(confidence) ||
      confidence < 0 || confidence > 1
    ) return []
    return [{ candidateId, sourceText, estimatedGrams, confidence }]
  })
  if (!row.noMatch && selections.length === 0) return null
  return {
    selections,
    noMatch: row.noMatch,
    model,
    promptVersion: CANDIDATE_SELECTION_PROMPT_VERSION,
    inputTokens: 0,
    outputTokens: 0,
    attempts: 0,
    cacheHit: true,
  }
}

function providerErrorDetail(
  error: unknown,
): { type: string; code: string | null; message: string } {
  if (error instanceof Error) {
    return { type: error.name, code: null, message: error.message.slice(0, 180) }
  }
  if (typeof error === 'object' && error !== null) {
    const row = error as Record<string, unknown>
    return {
      type: 'ProviderError',
      code: typeof row.code === 'string' ? row.code : null,
      message: typeof row.message === 'string'
        ? row.message.slice(0, 180)
        : 'Unknown provider error',
    }
  }
  return { type: 'UnknownError', code: null, message: 'Unknown provider error' }
}

function toRetrievalCandidate(row: Record<string, unknown>): RetrievalCandidate | null {
  const defaultGrams = Number(row.default_grams)
  if (!row.food_id || !Number.isFinite(defaultGrams) || defaultGrams <= 0) return null
  return {
    foodId: String(row.food_id),
    canonicalName: String(row.canonical_name),
    matchedAlias: String(row.matched_alias),
    score: Number(row.score),
    defaultGrams,
    defaultPortionLabel: String(row.default_portion_label),
    nutritionPer100g: {
      calories: Number(row.calories_per_100g),
      protein: Number(row.protein_per_100g),
      carbs: Number(row.carbs_per_100g),
      fat: Number(row.fat_per_100g),
    },
  }
}

/**
 * Real catalog portions when the food has them, falling back to the single
 * default carried by retrieval. Two or more options is what lets the client
 * show a genuine size choice rather than synthesising one.
 */
function portionOptionsFor(
  candidate: RetrievalCandidate,
  portionsByFood: Map<string, CatalogPortion[]>,
): AnalysisItem['portionOptions'] {
  const portions = portionsByFood.get(candidate.foodId) ?? []
  if (portions.length === 0) {
    return [{
      label: candidate.defaultPortionLabel,
      grams: candidate.defaultGrams,
      sizeClass: 'regular' as const,
    }]
  }
  return portions
    .slice()
    .sort((left, right) => left.grams - right.grams)
    .map((portion) => ({
      label: portion.label,
      grams: portion.grams,
      ...(portion.sizeClass ? { sizeClass: portion.sizeClass } : {}),
      ...(portion.imageUrl ? { imageUrl: portion.imageUrl } : {}),
    }))
}

function toAnalysisItems(
  selection: CandidateSelectionResult,
  candidates: RetrievalCandidate[],
  portionsByFood: Map<string, CatalogPortion[]>,
): AnalysisItem[] {
  if (selection.noMatch) return []
  const byId = new Map(candidates.map((candidate) => [candidate.foodId, candidate]))
  return selection.selections.flatMap((selected, index) => {
    const candidate = byId.get(selected.candidateId)
    if (!candidate) return []
    // "tavuk" must be able to ask "which chicken?": when retrieval scores are
    // nearly tied or the model itself is unsure of the identity, the
    // clarification is about the food, not the portion, and the runner-up
    // candidates give the client something to offer.
    const alternatives = candidates
      .filter((other) => other.foodId !== candidate.foodId)
      .sort((left, right) => right.score - left.score)
    const identityAmbiguous = selected.confidence < IDENTITY_CONFIDENCE_GATE ||
      (alternatives.length > 0 && candidate.score - alternatives[0].score < IDENTITY_SCORE_GAP)
    const alternativeFoodIds = alternatives
      .slice(0, MAX_IDENTITY_ALTERNATIVES)
      .map((other) => other.foodId)
    return [{
      itemKey: `item-grounded-${index + 1}`,
      sourceText: selected.sourceText,
      foodId: candidate.foodId,
      canonicalName: candidate.canonicalName,
      portionLabel: `${Math.round(selected.estimatedGrams)} g`,
      grams: selected.estimatedGrams,
      quantity: 1,
      confidence: Math.round(Math.min(selected.confidence, candidate.score) * 100) / 100,
      matchMethod: 'llm' as const,
      needsClarification: true,
      clarificationReason: identityAmbiguous ? 'identity' as const : 'portion' as const,
      ...(identityAmbiguous && alternativeFoodIds.length > 0 ? { alternativeFoodIds } : {}),
      portionOptions: portionOptionsFor(candidate, portionsByFood),
      nutritionPer100g: candidate.nutritionPer100g,
    }]
  })
}

interface EstimationOutcome {
  items: AnalysisItem[]
  result: MacroEstimateResult
}

async function tryEstimateFallback(
  context: SupabaseContext,
  userId: string,
  input: { locale: 'tr-TR' | 'en-US'; texts: string[] },
): Promise<EstimationOutcome | null> {
  const apiKey = Deno.env.get('OPENAI_API_KEY')?.trim()
  if (!apiKey) return null
  try {
    // Same cost gate as every other model call: an exhausted budget skips the
    // estimate instead of failing an otherwise-useful response.
    await enforceAnalysisBudget(context, userId)
    const result = await estimateUnmatchedFoods({
      apiKey,
      locale: input.locale,
      foods: input.texts,
    })
    const items = result.estimates.map((estimate, index): AnalysisItem => ({
      // Rekeyed with the rest of the items once the full list is assembled.
      itemKey: `item-estimate-${index + 1}`,
      sourceText: estimate.sourceText,
      foodId: null,
      canonicalName: estimate.displayName,
      portionLabel: `${Math.round(estimate.estimatedGrams)} g`,
      grams: estimate.estimatedGrams,
      quantity: 1,
      confidence: Math.round(estimate.confidence * 100) / 100,
      matchMethod: 'ai_estimate' as const,
      needsClarification: true,
      clarificationReason: 'portion' as const,
      estimateId: crypto.randomUUID(),
      estimated: true,
      nutritionPer100g: estimate.nutritionPer100g,
    }))
    return { items, result }
  } catch (error) {
    // Estimation is best-effort on top of the previous NO_MATCH behavior, so
    // any failure (budget, provider, refusal) falls back to the old outcome.
    const detail = providerErrorDetail(error)
    redactedLog('info', 'macro_estimate_fallback_failed', {
      errorType: detail.type,
      errorCode: detail.code,
      errorMessage: detail.message,
    })
    return null
  }
}

async function persistEstimates(
  context: SupabaseContext,
  runId: string,
  estimation: EstimationOutcome,
): Promise<void> {
  // A retried run must not collide with estimate rows from an earlier attempt,
  // so the run's estimates are replaced wholesale (mirrors the candidate set).
  const { error: clearError } = await context.supabaseAdmin
    .from('analysis_estimates')
    .delete()
    .eq('analysis_run_id', runId)
  if (clearError) throw clearError
  const rows = estimation.items.map((item) => ({
    id: item.estimateId,
    analysis_run_id: runId,
    item_key: item.itemKey,
    display_name: item.canonicalName,
    estimated_grams: item.grams,
    calories_per_100g: item.nutritionPer100g.calories,
    protein_per_100g: item.nutritionPer100g.protein,
    carbs_per_100g: item.nutritionPer100g.carbs,
    fat_per_100g: item.nutritionPer100g.fat,
    confidence: item.confidence,
    model: estimation.result.model,
    prompt_version: estimation.result.promptVersion,
  }))
  const { error } = await context.supabaseAdmin.from('analysis_estimates').insert(rows)
  if (error) throw error
}

async function markRunFailed(
  context: SupabaseContext,
  runId: string,
  code: string,
  detail: string,
  visionFallbackReason: string | null = null,
): Promise<void> {
  const { error } = await context.supabaseAdmin.from('analysis_runs').update({
    status: 'failed',
    error_code: code,
    error_detail: detail.slice(0, 500),
    // Kept even on failure: "no_food_detected" on a NO_MATCH run is the signal
    // that the photo, not the pipeline, produced the empty result.
    vision_fallback_reason: visionFallbackReason,
    completed_at: new Date().toISOString(),
  }).eq('id', runId)
  if (error) redactedLog('error', 'analysis_failure_persistence_failed', { analysisRunId: runId })
}

function groupByFood<T>(
  rows: Array<Record<string, unknown>> | null,
  map: (row: Record<string, unknown>) => T,
): Map<string, T[]> {
  const grouped = new Map<string, T[]>()
  for (const row of rows ?? []) {
    const foodId = String(row.food_id)
    grouped.set(foodId, [...(grouped.get(foodId) ?? []), map(row)])
  }
  return grouped
}

function normalizeSizeClass(
  value: unknown,
): 'small' | 'regular' | 'large' | 'custom' | undefined {
  return value === 'small' || value === 'regular' || value === 'large' || value === 'custom'
    ? value
    : undefined
}

function userIdFromClaims(claims?: Record<string, unknown>): string | null {
  const value = claims?.sub ?? claims?.id
  return typeof value === 'string' && value.length > 0 ? value : null
}

function safeErrorMessage(error: unknown): string {
  return error instanceof Error ? error.message.slice(0, 500) : 'Unknown error'
}
