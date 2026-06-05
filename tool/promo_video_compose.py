#!/usr/bin/env python3
"""
yarunavi PR 動画コンポーザ (15 秒 9:16 SNS 縦動画)。

入力: screenshots/promo/raw_recording.mp4 (Simulator recordVideo の生出力)
出力: screenshots/promo/yarunavi_promo_15s_ja[_silent].mp4

処理:
  1. シミュレータの縦長フレーム (1290x2796 程度) を 9:16 にリサイズ + 黒帯 pad
  2. neon グラデーション風背景 (#0F1014 → #1A1C22) を pad 部分に塗る
  3. 各タイミングで字幕を焼き込む (drawtext, 日本語フォント)
  4. fade in/out
  5. BGM 指定があれば 0.5s fade in / 1.0s fade out で mix
  6. 最終出力 H.264 + AAC、 15 秒固定

使い方:
  python3 promo_video_compose.py                     # 無音版
  python3 promo_video_compose.py --bgm path/to.mp3   # BGM 入り
"""

import argparse
import os
import shutil
import subprocess
import sys
from pathlib import Path

PROJECT = Path(__file__).resolve().parent.parent
PROMO_DIR = PROJECT / 'screenshots' / 'promo'
DEFAULT_INPUT = PROMO_DIR / 'raw_recording.mp4'
DEFAULT_OUTPUT = PROMO_DIR / 'yarunavi_promo_15s_ja.mp4'

# Hiragino Sans (Mac 標準)、無ければ Apple SD Gothic Neo を試す
FONT_CANDIDATES = [
    '/System/Library/Fonts/ヒラギノ角ゴシック W6.ttc',
    '/System/Library/Fonts/Hiragino Sans GB.ttc',
    '/System/Library/Fonts/Apple SD Gothic Neo.ttc',
    '/System/Library/Fonts/PingFang.ttc',
]

# (開始秒, 終了秒, テキスト)。 0:07-0:09 はローディング演出のため字幕なし
SUBTITLES = [
    (0.3, 2.0, 'やることが多すぎる…'),
    (2.0, 5.0, '全部、頭の中で整理してた'),
    (5.0, 7.0, 'ワンタップで AI 整理'),
    (9.0, 13.0, '今日やるべきこと、ひと目で'),
    (13.0, 15.0, 'やるナビ ／ 無料'),
]

OUTPUT_W = 1080
OUTPUT_H = 1920
DURATION = 15.0  # 秒
BG_COLOR = '0x0F1014'  # ダーク neon 背景


def find_font() -> str:
    for f in FONT_CANDIDATES:
        if os.path.exists(f):
            return f
    print('WARN: 日本語フォントが見つかりません。 字幕が□になる可能性があります。',
          file=sys.stderr)
    return ''


def escape_drawtext(text: str) -> str:
    """ffmpeg drawtext の text= 用エスケープ。"""
    return (
        text.replace('\\', '\\\\\\\\')
        .replace(':', '\\\\:')
        .replace(',', '\\\\,')
        .replace("'", "\\\\'")
    )


def build_drawtext_chain(font: str) -> str:
    parts = []
    for start, end, text in SUBTITLES:
        esc = escape_drawtext(text)
        font_arg = f"fontfile='{font}':" if font else ''
        # 下から 22% 位置、 影付き、 fade in/out (alpha カーブ)
        in_dur = 0.2
        out_dur = 0.3
        alpha = (
            f"if(lt(t,{start}),0,"
            f"if(lt(t,{start + in_dur}),(t-{start})/{in_dur},"
            f"if(lt(t,{end - out_dur}),1,"
            f"if(lt(t,{end}),({end}-t)/{out_dur},0))))"
        )
        parts.append(
            f"drawtext={font_arg}text='{esc}':"
            f"fontsize=64:fontcolor=white:"
            f"borderw=3:bordercolor=black@0.7:"
            f"shadowx=2:shadowy=2:shadowcolor=black@0.5:"
            f"x=(w-text_w)/2:y=h-text_h-h*0.18:"
            f"alpha='{alpha}':"
            f"enable='between(t,{start},{end})'"
        )
    return ','.join(parts)


