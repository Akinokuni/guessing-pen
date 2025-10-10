// PostgREST API 配置
export const POSTGREST_URL = import.meta.env.VITE_POSTGREST_URL || 
  (import.meta.env.PROD ? '/api' : 'http://localhost:3001')