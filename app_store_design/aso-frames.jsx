// aso-frames.jsx — App Store screenshot frames (dark theme).
// Single: 1290×2796. Connected 2-up: 2580×2796.

const FRAME_W = 1290;
const FRAME_H = 2796;

// ---------- Minimal phone frame ----------
function PhoneFrame({ width, height, children, glow }) {
  const bezel = Math.round(width * 0.020);
  const screenW = width - bezel * 2;
  const screenH = height - bezel * 2;
  const radius = Math.round(width * 0.115);
  const innerRadius = radius - bezel + 2;
  const scale = screenW / 393;
  return (
    <div style={{
      width, height,
      background: 'linear-gradient(180deg,#1a1f30 0%,#0a0d18 100%)',
      borderRadius: radius,
      padding: bezel, boxSizing: 'border-box',
      position: 'relative',
      boxShadow: glow
        ? `0 0 80px ${glow}55, 0 30px 60px rgba(0,0,0,0.45), 0 0 0 1px rgba(255,255,255,0.06) inset`
        : '0 30px 60px rgba(0,0,0,0.5), 0 0 0 1px rgba(255,255,255,0.06) inset',
    }}>
      <div style={{
        width: screenW, height: screenH, borderRadius: innerRadius,
        overflow: 'hidden', position: 'relative', background: '#040818',
      }}>
        <div style={{
          position: 'absolute', top: bezel * 0.55, left: '50%', transform: 'translateX(-50%)',
          width: width * 0.28, height: width * 0.07, background: '#000', borderRadius: 100, zIndex: 5,
        }} />
        <div style={{
          width: 393, height: screenH / scale,
          transform: `scale(${scale})`, transformOrigin: 'top left',
        }}>
          {children}
        </div>
      </div>
    </div>
  );
}

// ---------- Background utilities ----------
function DottedBg({ color = 'rgba(255,255,255,0.05)', size = 22 }) {
  return (
    <div style={{
      position: 'absolute', inset: 0,
      backgroundImage: `radial-gradient(${color} 1.4px, transparent 1.4px)`,
      backgroundSize: `${size}px ${size}px`,
      pointerEvents: 'none',
    }} />
  );
}

function Glow({ x = '50%', y = '0%', size = 900, color = 'rgba(125,245,237,0.18)' }) {
  return (
    <div style={{
      position: 'absolute',
      left: x, top: y, width: size, height: size,
      transform: 'translate(-50%, -50%)',
      background: `radial-gradient(circle, ${color} 0%, transparent 60%)`,
      borderRadius: '50%', pointerEvents: 'none',
    }} />
  );
}

// ---------- Headline component ----------
function Headline({ eyebrow, eyebrowColor = 'rgba(125,245,237,1)', title, sub, titleSize = 120 }) {
  return (
    <div style={{ textAlign: 'center', color: '#fff', position: 'relative', zIndex: 2 }}>
      {eyebrow && (
        <div style={{
          display: 'inline-flex', alignItems: 'center', gap: 14,
          background: 'rgba(255,255,255,0.05)', backdropFilter: 'blur(12px)',
          padding: '14px 30px', borderRadius: 100, marginBottom: 34,
          fontSize: 30, fontWeight: 800, letterSpacing: 1, color: eyebrowColor,
          border: `1px solid ${eyebrowColor}55`,
          whiteSpace: 'nowrap',
        }}>
          {eyebrow}
        </div>
      )}
      <h1 style={{
        fontSize: titleSize, fontWeight: 900, lineHeight: 1.16, margin: 0,
        letterSpacing: -2,
      }}>
        {title.map((line, i) => (
          <div key={i} style={{ whiteSpace: 'nowrap' }}>
            {typeof line === 'string' ? line : line.map((seg, j) => (
              <span key={j} style={seg.accent ? { color: eyebrowColor } : {}}>{seg.text}</span>
            ))}
          </div>
        ))}
      </h1>
      {sub && (
        <div style={{
          fontSize: 34, fontWeight: 600, color: 'rgba(255,255,255,0.65)',
          marginTop: 28, lineHeight: 1.4, whiteSpace: 'nowrap',
        }}>{sub}</div>
      )}
    </div>
  );
}

