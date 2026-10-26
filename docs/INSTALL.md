# Smart Auto Clicker — Install and Setup Guide

This guide covers the app as it is now: Home and Settings screens, the
floating control panel, and Emergency Stop. Automatic clicking is **not**
part of this version — Start/Pause/Stop only change the panel's status.

Works on **Android 8.0 and newer** phones. Android only (no iPhone, no
Windows/Mac version).

---

## 1. Build the APK (on the computer)

From the `driver_alert_assistant` folder:

```bash
flutter build apk --debug
```

The file is created at:

```
driver_alert_assistant\build\app\outputs\flutter-apk\app-debug.apk
```

---

## 2. Install on a phone

### Option A — with a USB cable (recommended)

1. On the phone: **Settings → About phone → Software information** → tap
   **Build number** 7 times to turn on Developer options.
2. **Settings → Developer options** → turn on **USB debugging**.
3. Samsung only: if **Auto Blocker** is on (**Settings → Security and
   privacy → Auto Blocker**), turn it off while installing. It blocks USB
   installs.
4. Connect the cable and tap **Allow** on the phone's
   "Allow USB debugging?" message.
5. On the computer, check the phone is seen, then install:

```bash
adb devices
```

```bash
adb install -r build\app\outputs\flutter-apk\app-debug.apk
```

`adb` is in `%LOCALAPPDATA%\Android\sdk\platform-tools\`.
You can also run `flutter install` from the project folder.

### Option B — copy the file

1. Copy `app-debug.apk` to the phone (USB, Google Drive, etc.).
2. Open it in **My Files** and tap **Install**.
3. If asked, allow **Install unknown apps** for the app you opened it from.
4. If Samsung Auto Blocker stops it, turn Auto Blocker off, install, then
   turn it back on.

---

## 3. Turn on the accessibility service

The floating panel only appears once this is on. The app uses it **only**
to draw the panel; this version does not read other apps' screens or tap.

1. Open **Smart Auto Clicker** and tap **Open Accessibility settings**.
2. Choose **Installed apps** (or **Downloaded apps**) → **Smart Auto Clicker**.
3. Turn on the **main switch** ("Use Smart Auto Clicker").
   The separate "shortcut" switch is **not** needed.
4. Tap **Allow** on Android's message.
5. Back in the app, the status card should say **Accessibility: ON**.

### "The switch is greyed out" (Android 13 and newer)

Android blocks accessibility for apps installed from a file until you allow it:

1. Try to turn the switch on once (it will be blocked).
2. Open **Settings → Apps → Smart Auto Clicker** (or use **Open App info**
   in the app's help).
3. Tap **⋮** (top right) → **Allow restricted settings** and confirm.
4. Go back and turn on accessibility again.

Installing with `adb install` (Option A) usually skips this step.

---

## 4. Samsung battery settings

Samsung may stop background apps to save battery, which turns the panel off.

1. **Settings → Apps → Smart Auto Clicker → Battery** → choose
   **Unrestricted**.
2. **Settings → Battery → Background usage limits → Never sleeping apps**
   → add **Smart Auto Clicker**.
3. Make sure Smart Auto Clicker is **not** in "Sleeping apps" or
   "Deep sleeping apps".

On other brands, look for "Battery optimization" and set the app to
**Not optimized / Unrestricted**. See https://dontkillmyapp.com for your brand.

---

## 5. Using the panel

| Control | What it does |
|---|---|
| ⠿ handle | Drag to move the panel. Position is remembered separately for portrait and landscape. |
| – / + | Make the panel small (status + Emergency Stop) or full size. |
| ✕ | Hide the panel. Not allowed while running or paused — press Stop first. |
| Start / Pause / Resume / Stop | Change the status. **No clicking happens in this version.** |
| Add point / Region / Rules | Show "Coming in a later update". |
| EMERGENCY STOP | Stops everything. Stays on after closing the app. |

To turn Emergency Stop off: open the app → **Turn off Emergency Stop** →
confirm. The clicker stays **Stopped**; it never restarts by itself.

If accessibility is turned off while running, the clicker stops and the app
shows "Stopped because accessibility was turned off."

---

## 6. Troubleshooting

| Problem | Fix |
|---|---|
| `adb devices` shows nothing | Try another cable/USB port, re-tap **Allow** on the phone, or turn USB debugging off and on. |
| `adb devices` shows `unauthorized` | Unlock the phone and tap **Allow** on the USB debugging message. |
| Install blocked | Turn off Samsung **Auto Blocker**, or allow **Install unknown apps**. |
| `INSTALL_FAILED_UPDATE_INCOMPATIBLE` | Uninstall the old app first: `adb uninstall lk.driveralert.driver_alert_assistant` |
| Accessibility switch greyed out | Do **Allow restricted settings** (section 3). |
| App still says Accessibility: OFF | Make sure you turned on the **main** switch, not the shortcut. Close and reopen the app. |
| "Show floating panel" is grey | Accessibility is off — see section 3. |
| Panel disappears after a while | Samsung battery settings (section 4). Then re-check accessibility is still ON. |
| Accessibility turns itself off after an update | Normal on some phones after reinstalling — turn it on again. |
| "Can't reach the clicker service" | Close the app fully (swipe it away in Recents) and open it again. |
| No vibration | Check **Settings → Vibrate on start and stop** in the app, and that the phone isn't on silent with vibration off. |

---

## 7. Uninstall

Settings → Apps → Smart Auto Clicker → **Uninstall**, or:

```bash
adb uninstall lk.driveralert.driver_alert_assistant
```
