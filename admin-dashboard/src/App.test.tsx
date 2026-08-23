import { cleanup, render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import App from './App'
import { I18nProvider } from './i18n'
import type {
  CatalogFoodRow, CategoryQualityRow, CorrectionReasonRow, DailyRow, EvalCaseRow, EvalRunRow, QueueRow,
} from './lib/queries'

/* The console has no demo mode, so these tests drive it the only way it can be
   driven: by standing in for Supabase and asserting the four states each screen
   has to render — loading, error, empty, and loaded. */

type Scenario = {
  configured: boolean
  session: unknown
  admin: boolean
  daily: DailyRow[] | Error
  reasons: CorrectionReasonRow[]
  categories: CategoryQualityRow[]
  queue: QueueRow[]
  catalog: CatalogFoodRow[]
  evalRuns: EvalRunRow[]
  evalCases: EvalCaseRow[]
}

const scenario: Scenario = {
  configured: true,
  session: { user: { id: 'u-1', email: 'ops@example.com', app_metadata: {} }, expires_at: 0 },
  admin: true,
  daily: [],
  reasons: [],
  categories: [],
  queue: [],
  catalog: [],
  evalRuns: [],
  evalCases: [],
}

vi.mock('./lib/supabase', async (importOriginal) => {
  const actual = await importOriginal<typeof import('./lib/supabase')>()
  return {
    ...actual,
    get isSupabaseConfigured() { return scenario.configured },
    get supabase() {
      if (!scenario.configured) return null
      return {
        auth: {
          getSession: async () => ({ data: { session: scenario.session } }),
          onAuthStateChange: () => ({ data: { subscription: { unsubscribe: () => undefined } } }),
        },
      }
    },
  }
})

vi.mock('./lib/queries', () => ({
  assertConsoleAdmin: async () => { if (!scenario.admin) throw new Error('not an admin') },
  signInWithPassword: async () => undefined,
  sendEmailCode: async () => undefined,
  verifyEmailCode: async () => undefined,
  signOut: async () => undefined,
  getSession: async () => scenario.session,
  sinceIso: () => new Date().toISOString(),
  fetchAnalysisDaily: async () => { if (scenario.daily instanceof Error) throw scenario.daily; return scenario.daily },
  fetchCorrectionReasons: async () => scenario.reasons,
  fetchCategoryQuality: async () => scenario.categories,
  fetchReviewQueue: async () => scenario.queue,
  fetchErrorBreakdown: async () => [],
  fetchTraces: async () => [],
  fetchTrace: async () => null,
  fetchTraceCandidates: async () => [],
  fetchAccounts: async () => [],
  fetchProductionCatalogStatus: async () => ({
    catalog_version: 'canonical-v2-lean-60k', food_records: 60_000,
    macro_complete_records: 60_000, alias_records: 120_000, portion_records: 120_000,
  }),
  fetchProductionCatalogFoods: async () => ({ rows: scenario.catalog, total: scenario.catalog.length }),
  fetchProductionCatalogFood: async (foodId: string) => {
    const row = scenario.catalog.find((food) => food.food_id === foodId)!
    return {
      id: row.food_id, canonical_name: row.canonical_name, locale: row.locale,
      source: 'canonical_v2_lean', source_food_id: 'canonical-1',
      calories_per_100g: row.calories_per_100g, protein_per_100g: row.protein_per_100g,
      carbs_per_100g: row.carbs_per_100g, fat_per_100g: row.fat_per_100g,
      metadata: { brand: row.brand, barcode: row.barcode, category: row.category, tier: row.tier, canonical_id: 'canonical-1' },
      food_aliases: [{ id: 1, alias: row.canonical_name, locale: 'tr-TR', priority: 90 }],
      food_portions: [{ id: 1, label: '1 porsiyon', grams: 100, locale: 'tr-TR', is_default: true }],
    }
  },
  fetchBundles: async () => [],
  fetchEvalRuns: async () => scenario.evalRuns,
  fetchEvalCases: async () => scenario.evalCases,
}))

const day = (over: Partial<DailyRow>): DailyRow => ({
  day: '2026-08-18', runs: 100, completed: 99, failed: 1, with_photo: 60,
  avg_latency_ms: 2000, p95_latency_ms: 4000, cost_micros: 1_000_000,
  input_tokens: 1000, output_tokens: 200, retried: 2, ...over,
})

const queueRow = (over: Partial<QueueRow>): QueueRow => ({
  item_id: 'item-1', meal_id: 'meal-1', user_id: 'user-abcd-1234', meal_name: 'Lunch',
  occurred_at: new Date().toISOString(), image_path: null, canonical_name: 'Yogurt sauce',
  portion_label: '1 serving', grams: 25, calories: 40, confidence_pct: 96,
  match_method: 'retrieval', review_status: 'corrected', trace_id: 'trace-1',
  model_name: 'vision-v3.2', prompt_version: 'v16', latency_ms: 2400, correction_count: 1, ...over,
})

const renderApp = () => render(<I18nProvider><App /></I18nProvider>)

describe('console shell', () => {
  beforeEach(() => {
    history.replaceState(null, '', '/admin/overview')
    globalThis.localStorage?.clear()
    Object.assign(scenario, {
      configured: true,
      session: { user: { id: 'u-1', email: 'ops@example.com', app_metadata: {} }, expires_at: 0 },
      admin: true,
      daily: [],
      reasons: [],
      categories: [],
      queue: [],
      catalog: [],
      evalRuns: [],
      evalCases: [],
    })
  })
  afterEach(cleanup)

  it('refuses to render data when Supabase is not configured', async () => {
    scenario.configured = false
    renderApp()
    expect(await screen.findByText('Supabase is not connected')).toBeInTheDocument()
    expect(screen.queryByRole('heading', { name: 'Overview' })).not.toBeInTheDocument()
  })

  it('blocks an account that is not on the admin allow-list and hands over the fix', async () => {
    scenario.admin = false
    renderApp()
    expect(await screen.findByText('This account cannot read console data')).toBeInTheDocument()
    // The grant statement must be ready to paste, carrying the signed-in email.
    expect(screen.getByText(/insert into public\.console_admins/)).toHaveTextContent("email = 'ops@example.com'")
    expect(screen.getByRole('button', { name: 'Check again' })).toBeInTheDocument()
  })

  it('asks for credentials when there is no session', async () => {
    scenario.session = null
    renderApp()
    expect(await screen.findByRole('heading', { name: 'Sign in to the console' })).toBeInTheDocument()
  })

  it('shows an empty state instead of inventing numbers', async () => {
    renderApp()
    expect(await screen.findByText('No analyses in this period')).toBeInTheDocument()
    // Nothing that looks like a metric should have been rendered.
    expect(screen.queryByText(/%$/)).not.toBeInTheDocument()
  })

  it('names the missing migration when the admin views do not exist', async () => {
    scenario.daily = Object.assign(new Error('relation does not exist'), { code: '42P01' })
    renderApp()
    expect(await screen.findByText('Console views are missing')).toBeInTheDocument()
    expect(screen.getByText(/20260821120000_admin_console_reads\.sql/)).toBeInTheDocument()
  })

  it('derives overview metrics from the rows Supabase returned', async () => {
    scenario.daily = [day({ runs: 100, completed: 90, failed: 10, p95_latency_ms: 7000 })]
    renderApp()
    // 90/100 completed, below the 99% threshold, so the signal must surface.
    expect(await screen.findAllByText('90.0%')).not.toHaveLength(0)
    expect(screen.getByRole('button', { name: /success rate below target/i })).toBeInTheDocument()
    expect(screen.getByRole('button', { name: /p95 latency above budget/i })).toBeInTheDocument()
  })

  it('reports every threshold met when the numbers are healthy', async () => {
    scenario.daily = [day({ runs: 100, completed: 100, failed: 0, p95_latency_ms: 3000, cost_micros: 100 })]
    renderApp()
    expect(await screen.findByText('Every threshold is being met in this period.')).toBeInTheDocument()
  })

  it('lists the review queue that Supabase returned', async () => {
    scenario.queue = [queueRow({}), queueRow({ item_id: 'item-2', canonical_name: 'White rice', confidence_pct: 71, review_status: 'unreviewed' })]
    renderApp()
    await userEvent.click(await screen.findByRole('button', { name: 'Meal Reviews' }))
    expect(await screen.findByText('Yogurt sauce')).toBeInTheDocument()
    expect(screen.getByText('White rice')).toBeInTheDocument()
  })

  it('browses production foods and opens read-only catalog details', async () => {
    scenario.catalog = [{
      food_id: 'food-1', canonical_name: 'Süzme Yoğurt', locale: 'tr-TR',
      category: 'Dairy', brand: 'Örnek Marka', barcode: '8690000000001',
      tier: 'tr_branded', dataset_version: '2026-08', calories_per_100g: 120,
      protein_per_100g: 8, carbs_per_100g: 4, fat_per_100g: 8, total_count: 1,
    }]
    renderApp()
    await userEvent.click(await screen.findByRole('button', { name: 'Food Catalog' }))
    expect(await screen.findByRole('heading', { name: 'Food Catalog' })).toBeInTheDocument()
    expect(screen.getAllByText('60,000')).toHaveLength(2)
    await userEvent.click(await screen.findByText('Süzme Yoğurt'))
    expect(await screen.findByRole('dialog', { name: 'Süzme Yoğurt' })).toBeInTheDocument()
    expect(screen.getByText('1 porsiyon')).toBeInTheDocument()
    expect(screen.getAllByText('8690000000001')).toHaveLength(2)
  })

  it('tells the operator how to publish eval results when none are stored', async () => {
    renderApp()
    await userEvent.click(await screen.findByRole('button', { name: 'AI Evals' }))
    expect(await screen.findByText('No eval results stored yet')).toBeInTheDocument()
    expect(screen.getByText(/deno task eval -- --persist/)).toBeInTheDocument()
  })

  it('lists stored eval runs and opens the failed cases of one', async () => {
    scenario.evalRuns = [{
      id: 'run-1', kind: 'deterministic', suite: 'turkish_meals_v1', git_ref: 'abc1234',
      model: null, prompt_version: 'deterministic-tr-v1',
      started_at: '2026-08-24T12:00:00Z', finished_at: '2026-08-24T12:00:01Z',
      case_count: 60, passed_count: 59,
      metrics: { foodIdentityF1: 0.99, portionMape: 0.02, noMatchSpecificity: 1 },
      cost_micros: null, notes: null, created_at: '2026-08-24T12:00:01Z',
    }]
    scenario.evalCases = [{
      id: 1, eval_run_id: 'run-1', case_id: 'tr-041', passed: false,
      expected: { items: [{ foodId: 'food-rice', grams: 150 }] },
      actual: { items: [] }, failure_kind: 'missing', latency_ms: null,
    }]
    renderApp()
    await userEvent.click(await screen.findByRole('button', { name: 'AI Evals' }))
    expect(await screen.findByText('turkish_meals_v1')).toBeInTheDocument()
    expect(screen.getByText('59/60')).toBeInTheDocument()
    await userEvent.click(screen.getByText('turkish_meals_v1'))
    expect(await screen.findByRole('dialog', { name: 'deterministic · turkish_meals_v1' })).toBeInTheDocument()
    expect(await screen.findByText('tr-041')).toBeInTheDocument()
    expect(screen.getByText(/food-rice/)).toBeInTheDocument()
  })

  it('opens a queue item by id and keeps the id in the URL', async () => {
    scenario.queue = [queueRow({})]
    renderApp()
    await userEvent.click(await screen.findByRole('button', { name: 'Meal Reviews' }))
    await userEvent.click(await screen.findByText('Yogurt sauce'))
    await waitFor(() => expect(location.search).toContain('item=item-1'))
    expect(await screen.findByRole('heading', { name: 'Yogurt sauce' })).toBeInTheDocument()
    expect(screen.getByText('vision-v3.2')).toBeInTheDocument()
  })

  it('says plainly that the audit log has no source', async () => {
    renderApp()
    await userEvent.click(await screen.findByRole('button', { name: 'Audit Log' }))
    expect(await screen.findByText('No audit source is connected')).toBeInTheDocument()
  })

  it('switches the whole shell to Turkish', async () => {
    renderApp()
    // Wait for the shell so the click lands on the top bar's toggle rather than
    // the transient one on the sign-in screen.
    await screen.findByRole('button', { name: 'Meal Reviews' })
    await userEvent.click(screen.getByRole('button', { name: 'TR' }))
    expect(await screen.findByRole('heading', { name: 'Genel Bakış' })).toBeInTheDocument()
    await userEvent.click(screen.getByRole('button', { name: 'Mobil Uygulama' }))
    expect(await screen.findByRole('heading', { name: 'Mobil Uygulama' })).toBeInTheDocument()
  })
})
