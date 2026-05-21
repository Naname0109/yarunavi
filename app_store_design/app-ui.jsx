// app-ui.jsx — Dark-theme task management UI for ASO screenshots.
// Designed at iPhone-like 393×852 logical px; scales via parent transform.

const D = {
  bg: '#040818',
  bgGrad: 'radial-gradient(120% 70% at 60% 0%, #1a2350 0%, #0a1230 35%, #050a20 75%)',
  card: 'rgba(255,255,255,0.04)',
  cardBorder: 'rgba(255,255,255,0.07)',
  cardBorderStrong: 'rgba(125,245,237,0.18)',
  ink: '#ffffff',
  inkMuted: '#7e89ad',
  inkDim: '#5d6688',
  cyan: '#7df5ed',
  cyanDeep: '#3da5f0',
  cyanGrad: 'linear-gradient(90deg, #7df5ed 0%, #6bb5ff 100%)',
  fabGrad: 'linear-gradient(155deg, #5fe9ff 0%, #b48cff 100%)',
  red: '#ff5d6c',
  pink: '#ff4d8d',
  amber: '#e9a85a',
  green: '#4ad9b8',
};

const phoneRoot = {
  position: 'relative',
  width: '100%',
  height: '100%',
  background: D.bgGrad,
  fontFamily: '"Noto Sans JP","Hiragino Sans",system-ui,sans-serif',
  color: D.ink,
  overflow: 'hidden',
  fontFeatureSettings: '"palt"',
};

function StatusBar({ time = '9:41' }) {
  return (
    <div style={{
      height: 54, display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      padding: '0 28px', fontSize: 17, fontWeight: 700, color: D.ink,
    }}>
      <div>{time}</div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
        <svg width="18" height="12" viewBox="0 0 18 12"><rect x="0" y="6" width="3" height="6" rx="1" fill={D.ink}/><rect x="5" y="3" width="3" height="9" rx="1" fill={D.ink}/><rect x="10" y="0" width="3" height="12" rx="1" fill={D.ink}/><rect x="15" y="0" width="3" height="12" rx="1" fill={D.ink} opacity="0.4"/></svg>
        <svg width="17" height="12" viewBox="0 0 17 12"><path d="M8.5 1 C12 1 14.5 2.5 16 4 L8.5 12 L1 4 C2.5 2.5 5 1 8.5 1Z" fill={D.ink}/></svg>
        <div style={{ width: 26, height: 12, border: `1.5px solid ${D.ink}`, borderRadius: 3, position: 'relative' }}>
          <div style={{ position: 'absolute', inset: 1.5, background: D.ink, borderRadius: 1.5, width: '88%' }} />
        </div>
      </div>
    </div>
  );
}

function TabBar({ active = 'home' }) {
  const tabs = [
    { id: 'home', label: 'ホーム' },
    { id: 'cal', label: 'カレンダー' },
    { id: 'add', label: '' },
    { id: 'stat', label: '実績' },
    { id: 'set', label: '設定' },
  ];
  return (
    <div style={{
      position: 'absolute', left: 16, right: 16, bottom: 22,
      background: 'rgba(14,21,48,0.85)', backdropFilter: 'blur(20px)',
      border: `1px solid ${D.cardBorder}`,
      borderRadius: 100, padding: '10px 14px',
      display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      boxShadow: '0 12px 32px rgba(0,0,0,0.4)',
    }}>
      {tabs.map((t) => {
        const isActive = t.id === active;
        if (t.id === 'add') {
          return (
            <div key={t.id} style={{
              width: 54, height: 54, borderRadius: 28,
              background: D.fabGrad, color: '#fff',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontSize: 30, fontWeight: 300, marginTop: -10, marginBottom: -10,
              boxShadow: '0 8px 22px rgba(95,233,255,0.4), 0 0 0 1px rgba(255,255,255,0.1) inset',
            }}>+</div>
          );
        }
        return (
          <div key={t.id} style={{
            flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 3,
            padding: '6px 4px', borderRadius: 14, minWidth: 0,
            background: isActive ? 'rgba(125,245,237,0.10)' : 'transparent',
            border: isActive ? `1px solid rgba(125,245,237,0.20)` : '1px solid transparent',
          }}>
            <TabIcon id={t.id} color={isActive ? D.cyan : D.inkMuted} />
            <div style={{ fontSize: 11, fontWeight: 600, color: isActive ? D.cyan : D.inkMuted, whiteSpace: 'nowrap' }}>{t.label}</div>
          </div>
        );
      })}
    </div>
  );
}

