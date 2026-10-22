#!/bin/sh
set -eu
cd "$(dirname "$0")"
swift build -c release --product codex_stats_app
app="$PWD/.build/Swear Stats.app"
mkdir -p "$app/Contents/MacOS"
cp .build/release/codex_stats_app "$app/Contents/MacOS/codex_stats_app.new"
mv "$app/Contents/MacOS/codex_stats_app.new" "$app/Contents/MacOS/codex_stats_app"
mkdir -p "$app/Contents/Resources"
if [ -d "$app/codex_stats_CodexStatsCore.bundle" ]; then
    mv "$app/codex_stats_CodexStatsCore.bundle" "$app/Contents/Resources/"
fi
ditto .build/release/codex_stats_CodexStatsCore.bundle "$app/Contents/Resources/codex_stats_CodexStatsCore.bundle"
cat > "$app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleName</key><string>Swear Stats</string>
<key>CFBundleDisplayName</key><string>Swear Stats</string>
<key>CFBundleIdentifier</key><string>local.bogdan.codex-stats</string>
<key>CFBundleExecutable</key><string>codex_stats_app</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleVersion</key><string>1</string>
<key>CFBundleShortVersionString</key><string>1.0</string>
<key>LSMinimumSystemVersion</key><string>13.0</string>
</dict></plist>
PLIST
codesign --force --sign - --identifier local.bogdan.codex-stats "$app"
codesign --verify --strict "$app"
if [ "${1:-}" != "--build-only" ]; then
    open "$app"
fi
