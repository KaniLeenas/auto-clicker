# Driver Alert Assistant — Phase 0: Research and Plan

Date: 2026-10-26
Status: **Waiting for approval. No app code has been written.**

---

## 1. What this app will do (simple words)

The app watches the PickMe Driver or Uber Driver screen while you drive.
When a new trip request appears, it reads the fare and distances it can see,
checks them against your rules (for example: fare at least LKR 1,000,
pickup no more than 5 km, trip at least 3 km), and alerts you with sound,
vibration and a short reason. **You always accept real trips yourself.**

---

## 2. What I checked on this computer (actual results)

| Item | What I found | What to do |
|---|---|---|
| Project folder | Empty. Not a git repository. On OneDrive Desktop, path has a space (`AUTO CLIKER`). | See decision D1 below. |
| Flutter | 3.35.1 stable (Aug 2025), Dart 3.9.0 | Upgrade to the current stable (3.47.x) with `flutter upgrade`. |
| Java | Only JDK 25.0.1 installed, set as `JAVA_HOME` | Install Android Studio (it includes a JDK 21). Point Flutter to it. JDK 25 needs Gradle 9.1+ and older templates fail on it. |
| Android Studio | **Not installed** | Install it (you asked for Android Studio). |
| Android SDK | Present. Platforms 31, 33, 34, 35, 36. Build-tools 36.0.0. | Good. |
| Android licenses | Some not accepted | Run `flutter doctor --android-licenses`. |
| adb | Installed in SDK, but not on `PATH` | Add `%LOCALAPPDATA%\Android\sdk\platform-tools` to `PATH`. |
| Phone connected | No Android device connected | Needed from Phase 1 testing onward. |

---

## 3. Current stable versions (checked online today)

| Tool | Current stable | Source |
|---|---|---|
| Flutter | **3.47** (3.47.8 security hotfix mentioned on docs site). 3.50 due Nov 2026. | docs.flutter.dev release notes / archive |
| Dart | Bundled with Flutter 3.47 (exact number confirmed after `flutter upgrade`) | — |
| Android Gradle Plugin | **9.4.0** (Sep 2026). Needs Gradle 9.6.0, JDK 17+, build-tools 36.0.0, max API 37 | developer.android.com AGP release notes |
| Kotlin | **2.4.0** (June 2026) | JetBrains blog |
| Gradle | 9.6.x | AGP requirement |
| Android API supported by Flutter | **API 24 – 37** | docs.flutter.dev supported platforms |

Plan: I will **not** hand-pick these numbers. I will use whatever versions
`flutter create` generates after upgrading, then report them. Note: Flutter
3.44+ is moving Android projects to AGP 9 "built-in Kotlin"
(`android.builtInKotlin`). Some plugins may not be migrated yet, so I will
keep the number of plugins small.

**Minimum Android version:** Keep **Android 8.0 (API 26)** as you asked.
Flutter supports API 24+, and ML Kit needs 21+, so 26 is safe. No reason
found to change it.

---

## 4. Official PickMe and Uber information

* **No public API for trip requests.** I found no official PickMe or Uber
  API that lets a third-party app see or accept driver trip requests.
  The app will only use what is visible on your own phone's screen.
* **Uber:** An Uber spokesperson has stated publicly that using
  third-party tools to get around the system breaks Uber's Community
  Guidelines and Terms of Service. Uber has sent legal letters to companies
  making trip-filtering / auto-accept apps (Mystro, GigU). Uber's
  guidelines say breaking them may cause loss of account access.
* **PickMe:** I could not find PickMe's public driver terms online.
  Please check the terms inside the PickMe Driver app or ask PickMe driver
  support.

**What this means for the app:**

1. **Live auto-accept (Mode 3) stays permanently OFF.** No supported or
   permitted method exists. The app will show it as "Not available".
