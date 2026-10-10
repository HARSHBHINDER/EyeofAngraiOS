# EyeofAngra — iOS

**Emergency evidence capture for iPhone — private by design.** EyeofAngra records
video, audio, and photos the instant your safety, liberty, or wellbeing is at
risk, and keeps every file on the device itself. No account, no cloud, no
analytics, and nothing leaves your phone unless you send it.

Built for the moment, not the demo: one-tap capture, a stealth mode that blacks
the screen out while it films, audio that survives a locked screen, and home- and
lock-screen widgets that open straight into a running recording.

Android version: [EyeofAngra](https://github.com/HARSHBHINDER/EyeofAngra).

## Install

Every release is listed below with its changes and both ways to install. The
table regenerates automatically on each push from
[`versions.json`](versions.json).

<!-- VERSIONS:TABLE:START -->
<table>
<thead><tr><th>#</th><th>Version</th><th>Changes &amp; features</th><th>Install</th></tr></thead>
<tbody>
<tr><td align="center">1</td><td align="center"><strong>v1.5</strong><br><sub>2026-10-10</sub></td><td><ul><li>Swipe to select: in select mode, slide sideways across tiles and every one you pass is selected; vertical movement still scrolls.</li><li>Pinch the Vault to resize it, from 1 to 7 tiles per row; your choice is remembered.</li><li>Photos-style grid: square, edge-to-edge tiles with thin gaps, length bottom-right, capture time on larger tiles, sharper thumbnails when zoomed in.</li></ul></td><td align="center"><a href="https://github.com/HARSHBHINDER/EyeofAngraiOS/releases/latest/download/EyeofAngra.ipa"><img src="https://img.shields.io/badge/IPA%20download-2EA44F?style=flat-square&logo=apple&logoColor=white" alt="Download EyeofAngra.ipa"></a><br><a href="https://raw.githubusercontent.com/HARSHBHINDER/EyeofAngraiOS/main/altstore.json"><img src="https://img.shields.io/badge/AltStore%20source-0B84FF?style=flat-square&logo=altstore&logoColor=white" alt="AltStore source feed"></a></td></tr>
<tr><td align="center">2</td><td align="center"><strong>v1.4</strong><br><sub>2026-10-10</sub></td><td><ul><li>Auto-rotation removed: the app stays in portrait.</li><li>Recordings and photos are portrait too, however the phone is held: the screen, the record button and the captures never change orientation.</li></ul></td><td align="center"><a href="https://raw.githubusercontent.com/HARSHBHINDER/EyeofAngraiOS/main/altstore.json"><img src="https://img.shields.io/badge/AltStore%20source-0B84FF?style=flat-square&logo=altstore&logoColor=white" alt="AltStore source feed"></a></td></tr>
<tr><td align="center">3</td><td align="center"><strong>v1.3</strong><br><sub>2026-10-10</sub></td><td><ul><li>Select mode in the Vault: tap Select, tick any mix of videos, photos and audio, or use All.</li><li>Batch actions: Save to Photos, Move to Photos, Export through the share sheet (Save to Files, AirDrop, any app, audio included) and Delete.</li><li>Move to Photos hands each file to Photos instead of copying it, so multi-GB videos move with no duplicate and no load on the phone.</li></ul></td><td align="center"><a href="https://raw.githubusercontent.com/HARSHBHINDER/EyeofAngraiOS/main/altstore.json"><img src="https://img.shields.io/badge/AltStore%20source-0B84FF?style=flat-square&logo=altstore&logoColor=white" alt="AltStore source feed"></a></td></tr>
<tr><td align="center">4</td><td align="center"><strong>v1.2</strong><br><sub>2026-10-10</sub></td><td><ul><li>Records the way the iPhone Camera app does: HEVC video in .mov and HEIC photos, falling back to H.264 / JPEG on older hardware.</li><li>Save to Photos: hold any video or photo in the Vault and it goes straight into the Photos library, playable there like a Camera recording.</li><li>Vault tiles show a real frame from each video, its length, and when it was recorded; audio tiles show their length.</li></ul></td><td align="center"><a href="https://raw.githubusercontent.com/HARSHBHINDER/EyeofAngraiOS/main/altstore.json"><img src="https://img.shields.io/badge/AltStore%20source-0B84FF?style=flat-square&logo=altstore&logoColor=white" alt="AltStore source feed"></a></td></tr>
<tr><td align="center">5</td><td align="center"><strong>v1.1</strong><br><sub>2026-10-09</sub></td><td><ul><li>Home-screen and lock-screen widgets: tap to deeplink straight into Video or Audio and arm capture automatically.</li><li>Fixed: changing video quality in Settings now applies immediately, not only after switching tabs.</li><li>Premium interface pass: gold hairline cards, translucent chrome, spring-driven capture control with haptics, serif timers.</li><li>New app icon.</li></ul></td><td align="center"><a href="https://raw.githubusercontent.com/HARSHBHINDER/EyeofAngraiOS/main/altstore.json"><img src="https://img.shields.io/badge/AltStore%20source-0B84FF?style=flat-square&logo=altstore&logoColor=white" alt="AltStore source feed"></a></td></tr>
<tr><td align="center">6</td><td align="center"><strong>v1.0</strong><br><sub>2026-08-17</sub></td><td><ul><li>Five destinations: Video, Audio, Photo, Vault, and Settings.</li><li>Stealth capture: video and photo black the screen out and drop the backlight to zero while recording, so the phone reads as idle. Tap anywhere to stop.</li><li>One shared capture session across Video and Photo, because iOS grants the camera to a single session at a time.</li><li>Audio-only capture keeps running with the screen locked, via the audio background mode.</li><li>Capture quality: 4K, 1080p, or 720p, applied live with an automatic fallback on devices that cannot reach the chosen preset.</li><li>Home-screen widget (Video and Audio) and a lock-screen Video widget, opening straight into the tab and arming capture.</li><li>Premium interface: serif gold wordmark, translucent chrome with gold hairlines, spring-driven capture control with haptics, and a gold-washed timer.</li><li>Everything is written to the device only. No account, no cloud, no analytics.</li></ul></td><td align="center"><a href="https://raw.githubusercontent.com/HARSHBHINDER/EyeofAngraiOS/main/altstore.json"><img src="https://img.shields.io/badge/AltStore%20source-0B84FF?style=flat-square&logo=altstore&logoColor=white" alt="AltStore source feed"></a></td></tr>
</tbody>
</table>
<!-- VERSIONS:TABLE:END -->

> **AltStore** is the easier route — it signs with your own free Apple ID and
> renews automatically. The **IPA** is deliberately unsigned, so any signing
> method (AltStore, Sideloadly, 3uTools, or your own certificate) works.

## Install with AltStore

Add the source once; after that the app installs and updates from AltStore's
Browse tab like any other app.

1. Install [AltStore](https://altstore.io) on your iPhone, and AltServer on a
   Windows or Mac computer.
2. In AltStore: **Browse → Sources → +**, and paste:
   ```
   https://raw.githubusercontent.com/HARSHBHINDER/EyeofAngraiOS/main/altstore.json
   ```
3. Open the EyeofAngra source, tap **Install** ("Free" on first install).

AltStore signs the app with **your own free Apple ID** — no developer account,
no payment. Apple's free signature lasts **7 days**; AltStore renews it
automatically over Wi-Fi whenever your phone and AltServer are on the same
network. Keep the computer awake and reachable roughly weekly.

Free Apple IDs are limited by Apple to 3 sideloaded apps at a time.

## Install with SideStore (no computer left running)

SideStore refreshes the signature from the phone itself, so unlike AltStore it
does not need a computer awake on the same Wi-Fi every week.

1. On Windows, install Apple's **Apple Devices** app (or iTunes) — it provides
   the `usbmuxd` service that every sideloader talks to.
2. Install [iLoader](https://github.com/nab138/iloader)
   (`winget install --id nabdev.iloader -e`), plug the iPhone in, unlock it,
   and tap **Trust**.
3. Sign in with your Apple ID and let iLoader install SideStore and place the
   pairing file. Approve the VPN profile SideStore asks for — it is a local
   loopback to the phone's own services, not a network connection — then trust
   the developer profile under **Settings → General → VPN & Device Management**.
4. In SideStore: **Sources → +**, paste the same source URL as above, open the
   EyeofAngra source, and tap **Install**.

## Install by signing it yourself

Download `EyeofAngra.ipa` from the
[latest release](../../releases/latest) and sign it with 3uTools, Sideloadly,
or your own certificate. The `.ipa` is deliberately unsigned so any signing
method works.

## Features

- **Video** — one-button evidence video with sound, saved as `VID_…​.mp4`,
  with an always-visible red recording indicator.
- **Audio** — audio-only capture as `AUD_…​.m4a`. Continues in the background
  via the audio background mode.
- **Photos** — dark tap-anywhere screen for evidence stills, saved as
  `IMG_…​.jpg`.
- **Safety & Legal** — what is recorded, local-only storage, your legal
  responsibility.

Recordings appear in the Files app under *On My iPhone → EyeofAngra*, so you
can export them without any cloud service.

## Building

`project.yml` is an [XcodeGen](https://github.com/yonaskolb/XcodeGen) spec, so
no `.xcodeproj` is checked in.

**On a Mac:** `brew install xcodegen && xcodegen generate`, then open
`EyeofAngra.xcodeproj`. Set your signing team before running on a device.

**Without a Mac:** every push to `main` builds on a free GitHub-hosted macOS
runner ([`build-ipa.yml`](.github/workflows/build-ipa.yml)), publishes the
`.ipa` to Releases, and regenerates `altstore.json` so AltStore sees the new
version. No Apple account is involved in the build.

## Transparency

This app is deliberately **not** a hidden camera. A red on-screen indicator
shows whenever recording is active, iOS shows its own camera and microphone
indicators, and recording only ever starts from an explicit tap.

## Legal

Laws on recording conversations and filming people vary by country and state.
You are solely responsible for using this app lawfully. It cannot guarantee
your safety, the recovery of an interrupted file, or that a recording will be
accepted as evidence. Provided as-is — see [LICENSE](LICENSE).