function TabIcon({ id, color }) {
  const s = { width: 22, height: 22, fill: 'none', stroke: color, strokeWidth: 2, strokeLinecap: 'round', strokeLinejoin: 'round' };
  if (id === 'home') return <svg viewBox="0 0 24 24" {...s}><path d="M3 11l9-8 9 8"/><path d="M5 10v10h14V10"/></svg>;
  if (id === 'cal') return <svg viewBox="0 0 24 24" {...s}><rect x="3" y="5" width="18" height="16" rx="2"/><path d="M3 9h18M8 3v4M16 3v4"/></svg>;
  if (id === 'stat') return <svg viewBox="0 0 24 24" {...s}><path d="M8 21h8M12 17v4M6 4h12v5a6 6 0 01-12 0V4z"/><path d="M6 6H3v2a3 3 0 003 3M18 6h3v2a3 3 0 01-3 3"/></svg>;
  if (id === 'set') return <svg viewBox="0 0 24 24" {...s}><circle cx="12" cy="12" r="3"/><path d="M12 2v3M12 19v3M4.2 4.2l2.1 2.1M17.7 17.7l2.1 2.1M2 12h3M19 12h3M4.2 19.8l2.1-2.1M17.7 6.3l2.1-2.1"/></svg>;
  return null;
}

// ---------- HOME SCREEN (dark) ----------
function HomeScreen({ greeting = 'おはよう', date = '5月21日', dow = '木', taskCounts = { today: 1, week: 2, later: 7, total: 10 }, tasks } = {}) {
  const defaultTasks = [
    { section: 'today', dot: D.red, label: '今日', n: 1, items: [{ accent: D.red, title: '週報提出', due: '今日', dueColor: D.red }] },
    { section: 'week', dot: D.amber, label: '今週', n: 2, items: [
      { accent: D.amber, title: '企画書作成', due: '5月23日', dueColor: D.amber },
      { accent: D.amber, title: '家賃振込', due: '5月24日', dueColor: D.amber, muted: true },
    ]},
    { section: 'later', dot: D.cyan, label: '来週以降', n: 7, items: [] },
  ];
  const t = tasks || defaultTasks;
  return (
    <div style={phoneRoot}>
      <StatusBar />
      <div style={{ padding: '8px 22px 0' }}>
        <div style={{ fontSize: 15, color: D.inkMuted, fontWeight: 600, marginBottom: 2, letterSpacing: 4 }}>{greeting}</div>
        <div style={{ display: 'flex', alignItems: 'baseline', gap: 6, marginBottom: 18, whiteSpace: 'nowrap' }}>
          <div style={{ fontSize: 34, fontWeight: 900, letterSpacing: -0.5, whiteSpace: 'nowrap' }}>{date}</div>
          <div style={{ fontSize: 18, color: D.inkMuted, fontWeight: 700 }}>{dow}</div>
        </div>

        {/* Hero card */}
        <div style={{
          background: 'linear-gradient(180deg, rgba(125,245,237,0.06) 0%, rgba(10,20,55,0.7) 100%)',
          border: `1px solid ${D.cardBorderStrong}`,
          borderRadius: 22, padding: '18px 20px 20px', color: D.ink,
          boxShadow: '0 0 40px rgba(125,245,237,0.08) inset',
        }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
            <div style={{ background: 'rgba(255,255,255,0.06)', border: `1px solid ${D.cardBorder}`, borderRadius: 100, padding: '5px 14px', fontSize: 13, fontWeight: 700 }}>今日</div>
            <div style={{ background: 'rgba(255,255,255,0.04)', border: `1px solid ${D.cardBorder}`, borderRadius: 100, padding: '5px 12px', display: 'flex', alignItems: 'center', gap: 8, fontSize: 13, fontWeight: 700 }}>
              <span>Lv.1</span><span style={{ color: D.cyan }}>+30</span>
            </div>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 14 }}>
            <div>
              <div style={{ fontSize: 13, color: D.inkMuted, fontWeight: 600, marginBottom: 2 }}>今日の進捗</div>
              <div style={{ display: 'flex', alignItems: 'baseline', gap: 2 }}>
                <div style={{ fontSize: 52, fontWeight: 800, lineHeight: 1 }}>0</div>
                <div style={{ fontSize: 22, fontWeight: 700, color: D.inkMuted }}>/1</div>
              </div>
            </div>
            <div style={{
              width: 70, height: 70, borderRadius: 35,
              border: `4px solid ${D.cardBorder}`,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontSize: 15, fontWeight: 800, color: D.ink,
            }}>0%</div>
          </div>
          <div style={{
            background: D.cyanGrad, color: '#06243d', borderRadius: 16, padding: '14px 18px',
            display: 'flex', alignItems: 'center', justifyContent: 'space-between',
            fontWeight: 800, fontSize: 14, whiteSpace: 'nowrap',
            boxShadow: '0 8px 24px rgba(125,245,237,0.25)',
          }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <span style={{ fontSize: 14 }}>✦</span>
              <span>今日のタスクをAIで整理</span>
            </div>
            <span style={{ color: '#06243d' }}>›</span>
          </div>
          <div style={{ textAlign: 'center', marginTop: 10, fontSize: 12, color: D.inkMuted, fontWeight: 600 }}>今月 残り 30/30回</div>
        </div>

        {/* Filter pills */}
        <div style={{ display: 'flex', gap: 6, marginTop: 16, marginBottom: 4 }}>
          <Pill color={D.red} label="今日" n={taskCounts.today} />
          <Pill color={D.amber} label="今週" n={taskCounts.week} />
          <Pill color={D.cyan} label="来週以降" n={taskCounts.later} />
          <Pill color={D.inkMuted} label="全タスク" n={taskCounts.total} />
        </div>

        {/* Task list */}
        <div style={{ marginTop: 8 }}>
          {t.map((sec, i) => (
            <React.Fragment key={i}>
              <SectionHead dot={sec.dot} label={sec.label} n={sec.n} />
              {sec.items.map((it, j) => <TaskCard key={j} {...it} />)}
            </React.Fragment>
          ))}
        </div>
      </div>
      <TabBar active="home" />
    </div>
  );
}