2. Test-mode clicks happen **only** on sample screens inside our own app.
3. **Risk you should know:** even only *reading* the Uber/PickMe screen
   with a helper app could be seen by the platform as a "third-party tool".
   This app does not change their app, does not touch their servers,
   and does not tap their buttons — but the final decision about your
   account risk is yours. I recommend reading both apps' driver terms first.

---

## 5. How an app can read another app's screen

| Method | Can it read PickMe/Uber? | Notes |
|---|---|---|
| **Accessibility Service** (main choice) | **Probably — must test on the phone** | Reads text of on-screen views (`getRootInActiveWindow`). Can limit to only the PickMe and Uber package names so it ignores other apps. Kept alive by Android while enabled, so no extra background service needed. |
| Notification Listener | Maybe | If a driver app shows a notification for a trip request, we could read it. Must test. Optional backup. |
| Screen capture + ML Kit OCR (Phase 9 only) | Maybe | Needs your consent **every session** (Android 14+). Stops automatically when the screen locks (Android 15 QPR1+). Blank if the app sets `FLAG_SECURE`. Uses more battery. |
| Official API | **No** | None exists. |

**Things that can stop accessibility reading (must test on your phone):**

* Apps can mark views as `accessibilityDataSensitive` (Android 16+, and
  views with `filterTouchesWhenObscured`). Those views are hidden from
  helper apps that are not real accessibility tools. If PickMe/Uber do
  this on trip cards, we will not see the text.
* Map areas, custom-drawn views or games-style UIs often have no readable text.
* **We must not declare ourselves an "accessibility tool"** to get around
  this — that would be false and is against Google policy.
* **Android 13+ "Restricted settings":** because we install the APK
  ourselves (not from Play Store), Android blocks turning on accessibility
  until you open App info → ⋮ menu → **Allow restricted settings**.
  The option appears only after you first try to enable the service.
* **Android 17 Advanced Protection mode** (if you turn it on) blocks
  accessibility for apps that are not accessibility tools. Keep it off.

---

## 6. Floating toolbar over another app

Two official ways:

| Way | Permission | Choice |
|---|---|---|
| `TYPE_ACCESSIBILITY_OVERLAY` window, drawn by our Accessibility Service | None extra (comes with accessibility) | **Main choice** — works whenever monitoring works. |
| `TYPE_APPLICATION_OVERLAY` | "Display over other apps" (`SYSTEM_ALERT_WINDOW`), user grants in Settings | Backup, needed if we want the toolbar while accessibility is off. |

The toolbar will be built in **Kotlin (native Android views)**, not
Flutter, so it is small, fast, and works even if the main app screen is
closed. It will be draggable and remember its position (separately for
portrait and landscape).

---

## 7. Permissions needed

| Permission | Why (driver-friendly) | When asked | Phase |
|---|---|---|---|
| Accessibility service | "Lets the app read the trip request on the PickMe/Uber screen." | When you press Start Monitoring the first time | 4 |
| Notifications (`POST_NOTIFICATIONS`, Android 13+) | "Shows alerts and the 'monitoring is on' message." | First start | 5 |
| Vibrate | Vibration alerts | Automatic (no prompt) | 5 |
| Display over other apps (optional) | "Shows the small toolbar on top of PickMe/Uber." | Only if needed | 6 |
| Screen capture (MediaProjection) + foreground service type `mediaProjection` | "Lets the app read the screen picture when text cannot be read." Asked every time. | Only if Phase 9 is needed | 9 |
| Location – while using the app only (`ACCESS_FINE_LOCATION`) | "Shows where you are on the map." No background location. | When you open the map | 10 |
| Ignore battery optimisation (link to settings) | "Stops Samsung from putting the app to sleep." | Help screen | 6/12 |

Not needed: Internet for alerts (alerts work offline), contacts, storage,
camera, background location.

---

## 8. Samsung phone notes

* Samsung's battery features can kill helper apps. You will need to:
  Settings → Apps → Driver Alert Assistant → Battery → **Unrestricted**;
  Battery → Background usage limits → add to **Never sleeping apps**;
  turn off "Put unused apps to sleep". Samsung may reset these after
  firmware updates.
