// Loads .env for local runs. ESM executes imports in order, so this must stay
// first: the CLI entrypoints read process.env at module scope. No-ops when the
// file is absent, which is the case on Railway where env is injected directly.
import 'dotenv/config'
import { readFile } from 'node:fs/promises'
import { analyzeDeterministically, type CatalogFood } from '../routes/analyze-meal/deterministic.ts'
import { type EvalCaseRecord, persistenceRequested, persistEvalRun } from './persist-eval-run.ts'

interface ExpectedItem {
  foodId: string
  grams: number
}

interface GoldCase {
  id: string
  input: string
  expectedItems: ExpectedItem[]
  expectNoMatch?: boolean
  tags: string[]
}

const root = new URL('../../../', import.meta.url)
const catalog = JSON.parse(
  await readFile(new URL('evals/catalog_v1.json', root), 'utf-8'),
) as CatalogFood[]
const lines = (await readFile(new URL('evals/gold/turkish_meals_v1.jsonl', root), 'utf-8'))
  .split('\n')
  .filter(Boolean)
const cases = lines.map((line, index) => validateCase(JSON.parse(line), index + 1))

let truePositive = 0
let falsePositive = 0
let falseNegative = 0
let exactCases = 0
let noMatchCorrect = 0
let noMatchTotal = 0
const portionErrors: number[] = []
const failures: Array<{ id: string; input: string; reasons: string[] }> = []
const caseRecords: EvalCaseRecord[] = []
const startedAt = new Date().toISOString()

for (const gold of cases) {
  const result = analyzeDeterministically(gold.input, catalog)
  const expectedByFood = aggregateExpected(gold.expectedItems)
  const actualByFood = aggregateActual(result.items)
  const reasons: string[] = []

  for (const [foodId, expectedGrams] of expectedByFood) {
    const actualGrams = actualByFood.get(foodId)
    if (actualGrams == null) {
      falseNegative++
      reasons.push(`missing:${foodId}`)
      continue
    }
    truePositive++
    const error = Math.abs(actualGrams - expectedGrams) / expectedGrams
    portionErrors.push(error)
    if (error > 0.1) reasons.push(`portion:${foodId}:${actualGrams}/${expectedGrams}`)
  }
  for (const foodId of actualByFood.keys()) {
    if (!expectedByFood.has(foodId)) {
      falsePositive++
      reasons.push(`extra:${foodId}`)
    }
  }
  if (gold.expectNoMatch) {
    noMatchTotal++
    if (result.items.length === 0) noMatchCorrect++
    else reasons.push('hallucinated_match')
  }
  if (reasons.length === 0) exactCases++
  else failures.push({ id: gold.id, input: gold.input, reasons })
  caseRecords.push({
    caseId: gold.id,
    passed: reasons.length === 0,
    expected: { items: gold.expectedItems, expectNoMatch: gold.expectNoMatch === true },
    actual: { items: result.items },
    failureKind: reasons[0]?.split(':')[0] ?? null,
    latencyMs: null,
  })
}

const finishedAt = new Date().toISOString()
const precision = divide(truePositive, truePositive + falsePositive)
const recall = divide(truePositive, truePositive + falseNegative)
const report = {
  dataset: 'turkish_meals_v1',
  pipeline: 'deterministic-tr-v1',
  cases: cases.length,
  metrics: {
    exactCaseAccuracy: round(exactCases / cases.length),
    foodIdentityPrecision: round(precision),
    foodIdentityRecall: round(recall),
    foodIdentityF1: round(divide(2 * precision * recall, precision + recall)),
    portionMape: round(portionErrors.reduce((sum, value) => sum + value, 0) / portionErrors.length),
    noMatchSpecificity: round(divide(noMatchCorrect, noMatchTotal)),
  },
  failureCount: failures.length,
  failures,
}

console.log(JSON.stringify(report, null, 2))

