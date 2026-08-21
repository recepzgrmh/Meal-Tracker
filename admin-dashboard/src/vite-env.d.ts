/// <reference types="vite/client" />

interface ImportMetaEnv {
  /** Supabase project URL, e.g. https://<ref>.supabase.co */
  readonly VITE_SUPABASE_URL?: string
  /** Publishable (anon) key. Never the service-role key — this ships to the browser. */
  readonly VITE_SUPABASE_ANON_KEY?: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}
