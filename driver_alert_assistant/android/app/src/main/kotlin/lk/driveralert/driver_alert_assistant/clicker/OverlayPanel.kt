package lk.driveralert.driver_alert_assistant.clicker

import android.annotation.SuppressLint
import android.content.Context
import android.content.res.Configuration
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Point
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.util.TypedValue
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import kotlin.math.abs

/**
 * The movable floating control panel, drawn above other apps.
 *
 * It uses an accessibility overlay window, so no extra "Display over other
 * apps" permission is needed. Touches outside the panel go to the app
 * underneath. The Emergency Stop button is visible even when collapsed.
 */
class OverlayPanel(private val service: ClickerAccessibilityService) {

    private val wm = service.getSystemService(WindowManager::class.java)
    private val prefs = service.getSharedPreferences("clicker_panel", Context.MODE_PRIVATE)
    private var collapsed = prefs.getBoolean("collapsed", false)
    private var attached = false

    private val params = WindowManager.LayoutParams(
        WindowManager.LayoutParams.WRAP_CONTENT,
        WindowManager.LayoutParams.WRAP_CONTENT,
        WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
        WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
            WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
        PixelFormat.TRANSLUCENT,
    ).apply { gravity = Gravity.TOP or Gravity.START }

    private val root = LinearLayout(service).apply {
        orientation = LinearLayout.VERTICAL
        setPadding(dp(8), dp(6), dp(8), dp(8))
        minimumWidth = dp(260)
        // Fully solid so the screen behind never shows through the buttons.
        background = GradientDrawable().apply {
            cornerRadius = dp(16).toFloat()
            setColor(Color.rgb(32, 33, 36))
        }
    }

    private val status = TextView(service).apply {
        setTextColor(Color.WHITE)
        setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
        setPadding(dp(6), 0, dp(6), 0)
    }
    private val body = LinearLayout(service).apply { orientation = LinearLayout.VERTICAL }

    private val startButton = button("Start") { run("start") }
    private val pauseButton = button("Pause") { run("pause") }
    private val resumeButton = button("Resume") { run("resume") }
    private val stopButton = button("Stop") { run("stop") }
    private val collapseButton = button("–") { toggleCollapsed() }
    private val hideButton = button("✕") {
        if (!ClickerRuntime.hidePanel()) toast("Stop the auto clicker first.")
    }
    private val emergencyButton = button("EMERGENCY STOP", Color.rgb(198, 40, 40)) {
        run("emergencyStop")
    }

    fun show() {
        buildLayout()
        render()
        wm.addView(root, params)
        attached = true
        root.post { restorePosition() }
    }

    fun remove() {
        if (!attached) return
        attached = false
        try {
            wm.removeView(root)
        } catch (_: IllegalArgumentException) {
            // Already removed by the system.
        }
    }

    /** Called after rotation or a screen-size change. */
    fun onScreenChanged() {
        if (attached) root.post { restorePosition() }
    }

    fun render() {
        val state = ClickerRuntime.state
        status.text = when (state) {
            RunState.STOPPED -> "● Stopped"
            RunState.RUNNING -> "● Running"
            RunState.PAUSED -> "● Paused"
            RunState.EMERGENCY_STOPPED -> "● EMERGENCY STOP"
        }
        status.setTextColor(
            when (state) {
                RunState.RUNNING -> Color.rgb(129, 199, 132)
                RunState.PAUSED -> Color.rgb(255, 213, 79)
                RunState.EMERGENCY_STOPPED -> Color.rgb(239, 154, 154)
                RunState.STOPPED -> Color.WHITE
            },
        )
        startButton.isEnabled = state == RunState.STOPPED
        pauseButton.visibility = if (state == RunState.PAUSED) View.GONE else View.VISIBLE
        pauseButton.isEnabled = state == RunState.RUNNING
        resumeButton.visibility = if (state == RunState.PAUSED) View.VISIBLE else View.GONE
        stopButton.isEnabled = state == RunState.RUNNING || state == RunState.PAUSED
        body.visibility = if (collapsed) View.GONE else View.VISIBLE
        collapseButton.text = if (collapsed) "+" else "–"
        collapseButton.contentDescription = if (collapsed) "Show all buttons" else "Make panel small"
        if (attached) root.post { restorePosition() }
    }

