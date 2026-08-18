import type { AnalysisItem } from '../_shared/contracts.ts'
import type { DeterministicAnalysis } from './deterministic.ts'
import type { VisionFood } from './vision.ts'

export function applyVisionEvidence(
  analysis: DeterministicAnalysis,
  foods: VisionFood[],
): DeterministicAnalysis {
  return {
    ...analysis,
    items: analysis.items.map((item, index) => {
      const evidence = foods[index]
      if (!evidence) {
        return {
          ...item,
          confidence: Math.min(item.confidence, 0.6),
          needsClarification: true,
          clarificationReason: 'portion' as const,
        }
      }
      const identityUncertain = evidence.identityConfidence < 0.82
      const portionUncertain = evidence.portionConfidence < 0.78 ||
        evidence.portionBasis === 'catalog_default'
      return {
        ...item,
        confidence: roundConfidence(
          Math.min(item.confidence, evidence.identityConfidence, evidence.portionConfidence),
        ),
        needsClarification: identityUncertain || portionUncertain,
        ...((identityUncertain || portionUncertain)
          ? {
            clarificationReason: identityUncertain ? 'identity' as const : 'portion' as const,
          }
          : { clarificationReason: undefined }),
      }
    }),
  }
}

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

function roundConfidence(value: number): number {
  return Math.round(value * 100) / 100
}