def build_filter_complex(font: str, has_bgm: bool) -> str:
    # シミュレータ画面を 9:16 にフィット (高さ 1840 で内側に置く + 上下 40px 黒帯)
    # 元アスペクト ~ 9:19.5、 ターゲット 9:16 なので、高さ合わせると幅が余る
    # → 高さ 1820 にフィット (上下マージン 50) + 中央 pad で 1080x1920
    base = (
        f"[0:v]scale=-2:1820,"
        f"pad={OUTPUT_W}:{OUTPUT_H}:(ow-iw)/2:(oh-ih)/2:color={BG_COLOR}"
    )
    drawtext = build_drawtext_chain(font)
    fade = f"fade=t=in:st=0:d=0.4,fade=t=out:st={DURATION-0.6}:d=0.6"
    video_chain = f"{base},{drawtext},{fade}[v]"

    if has_bgm:
        audio_chain = (
            f"[1:a]aresample=44100,"
            f"afade=t=in:st=0:d=0.5,"
            f"afade=t=out:st={DURATION-1.0}:d=1.0,"
            f"atrim=0:{DURATION},asetpts=PTS-STARTPTS,"
            f"volume=0.55"
            f"[a]"
        )
        return f"{video_chain};{audio_chain}"
    return video_chain


def compose(
    input_path: Path,
    output_path: Path,
    bgm: Path | None,
):
    if not input_path.exists():
        print(f'ERROR: 入力動画が見つかりません: {input_path}', file=sys.stderr)
        sys.exit(1)
    if not shutil.which('ffmpeg'):
        print('ERROR: ffmpeg が PATH にありません。 brew install ffmpeg してください。',
              file=sys.stderr)
        sys.exit(1)

    font = find_font()
    has_bgm = bgm is not None

    filter_complex = build_filter_complex(font, has_bgm)

    output_path.parent.mkdir(parents=True, exist_ok=True)

    cmd: list[str] = ['ffmpeg', '-y', '-i', str(input_path)]
    if has_bgm:
        cmd.extend(['-i', str(bgm)])

    cmd.extend(['-t', str(DURATION),
                '-filter_complex', filter_complex,
                '-map', '[v]'])
    if has_bgm:
        cmd.extend(['-map', '[a]', '-c:a', 'aac', '-b:a', '160k'])
    else:
        cmd.extend(['-an'])

    cmd.extend([
        '-c:v', 'libx264',
        '-preset', 'medium',
        '-crf', '18',
        '-pix_fmt', 'yuv420p',
        '-movflags', '+faststart',
        str(output_path),
    ])

    print('[ffmpeg]', ' '.join(cmd[:5]), '...', cmd[-1])
    subprocess.run(cmd, check=True)

    size = output_path.stat().st_size
    print(f'\n✅ 完成: {output_path} ({size / 1024 / 1024:.2f} MB)')


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--input', default=str(DEFAULT_INPUT),
                    help=f'生録画 (default: {DEFAULT_INPUT})')
    ap.add_argument('--output', default=None,
                    help='出力パス (default: yarunavi_promo_15s_ja[_silent].mp4)')
    ap.add_argument('--bgm', default=None,
                    help='BGM ファイル (mp3/wav)。省略すると無音版を出力')
    args = ap.parse_args()

    input_path = Path(args.input)
    bgm = Path(args.bgm) if args.bgm else None
    if bgm and not bgm.exists():
        print(f'ERROR: BGM ファイルが見つかりません: {bgm}', file=sys.stderr)
        sys.exit(1)

    if args.output:
        output_path = Path(args.output)
    else:
        suffix = '' if bgm else '_silent'
        output_path = DEFAULT_OUTPUT.with_name(
            f'yarunavi_promo_15s_ja{suffix}.mp4')

    compose(input_path, output_path, bgm)


if __name__ == '__main__':
    main()
