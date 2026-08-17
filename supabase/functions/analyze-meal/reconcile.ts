import type { AnalysisItem } from '../_shared/contracts.ts'
import type { DeterministicAnalysis } from './deterministic.ts'

export function reconcileModalities(
  text: DeterministicAnalysis,
  vision: DeterministicAnalysis | null,
): DeterministicAnalysis {
  if (!vision) return text
  if (text.items.length === 0) return rekey(vision)

  const explicitFoodIds = new Set(text.items.map((item) => item.foodId))
  const visionOnly = vision.items.filter((item) => !explicitFoodIds.has(item.foodId))

  return {
    normalizedInput: [text.normalizedInput, vision.normalizedInput]
      .filter(Boolean)
      .join(' | '),
    items: rekeyItems([...text.items, ...visionOnly]),
    unmatchedText: [...new Set([...text.unmatchedText, ...vision.unmatchedText])],
  }
}

function rekey(analysis: DeterministicAnalysis): DeterministicAnalysis {
  return { ...analysis, items: rekeyItems(analysis.items) }
}

function rekeyItems(items: AnalysisItem[]): AnalysisItem[] {
  return items.map((item, index) => ({ ...item, itemKey: `item-${index + 1}` }))
}
