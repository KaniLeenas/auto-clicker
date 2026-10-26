# Smart Auto Clicker — Phase 0: Research and Plan

Date: 2026-10-27
Status: **Waiting for approval. No code written for this project yet.**

---

## 0. Scope boundary (please read first)

This is a **general-purpose** auto clicker: the user chooses the app, the
screen points or regions, the conditions and the actions.

What I will build and test:

* The full auto clicker engine, floating panel, rules, OCR, image matching,
  profiles, history and Emergency Stop.
* Testing on our own **sample app** (Phase 9) and on ordinary apps.

What I will **not** do, because of the earlier conversation:

* Build, tune, test or document it for **auto-accepting real trips in
  PickMe, Uber or any other ride-hailing / delivery driver app**. No
  ride-app presets, no ride-app compatibility testing in Phase 11, and no
  help configuring it for that. The reasons (other drivers, passengers,
  account bans) are the same as before, and making the tool general does
  not change them.
* Anything that hides automation from an app, bypasses security checks or
  anti-bot controls, or works around `FLAG_SECURE` / sensitive-view
  protections.

If you approve, this boundary stays for all phases.

---

## 1. What Android allows (summary)

| Capability | How | Android version | Status |
|---|---|---|---|
| Read text on screen of another app | AccessibilityService, `canRetrieveWindowContent`, `getRootInActiveWindow()` / `getWindows()` | All supported | Official. Some apps hide views (`accessibilityDataSensitive`, Android 16+). Custom-drawn UIs (games, maps, Flutter/Compose without semantics) may expose little text. |
| Click a button by its node | `AccessibilityNodeInfo.performAction(ACTION_CLICK)` | All | Official. Most reliable: no coordinates, survives rotation and layout changes. Only works when the node is clickable and visible. |
| Tap / swipe at screen coordinates | `dispatchGesture()` with `GestureDescription` (`canPerformGestures="true"`) | API 24+ (continued strokes API 26+) | Official. Limits on strokes and duration per gesture (exact numbers verified in Phase 5). |
| Back / Home / Recents | `performGlobalAction()` | All | Official. |
| Screenshot without MediaProjection | `AccessibilityService.takeScreenshot()` with `canTakeScreenshot="true"` | **API 30+ (Android 11)** | Official. Rate-limited (about 3 per second, verified in Phase 6). Fails on secure windows. |
| Screenshot on Android 7–10 | MediaProjection (screen capture consent) + foreground service type `mediaProjection` | API 21+ | Official. Asks the user every session on Android 14+. Stops when screen locks (Android 15 QPR1+). |
| Floating panel | `TYPE_ACCESSIBILITY_OVERLAY` from the accessibility service (no extra permission), or `TYPE_APPLICATION_OVERLAY` + "Display over other apps" | 22+ / 26+ (`TYPE_PHONE` on 24–25) | Official. |
| On-device OCR | Google ML Kit Text Recognition v2 | API 21+ | Official, offline, no cloud. |
| Image matching | Own Kotlin template matching on a small greyscale region (no OpenCV) | All | Plain code, no extra library. Good enough for a fixed-looking button; limited for big scale changes. |

**Limits that cannot be bypassed (and the app will not try):**

* Apps marked `FLAG_SECURE` → screenshots are black; OCR/image rules cannot run there.
* Views marked `accessibilityDataSensitive` / `filterTouchesWhenObscured` → hidden from non-accessibility-tool services; we will **not** falsely declare `isAccessibilityTool`.
* Android 13+ **Restricted settings**: sideloaded APK must be allowed in App info → ⋮ → *Allow restricted settings* before accessibility can be enabled.
* Android 17 **Advanced Protection** blocks non-tool accessibility services completely.
* Samsung battery features can kill the service: needs *Unrestricted* battery + *Never sleeping apps*.

---

## 2. Permissions (asked only when needed)

| Permission | Why (simple words) | When |
|---|---|---|
| Accessibility service | "Lets the app see buttons and text, and tap for you." | First time you press Start |
| Display over other apps (optional) | "Shows the control panel when accessibility is off." | Only if used |
| Notifications (Android 13+) | "Shows that the auto clicker is running and lets you stop it." | First Start |
| Screen capture (Android 7–10 only, or if accessibility screenshot fails) | "Lets the app look at the screen for picture/text rules." | Only for image/OCR rules |
| Foreground service (`specialUse`, `mediaProjection`) | Keeps capture running visibly | Only while capturing |

No internet, location, contacts, storage or camera permissions.

---

## 3. Android versions

Supported: **Android 7.0 (API 24) to Android 17**. API 24 is the lowest
version current Flutter (3.47) supports. Feature fallbacks:

* Android 7.0–7.1: overlay uses `TYPE_PHONE`; no continued strokes.
* Android 7–10: picture/OCR rules need MediaProjection consent.
* Android 11+: picture/OCR rules use accessibility screenshots (no extra prompt).

---

## 4. Recommended architecture (simplest maintainable)

```
┌──────────────── Flutter / Dart (UI isolate) ────────────────┐
│ Screens: Home · Profiles · Profile editor · Rules · History  │
│          Permissions help · Sample test screens              │
│ Storage: profiles + settings (JSON), history (SQLite)        │
└───────────────▲─────────────────────────────┬────────────────┘
                │ MethodChannel / EventChannel│
┌───────────────┴─────── Kotlin (Android) ────▼────────────────┐
│ ClickerAccessibilityService                                  │
│  ├─ Observer      – screen-change events → small Snapshot    │
│  │                  (texts, node bounds, optional region img)│
│  ├─ RuleBridge ───► background Dart engine (headless         │
│  │                  FlutterEngine) runs the RULE ENGINE      │
│  ├─ ActionExecutor – node click / gesture / global action    │
│  │                  re-checks target still valid before act  │
│  ├─ Scheduler     – delays, intervals, repeat limits         │
│  ├─ KillSwitch    – Emergency Stop, pure Kotlin, no Dart     │
│  ├─ OverlayPanel  – movable floating toolbar (native views)  │
│  └─ Capture       – accessibility screenshot / MediaProjection│
│                     + ML Kit OCR + template matching          │
└──────────────────────────────────────────────────────────────┘
```

Key decisions:

1. **Rule engine in Dart, one copy only.** The accessibility service starts
   a small background Flutter engine that runs the same Dart rule code
   the UI and tests use. No duplicate logic in Kotlin.
2. **Detection and action are separate.** Dart only *decides*
   (`Decision: click node X / tap point P / skip(reason) / ask user`).
   Kotlin *does*, after re-checking the target still exists and the
   screen has not changed since the decision.
3. **Emergency Stop lives in Kotlin**, works even if Dart is busy or
   crashed: cancels all scheduled actions, drops pending gestures,
   releases capture, logs the stop, and requires a manual restart.
4. **Prefer node clicks over coordinates.** Coordinates are stored as
   *fractions of the screen* plus orientation; on rotation or size change
   the profile is flagged "needs recalibration" instead of tapping a
   wrong place.
5. **Unknown = do nothing.** If text/image can't be read reliably, the
   engine returns `skip(reason)` or `askUser`, never a click.
6. **No app-specific code in the engine.** Target app is just a package
   name in a profile.

**Packages (exact versions chosen when added):** `shared_preferences`,
`sqflite`, `google_mlkit_text_recognition` (Phase 6 only). Overlay,
gestures, capture and template matching are written directly in Kotlin
(fewer plugins = fewer AGP 9 compatibility problems).

**Sample test app:** built into the same APK as a "Practice screens"
section (buttons that move, delayed text, rotating layout, duplicate
pop-ups), so no second APK is needed.

---

## 5. Confirmed vs needs testing

**Confirmed from official docs:** accessibility text reading, node clicks,
gestures (API 24+), overlay windows, MediaProjection rules, foreground
service types, ML Kit on-device OCR, restricted-settings behaviour.

**Needs testing on your Samsung:** gesture reliability and speed, overlay
behaviour with One UI, battery killing, screenshot rate limits, OCR speed.

**Verify in the phase that uses them:** exact gesture stroke/duration
limits, exact screenshot rate limit and error codes, `TYPE_PHONE`
behaviour on Android 7.

---

## 6. Decisions needed

* **D1 – Project:** create a new Flutter project `smart_auto_clicker`
  in `AUTO CLIKER\` (recommended), and leave `driver_alert_assistant`
  untouched?
* **D2 – Scope boundary:** do you accept section 0?
* **D3 – Phone:** Samsung model and Android / One UI version.

---

## Sources

* Accessibility service guide: https://developer.android.com/guide/topics/ui/accessibility/service
* accessibilityDataSensitive: https://developer.android.com/blog/posts/enhancing-android-security-stop-malware-from-snooping-on-your-app-data
* MediaProjection: https://developer.android.com/media/grow/media-projection
* Foreground service types: https://developer.android.com/develop/background-work/services/fgs/service-types
* Flutter supported platforms: https://docs.flutter.dev/reference/supported-platforms
* ML Kit text recognition: https://developers.google.com/ml-kit/vision/text-recognition/android
* Restricted settings: https://bayton.org/android/android-13-restricted-permissions/
* Android 17 Advanced Protection: https://thehackernews.com/2026/10/android-17-advanced-protection-locks.html
* Samsung background limits: https://dontkillmyapp.com/samsung