function Pill({ color, label, n }) {
  return (
    <div style={{
      background: 'transparent',
      border: `1px solid ${color}66`,
      borderRadius: 100, padding: '7px 12px',
      display: 'flex', alignItems: 'center', gap: 5, fontSize: 12, fontWeight: 700, color: D.ink,
      whiteSpace: 'nowrap',
    }}>
      <div style={{ width: 6, height: 6, borderRadius: 4, background: color }} />
      <span>{label}</span>
      <span style={{ fontWeight: 800, color }}>{n}</span>
    </div>
  );
}
function SectionHead({ dot, label, n }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '14px 4px 8px', fontSize: 14, fontWeight: 700, color: D.ink, whiteSpace: 'nowrap' }}>
      <div style={{ width: 8, height: 8, borderRadius: 5, background: dot }} />
      <span>{label}</span>
      <span style={{ color: D.inkMuted, fontWeight: 700 }}>{n}</span>
      <div style={{ flex: 1, height: 1, background: D.cardBorder, marginLeft: 6 }} />
    </div>
  );
}
function TaskCard({ accent, title, due, dueColor, muted }) {
  return (
    <div style={{
      background: 'rgba(255,255,255,0.025)',
      border: `1px solid ${D.cardBorder}`,
      borderRadius: 14, padding: '14px 16px',
      display: 'flex', alignItems: 'center', gap: 12, marginBottom: 8,
      position: 'relative', overflow: 'hidden',
    }}>
      <div style={{ position: 'absolute', left: 0, top: 6, bottom: 6, width: 5, background: accent, borderRadius: 3, boxShadow: `0 0 12px ${accent}88` }} />
      <div style={{
        width: 26, height: 26, borderRadius: 14,
        border: `2px solid ${muted ? D.inkDim : accent}`,
      }} />
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 16, fontWeight: 700, color: D.ink, marginBottom: 2, whiteSpace: 'nowrap' }}>{title}</div>
        <div style={{ fontSize: 12, fontWeight: 700, color: dueColor, display: 'flex', alignItems: 'center', gap: 4, whiteSpace: 'nowrap' }}>
          <span>⚡</span>{due}
        </div>
      </div>
      <div style={{ color: D.inkDim, fontSize: 18 }}>›</div>
    </div>
  );
}