    @SuppressLint("ClickableViewAccessibility")
    private fun buildLayout() {
        val handle = TextView(service).apply {
            text = "⠿"
            contentDescription = "Drag to move the panel"
            setTextColor(Color.WHITE)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 22f)
            setPadding(dp(4), 0, dp(4), 0)
            setOnTouchListener(DragListener())
        }
        val header = row().apply {
            gravity = Gravity.CENTER_VERTICAL
            addView(handle)
            addView(status, LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f))
            addView(collapseButton)
            addView(hideButton)
        }
        val controls = row().apply {
            addView(startButton, weighted())
            addView(pauseButton, weighted())
            addView(resumeButton, weighted())
            addView(stopButton, weighted())
        }
        val setup = row().apply {
            addView(button("Add point") { comingLater() }, weighted())
            addView(button("Region") { comingLater() }, weighted())
            addView(button("Rules") { comingLater() }, weighted())
        }
        body.addView(controls)
        body.addView(setup)
        root.addView(header)
        root.addView(body)
        // Full panel width with the same side gap as the other buttons, so it
        // never runs into the panel's rounded corners.
        root.addView(
            emergencyButton,
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            ).apply { setMargins(dp(4), dp(4), dp(4), 0) },
        )
    }

    private fun run(command: String) {
        when (ClickerRuntime.command(command)) {
            CommandResult.BLOCKED_EMERGENCY -> toast("Emergency Stop is ON. Turn it off in the app first.")
            CommandResult.BLOCKED_NO_SERVICE -> toast("Accessibility is off.")
            CommandResult.NOT_ALLOWED_NOW -> toast("Not possible right now.")
            else -> Unit
        }
    }

    private fun toggleCollapsed() {
        collapsed = !collapsed
        prefs.edit().putBoolean("collapsed", collapsed).apply()
        render()
    }

    private fun comingLater() = toast("Coming in a later update.")

    private fun toast(text: String) = Toast.makeText(service, text, Toast.LENGTH_SHORT).show()

    private fun orientationKey(): String =
        if (service.resources.configuration.orientation == Configuration.ORIENTATION_LANDSCAPE) {
            "landscape"
        } else {
            "portrait"
        }

    private fun screenSize(): Point =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val bounds = wm.currentWindowMetrics.bounds
            Point(bounds.width(), bounds.height())
        } else {
            Point().also {
                @Suppress("DEPRECATION")
                wm.defaultDisplay.getRealSize(it)
            }
        }

    private fun restorePosition() {
        if (!attached) return
        val screen = screenSize()
        val key = orientationKey()
        params.x = PanelPosition.fromFraction(prefs.getFloat("x_$key", 1f), root.width, screen.x)
        params.y = PanelPosition.fromFraction(prefs.getFloat("y_$key", 0.3f), root.height, screen.y)
        wm.updateViewLayout(root, params)
    }

    private fun savePosition() {
        val screen = screenSize()
        val key = orientationKey()
        prefs.edit()
            .putFloat("x_$key", PanelPosition.toFraction(params.x, root.width, screen.x))
            .putFloat("y_$key", PanelPosition.toFraction(params.y, root.height, screen.y))
            .apply()
    }

    private inner class DragListener : View.OnTouchListener {
        private var startX = 0
        private var startY = 0
        private var touchX = 0f
        private var touchY = 0f
        private var moved = false

        override fun onTouch(v: View, event: MotionEvent): Boolean {
            when (event.actionMasked) {
                MotionEvent.ACTION_DOWN -> {
                    startX = params.x
                    startY = params.y
                    touchX = event.rawX
                    touchY = event.rawY
                    moved = false
                }
                MotionEvent.ACTION_MOVE -> {
                    val dx = event.rawX - touchX
                    val dy = event.rawY - touchY
                    if (abs(dx) > dp(4) || abs(dy) > dp(4)) moved = true
                    val screen = screenSize()
                    params.x = PanelPosition.clamp(startX + dx.toInt(), root.width, screen.x)
                    params.y = PanelPosition.clamp(startY + dy.toInt(), root.height, screen.y)
                    wm.updateViewLayout(root, params)
                }
                MotionEvent.ACTION_UP -> if (moved) savePosition() else v.performClick()
            }
            return true
        }
    }

    private fun row() = LinearLayout(service).apply { orientation = LinearLayout.HORIZONTAL }

    private fun weighted() =
        LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)

    private fun button(text: String, color: Int? = null, onClick: () -> Unit) =
        Button(service).apply {
            this.text = text
            isAllCaps = false
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
            minHeight = dp(44)
            minimumHeight = dp(44)
            minWidth = dp(44)
            minimumWidth = dp(44)
            if (color != null) {
                background = GradientDrawable().apply {
                    cornerRadius = dp(8).toFloat()
                    setColor(color)
                }
                setTextColor(Color.WHITE)
            }
            setOnClickListener { onClick() }
        }

    private fun dp(value: Int): Int = (value * service.resources.displayMetrics.density).toInt()
}
