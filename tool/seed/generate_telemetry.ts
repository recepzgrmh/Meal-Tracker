import { writeFileSync, readFileSync } from 'node:fs'
import { join } from 'node:path'
import { fileURLToPath } from 'node:url'

// Generator for 7-day realistic telemetry seed data in Postgres / Supabase
const repoRoot = fileURLToPath(new URL('../../', import.meta.url))
const baseSeedPath = join(repoRoot, 'supabase/seed.sql')
const existingSeed = readFileSync(baseSeedPath, 'utf-8')

const sqlStatements: string[] = []

sqlStatements.push(`
-- ============================================================================
-- REALISTIC 7-DAY DEMO TELEMETRY & AUDIT SEED DATA
-- Generated to populate Admin Dashboard metrics, traces, latency histograms,
-- quality calibration, version comparisons, and review queue.
-- ============================================================================
`)

// 1. Ensure test/demo users exist in public.profiles (if table exists)
const demoUserId = '00000000-0000-0000-0000-000000000001'
const demoUserId2 = '00000000-0000-0000-0000-000000000002'
const demoUserId3 = '00000000-0000-0000-0000-000000000003'

// 2. Sample inputs and outputs
const sampleMealQueries = [
  { text: 'kahvaltıda 2 haşlanmış yumurta ve 30g beyaz peynir', kind: 'text', foods: ['10000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000002'], grams: [100, 30], confidence: 0.95, method: 'deterministic' },
  { text: '1 simit ve çay', kind: 'text', foods: ['10000000-0000-0000-0000-000000000003'], grams: [100], confidence: 0.98, method: 'deterministic' },
  { text: 'yarım simit ve 50g beyaz peynir', kind: 'text', foods: ['10000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000002'], grams: [50, 50], confidence: 0.90, method: 'hybrid' },
  { text: '3 yumurta', kind: 'text', foods: ['10000000-0000-0000-0000-000000000001'], grams: [150], confidence: 0.92, method: 'deterministic' },
  { text: 'kahvaltı: 2 yumurta + 30g peynir + 1 simit', kind: 'text', foods: ['10000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000003'], grams: [100, 30, 100], confidence: 0.96, method: 'deterministic' },
  { text: 'fotoğraf çekimi kahvaltı tabağı', kind: 'photo', foods: ['10000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000003'], grams: [50, 30, 100], confidence: 0.85, method: 'vision' },
  { text: 'kremalı tavuklu makarna', kind: 'text', foods: ['10000000-0000-0000-0000-000000000001'], grams: [170], confidence: 0.75, method: 'ai_estimate' },
  { text: 'bir yumurta biraz peynir yarım simit', kind: 'mixed', foods: ['10000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000003'], grams: [50, 15, 50], confidence: 0.88, method: 'hybrid' },
  { text: '0 yumurta yedim', kind: 'text', foods: ['10000000-0000-0000-0000-000000000001'], grams: [50], confidence: 0.84, method: 'deterministic' },
  { text: 'avokadolu tost', kind: 'text', foods: [], grams: [], confidence: 0.0, method: 'none' }
]

const foodNames: Record<string, string> = {
  '10000000-0000-0000-0000-000000000001': 'Tavuk Yumurtası, Haşlanmış',
  '10000000-0000-0000-0000-000000000002': 'Beyaz Peynir, Tam Yağlı',
  '10000000-0000-0000-0000-000000000003': 'Simit'
}

const foodCalories: Record<string, number> = {
  '10000000-0000-0000-0000-000000000001': 155,
  '10000000-0000-0000-0000-000000000002': 289,
  '10000000-0000-0000-0000-000000000003': 340
}

const foodProtein: Record<string, number> = {
  '10000000-0000-0000-0000-000000000001': 12.6,
  '10000000-0000-0000-0000-000000000002': 16.0,
  '10000000-0000-0000-0000-000000000003': 10.0
}

const foodCarbs: Record<string, number> = {
  '10000000-0000-0000-0000-000000000001': 1.1,
  '10000000-0000-0000-0000-000000000002': 2.5,
  '10000000-0000-0000-0000-000000000003': 57.0
}

const foodFat: Record<string, number> = {
  '10000000-0000-0000-0000-000000000001': 10.6,
  '10000000-0000-0000-0000-000000000002': 24.0,
  '10000000-0000-0000-0000-000000000003': 8.0
}