// ---------- CALENDAR SCREEN ----------
function CalendarScreen() {
  const days = [
    [null, null, null, null, '1', '2', '3'],
    ['4', '5', '6', '7', '8', '9', '10'],
    ['11', '12', '13', '14', '15', '16', '17'],
    ['18', '19', '20', '21', '22', '23', '24'],
    ['25', '26', '27', '28', '29', '30', '31'],
  ];
  const today = '21';
  const tagColors = { 23: D.amber, 24: D.amber, 25: D.cyan, 26: D.cyan };
  return (
    <div style={phoneRoot}>
      <StatusBar />
      <div style={{ padding: '14px 22px 0' }}>
        <div style={{
          background: 'rgba(255,255,255,0.04)', border: `1px solid ${D.cardBorder}`,
          borderRadius: 100, padding: 4, display: 'flex', gap: 4, marginBottom: 22,
          whiteSpace: 'nowrap',
        }}>
          <div style={{ flex: 1, textAlign: 'center', padding: '10px 0', borderRadius: 100, background: 'rgba(125,245,237,0.10)', border: `1px solid rgba(125,245,237,0.30)`, fontSize: 13, fontWeight: 700, color: D.cyan }}>✓ AIのおすすめ日</div>
          <div style={{ flex: 1, textAlign: 'center', padding: '10px 0', fontSize: 13, fontWeight: 600, color: D.inkMuted }}>⏱ 期限の日</div>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 14 }}>
          <div style={{ color: D.cyan, fontSize: 18, fontWeight: 800 }}>‹</div>
          <div style={{ fontSize: 19, fontWeight: 800 }}>2026年5月</div>
          <div style={{ color: D.cyan, fontSize: 18, fontWeight: 800 }}>›</div>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(7,1fr)', textAlign: 'center', fontSize: 12, color: D.inkMuted, fontWeight: 700, marginBottom: 6 }}>
          {['月','火','水','木','金','土','日'].map((d) => <div key={d}>{d}</div>)}
        </div>

        {days.map((row, ri) => (
          <div key={ri} style={{ display: 'grid', gridTemplateColumns: 'repeat(7,1fr)', gap: 2, marginBottom: 2 }}>
            {row.map((d, ci) => {
              if (!d) return <div key={ci} />;
              const tag = tagColors[d];
              const isToday = d === today;
              return (
                <div key={ci} style={{
                  aspectRatio: '1', display: 'flex', flexDirection: 'column',
                  alignItems: 'center', justifyContent: 'center', gap: 4,
                  borderRadius: 10, fontSize: 13, fontWeight: 700,
                  background: isToday ? 'rgba(125,245,237,0.08)' : (tag ? 'rgba(255,255,255,0.03)' : 'transparent'),
                  color: isToday ? D.cyan : D.ink,
                  border: isToday ? `1.5px solid ${D.cyan}` : 'none',
                }}>
                  <div>{d}</div>
                  {tag && <div style={{ width: 18, height: 3, borderRadius: 2, background: tag }} />}
                </div>
              );
            })}
          </div>
        ))}

        <div style={{ display: 'flex', gap: 10, justifyContent: 'center', marginTop: 16, fontSize: 11, color: D.inkMuted, fontWeight: 600 }}>
          <Legend color={D.red} label="緊急" />
          <Legend color={D.amber} label="今週" />
          <Legend color={D.cyan} label="来週〜" />
          <Legend color={D.inkDim} label="未整理" />
          <Legend color={D.inkMuted} label="完了" />
        </div>

        <div style={{ marginTop: 20 }}>
          <TaskCard accent={D.red} title="週報提出" due="今日" dueColor={D.red} />
        </div>
      </div>
      <TabBar active="cal" />
    </div>
  );
}
function Legend({ color, label }) {
  return <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}><div style={{ width: 9, height: 9, borderRadius: 2, background: color }} /><span>{label}</span></div>;
}

