# Daily Verse — macOS Widget

A small macOS desktop widget that shows the **YouVersion Verse of the Day**, sized like the system Battery widget (`systemSmall`). It refreshes automatically each morning and supports **Liquid Glass** on macOS Tahoe.

## Features

- **YouVersion daily verse**: the same verse as [bible.com/verse-of-the-day](https://www.bible.com/verse-of-the-day) and the YouVersion app, fetched from YouVersion's public API
- **Daily auto-refresh** — timeline reloads shortly after midnight
- **Liquid Glass** — uses `containerBackground`, `widgetRenderingMode`, and `widgetAccentable()` so the widget adapts to clear/tinted desktop appearances
- **Three appearance styles** — configurable per widget (Liquid Glass, Frosted, Fully Clear)
- **Small size only** — matches the Battery widget footprint on Mac desktop

## Requirements

- macOS 15.0 or later (Liquid Glass accents on macOS 26 Tahoe and later, tested on macOS 27)
- Xcode 16+ (Xcode 27 recommended)
- No Apple Developer account needed

## Setup

1. Open `BibleVerse.xcodeproj` in Xcode.
2. Build and run (`⌘R`). The host app previews today’s verse and embeds the widget extension.

Both targets use **Sign to Run Locally**, so there is no Team to pick and no provisioning profile.
That is deliberate: a free Personal Team profile expires after 7 days, and once it does macOS refuses to launch the app or the widget (see [Troubleshooting](#troubleshooting)).
If you have a paid Developer Program membership and want to distribute the app, set your Team under **Signing & Capabilities** on both targets.

### Optional: YouVersion Platform API

By default the widget uses YouVersion's public API behind bible.com (no API key). For the official REST API:

1. Register at [platform.youversion.com](https://platform.youversion.com) and create an app key.
2. Copy `Config/Secrets.xcconfig.example` to `Config/Secrets.xcconfig` (already present).
3. Set `YVP_APP_KEY = your_key_here`.

## Add the widget to your desktop

1. Right-click the desktop → **Edit Widgets**
2. Search for **Daily Verse**
3. Drag the **small** size next to your Battery widget
4. Click the widget while editing → choose **Appearance**:
   - **Liquid Glass** (default) — best with a clear or tinted desktop wallpaper
   - **Frosted** — light blur, readable on busy wallpapers
   - **Fully Clear** — maximum transparency

To change it later, right-click the widget → **Edit “Daily Verse”**. Each widget instance keeps its own appearance.

## Is this a “real” app?

Yes. When you press **⌘R**, Xcode builds:

- `BibleVerse.app` — a real macOS application
- `DailyVerseWidget.appex` — the widget extension embedded inside it

You won’t get a DMG or drag-to-Applications flow automatically — that’s normal for Xcode development builds.

### Where the built app lives

After a successful build:

1. In Xcode’s left sidebar, open **Products**
2. Right-click **BibleVerse.app** → **Show in Finder**

Or find it under Xcode’s DerivedData folder (path varies by machine).

### Install like a normal app (optional)

1. Drag `BibleVerse.app` to **Applications**
2. Open it once from Applications (approve in **System Settings → Privacy & Security** if prompted)
3. Add the desktop widget as described above

The host app must remain installed for the widget to keep working.

### Sharing with others

| Method | What others need |
|--------|------------------|
| **Open source on GitHub** (recommended) | Clone repo, open in Xcode, set signing team, build |
| **DMG download** | You create a signed/notarized DMG (advanced; needs Apple Developer Program for easy install) |
| **Mac App Store** | Separate Apple review process + paid developer account |

This repo is MIT-licensed — see [LICENSE](LICENSE). Others can fork, modify, and share the **code**. Bible verse *text* remains © its publishers (typically ESV via YouVersion); respect [YouVersion’s terms](https://www.youversion.com/terms) if using their API.

## Project structure

```
BibleVerse/              Host app (required for widget distribution)
DailyVerseWidget/        WidgetKit extension
Shared/                  Verse fetcher + models
Config/Secrets.xcconfig  Optional YouVersion API key
```

## Troubleshooting

### The app or widget won't open (“The application cannot be opened”, blank widget)

Older builds of this project were signed with a free Personal Team. Those builds embed a provisioning profile that expires after 7 days, and macOS then kills the app at launch (`Launchd job spawn failed`) and fails to load the widget.
Pull the latest code and rebuild with `⌘R`. Current builds are signed to run locally, so they don't expire.

## How refresh works

`VerseProvider` fetches the verse when the timeline is requested, then schedules the next reload at **12:05 AM** local time so YouVersion has rolled over to the new day.

## License

MIT — see [LICENSE](LICENSE). Bible text is © respective publishers. Not affiliated with YouVersion.
