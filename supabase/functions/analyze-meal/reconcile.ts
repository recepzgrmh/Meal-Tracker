import type { AnalysisItem } from '../_shared/contracts.ts'
import { type DeterministicAnalysis, normalizeTurkishInput } from './deterministic.ts'
import type { VisionFood } from './vision.ts'

export function applyVisionEvidence(
  analysis: DeterministicAnalysis,
  foods: VisionFood[],
): DeterministicAnalysis {
  // Evidence is paired by normalized-name overlap, never by array position:
  // when the parser resolves fewer items than vision reported, positional
  // pairing attached food A's confidence to food B. Vision evidence that
  // matches no item is dropped rather than misapplied.
  const usedEvidence = new Set<number>()
  return {
    ...analysis,
    items: analysis.items.map((item) => {
      const evidence = matchVisionFood(item, foods, usedEvidence)
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

/**
 * Unmatched tokens still uncovered after later stages (grounding, estimates)
 * contributed `items`. Anything left must stay visible to the client instead
 * of being silently dropped when at least one sibling item resolved.
 */
export function remainingUnmatchedText(unmatched: string[], items: AnalysisItem[]): string[] {
  const covered = new Set(
    items
      .flatMap((item) => normalizeTurkishInput(item.sourceText).split(' '))
      .filter(Boolean),
  )
  return unmatched.filter((token) => !covered.has(token))
}

function matchVisionFood(
  item: AnalysisItem,
  foods: VisionFood[],
  usedEvidence: Set<number>,
): VisionFood | null {
  const itemTokens = new Set(
    [
      ...normalizeTurkishInput(item.sourceText).split(' '),
      ...normalizeTurkishInput(item.canonicalName).split(' '),
    ].filter(Boolean),
  )
  for (let index = 0; index < foods.length; index += 1) {
    if (usedEvidence.has(index)) continue
    const descriptionTokens = normalizeTurkishInput(foods[index].description)
      .split(' ')
      .filter(Boolean)
    if (descriptionTokens.some((token) => itemTokens.has(token))) {
      usedEvidence.add(index)
      return foods[index]
    }
  }
  return null
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