// ---------- AI RESULT (POPULATED) ----------
function AIResultScreen() {
  return (
    <div style={phoneRoot}>
      <StatusBar />
      <div style={{ padding: '8px 22px 0' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 18, whiteSpace: 'nowrap' }}>
          <div style={{ fontSize: 20, fontWeight: 800, display: 'flex', alignItems: 'center', gap: 8 }}>
            <span style={{ color: D.cyan, fontSize: 18 }}>✦</span> AI整理の結果
          </div>
          <div style={{ fontSize: 14, color: D.cyan, fontWeight: 700 }}>完了</div>
        </div>

        <div style={{
          background: 'linear-gradient(135deg, rgba(125,245,237,0.10) 0%, rgba(180,140,255,0.08) 100%)',
          border: `1px solid ${D.cardBorderStrong}`,
          borderRadius: 18, padding: '16px 18px', marginBottom: 16,
        }}>
          <div style={{ fontSize: 11, fontWeight: 800, color: D.cyan, marginBottom: 6, letterSpacing: 1 }}>AIからの提案</div>
          <div style={{ fontSize: 14, fontWeight: 700, lineHeight: 1.5, color: D.ink }}>
            締切が迫る「週報提出」を最優先に。<br/>「企画書作成」は午後の集中時間に。
          </div>
        </div>

        <div style={{ fontSize: 12, fontWeight: 800, color: D.inkMuted, marginBottom: 10, letterSpacing: 1 }}>今日のおすすめ順</div>

        <AIRankCard rank={1} title="週報提出" meta="所要 15分" tag="最優先" tagColor={D.red} />
        <AIRankCard rank={2} title="企画書作成" meta="所要 90分" tag="集中タイム" tagColor={D.amber} />
        <AIRankCard rank={3} title="メール返信" meta="所要 20分" tag="スキマ時間" tagColor={D.cyan} />
        <AIRankCard rank={4} title="日用品買い出し" meta="帰り道に" tag="ついで" tagColor={D.inkMuted} />
      </div>
      <TabBar active="home" />
    </div>
  );
}
function AIRankCard({ rank, title, meta, tag, tagColor }) {
  return (
    <div style={{
      background: 'rgba(255,255,255,0.025)',
      border: `1px solid ${D.cardBorder}`,
      borderRadius: 14, padding: '13px 14px',
      display: 'flex', alignItems: 'center', gap: 12, marginBottom: 8,
      position: 'relative', overflow: 'hidden',
    }}>
      <div style={{ position: 'absolute', left: 0, top: 6, bottom: 6, width: 4, background: tagColor, borderRadius: 3, boxShadow: `0 0 10px ${tagColor}88` }} />
      <div style={{
        width: 32, height: 32, borderRadius: 10, background: 'rgba(255,255,255,0.06)', border: `1px solid ${tagColor}66`,
        color: tagColor,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontSize: 14, fontWeight: 900, marginLeft: 4,
      }}>{rank}</div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 15, fontWeight: 700, color: D.ink, marginBottom: 2, whiteSpace: 'nowrap' }}>{title}</div>
        <div style={{ fontSize: 11, fontWeight: 600, color: D.inkMuted, whiteSpace: 'nowrap' }}>{meta}</div>
      </div>
      <div style={{ background: `${tagColor}22`, color: tagColor, fontSize: 11, fontWeight: 800, padding: '5px 10px', borderRadius: 100, whiteSpace: 'nowrap', border: `1px solid ${tagColor}44` }}>{tag}</div>
    </div>
  );
}

// ---------- ADD TASK SHEET ----------
function AddTaskScreen() {
  return (
    <div style={phoneRoot}>
      <StatusBar />
      {/* faded home behind */}
      <div style={{ padding: '8px 22px 0', opacity: 0.35 }}>
        <div style={{ fontSize: 15, color: D.inkMuted, fontWeight: 600, marginBottom: 2, letterSpacing: 4 }}>おはよう</div>
        <div style={{ display: 'flex', alignItems: 'baseline', gap: 6, marginBottom: 18, whiteSpace: 'nowrap' }}>
          <div style={{ fontSize: 34, fontWeight: 900 }}>5月21日</div>
          <div style={{ fontSize: 18, color: D.inkMuted, fontWeight: 700 }}>木</div>
        </div>
        <div style={{ background: 'rgba(255,255,255,0.04)', border: `1px solid ${D.cardBorder}`, borderRadius: 22, height: 200 }} />
      </div>
      {/* dim overlay */}
      <div style={{ position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.45)' }} />
      <div style={{
        position: 'absolute', left: 0, right: 0, bottom: 0,
        background: '#0a1230', borderTopLeftRadius: 22, borderTopRightRadius: 22,
        padding: '12px 22px 32px', height: '70%',
        border: `1px solid ${D.cardBorder}`,
        boxShadow: '0 -20px 40px rgba(0,0,0,0.5)',
      }}>
        <div style={{ width: 38, height: 5, borderRadius: 3, background: D.inkDim, margin: '0 auto 14px' }} />
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 24, whiteSpace: 'nowrap' }}>
          <div style={{ color: D.cyan, fontSize: 15, fontWeight: 700 }}>キャンセル</div>
          <div style={{ fontSize: 17, fontWeight: 800 }}>タスクを追加</div>
          <div style={{ color: D.cyan, fontSize: 15, fontWeight: 800 }}>保存</div>
        </div>

        <div style={{ position: 'relative', border: `1.5px solid ${D.cardBorderStrong}`, borderRadius: 14, padding: '18px 16px 14px', marginBottom: 16 }}>
          <div style={{ position: 'absolute', top: -10, left: 16, background: '#0a1230', padding: '0 6px', fontSize: 12, color: D.cyan, fontWeight: 700 }}>タスク名</div>
          <div style={{ fontSize: 18, fontWeight: 700, color: D.ink, whiteSpace: 'nowrap' }}>買い物リスト<span style={{ color: D.cyan, marginLeft: 2 }}>|</span></div>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: 14, padding: '16px 4px', borderBottom: `1px solid ${D.cardBorder}`, whiteSpace: 'nowrap' }}>
          <CalIcon color={D.cyan} />
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 15, fontWeight: 700, marginBottom: 2 }}>期限日</div>
            <div style={{ fontSize: 13, color: D.inkMuted, fontWeight: 600 }}>2026年5月28日</div>
          </div>
          <div style={{ color: D.inkDim, fontSize: 18 }}>›</div>
        </div>

        <div style={{ border: `1px solid ${D.cardBorder}`, borderRadius: 14, padding: '14px 16px', marginTop: 16, display: 'flex', alignItems: 'center', gap: 14 }}>
          <NoteIcon color={D.inkMuted} />
          <div style={{ flex: 1, color: D.inkMuted, fontSize: 15, fontWeight: 600 }}>メモ</div>
        </div>

        <div style={{ textAlign: 'center', marginTop: 22, color: D.cyan, fontSize: 13, fontWeight: 700 }}>詳細設定 ▾</div>
      </div>
    </div>
  );
}