// ============================================================
// 1+2 HERO (2-up connected): Home → AI result
// 2580 × 2796 — sliced into two ASO slots
// ============================================================
function Frame_Hero2Up() {
  return (
    <div style={{
      width: FRAME_W * 2, height: FRAME_H,
      background: 'radial-gradient(120% 70% at 50% 10%, #0e1845 0%, #050b22 60%, #02050f 100%)',
      position: 'relative', overflow: 'hidden',
      fontFamily: '"Noto Sans JP","Hiragino Sans",system-ui,sans-serif',
    }}>
      <DottedBg color="rgba(255,255,255,0.04)" />
      <Glow x="35%" y="20%" size={1300} color="rgba(125,245,237,0.18)" />
      <Glow x="70%" y="15%" size={1100} color="rgba(180,140,255,0.16)" />

      {/* Headline */}
      <div style={{ position: 'absolute', top: 170, left: 0, right: 0, padding: '0 200px', textAlign: 'center' }}>
        <div style={{
          display: 'inline-flex', alignItems: 'center', gap: 16,
          background: 'rgba(125,245,237,0.08)', backdropFilter: 'blur(12px)',
          border: '1px solid rgba(125,245,237,0.30)',
          padding: '16px 36px', borderRadius: 100, marginBottom: 40,
          fontSize: 36, fontWeight: 800, color: '#7df5ed', letterSpacing: 1.5,
          whiteSpace: 'nowrap',
        }}>
          <SparkSvg /> AI × タスク管理
        </div>
        <h1 style={{
          fontSize: 180, fontWeight: 900, lineHeight: 1.12, margin: 0,
          letterSpacing: -3, color: '#fff',
        }}>
          <div style={{ whiteSpace: 'nowrap' }}>登録するだけ。</div>
          <div style={{ whiteSpace: 'nowrap' }}>
            <span style={{
              background: 'linear-gradient(90deg,#7df5ed 0%,#b48cff 100%)',
              WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent',
            }}>AI</span>
            が今日の道筋を作る。
          </div>
        </h1>
        <div style={{
          fontSize: 40, fontWeight: 600, color: 'rgba(255,255,255,0.65)',
          marginTop: 32, whiteSpace: 'nowrap',
        }}>
          書き出す → 優先順位を提案 → 迷わず動ける
        </div>
      </div>

      {/* Phones */}
      <div style={{
        position: 'absolute', bottom: -160, left: 0, width: '100%',
        display: 'flex', justifyContent: 'center', gap: 100, alignItems: 'flex-end',
      }}>
        <div style={{ position: 'relative' }}>
          <StepBadge text="STEP 01" caption="書き出す" color="#7df5ed" />
          <PhoneFrame width={1020} height={2090} glow="#7df5ed">
            <HomeScreen />
          </PhoneFrame>
        </div>

        {/* central connector */}
        <div style={{
          position: 'absolute', left: '50%', top: '52%', transform: 'translate(-50%,-50%)', zIndex: 3,
        }}>
          <div style={{
            width: 140, height: 140, borderRadius: 70,
            background: 'linear-gradient(135deg,#7df5ed 0%,#b48cff 100%)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: '0 0 80px rgba(125,245,237,0.55), 0 20px 50px rgba(0,0,0,0.4)',
            fontSize: 70, color: '#06243d', fontWeight: 900,
            border: '4px solid rgba(255,255,255,0.18)',
          }}>→</div>
        </div>

        <div style={{ position: 'relative' }}>
          <StepBadge text="STEP 02" caption="AIが整理" color="#b48cff" align="right" />
          <PhoneFrame width={1020} height={2090} glow="#b48cff">
            <AIResultScreen />
          </PhoneFrame>
        </div>
      </div>
    </div>
  );
}