/**
 * The floors this suite must clear to be called a gate.
 *
 * It scored 1.00 on every metric and still exited 0 no matter what, which made
 * it a report rather than a gate: a drop to 0.60 would have passed CI silently.
 * The floors sit just under the current values — close enough that a real
 * regression trips them, far enough that a single new hard case does not turn
 * the build red before anyone has looked at it.
 *
 * They are floors on a 60-case suite over a three-food fixture catalog, so
 * clearing them means "Turkish parsing did not regress", not "the product is
 * accurate". README/Evaluation says the same thing at more length.
 */
const GATES: Array<{ metric: keyof typeof report.metrics; min?: number; max?: number }> = [
  { metric: 'exactCaseAccuracy', min: 0.95 },
  { metric: 'foodIdentityF1', min: 0.95 },
  { metric: 'noMatchSpecificity', min: 0.9 },
  { metric: 'portionMape', max: 0.1 },
]

const breaches = GATES.flatMap((gate) => {
  const value = report.metrics[gate.metric]
  if (gate.min !== undefined && value < gate.min) {
    return [`${gate.metric} ${value} is below the floor of ${gate.min}`]
  }
  if (gate.max !== undefined && value > gate.max) {
    return [`${gate.metric} ${value} is above the ceiling of ${gate.max}`]
  }
  return []
})

if (breaches.length > 0) {
  console.error('\nAccuracy gate failed:')
  for (const breach of breaches) console.error(`  - ${breach}`)
  console.error(
    `\n${report.failureCount} of ${report.cases} cases failed. ` +
      'Failing cases with their reasons are in the report above.',
  )
  process.exitCode = 1
}

if (persistenceRequested()) {
  await persistEvalRun({
    kind: 'deterministic',
    suite: report.dataset,
    model: null,
    promptVersion: report.pipeline,
    startedAt,
    finishedAt,
    caseCount: cases.length,
    passedCount: exactCases,
    metrics: report.metrics,
    costMicros: null,
    notes: null,
  }, caseRecords)
}

function validateCase(value: unknown, line: number): GoldCase {
  if (typeof value !== 'object' || value === null) throw new Error(`Invalid case at line ${line}`)
  const item = value as Record<string, unknown>
  if (typeof item.id !== 'string' || typeof item.input !== 'string' || !Array.isArray(item.tags)) {
    throw new Error(`Invalid case metadata at line ${line}`)
  }
  if (!Array.isArray(item.expectedItems)) throw new Error(`Invalid expectedItems at line ${line}`)
  const expectedItems = item.expectedItems.map((raw) => {
    if (typeof raw !== 'object' || raw === null) throw new Error(`Invalid item at line ${line}`)
    const expected = raw as Record<string, unknown>
    if (
      typeof expected.foodId !== 'string' || typeof expected.grams !== 'number' ||
      expected.grams <= 0
    ) {
      throw new Error(`Invalid expected item at line ${line}`)
    }
    return { foodId: expected.foodId, grams: expected.grams }
  })
  if (item.expectNoMatch === true && expectedItems.length > 0) {
    throw new Error(`No-match case has expected items at line ${line}`)
  }
  return {
    id: item.id,
    input: item.input,
    expectedItems,
    expectNoMatch: item.expectNoMatch === true,
    tags: item.tags.map(String),
  }
}

function aggregateExpected(items: ExpectedItem[]): Map<string, number> {
  const totals = new Map<string, number>()
  for (const item of items) totals.set(item.foodId, (totals.get(item.foodId) ?? 0) + item.grams)
  return totals
}

function aggregateActual(
  items: Array<{ foodId: string | null; grams: number }>,
): Map<string, number> {
  const totals = new Map<string, number>()
  for (const item of items) {
    // A null foodId is the contract's way of saying the item never resolved to a
    // catalog food, so it is not a match to score. The deterministic pass does
    // not currently emit one, which is why `deno check` — scoped to the four
    // function entrypoints — never had to reconcile this with the contract.
    if (item.foodId === null) continue
    totals.set(item.foodId, (totals.get(item.foodId) ?? 0) + item.grams)
  }
  return totals
}

function divide(numerator: number, denominator: number): number {
  return denominator === 0 ? 0 : numerator / denominator
}

function round(value: number): number {
  return Math.round(value * 10000) / 10000
}