function CalIcon({ color }) {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="5" width="18" height="16" rx="2"/><path d="M3 9h18M8 3v4M16 3v4"/></svg>;
}
function NoteIcon({ color }) {
  return <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z"/><path d="M14 2v6h6M8 13h8M8 17h5"/></svg>;
}

// ---------- TASK DETAIL with COUNTDOWN (overdue) ----------
function TaskDetailScreen() {
  return (
    <div style={phoneRoot}>
      <StatusBar />
      <div style={{ padding: '14px 22px 0', position: 'relative' }}>
        {/* top row */}
        <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: 22 }}>
          <div style={{
            width: 40, height: 40, borderRadius: 20,
            border: `1px solid ${D.cardBorder}`, background: 'rgba(255,255,255,0.03)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            color: D.ink, fontSize: 18, fontWeight: 700,
          }}>‹</div>
          <div style={{
            border: `1px solid ${D.cardBorder}`, borderRadius: 100, padding: '10px 16px',
            display: 'flex', alignItems: 'center', gap: 6, color: D.cyan, fontSize: 13, fontWeight: 700,
            background: 'rgba(255,255,255,0.03)', whiteSpace: 'nowrap',
          }}>
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke={D.cyan} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M17 3l4 4L7 21H3v-4z"/></svg>
            タスクを編集
          </div>
        </div>

        <div style={{ display: 'flex', gap: 8, marginBottom: 16, whiteSpace: 'nowrap' }}>
          <div style={{ background: 'rgba(255,93,108,0.12)', color: D.red, border: `1px solid ${D.red}55`, borderRadius: 8, padding: '6px 14px', fontSize: 12, fontWeight: 800, letterSpacing: 1 }}>NORMAL</div>
          <div style={{ background: 'rgba(255,255,255,0.03)', color: D.inkMuted, border: `1px solid ${D.cardBorder}`, borderRadius: 8, padding: '6px 14px', fontSize: 12, fontWeight: 700 }}>定期設定</div>
        </div>

        <div style={{ fontSize: 32, fontWeight: 900, marginBottom: 22, whiteSpace: 'nowrap' }}>週報提出</div>

        {/* OVERDUE countdown card */}
        <div style={{
          position: 'relative',
          background: 'linear-gradient(180deg, rgba(255,77,141,0.08) 0%, rgba(10,18,48,0.4) 100%)',
          border: `1px solid rgba(255,77,141,0.35)`,
          borderRadius: 16, padding: '18px 20px 20px', marginBottom: 18,
          overflow: 'hidden',
        }}>
          <div style={{ position: 'absolute', top: 0, left: 0, right: 0, height: 2, background: `linear-gradient(90deg, ${D.pink}, ${D.cyan})` }} />
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 10 }}>
            <div style={{ width: 7, height: 7, borderRadius: 4, background: D.pink, boxShadow: `0 0 8px ${D.pink}` }} />
            <span style={{ color: D.pink, fontSize: 12, fontWeight: 800, letterSpacing: 1.5 }}>OVERDUE</span>
          </div>
          <div style={{
            fontSize: 56, fontWeight: 900, letterSpacing: -1, lineHeight: 1,
            fontVariantNumeric: 'tabular-nums', whiteSpace: 'nowrap',
            background: `linear-gradient(90deg, ${D.ink} 0%, ${D.pink} 100%)`,
            WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent',
            marginBottom: 8,
          }}>01:02:23</div>
          <div style={{ fontSize: 12, fontWeight: 600, color: D.inkMuted, whiteSpace: 'nowrap' }}>2026年5月21日 0:00</div>
        </div>

        {/* meta list */}
        <div style={{ border: `1px solid ${D.cardBorder}`, borderRadius: 14, padding: '4px 14px', marginBottom: 18 }}>
          <MetaRow icon={<CalIcon color={D.inkMuted} />} label="DUE" value="2026年5月21日 0:00" />
          <MetaRow icon={<RepeatIcon color={D.inkMuted} />} label="REPEAT" value="毎週" />
          <MetaRow icon={<BoltIcon color={D.inkMuted} />} label="EST" value="30 min" last />
        </div>

        <div style={{ border: `1px solid ${D.cardBorder}`, borderRadius: 14, padding: '14px 16px', marginBottom: 22 }}>
          <div style={{ fontSize: 11, color: D.inkMuted, fontWeight: 800, letterSpacing: 1.2, marginBottom: 6 }}>MEMO</div>
          <div style={{ fontSize: 14, color: D.ink, fontWeight: 600, whiteSpace: 'nowrap' }}>Teamsで提出 テンプレあり</div>
        </div>

        <div style={{
          background: D.cyanGrad, color: '#06243d',
          borderRadius: 14, padding: '16px',
          display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
          fontSize: 16, fontWeight: 800, whiteSpace: 'nowrap',
          boxShadow: '0 10px 28px rgba(125,245,237,0.35)',
        }}>
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#06243d" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round"><path d="M5 12l5 5L20 7"/></svg>
          完了にする
        </div>
      </div>
    </div>
  );
}
function MetaRow({ icon, label, value, last }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '14px 0', borderBottom: last ? 'none' : `1px solid ${D.cardBorder}`, whiteSpace: 'nowrap' }}>
      {icon}
      <div style={{ fontSize: 11, color: D.inkMuted, fontWeight: 800, letterSpacing: 1.2, width: 70 }}>{label}</div>
      <div style={{ flex: 1, textAlign: 'right', fontSize: 14, color: D.ink, fontWeight: 700 }}>{value}</div>
    </div>
  );
}
function RepeatIcon({ color }) { return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M17 1l4 4-4 4M3 11V9a4 4 0 014-4h14M7 23l-4-4 4-4M21 13v2a4 4 0 01-4 4H3"/></svg>; }
function BoltIcon({ color }) { return <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M13 2L3 14h9l-1 8 10-12h-9z"/></svg>; }

// ---------- PREMIUM PLAN ----------
function PremiumScreen() {
  const features = [
    { icon: 'block', label: '広告非表示' },
    { icon: 'sparkle', label: 'AI整理 月30回（無料は2回）' },
    { icon: 'bell', label: '通知の自動設定' },
    { icon: 'calexp', label: 'カレンダー書き出し' },
    { icon: 'check', label: 'タスク登録 無制限' },
    { icon: 'repeat', label: '定期タスク 無制限' },
    { icon: 'shapes', label: 'カテゴリ 無制限' },
  ];
  return (
    <div style={phoneRoot}>
      <StatusBar />
      <div style={{ padding: '14px 24px 0' }}>
        <div style={{ fontSize: 22, fontWeight: 800, color: D.ink, marginBottom: 22, whiteSpace: 'nowrap' }}>プレミアムプラン</div>

        {/* hero medal */}
        <div style={{ textAlign: 'center', padding: '30px 0 18px' }}>
          <div style={{
            display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
            width: 80, height: 80, marginBottom: 16, position: 'relative',
          }}>
            <div style={{ position: 'absolute', inset: 0, background: 'radial-gradient(circle, rgba(125,245,237,0.35) 0%, transparent 70%)', filter: 'blur(8px)' }} />
            <MedalIcon color={D.cyan} />
          </div>
          <div style={{ fontSize: 28, fontWeight: 800, color: D.ink, whiteSpace: 'nowrap' }}>プレミアムプラン</div>
        </div>

        {/* status button */}
        <div style={{
          background: 'rgba(125,245,237,0.10)', border: `1px solid ${D.cyan}66`,
          borderRadius: 14, padding: '16px',
          display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 10,
          fontSize: 15, fontWeight: 800, color: D.cyan, marginBottom: 22, whiteSpace: 'nowrap',
        }}>
          <svg width="20" height="20" viewBox="0 0 24 24" fill={D.cyan}><circle cx="12" cy="12" r="10" opacity="0.2"/><path d="M9 12l2 2 4-4" fill="none" stroke={D.cyan} strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"/></svg>
          プレミアム登録済み
        </div>

        {/* features card */}
        <div style={{ border: `1px solid ${D.cardBorder}`, borderRadius: 18, padding: '8px 18px', background: 'rgba(255,255,255,0.02)' }}>
          {features.map((f, i) => (
            <div key={i} style={{
              display: 'flex', alignItems: 'center', gap: 14, padding: '14px 0',
              borderBottom: i < features.length - 1 ? `1px solid ${D.cardBorder}` : 'none',
              whiteSpace: 'nowrap',
            }}>
              <FeatureIcon kind={f.icon} color={D.cyan} />
              <div style={{ fontSize: 15, color: D.ink, fontWeight: 600 }}>{f.label}</div>
            </div>
          ))}
        </div>

        <div style={{ textAlign: 'center', marginTop: 28, fontSize: 12, color: D.inkMuted, fontWeight: 600 }}>
          <span style={{ textDecoration: 'underline', textUnderlineOffset: 3 }}>利用規約</span>
          <span style={{ margin: '0 12px', color: D.inkDim }}>|</span>
          <span style={{ textDecoration: 'underline', textUnderlineOffset: 3 }}>プライバシーポリシー</span>
        </div>
      </div>
    </div>
  );
}
function MedalIcon({ color }) {
  return (
    <svg width="64" height="64" viewBox="0 0 64 64" fill="none">
      <defs>
        <linearGradient id="medalGrad" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stopColor={color} stopOpacity="1"/>
          <stop offset="100%" stopColor={color} stopOpacity="0.5"/>
        </linearGradient>
      </defs>
      {/* ribbon */}
      <path d="M22 38 L18 60 L32 53 L46 60 L42 38 Z" fill="url(#medalGrad)" opacity="0.55"/>
      {/* outer circle */}
      <circle cx="32" cy="26" r="20" fill="url(#medalGrad)"/>
      <circle cx="32" cy="26" r="20" fill="none" stroke={color} strokeWidth="2"/>
      {/* inner circle */}
      <circle cx="32" cy="26" r="13" fill="#040818"/>
      {/* star */}
      <path d="M32 17 L34.5 23 L41 23.5 L36 27.5 L37.5 34 L32 30.5 L26.5 34 L28 27.5 L23 23.5 L29.5 23 Z" fill={color}/>
    </svg>
  );
}
function FeatureIcon({ kind, color }) {
  const s = { width: 22, height: 22, fill: 'none', stroke: color, strokeWidth: 2, strokeLinecap: 'round', strokeLinejoin: 'round' };
  switch (kind) {
    case 'block': return <svg viewBox="0 0 24 24" {...s}><circle cx="12" cy="12" r="10"/><path d="M5 5l14 14"/></svg>;
    case 'sparkle': return <svg viewBox="0 0 24 24" {...s}><path d="M12 3v4M12 17v4M3 12h4M17 12h4M5.6 5.6l2.8 2.8M15.6 15.6l2.8 2.8M5.6 18.4l2.8-2.8M15.6 8.4l2.8-2.8"/></svg>;
    case 'bell': return <svg viewBox="0 0 24 24" {...s}><path d="M18 8a6 6 0 10-12 0c0 7-3 9-3 9h18s-3-2-3-9M13.7 21a2 2 0 01-3.4 0"/></svg>;
    case 'calexp': return <svg viewBox="0 0 24 24" {...s}><rect x="3" y="5" width="18" height="16" rx="2"/><path d="M3 9h18M8 3v4M16 3v4M12 13v6M9 16l3 3 3-3"/></svg>;
    case 'check': return <svg viewBox="0 0 24 24" {...s}><circle cx="12" cy="12" r="10"/><path d="M8 12l3 3 5-6"/></svg>;
    case 'repeat': return <svg viewBox="0 0 24 24" {...s}><path d="M17 1l4 4-4 4M3 11V9a4 4 0 014-4h14M7 23l-4-4 4-4M21 13v2a4 4 0 01-4 4H3"/></svg>;
    case 'shapes': return <svg viewBox="0 0 24 24" {...s}><circle cx="6" cy="6" r="3"/><rect x="14" y="3" width="7" height="7" rx="1"/><path d="M9 21l-6 0 3-6z"/><rect x="14" y="14" width="7" height="7" rx="1"/></svg>;
    default: return null;
  }
}

Object.assign(window, {
  HomeScreen, CalendarScreen, AIResultScreen, AddTaskScreen, TaskDetailScreen, PremiumScreen,
  APP_TOKENS: D,
});