function StepBadge({ text, caption, color, align = 'left' }) {
  return (
    <div style={{
      position: 'absolute', top: -130,
      left: align === 'left' ? 30 : 'auto',
      right: align === 'right' ? 30 : 'auto',
      display: 'flex', alignItems: 'center', gap: 14,
      background: 'rgba(10,18,48,0.85)', backdropFilter: 'blur(12px)',
      border: `1px solid ${color}66`,
      borderRadius: 100, padding: '14px 24px 14px 18px',
      boxShadow: `0 0 30px ${color}33`,
      whiteSpace: 'nowrap',
    }}>
      <div style={{
        background: `${color}22`, color, fontSize: 16, fontWeight: 900,
        padding: '5px 12px', borderRadius: 100, letterSpacing: 1.5,
        border: `1px solid ${color}66`,
      }}>{text}</div>
      <div style={{ fontSize: 30, fontWeight: 800, color: '#fff' }}>{caption}</div>
    </div>
  );
}

function SparkSvg() {
  return (
    <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="#7df5ed" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
      <path d="M12 3l1.5 5.5L19 10l-5.5 1.5L12 17l-1.5-5.5L5 10l5.5-1.5z"/>
      <path d="M19 17l.7 2.3L22 20l-2.3.7L19 23l-.7-2.3L16 20l2.3-.7z" opacity="0.7"/>
    </svg>
  );
}

// ============================================================
// SINGLE FRAMES
// ============================================================

