import { createClient } from '@supabase/supabase-js'

// Supabase 配置
const supabaseUrl = import.meta.env.VITE_SUPABASE_URL || 'https://dcfoohekabvbxupdagwb.supabase.co'
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRjZm9vaGVrYWJ2Ynh1cGRhZ3diIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTYwNjQ5ODIsImV4cCI6MjA3MTY0MDk4Mn0.dxTpW5-ZikfYT5_mrA_5MNGomzxjp8jy3ST57lGgv9c'

// 创建 Supabase 客户端
export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
  },
  db: {
    schema: 'public'
  },
  global: {
    headers: {
      'X-Client-Info': 'guessing-pen-challenge'
    }
  }
})

// 数据库类型定义
export interface Database {
  public: {
    Tables: {
      players: {
        Row: {
          id: string
          nickname: string
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          nickname: string
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          nickname?: string
          created_at?: string
          updated_at?: string
        }
      }
      game_sessions: {
        Row: {
          id: string
          player_id: string
          total_score: number
          combinations_count: number
          completed_at: string | null
          created_at: string
        }
        Insert: {
          id?: string
          player_id: string
          total_score?: number
          combinations_count?: number
          completed_at?: string | null
          created_at?: string
        }
        Update: {
          id?: string
          player_id?: string
          total_score?: number
          combinations_count?: number
          completed_at?: string | null
          created_at?: string
        }
      }
      answer_combinations: {
        Row: {
          id: string
          session_id: string
          card_ids: string[]
          ai_marked_card_id: string | null
          is_grouping_correct: boolean
          is_ai_detection_correct: boolean
          score: number
          created_at: string
        }
        Insert: {
          id?: string
          session_id: string
          card_ids: string[]
          ai_marked_card_id?: string | null
          is_grouping_correct?: boolean
          is_ai_detection_correct?: boolean
          score?: number
          created_at?: string
        }
        Update: {
          id?: string
          session_id?: string
          card_ids?: string[]
          ai_marked_card_id?: string | null
          is_grouping_correct?: boolean
          is_ai_detection_correct?: boolean
          score?: number
          created_at?: string
        }
      }
    }
    Views: {
      leaderboard: {
        Row: {
          nickname: string
          total_score: number
          combinations_count: number
          completed_at: string
          rank: number
        }
      }
      game_stats: {
        Row: {
          total_players: number
          average_score: number
          highest_score: number
          completion_rate: number
          ai_detection_accuracy: number
        }
      }
    }
  }
}