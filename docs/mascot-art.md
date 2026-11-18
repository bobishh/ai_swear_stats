# Editable mascot packages

Open **Mascot…** in the sidebar. **Export starter…** creates a local folder with the built-in artwork and manifest. Ask an image-capable agent to change that folder using **Copy agent instructions**. **Use folder…** selects a package; **Reload** reads subsequent local edits. The selected folder persists across launches. **Built-in** restores Bodya. **Show on desktop** controls placement independently of appearance.

A package contains `manifest.json` and individual transparent RGBA PNG frames. No atlas unpacker or Swift change is required to replace a frame. Files remain local; selecting a package neither runs code nor sends conversations anywhere. Keep the selected folder available; an unavailable package falls back to the built-in artwork on next launch and reports the error in Mascot settings.

```json
{
  "formatVersion": 1,
  "name": "My character",
  "canvas": {"width": 192, "height": 208, "footX": 96, "footY": 204},
  "clips": {
    "walk-right": {
      "frameDuration": 0.12,
      "frames": ["walk-right/00.png", "walk-right/01.png"]
    }
  }
}
```

The abbreviated example shows one clip. A valid package must declare all seven clips: `walk-left`, `walk-right`, `squat`, `drink`, `throw`, `rowdy`, `sleep`. Each needs 2–32 ordered frames and a finite `frameDuration` of 0.04–1 seconds. The `throw` clip also needs a zero-based `releaseFrame` within its frame array. It must face right: the application projects a single bottle from the actor's right hand to the empty pile.

All frames use a fixed 192 × 208 canvas and foot anchor (96, 204). Keep the camera and registration fixed across actions; retain transparency around the character. The app draws the full bottle queue, empty pile and projectile. Do not draw those into the frames. The starter uses eight walking frames per direction, six for squat/drink/throw/rowdy and four for sleep.

The application owns the 4.8-second bottle cycle, a one-second pause after drinking, and the resting pause after the throw. The authored drinking clip plus that pause and the throwing clip must fit the cycle, including the 0.6-second flight after release. Changing a skin must not reset bottle counts, phase, audio preferences or placement.

Validation rejects incompatible versions, missing clips or frames, invalid timings, wrong dimensions or non-RGBA PNG headers, paths outside the folder, symlinks, a manifest larger than 64 KiB, and frames larger than 2 MiB. The app decodes every required image before replacing the active appearance. Keep only necessary art and metadata in shared packages; executable additions have no effect.

Run `swift run codex_stats_app --check-mascot /path/to/folder` to validate a package locally without launching the dashboard. Run `swift test --filter MascotAppearanceTests` for the format contract.
