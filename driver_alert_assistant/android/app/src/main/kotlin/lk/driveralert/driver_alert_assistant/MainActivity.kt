package lk.driveralert.driver_alert_assistant

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import lk.driveralert.driver_alert_assistant.clicker.ClickerRuntime

class MainActivity : FlutterActivity() {

    private var statusSink: EventChannel.EventSink? = null
    private val statusListener: () -> Unit = { statusSink?.success(ClickerRuntime.statusMap()) }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        ClickerRuntime.init(this)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        MethodChannel(messenger, "smart_clicker/control").setMethodCallHandler { call, result ->
            when (call.method) {
                "getStatus" -> result.success(ClickerRuntime.statusMap())
                "command" -> {
                    val name = call.argument<String>("name")
                    if (name == null) {
                        result.error("bad_args", "Missing command name", null)
                    } else {
                        result.success(ClickerRuntime.command(name).name)
                    }
                }
                "showPanel" -> result.success(ClickerRuntime.showPanel())
                "hidePanel" -> result.success(ClickerRuntime.hidePanel())
                "updateSettings" -> {
                    ClickerRuntime.setVibrationOn(call.argument<Boolean>("vibrationOn") ?: true)
                    result.success(null)
                }
                "openAccessibilitySettings" ->
                    result.success(open(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)))
                "openAppInfo" -> result.success(
                    open(
                        Intent(
                            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                            Uri.fromParts("package", packageName, null),
                        ),
                    ),
                )
                else -> result.notImplemented()
            }
        }

        EventChannel(messenger, "smart_clicker/status").setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    statusSink = events
                    ClickerRuntime.addListener(statusListener)
                    events.success(ClickerRuntime.statusMap())
                }

                override fun onCancel(arguments: Any?) {
                    ClickerRuntime.removeListener(statusListener)
                    statusSink = null
                }
            },
        )
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        ClickerRuntime.removeListener(statusListener)
        statusSink = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    private fun open(intent: Intent): Boolean =
        try {
            startActivity(intent)
            true
        } catch (_: ActivityNotFoundException) {
            false
        }
}
