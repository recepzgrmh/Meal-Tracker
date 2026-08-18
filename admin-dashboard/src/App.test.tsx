import { cleanup, render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { afterEach, beforeEach, describe, expect, it } from 'vitest'
import App from './App'
import { I18nProvider } from './i18n'

const renderApp = () => render(<I18nProvider><App /></I18nProvider>)

describe('AI operations investigation flow', () => {
  beforeEach(() => { history.replaceState(null, '', '/admin/overview'); globalThis.localStorage?.clear() })
  afterEach(cleanup)

  it('routes an attention signal to filtered quality evidence', async () => {
    renderApp()
    await userEvent.click(screen.getByRole('button', { name: /sauce correction rate/i }))
    expect(screen.getByRole('heading', { name: 'AI Quality' })).toBeInTheDocument()
    expect(screen.getByRole('button', { name: /sauces · high confidence/i })).toBeInTheDocument()
    expect(location.search).toContain('filter=')
  })

  it('opens a privacy-safe meal diff and its trace', async () => {
    renderApp()
    await userEvent.click(screen.getByRole('button', { name: 'Meal Reviews' }))
    await userEvent.click(screen.getByText('Chicken rice bowl'))
    expect(screen.getByRole('heading', { name: 'Meal inspector' })).toBeInTheDocument()
    expect(screen.getByText('PII redacted')).toBeInTheDocument()
    expect(screen.getByText('Yogurt sauce')).toBeInTheDocument()
    await userEvent.click(screen.getByRole('button', { name: /open trace tr_9da48b1e/i }))
    expect(screen.getByRole('heading', { name: /traces · tr_9da48b1e/i })).toBeInTheDocument()
    expect(screen.getByText('Yogurt sauce, plain')).toBeInTheDocument()
    expect(screen.getByText('Duplicate prevented')).toBeInTheDocument()
  })

  it('switches the whole admin shell to Turkish and manages an OTA draft', async () => {
    renderApp()
    await userEvent.click(screen.getByRole('button', { name: 'TR' }))
    expect(screen.getByRole('heading', { name: 'Genel Bakış' })).toBeInTheDocument()
    expect(screen.getByPlaceholderText('Öğün, iz, istek veya kullanıcı kimliği ara')).toBeInTheDocument()
    await userEvent.click(screen.getByRole('button', { name: 'Mobil Uygulama' }))
    expect(screen.getByRole('heading', { name: 'Mobil Uygulama' })).toBeInTheDocument()
    expect(screen.getByText('Çeviri paketleri')).toBeInTheDocument()
    await userEvent.click(screen.getByRole('button', { name: 'Doğrula' }))
    expect(screen.getByRole('status')).toHaveTextContent('Doğrulama başarılı')
  })
})