* **Auto Blocker** (One UI 6+) blocks installing APKs from outside the
  store and USB debugging commands. Turn it off while installing; turn it
  back on later if you like.
* Accessibility, overlays, notifications, MediaProjection and ML Kit are
  standard Android and **should** work on Samsung, but must be tested on
  your phone.

**Please tell me:** your Samsung model and Android / One UI version
(Settings → About phone → Software information).

---

## 9. Confirmed vs needs testing

**Confirmed possible (official docs):**

* Flutter app with Kotlin native parts, local storage, min Android 8.0.
* Accessibility service limited to chosen apps, reading view text.
* Floating toolbar via accessibility overlay or "display over other apps".
* Sound + vibration + notification alerts, fully offline.
* Simulated clicks on our own sample screen.
* On-device text recognition with ML Kit (no cloud).
* Map with location marker and radius circle using OpenStreetMap (no API key).

**Needs testing on your phone:**

* Whether PickMe Driver trip cards expose readable text (fare, distances).
* Whether Uber Driver trip cards expose readable text.
* Exact package names of both apps (I will check with
  `adb shell pm list packages`; Uber Driver is expected to be
  `com.ubercab.driver`, PickMe Driver is unknown).
* How fast alerts appear after the request shows.
* Whether screen capture is blocked (`FLAG_SECURE`).
* Samsung battery behaviour over a long shift.

**Not possible / not allowed:**

* Using a PickMe/Uber API for trips (none exists).
* Live auto-accept of real trips.
* Changing PickMe's or Uber's own passenger-matching radius.

---

## 10. Proposed architecture

Key idea: the **fast path** (read screen → check rules → alert → toolbar)
runs in **Kotlin** inside the Accessibility Service, so it works instantly
even when the Flutter screens are closed. **Flutter/Dart** is used for all
screens, settings, history, sample test screen and the map.

```
┌───────────────────────── Flutter (Dart) ─────────────────────────┐
│ Screens: Home · Profiles (PickMe/Uber) · Trip Rules · Alerts ·    │
│          History · Test Mode (sample screen) · Map · Help         │
│ Logic:   rules engine (Dart, for Test Mode + unit tests)          │
│ Storage: settings (JSON) + history (local SQLite)                 │
└───────────────▲──────────────────────────────┬───────────────────┘
                │ MethodChannel / EventChannel │ settings JSON
┌───────────────┴──────────── Kotlin (Android) ▼───────────────────┐
│ TripAccessibilityService  – only PickMe/Uber packages             │
│   ├─ ScreenReader      – collects text from changed views         │
│   ├─ RequestParser     – finds fare / pickup km / trip km         │
│   ├─ DuplicateGuard    – fingerprint + cooldown delay             │
│   ├─ RuleMatcher       – same rules as Dart (shared test cases)   │
│   ├─ AlertPlayer       – sound + vibration + notification         │
│   ├─ OverlayToolbar    – draggable, Start/Stop/Emergency Stop     │
│   └─ HistoryWriter     – writes to local database                 │
│ EmergencyStop          – one shared switch, checked first always  │
│ (Phase 9 only) ScreenCaptureService + ML Kit OCR                  │
└───────────────────────────────────────────────────────────────────┘
```

**Rules duplicated in Dart and Kotlin?** Yes, but kept tiny (3 number
checks + "missing value" check). One shared file of test cases
(`test_cases/rules.json`) is run by both Dart tests and Kotlin unit tests,
so both must give the same answer. This is simpler and faster than running
a hidden Flutter engine inside the service.

**Storage:** settings saved as JSON per profile (PickMe and Uber are
separate keys, so changing one never changes the other). History saved in
a local SQLite database on the phone, with a "Clear history" button. No
passenger names, phone numbers, addresses or screenshots are stored.

**Planned folders:**