// 3 — Calendar
function Frame_Calendar() {
  return (
    <div style={{
      width: FRAME_W, height: FRAME_H,
      background: 'radial-gradient(110% 80% at 50% 10%, #0d2b3d 0%, #051624 60%, #02080f 100%)',
      position: 'relative', overflow: 'hidden',
      fontFamily: '"Noto Sans JP","Hiragino Sans",system-ui,sans-serif',
    }}>
      <DottedBg color="rgba(255,255,255,0.05)" />
      <Glow x="50%" y="0%" size={1100} color="rgba(74,217,184,0.20)" />
      <div style={{ padding: '170px 80px 0', position: 'relative' }}>
        <Headline
          eyebrow={<><CalIconSm /> カレンダー連動</>}
          eyebrowColor="#4ad9b8"
          title={[
            '予定も進捗も、',
            [{ text: 'ひと目', accent: true }, { text: 'でわかる。' }],
          ]}
          sub="緊急 · 今週 · 来週を、色で見分ける"
          titleSize={124}
        />
      </div>
      <div style={{ position: 'absolute', bottom: -50, left: '50%', transform: 'translateX(-50%)' }}>
        <PhoneFrame width={970} height={1980} glow="#4ad9b8">
          <CalendarScreen />
        </PhoneFrame>
      </div>
    </div>
  );
}
function CalIconSm() { return <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#4ad9b8" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="5" width="18" height="16" rx="2"/><path d="M3 9h18M8 3v4M16 3v4"/></svg>; }

// 4 — Task Detail / Countdown
function Frame_TaskDetail() {
  return (
    <div style={{
      width: FRAME_W, height: FRAME_H,
      background: 'radial-gradient(120% 80% at 50% 10%, #3a0a1e 0%, #1a0612 50%, #08020a 100%)',
      position: 'relative', overflow: 'hidden',
      fontFamily: '"Noto Sans JP","Hiragino Sans",system-ui,sans-serif',
    }}>
      <DottedBg color="rgba(255,255,255,0.05)" />
      <Glow x="50%" y="5%" size={1200} color="rgba(255,77,141,0.20)" />
      <div style={{ padding: '170px 80px 0', position: 'relative' }}>
        <Headline
          eyebrow={<><BellIconSm /> 締切リマインド</>}
          eyebrowColor="#ff7aab"
          title={[
            'うっかり忘れを、',
            [{ text: 'ゼロに', accent: true }, { text: '。' }],
          ]}
          sub="残り時間を、刻一刻と表示"
          titleSize={130}
        />
      </div>
      <div style={{ position: 'absolute', bottom: -50, left: '50%', transform: 'translateX(-50%)' }}>
        <PhoneFrame width={970} height={1980} glow="#ff5d8a">
          <TaskDetailScreen />
        </PhoneFrame>
      </div>
    </div>
  );
}
function BellIconSm() { return <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#ff7aab" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><path d="M18 8a6 6 0 10-12 0c0 7-3 9-3 9h18s-3-2-3-9M13.7 21a2 2 0 01-3.4 0"/></svg>; }

// 5 — Quick Add
function Frame_Quick() {
  return (
    <div style={{
      width: FRAME_W, height: FRAME_H,
      background: 'radial-gradient(120% 80% at 50% 10%, #1a2856 0%, #0a1438 55%, #03061a 100%)',
      position: 'relative', overflow: 'hidden',
      fontFamily: '"Noto Sans JP","Hiragino Sans",system-ui,sans-serif',
    }}>
      <DottedBg color="rgba(255,255,255,0.05)" />
      <Glow x="50%" y="5%" size={1100} color="rgba(125,245,237,0.20)" />
      <div style={{ padding: '170px 80px 0', position: 'relative' }}>
        <Headline
          eyebrow={<><BoltIconSm /> かんたん登録</>}
          eyebrowColor="#7df5ed"
          title={[
            [{ text: '2秒', accent: true }, { text: 'で登録、' }],
            'あとはAIに。',
          ]}
          sub="日付もメモも、後からでOK"
          titleSize={130}
        />
      </div>
      <div style={{ position: 'absolute', bottom: -50, left: '50%', transform: 'translateX(-50%)' }}>
        <PhoneFrame width={970} height={1980} glow="#7df5ed">
          <AddTaskScreen />
        </PhoneFrame>
      </div>
    </div>
  );
}
function BoltIconSm() { return <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#7df5ed" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><path d="M13 2L3 14h9l-1 8 10-12h-9z"/></svg>; }

// 6 — Premium Plan
function Frame_Premium() {
  return (
    <div style={{
      width: FRAME_W, height: FRAME_H,
      background: 'radial-gradient(120% 80% at 50% 10%, #0c2935 0%, #061520 50%, #02060c 100%)',
      position: 'relative', overflow: 'hidden',
      fontFamily: '"Noto Sans JP","Hiragino Sans",system-ui,sans-serif',
    }}>
      <DottedBg color="rgba(255,255,255,0.05)" />
      <Glow x="50%" y="0%" size={1200} color="rgba(125,245,237,0.22)" />
      <Glow x="50%" y="90%" size={900} color="rgba(180,140,255,0.14)" />
      <div style={{ padding: '170px 80px 0', position: 'relative' }}>
        <Headline
          eyebrow={<><MedalSm /> PREMIUM</>}
          eyebrowColor="#7df5ed"
          title={[
            'プレミアムで、',
            [{ text: '無制限', accent: true }, { text: 'へ。' }],
          ]}
          sub="広告非表示・AI整理 月30回・全機能解放"
          titleSize={128}
        />
      </div>
      <div style={{ position: 'absolute', bottom: -50, left: '50%', transform: 'translateX(-50%)' }}>
        <PhoneFrame width={970} height={1980} glow="#7df5ed">
          <PremiumScreen />
        </PhoneFrame>
      </div>
    </div>
  );
}
function MedalSm() { return <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#7df5ed" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="9" r="6"/><path d="M9 14l-2 8 5-2 5 2-2-8"/></svg>; }

Object.assign(window, {
  Frame_Hero2Up, Frame_Calendar, Frame_TaskDetail, Frame_Quick, Frame_Premium,
  PhoneFrame, FRAME_W, FRAME_H,
});
