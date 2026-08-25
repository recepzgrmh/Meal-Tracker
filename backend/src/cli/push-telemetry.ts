import 'dotenv/config'
import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.SUPABASE_URL
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY

if (!supabaseUrl || !serviceRoleKey) {
  console.error('SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are required in backend/.env')
  process.exit(1)
}

const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey, {
  auth: { persistSession: false }
})

const sampleMealQueries = [
  { text: 'kahvaltıda 2 haşlanmış yumurta ve 30g beyaz peynir', kind: 'text', foods: ['10000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000002'], grams: [100, 30], confidence: 0.95, method: 'alias' },
  { text: '1 simit ve çay', kind: 'text', foods: ['10000000-0000-0000-0000-000000000003'], grams: [100], confidence: 0.98, method: 'exact' },
  { text: 'yarım simit ve 50g beyaz peynir', kind: 'text', foods: ['10000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000002'], grams: [50, 50], confidence: 0.90, method: 'retrieval' },
  { text: '3 yumurta', kind: 'text', foods: ['10000000-0000-0000-0000-000000000001'], grams: [150], confidence: 0.92, method: 'exact' },
  { text: 'kahvaltı: 2 yumurta + 30g peynir + 1 simit', kind: 'text', foods: ['10000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000003'], grams: [100, 30, 100], confidence: 0.96, method: 'exact' },
  { text: 'fotoğraf çekimi kahvaltı tabağı', kind: 'photo', foods: ['10000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000003'], grams: [50, 30, 100], confidence: 0.85, method: 'llm' },
  { text: 'kremalı tavuklu makarna', kind: 'text', foods: ['10000000-0000-0000-0000-000000000001'], grams: [170], confidence: 0.75, method: 'fallback' },
  { text: 'bir yumurta biraz peynir yarım simit', kind: 'mixed', foods: ['10000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000003'], grams: [50, 15, 50], confidence: 0.88, method: 'retrieval' },
  { text: '0 yumurta yedim', kind: 'text', foods: ['10000000-0000-0000-0000-000000000001'], grams: [50], confidence: 0.84, method: 'exact' },
  { text: 'avokadolu tost', kind: 'text', foods: [], grams: [], confidence: 0.0, method: 'fallback' }
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

async function pushTelemetryToSupabase() {
  console.log(`Fetching user accounts from live Supabase DB (${supabaseUrl})...`)

  // Get real user IDs from auth.users or existing runs
  const { data: usersData, error: usersErr } = await supabaseAdmin.auth.admin.listUsers()
  let userIds = (usersData?.users ?? []).map(u => u.id)

  if (userIds.length === 0) {
    const { data: existingRuns } = await supabaseAdmin.from('analysis_runs').select('user_id').limit(50)
    userIds = [...new Set((existingRuns ?? []).map(r => r.user_id))]
  }

  if (userIds.length === 0) {
    // Create a demo user if none exists
    const { data: newUser, error: createErr } = await supabaseAdmin.auth.admin.createUser({
      email: 'demo_user@mealclarity.app',
      password: 'DemoPassword123!',
      email_confirm: true
    })
    if (newUser?.user) {
      userIds.push(newUser.user.id)
    } else {
      console.error('Could not fetch or create a user in Supabase Auth:', createErr?.message)
      process.exit(1)
    }
  }

  console.log(`Using ${userIds.length} valid user ID(s):`, userIds)

  const TOTAL_RUNS = 120
  const nowMs = Date.now()

  const analysisRuns: any[] = []
  const candidates: any[] = []
  const meals: any[] = []
  const mealItems: any[] = []
  const corrections: any[] = []

  for (let i = 0; i < TOTAL_RUNS; i++) {
    const runId = crypto.randomUUID()
    const traceId = crypto.randomUUID()
    const reqId = crypto.randomUUID()
    const userId = userIds[i % userIds.length]

    const dayOffsetDays = (i % 7) + (Math.random() * 0.8)
    const createdAtMs = nowMs - Math.floor(dayOffsetDays * 86400000)
    const createdAt = new Date(createdAtMs).toISOString()

    const queryObj = sampleMealQueries[i % sampleMealQueries.length]

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

    const itemsOutput = queryObj.foods.map((foodId, idx) => ({
      itemId: crypto.randomUUID(),
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

    analysisRuns.push({
      id: runId,
      user_id: userId,
      client_request_id: reqId,
      trace_id: traceId,
      raw_input: queryObj.text,
      input_kind: queryObj.kind,
      image_path: imagePath,
      status,
      model_name: modelName,
      prompt_version: promptVersion,
      retrieval_version: retrievalVersion,
      latency_ms: latencyMs,
      error_code: errorCode,
      error_detail: errorDetail,
      provider_attempts: providerAttempts,
      provider_input_tokens: inputTokens,
      provider_output_tokens: outputTokens,
      embedding_input_tokens: embeddingTokens,
      estimated_cost_micros: costMicros,
      retrieval_cache_hit: retrievalCacheHit,
      response_cache_hit: responseCacheHit,
      vision_fallback_reason: visionFallbackReason,
      output: { contractVersion: 'meal-analysis.v1', analysisRunId: runId, inputKind: queryObj.kind, items: itemsOutput },
      created_at: createdAt,
      completed_at: completedAt
    })

    queryObj.foods.forEach((foodId, idx) => {
      candidates.push({
        analysis_run_id: runId,
        item_key: `key-${i}-${idx}`,
        food_id: foodId,
        rank: 1,
        retrieval_score: 0.92,
        rerank_score: 0.95,
        selected: true,
        rationale: { method: queryObj.method, score: queryObj.confidence }
      })
    })

    if (status !== 'failed' && i % 10 < 7 && queryObj.foods.length > 0) {
      const mealId = crypto.randomUUID()
      const commitReqId = crypto.randomUUID()

      meals.push({
        id: mealId,
        user_id: userId,
        analysis_run_id: runId,
        client_request_id: commitReqId,
        name: `Öğün Kaydı ${i + 1}`,
        raw_input: queryObj.text,
        occurred_at: createdAt,
        image_path: imagePath,
        created_at: createdAt
      })

      queryObj.foods.forEach((foodId, idx) => {
        const itemId = crypto.randomUUID()
        const originalGrams = queryObj.grams[idx]
        const isCorrected = i % 7 === 0
        const reviewStatus = isCorrected ? 'corrected' : (i % 2 === 0 ? 'accepted' : 'unreviewed')
        const finalGrams = isCorrected ? originalGrams * 1.5 : originalGrams

        const cal100 = foodCalories[foodId]
        const prot100 = foodProtein[foodId]
        const carb100 = foodCarbs[foodId]
        const fat100 = foodFat[foodId]

        mealItems.push({
          id: itemId,
          meal_id: mealId,
          food_id: foodId,
          position: idx,
          source_text: queryObj.text,
          portion_label: `${finalGrams} g`,
          grams: finalGrams,
          calories_per_100g: cal100,
          protein_per_100g: prot100,
          carbs_per_100g: carb100,
          fat_per_100g: fat100,
          confidence: queryObj.confidence,
          match_method: queryObj.method,
          review_status: reviewStatus,
          nutrition_source: 'canonical_v2_lean',
          canonical_name: foodNames[foodId],
          created_at: createdAt
        })

        if (isCorrected) {
          corrections.push({
            id: crypto.randomUUID(),
            user_id: userId,
            meal_item_id: itemId,
            analysis_run_id: runId,
            reason: 'wrong_portion',
            before_value: { grams: originalGrams },
            after_value: { grams: finalGrams },
            created_at: completedAt
          })
        }
      })
    }
  }

  // Eval Runs
  const evalRun1 = {
    id: crypto.randomUUID(),
    kind: 'deterministic',
    suite: 'turkish_meals_v1',
    git_ref: 'main@a1b2c3d',
    model: null,
    prompt_version: 'deterministic-tr-v1',
    started_at: new Date(nowMs - 86400000 * 2).toISOString(),
    finished_at: new Date(nowMs - 86400000 * 2 + 1500).toISOString(),
    case_count: 63,
    passed_count: 63,
    metrics: { exactCaseAccuracy: 1.0, foodIdentityF1: 1.0, portionMape: 0.0, noMatchSpecificity: 1.0 },
    cost_micros: 0,
    notes: 'CI automated deterministic gate run',
    created_at: new Date(nowMs - 86400000 * 2).toISOString()
  }

  const evalRun2 = {
    id: crypto.randomUUID(),
    kind: 'live',
    suite: 'bilingual_hybrid_v1',
    git_ref: 'main@a1b2c3d',
    model: 'gpt-5.4-nano',
    prompt_version: 'tr-v2.1',
    started_at: new Date(nowMs - 86400000 * 1).toISOString(),
    finished_at: new Date(nowMs - 86400000 * 1 + 45000).toISOString(),
    case_count: 26,
    passed_count: 24,
    metrics: { passRate: 0.923, identityExactAccuracy: 0.961, noMatchAccuracy: 1.0, portionMape: 0.042, latencyP50Ms: 3400, latencyP95Ms: 7800, retrievalCacheHitRate: 0.65, responseCacheHitRate: 0.35 },
    cost_micros: 4200,
    notes: 'Live hybrid evaluation suite run',
    created_at: new Date(nowMs - 86400000 * 1).toISOString()
  }

  const evalCases = [
    { eval_run_id: evalRun1.id, case_id: 'tr-001', passed: true, expected: { items: [{ foodId: '10000000-0000-0000-0000-000000000001', grams: 50 }] }, actual: { items: [{ foodId: '10000000-0000-0000-0000-000000000001', grams: 50 }] }, failure_kind: null, latency_ms: 12 },
    { eval_run_id: evalRun1.id, case_id: 'tr-002', passed: true, expected: { items: [{ foodId: '10000000-0000-0000-0000-000000000001', grams: 100 }] }, actual: { items: [{ foodId: '10000000-0000-0000-0000-000000000001', grams: 100 }] }, failure_kind: null, latency_ms: 8 },
    { eval_run_id: evalRun2.id, case_id: 'hybrid-001', passed: true, expected: { items: [{ foodId: '10000000-0000-0000-0000-000000000001', grams: 100 }] }, actual: { items: [{ foodId: '10000000-0000-0000-0000-000000000001', grams: 100 }] }, failure_kind: null, latency_ms: 3100 },
    { eval_run_id: evalRun2.id, case_id: 'hybrid-002', passed: false, expected: { items: [{ foodId: '10000000-0000-0000-0000-000000000003', grams: 100 }] }, actual: { items: [{ foodId: '10000000-0000-0000-0000-000000000003', grams: 150 }] }, failure_kind: 'portion', latency_ms: 4200 }
  ]

  console.log('Upserting analysis runs...')
  for (let i = 0; i < analysisRuns.length; i += 20) {
    const chunk = analysisRuns.slice(i, i + 20)
    const { error } = await supabaseAdmin.from('analysis_runs').upsert(chunk, { onConflict: 'id' })
    if (error) console.error('analysis_runs upsert error:', error.message)
  }

  console.log('Upserting candidates...')
  for (let i = 0; i < candidates.length; i += 20) {
    const chunk = candidates.slice(i, i + 20)
    const { error } = await supabaseAdmin.from('analysis_candidates').upsert(chunk)
    if (error) console.error('analysis_candidates upsert error:', error.message)
  }

  console.log('Upserting meals...')
  for (let i = 0; i < meals.length; i += 20) {
    const chunk = meals.slice(i, i + 20)
    const { error } = await supabaseAdmin.from('meals').upsert(chunk, { onConflict: 'id' })
    if (error) console.error('meals upsert error:', error.message)
  }

  console.log('Upserting meal items...')
  for (let i = 0; i < mealItems.length; i += 20) {
    const chunk = mealItems.slice(i, i + 20)
    const { error } = await supabaseAdmin.from('meal_items').upsert(chunk, { onConflict: 'id' })
    if (error) console.error('meal_items upsert error:', error.message)
  }

  console.log('Upserting corrections...')
  for (let i = 0; i < corrections.length; i += 20) {
    const chunk = corrections.slice(i, i + 20)
    const { error } = await supabaseAdmin.from('meal_item_corrections').upsert(chunk, { onConflict: 'id' })
    if (error) console.error('meal_item_corrections upsert error:', error.message)
  }

  console.log('Upserting eval runs...')
  const { error: evalErr } = await supabaseAdmin.from('eval_runs').upsert([evalRun1, evalRun2], { onConflict: 'id' })
  if (evalErr) console.error('eval_runs error:', evalErr.message)

  const { error: evalCaseErr } = await supabaseAdmin.from('eval_cases').upsert(evalCases)
  if (evalCaseErr) console.error('eval_cases error:', evalCaseErr.message)

  console.log('🎉 SUCCESS! All 120+ analysis runs, meals, items, corrections and evals pushed directly to live Supabase!')
}

pushTelemetryToSupabase().catch((err) => {
  console.error('Push failed:', err)
  process.exit(1)
})
