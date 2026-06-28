-- ============================================================
-- 英留模拟器 · Supabase 初始化迁移
-- 执行方式：Supabase 仪表盘 → SQL Editor → 粘贴运行
-- ============================================================

-- 1. sessions：每次打开 demo 开始一个 session
CREATE TABLE IF NOT EXISTS sessions (
  id            TEXT PRIMARY KEY,
  scene_id      TEXT NOT NULL,
  lang          TEXT DEFAULT 'zh',
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  completed_at  TIMESTAMPTZ,
  total_turns   INT  DEFAULT 0,
  total_signals INT  DEFAULT 0,
  total_hints   INT  DEFAULT 0,
  total_replays INT  DEFAULT 0,
  avoidant_count INT DEFAULT 0
);

-- 2. signals：每一轮的完整行为信号（含元认知自报告）
CREATE TABLE IF NOT EXISTS signals (
  id               BIGSERIAL PRIMARY KEY,
  session_id       TEXT NOT NULL,
  scene_id         TEXT NOT NULL,
  turn_id          INT  NOT NULL,
  event_type       TEXT NOT NULL,        -- 'turn_complete' | 'replay' | 'hint'
  created_at       TIMESTAMPTZ DEFAULT NOW(),

  -- 行为信号
  reaction_time_s  FLOAT,
  replay_count     INT  DEFAULT 0,
  hint_clicked     BOOLEAN DEFAULT FALSE,
  choice           TEXT,                 -- 'A' | 'B' | 'C'
  choice_quality   TEXT,                 -- 'good' | 'neutral' | 'avoidant'

  -- 元认知自报告（MALQ 对应维度）
  meta_understood  TEXT,                 -- 'yes'|'partial'|'no'  ← Person Knowledge
  meta_predicted   BOOLEAN,             -- true|false             ← Planning & Evaluation

  -- 当轮 UCP 变化量
  ucp_deltas       JSONB
);

-- 3. ucp_snapshots：每次场景完成后保存完整 UCP 画像快照
CREATE TABLE IF NOT EXISTS ucp_snapshots (
  id          BIGSERIAL PRIMARY KEY,
  session_id  TEXT NOT NULL,
  scene_id    TEXT NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  ucp         JSONB NOT NULL             -- 完整 UCP 状态（所有维度）
);

-- ============================================================
-- RLS 策略（Demo 阶段允许匿名读写，上线后收紧）
-- ============================================================
ALTER TABLE sessions      ENABLE ROW LEVEL SECURITY;
ALTER TABLE signals       ENABLE ROW LEVEL SECURITY;
ALTER TABLE ucp_snapshots ENABLE ROW LEVEL SECURITY;

-- 匿名用户可读写（demo 阶段）
CREATE POLICY "anon_all" ON sessions      FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "anon_all" ON signals       FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "anon_all" ON ucp_snapshots FOR ALL TO anon USING (true) WITH CHECK (true);

-- ============================================================
-- 快捷视图：方便在 Supabase Table View 里直接分析数据
-- ============================================================
CREATE OR REPLACE VIEW v_session_summary AS
SELECT
  s.id           AS session_id,
  s.scene_id,
  s.created_at,
  s.completed_at,
  s.total_signals,
  s.total_hints,
  s.total_replays,
  s.avoidant_count,
  u.ucp          AS final_ucp
FROM sessions s
LEFT JOIN LATERAL (
  SELECT ucp FROM ucp_snapshots
  WHERE session_id = s.id
  ORDER BY created_at DESC LIMIT 1
) u ON true;

-- ============================================================
-- 完成提示
-- ============================================================
-- 运行成功后你会看到三张表：sessions / signals / ucp_snapshots
-- 以及一个视图：v_session_summary