```
driver_alert_assistant/
  lib/
    main.dart
    app/            (theme, navigation)
    models/         (profile, trip rules, trip request, history entry)
    services/       (storage, native bridge, rules engine)
    screens/        (home, profile, rules, alerts, history, test mode, map, help)
    widgets/
  android/app/src/main/kotlin/.../
    accessibility/  overlay/  alerts/  rules/  storage/  capture/ (Phase 9)
  test/             (Dart unit + widget tests)
  android/app/src/test/  (Kotlin unit tests)
  test_cases/rules.json  (shared rule test cases)
  docs/
```

**Planned packages (kept small; exact versions after `flutter create`):**

| Package | Why | Phase |
|---|---|---|
| `shared_preferences` | Save settings | 1 |
| `sqflite` | Save history | 8 |
| `flutter_map` + `latlong2` | Map with OpenStreetMap tiles, no API key, built-in metre-based circle | 10 |
| `geolocator` | Current location | 10 |
| `google_mlkit_text_recognition` | On-device OCR, only if Phase 9 is needed | 9 |

Sound, vibration, overlay, accessibility and screen capture are done in
Kotlin directly (no extra plugins), which avoids plugin compatibility issues
with AGP 9.

**Map radius formula (Phase 10):** the circle is set in **metres**, so
zooming never changes the real radius. On screen,
`metres per pixel = 156543.03392 × cos(latitude) / 2^zoom`
(standard Web Mercator formula). `flutter_map` draws circles in metres
directly, so slider and circle stay in sync.

---

## 11. Decisions I need from you

* **D1 – Project location.** OneDrive can lock files during Gradle builds
  and slow them down. Options: (a) create the project in
  `C:\dev\driver_alert_assistant` (recommended), or (b) inside this
  OneDrive folder as `AUTO CLIKER\driver_alert_assistant`.
* **D2 – Tool setup.** OK for me to run `flutter upgrade`? You install
  Android Studio yourself (it's an installer), then I set Flutter to use
  its JDK.
* **D3 – Git.** OK to run `git init` in the project folder so every phase
  can be saved and undone?
* **D4 – Account risk.** Confirm you have read section 4 and still want to
  build the screen-reading monitor for your own use.
* **D5 – Phone details.** Samsung model and Android/One UI version.

---

## Sources

* Flutter release notes / archive: https://docs.flutter.dev/release/release-notes , https://docs.flutter.dev/release/archive
* Flutter supported platforms: https://docs.flutter.dev/reference/supported-platforms
* Flutter built-in Kotlin migration: https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin
* AGP release notes: https://developer.android.com/build/releases/gradle-plugin
* Gradle Java compatibility: https://docs.gradle.org/current/userguide/compatibility.html
* Kotlin 2.4.0: https://blog.jetbrains.com/kotlin/2026/03/kotlin-2-3-20-released/ (2.3.20) and coverage of 2.4.0 release
* Accessibility service: https://developer.android.com/guide/topics/ui/accessibility/service
* accessibilityDataSensitive: https://developer.android.com/blog/posts/enhancing-android-security-stop-malware-from-snooping-on-your-app-data
* Restricted settings (Android 13+): https://bayton.org/android/android-13-restricted-permissions/
* Android 17 Advanced Protection: https://thehackernews.com/2026/10/android-17-advanced-protection-locks.html
* MediaProjection: https://developer.android.com/media/grow/media-projection
* Foreground service types: https://developer.android.com/develop/background-work/services/fgs/service-types
* Samsung background limits: https://dontkillmyapp.com/samsung
* ML Kit text recognition: https://developers.google.com/ml-kit/vision/text-recognition/android
* Uber community guidelines (LK): https://www.uber.com/lk/en/communityguidelines
* Uber fraud activities: https://www.uber.com/gb/en/drive/driver-app/fraud-activities
* Third-party driver apps (Uber statements): https://thehustle.co/news/the-third-party-apps-uber-and-lyft-are-trying-to-kill
