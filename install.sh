#!/bin/bash
# Desktop Plant 맥 설치 (터미널 한 줄용):
#   curl -fsSL https://raw.githubusercontent.com/Bu-Du-Dak/desktop-plant/main/install.sh | bash
# 하는 일: 내 맥(Apple 칩/Intel)에 맞는 최신 버전을 GitHub 릴리스에서 받아 → 파일이 맞는지 확인(sha512)
# → 응용 프로그램 폴더에 넣고 → 실행. 터미널로 받은 파일은 "인터넷에서 받음" 표시가 없어 경고 없이 열린다.
# 공개 저장소(Bu-Du-Dak/desktop-plant)의 install.sh는 이 파일의 사본이다.
set -euo pipefail

REPO="Bu-Du-Dak/desktop-plant"
BASE="https://github.com/$REPO/releases/latest/download"
# 응용 프로그램 폴더에 쓸 수 없는 계정이면 내 응용 프로그램 폴더(~/Applications)에
DEST="${DESKTOP_PLANT_DIR:-/Applications}"
[ -w "$DEST" ] || DEST="$HOME/Applications"
mkdir -p "$DEST"
APP="$DEST/Desktop Plant.app"

case "$(uname -m)" in
  arm64) ARCH=arm64 ;;
  x86_64) ARCH=x64 ;;
  *) echo "이 Mac에서는 설치할 수 없어요 ($(uname -m))"; exit 1 ;;
esac

echo "🌱 Desktop Plant 설치를 시작해요 ($ARCH)"
YML=$(curl -fsSL "$BASE/latest-mac.yml")
FILE=$(printf '%s\n' "$YML" | grep -Eo "Desktop-Plant-[0-9.]+-mac-$ARCH\.zip" | head -1)
SHA=$(printf '%s\n' "$YML" | awk -v f="$FILE" '$0 ~ "url: "f {getline; sub(/.*sha512: /, ""); print; exit}')
if [ -z "$FILE" ] || [ -z "$SHA" ]; then echo "최신 버전 정보를 읽지 못했어요. 잠시 뒤 다시 해 주세요."; exit 1; fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
echo "⬇️  $FILE 받는 중…"
curl -fL --progress-bar "$BASE/$FILE" -o "$TMP/app.zip"
if [ "$(openssl dgst -sha512 -binary "$TMP/app.zip" | base64 | tr -d '\n')" != "$SHA" ]; then
  echo "받은 파일이 올바르지 않아요 (확인값 불일치). 설치하지 않았어요."; exit 1
fi

# 켜져 있으면 끄고 (저장하고 꺼진다) 새 것으로 바꾼다. 키우던 식물 데이터는 다른 폴더라 그대로
if [ -z "${DESKTOP_PLANT_NO_OPEN:-}" ]; then osascript -e 'quit app "Desktop Plant"' >/dev/null 2>&1 || true; sleep 1; fi
rm -rf "$APP"
ditto -xk "$TMP/app.zip" "$DEST"
xattr -dr com.apple.quarantine "$APP" 2>/dev/null || true

echo "✅ 설치 완료: $APP"
if [ -z "${DESKTOP_PLANT_NO_OPEN:-}" ]; then
  open "$APP"
  echo "   화면 위 메뉴 막대에 식물 아이콘이 생기고, 바탕화면에 식물이 나타나요."
fi
