package lk.driveralert.driver_alert_assistant.clicker

import android.content.Context
import android.content.SharedPreferences
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import java.util.concurrent.CopyOnWriteArraySet

/**
 * Shared clicker state for the app screens and the accessibility service
 * (both run in the same app process). All calls happen on the main thread.
 */
object ClickerRuntime {

    private const val PREFS = "clicker_runtime"
    private const val KEY_EMERGENCY = "emergency_stop_active"
    private const val KEY_VIBRATION = "vibration_on"

    private var appContext: Context? = null
    private var prefs: SharedPreferences? = null
    private var machine = ClickerStateMachine()
    private val listeners = CopyOnWriteArraySet<() -> Unit>()

    /** Set while the accessibility service is connected. */
    var service: ClickerAccessibilityService? = null
        private set

    /** Last important message for the user, e.g. why the clicker stopped. */
    var message: String? = null
        private set

    val state: RunState get() = machine.state

    fun init(context: Context) {
        if (prefs != null) return
        appContext = context.applicationContext
        val p = context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        prefs = p
        machine = ClickerStateMachine(emergencyActive = p.getBoolean(KEY_EMERGENCY, false))
    }

    fun addListener(listener: () -> Unit) {
        listeners.add(listener)
    }

    fun removeListener(listener: () -> Unit) {
        listeners.remove(listener)
    }

    fun command(name: String): CommandResult {
        val wasActive = machine.isActive
        val ready = service != null
        val result = when (name) {
            "start" -> machine.start(ready)
            "pause" -> machine.pause()
            "resume" -> machine.resume(ready)
            "stop" -> machine.stop()
            "emergencyStop" -> machine.emergencyStop()
            "clearEmergency" -> machine.clearEmergency()
            else -> CommandResult.UNKNOWN_COMMAND
        }
        if (result == CommandResult.OK) {
            message = when (name) {
                "emergencyStop" -> "Emergency Stop pressed. Everything is stopped."
                "clearEmergency" -> null
                else -> message
            }
            if (name == "start") message = null
            if (name == "start" || (wasActive && !machine.isActive)) vibrate()
            saveEmergency()
        }
        notifyChanged()
        return result
    }

    fun onServiceConnected(connected: ClickerAccessibilityService) {
        service = connected
        notifyChanged()
    }

    fun onServiceDisconnected(disconnected: ClickerAccessibilityService) {
        if (service !== disconnected) return
        service = null
        if (machine.serviceLost()) {
            message = "Stopped because accessibility was turned off."
            vibrate()
        }
        notifyChanged()
    }

    fun showPanel(): Boolean {
        val s = service ?: return false
        s.showPanel()
        notifyChanged()
        return true
    }

    /** Refuses to hide the panel while the clicker is running or paused. */
    fun hidePanel(): Boolean {
        if (machine.isActive) return false
        service?.hidePanel()
        notifyChanged()
        return true
    }

    fun setVibrationOn(on: Boolean) {
        prefs?.edit()?.putBoolean(KEY_VIBRATION, on)?.apply()
    }

    fun statusMap(): Map<String, Any?> = mapOf(
        "state" to when (machine.state) {
            RunState.STOPPED -> "stopped"
            RunState.RUNNING -> "running"
            RunState.PAUSED -> "paused"
            RunState.EMERGENCY_STOPPED -> "emergencyStopped"
        },
        "serviceEnabled" to (service != null),
        "panelVisible" to (service?.isPanelVisible == true),
        "message" to message,
    )

    fun notifyChanged() {
        service?.refreshPanel()
        listeners.forEach { it() }
    }

    private fun saveEmergency() {
        // commit() so the Emergency Stop survives even if the app is killed now.
        prefs?.edit()?.putBoolean(KEY_EMERGENCY, machine.isEmergency)?.commit()
    }

    private fun vibrate() {
        val context = appContext ?: return
        if (prefs?.getBoolean(KEY_VIBRATION, true) == false) return
        try {
            val vibrator: Vibrator? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                context.getSystemService(VibratorManager::class.java)?.defaultVibrator
            } else {
                @Suppress("DEPRECATION")
                context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
            }
            if (vibrator?.hasVibrator() != true) return
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator.vibrate(VibrationEffect.createOneShot(80, VibrationEffect.DEFAULT_AMPLITUDE))
            } else {
                @Suppress("DEPRECATION")
                vibrator.vibrate(80)
            }
        } catch (_: RuntimeException) {
            // Vibration is a nice-to-have; never let it break a stop.
        }
    }
}