// Generate 120 analysis runs over the last 7 days
const TOTAL_RUNS = 120
const nowMs = Date.now()
const users = [demoUserId, demoUserId2, demoUserId3]

sqlStatements.push(`-- Clean up existing demo telemetry to avoid duplicates on re-seed
delete from public.meal_item_corrections where meal_item_id in (select id from public.meal_items where meal_id in (select id from public.meals where user_id in ('${demoUserId}', '${demoUserId2}', '${demoUserId3}')));
delete from public.meal_items where meal_id in (select id from public.meals where user_id in ('${demoUserId}', '${demoUserId2}', '${demoUserId3}'));
delete from public.meals where user_id in ('${demoUserId}', '${demoUserId2}', '${demoUserId3}');
delete from public.analysis_candidates where analysis_run_id in (select id from public.analysis_runs where user_id in ('${demoUserId}', '${demoUserId2}', '${demoUserId3}'));
delete from public.analysis_runs where user_id in ('${demoUserId}', '${demoUserId2}', '${demoUserId3}');
`)

for (let i = 0; i < TOTAL_RUNS; i++) {
  const runId = `a0000000-0000-4000-8000-${(i + 1).toString(16).padStart(12, '0')}`
  const traceId = `t0000000-0000-4000-8000-${(i + 1).toString(16).padStart(12, '0')}`
  const reqId = `c0000000-0000-4000-8000-${(i + 1).toString(16).padStart(12, '0')}`
  const userId = users[i % users.length]
  
  // Distribute over 7 days (day 0 to day 6 ago)
  const dayOffsetDays = (i % 7) + (Math.random() * 0.8)
  const createdAtMs = nowMs - Math.floor(dayOffsetDays * 86400000)
  const createdAt = new Date(createdAtMs).toISOString()
  
  const queryObj = sampleMealQueries[i % sampleMealQueries.length]
  
  // Status: 85% completed, 10% needs_review, 5% failed
  let status = 'completed'
  let errorCode: string | null = null
  let errorDetail: string | null = null
  if (i % 20 === 19) {
    status = 'failed'
    errorCode = i % 2 === 0 ? 'PROVIDER_TIMEOUT' : 'NO_MATCH'
    errorDetail = errorCode === 'PROVIDER_TIMEOUT' ? 'OpenAI request timed out after 12000ms' : 'No matching catalog item found above threshold'
  } else if (i % 10 === 9) {
    status = 'needs_review'
  }

  const isPhoto = queryObj.kind === 'photo' || queryObj.kind === 'mixed'
  const imagePath = isPhoto ? `${userId}/${reqId}/source.png` : null
  const latencyMs = isPhoto ? 5400 + (i % 3500) : 1800 + (i % 2200)
  const completedAt = new Date(createdAtMs + latencyMs).toISOString()

  // Versions: 80% gpt-5.4-nano / tr-v2.1, 20% older gpt-4o-mini / tr-v1.8 for version comparison
  const isOlderVersion = i % 5 === 0
  const modelName = isOlderVersion ? 'gpt-4o-mini' : 'gpt-5.4-nano'
  const promptVersion = isOlderVersion ? 'tr-v1.8' : 'tr-v2.1'
  const retrievalVersion = 'hybrid-rrf-v1'

  const providerAttempts = i % 15 === 14 ? 2 : 1
  const inputTokens = isPhoto ? 1420 + (i % 300) : 480 + (i % 150)
  const outputTokens = 150 + (i % 80)
  const embeddingTokens = 24 + (i % 12)
  const costMicros = Math.round((inputTokens * 0.20 + outputTokens * 1.25 + embeddingTokens * 0.02) * 10)

  const retrievalCacheHit = i % 3 === 0
  const responseCacheHit = i % 5 === 0
  const visionFallbackReason = (isPhoto && i % 4 === 0) ? 'low_confidence' : null

  // Output JSON
  const itemsOutput = queryObj.foods.map((foodId, idx) => ({
    itemId: `item-${i}-${idx}`,
    itemKey: `key-${i}-${idx}`,
    foodId,
    canonicalName: foodNames[foodId],
    portionLabel: `${queryObj.grams[idx]} g`,
    grams: queryObj.grams[idx],
    calories: Math.round(foodCalories[foodId] * queryObj.grams[idx] / 100),
    confidence: queryObj.confidence,
    matchMethod: queryObj.method,
    needsClarification: queryObj.confidence < 0.85
  }))

  const outputJson = JSON.stringify({
    contractVersion: 'meal-analysis.v1',
    analysisRunId: runId,
    inputKind: queryObj.kind,
    items: itemsOutput
  }).replace(/'/g, "''")

  sqlStatements.push(`
insert into public.analysis_runs (
  id, user_id, client_request_id, trace_id, raw_input, input_kind, image_path, status,
  model_name, prompt_version, retrieval_version, latency_ms, error_code, error_detail,
  provider_attempts, provider_input_tokens, provider_output_tokens, embedding_input_tokens,
  estimated_cost_micros, retrieval_cache_hit, response_cache_hit, vision_fallback_reason,
  output, created_at, completed_at
) values (
  '${runId}', '${userId}', '${reqId}', '${traceId}', '${queryObj.text.replace(/'/g, "''")}', '${queryObj.kind}', ${imagePath ? `'${imagePath}'` : 'null'}, '${status}',
  '${modelName}', '${promptVersion}', '${retrievalVersion}', ${latencyMs}, ${errorCode ? `'${errorCode}'` : 'null'}, ${errorDetail ? `'${errorDetail}'` : 'null'},
  ${providerAttempts}, ${inputTokens}, ${outputTokens}, ${embeddingTokens},
  ${costMicros}, ${retrievalCacheHit}, ${responseCacheHit}, ${visionFallbackReason ? `'${visionFallbackReason}'` : 'null'},
  '${outputJson}'::jsonb, '${createdAt}', '${completedAt}'
);
`)

  // Candidates for this run
  queryObj.foods.forEach((foodId, idx) => {
    sqlStatements.push(`
insert into public.analysis_candidates (
  analysis_run_id, item_key, food_id, rank, retrieval_score, rerank_score, selected, rationale
) values (
  '${runId}', 'key-${i}-${idx}', '${foodId}', 1, 0.92, 0.95, true, '{"method": "${queryObj.method}", "score": ${queryObj.confidence}}'::jsonb
);
`)
  })

  // If status is completed or needs_review, create committed meal & items for 70% of runs
  if (status !== 'failed' && i % 10 < 7 && queryObj.foods.length > 0) {
    const mealId = `m0000000-0000-4000-8000-${(i + 1).toString(16).padStart(12, '0')}`
    const commitReqId = `cm000000-0000-4000-8000-${(i + 1).toString(16).padStart(12, '0')}`
    
    sqlStatements.push(`
insert into public.meals (
  id, user_id, analysis_run_id, client_request_id, name, raw_input, occurred_at, image_path, created_at
) values (
  '${mealId}', '${userId}', '${runId}', '${commitReqId}', 'Öğün Kaydı ${i + 1}', '${queryObj.text.replace(/'/g, "''")}', '${createdAt}', ${imagePath ? `'${imagePath}'` : 'null'}, '${createdAt}'
);
`)

    queryObj.foods.forEach((foodId, idx) => {
      const itemId = `mi000000-0000-4000-8000-${(i + 1).toString(16).padStart(8, '0')}-${idx}`
      const originalGrams = queryObj.grams[idx]
      // 15% of items were corrected by the user in review!
      const isCorrected = i % 7 === 0
      const reviewStatus = isCorrected ? 'corrected' : (i % 2 === 0 ? 'accepted' : 'unreviewed')
      const finalGrams = isCorrected ? originalGrams * 1.5 : originalGrams
      
      const cal100 = foodCalories[foodId]
      const prot100 = foodProtein[foodId]
      const carb100 = foodCarbs[foodId]
      const fat100 = foodFat[foodId]

      const itemCalories = Math.round(cal100 * finalGrams / 100)
      const itemProtein = Math.round(prot100 * finalGrams / 100 * 10) / 10
      const itemCarbs = Math.round(carb100 * finalGrams / 100 * 10) / 10
      const itemFat = Math.round(fat100 * finalGrams / 100 * 10) / 10

      sqlStatements.push(`
insert into public.meal_items (
  id, meal_id, food_id, item_key, source_text, portion_label, grams,
  calories, protein, carbs, fat, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  confidence, match_method, review_status, canonical_name
) values (
  '${itemId}', '${mealId}', '${foodId}', 'key-${i}-${idx}', '${queryObj.text.replace(/'/g, "''")}', '${finalGrams} g', ${finalGrams},
  ${itemCalories}, ${itemProtein}, ${itemCarbs}, ${itemFat}, ${cal100}, ${prot100}, ${carb100}, ${fat100},
  ${queryObj.confidence}, '${queryObj.method}', '${reviewStatus}', '${foodNames[foodId]}'
);
`)

      if (isCorrected) {
        sqlStatements.push(`
insert into public.meal_item_corrections (
  meal_item_id, reason, before_value, after_value, created_at
) values (
  '${itemId}', 'wrong_portion', '{"grams": ${originalGrams}}'::jsonb, '{"grams": ${finalGrams}}'::jsonb, '${completedAt}'
);
`)
      }
    })
  }
}

// 3. Persisted Eval Runs for AI Evals page
const evalRunId1 = 'e0000000-0000-4000-8000-000000000001'
const evalRunId2 = 'e0000000-0000-4000-8000-000000000002'

sqlStatements.push(`
delete from public.eval_cases where eval_run_id in ('${evalRunId1}', '${evalRunId2}');
delete from public.eval_runs where id in ('${evalRunId1}', '${evalRunId2}');

insert into public.eval_runs (
  id, kind, suite, git_ref, model, prompt_version, started_at, finished_at,
  case_count, passed_count, metrics, cost_micros, notes, created_at
) values (
  '${evalRunId1}', 'deterministic', 'turkish_meals_v1', 'main@a1b2c3d', null, 'deterministic-tr-v1',
  '${new Date(nowMs - 86400000 * 2).toISOString()}', '${new Date(nowMs - 86400000 * 2 + 1500).toISOString()}',
  63, 63, '{"exactCaseAccuracy": 1.0, "foodIdentityF1": 1.0, "portionMape": 0.0, "noMatchSpecificity": 1.0}'::jsonb,
  0, 'CI automated deterministic gate run', '${new Date(nowMs - 86400000 * 2).toISOString()}'
), (
  '${evalRunId2}', 'live', 'bilingual_hybrid_v1', 'main@a1b2c3d', 'gpt-5.4-nano', 'tr-v2.1',
  '${new Date(nowMs - 86400000 * 1).toISOString()}', '${new Date(nowMs - 86400000 * 1 + 45000).toISOString()}',
  26, 24, '{"passRate": 0.923, "identityExactAccuracy": 0.961, "noMatchAccuracy": 1.0, "portionMape": 0.042, "latencyP50Ms": 3400, "latencyP95Ms": 7800, "retrievalCacheHitRate": 0.65, "responseCacheHitRate": 0.35}'::jsonb,
  4200, 'Live hybrid evaluation suite run', '${new Date(nowMs - 86400000 * 1).toISOString()}'
);

insert into public.eval_cases (
  eval_run_id, case_id, passed, expected, actual, failure_kind, latency_ms
) values
  ('${evalRunId1}', 'tr-001', true, '{"items": [{"foodId": "10000000-0000-0000-0000-000000000001", "grams": 50}]}'::jsonb, '{"items": [{"foodId": "10000000-0000-0000-0000-000000000001", "grams": 50}]}'::jsonb, null, 12),
  ('${evalRunId1}', 'tr-002', true, '{"items": [{"foodId": "10000000-0000-0000-0000-000000000001", "grams": 100}]}'::jsonb, '{"items": [{"foodId": "10000000-0000-0000-0000-000000000001", "grams": 100}]}'::jsonb, null, 8),
  ('${evalRunId2}', 'hybrid-001', true, '{"items": [{"foodId": "10000000-0000-0000-0000-000000000001", "grams": 100}]}'::jsonb, '{"items": [{"foodId": "10000000-0000-0000-0000-000000000001", "grams": 100}]}'::jsonb, null, 3100),
  ('${evalRunId2}', 'hybrid-002', false, '{"items": [{"foodId": "10000000-0000-0000-0000-000000000003", "grams": 100}]}'::jsonb, '{"items": [{"foodId": "10000000-0000-0000-0000-000000000003", "grams": 150}]}'::jsonb, 'portion', 4200);
`)

// Write back to seed.sql
const fullSeedContent = existingSeed + '\n' + sqlStatements.join('\n')
writeFileSync(baseSeedPath, fullSeedContent, 'utf-8')

console.log('Successfully generated 7-day realistic telemetry seed data in supabase/seed.sql!')
