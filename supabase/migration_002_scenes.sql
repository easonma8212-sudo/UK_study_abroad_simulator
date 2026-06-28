-- ============================================================
-- 英留模拟器 · Migration 002 — 场景内容表
-- 执行方式：Supabase 仪表盘 → SQL Editor → 粘贴运行
-- ============================================================

-- scenes：存储所有场景题目内容
-- scene_data 是完整的 WORLDS[id] 对象（JSON），demo 直接消费
CREATE TABLE IF NOT EXISTS scenes (
  id           TEXT PRIMARY KEY,              -- 场景唯一ID，如 'supermarket_checkout'
  scene_data   JSONB NOT NULL,               -- 完整场景对象（含 turns、activeDims 等）
  status       TEXT NOT NULL DEFAULT 'draft', -- 'draft' | 'published'
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  updated_at   TIMESTAMPTZ DEFAULT NOW()
);

-- 自动更新 updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER scenes_updated_at
  BEFORE UPDATE ON scenes
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- RLS（Demo 阶段允许匿名读写）
ALTER TABLE scenes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "anon_read"  ON scenes FOR SELECT TO anon USING (true);
CREATE POLICY "anon_write" ON scenes FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "anon_update" ON scenes FOR UPDATE TO anon USING (true) WITH CHECK (true);

-- ============================================================
-- 完成提示
-- ============================================================
-- 运行成功后你会看到一张新表：scenes
-- 通过 content_creator.html 的「保存到 Supabase」按钮向此表写入场景
-- demo.html 启动时会自动从此表加载 status='published' 的场景
