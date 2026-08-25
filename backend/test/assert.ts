import { expect } from 'vitest'

/**
 * The suite was written against `jsr:@std/assert`. Reimplementing those three
 * helpers on top of vitest's `expect` keeps all 141 assertion call sites
 * byte-identical to the Deno originals, so the port is reviewable as a move
 * rather than a rewrite — and a rewrite of that many assertions is exactly
 * where a silently weakened test would hide.
 */

export function assertEquals(actual: unknown, expected: unknown, msg?: string): void {
  // toStrictEqual, not toEqual: std/assert compares structurally and counts an
  // explicit `undefined` property as present, so `{a:1}` and `{a:1,b:undefined}`
  // are unequal there. toEqual ignores those, which would silently weaken every
  // assertion that moved over.
  expect(actual, msg).toStrictEqual(expected)
}

export function assertStringIncludes(actual: string, expected: string, msg?: string): void {
  expect(actual, msg).toContain(expected)
}

type ErrorConstructor<E extends Error> = new (...args: never[]) => E

/**
 * Mirrors std/assert: awaits the thunk, fails if it resolves, and otherwise
 * checks the error's class and message. It returns the caught error because
 * some call sites assert further on it.
 */
export async function assertRejects<E extends Error = Error>(
  fn: () => PromiseLike<unknown>,
  errorClassOrMsg?: ErrorConstructor<E> | string,
  msgIncludes?: string,
): Promise<E> {
  let caught: unknown
  let rejected = false
  try {
    await fn()
  } catch (error) {
    rejected = true
    caught = error
  }

  if (!rejected) {
    throw new Error('Expected function to reject, but it resolved')
  }

  if (typeof errorClassOrMsg === 'function') {
    expect(caught).toBeInstanceOf(errorClassOrMsg)
    if (msgIncludes !== undefined) {
      expect((caught as Error).message).toContain(msgIncludes)
    }
  } else if (typeof errorClassOrMsg === 'string') {
    expect((caught as Error).message).toContain(errorClassOrMsg)
  }

  return caught as E
}
