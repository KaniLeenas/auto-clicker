package lk.driveralert.driver_alert_assistant.clicker

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.content.res.Configuration
import android.view.accessibility.AccessibilityEvent

/**
 * The accessibility service that hosts the floating control panel.
 *
 * Phase 2 only shows the panel. Reading the screen and clicking are added
 * in later phases; until then this service does not look at other apps.
 */
class ClickerAccessibilityService : AccessibilityService() {

    private var panel: OverlayPanel? = null

    val isPanelVisible: Boolean get() = panel != null

    override fun onServiceConnected() {
        super.onServiceConnected()
        ClickerRuntime.init(this)
        ClickerRuntime.onServiceConnected(this)
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // Screen reading is added in a later phase.
    }

    override fun onInterrupt() {
        // Nothing to interrupt yet.
    }

    override fun onUnbind(intent: Intent?): Boolean {
        disconnect()
        return super.onUnbind(intent)
    }

    override fun onDestroy() {
        disconnect()
        super.onDestroy()
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        panel?.onScreenChanged()
    }

    fun showPanel() {
        if (panel == null) panel = OverlayPanel(this).also { it.show() }
    }

    fun hidePanel() {
        panel?.remove()
        panel = null
    }

    fun refreshPanel() {
        panel?.render()
    }

    private fun disconnect() {
        hidePanel()
        ClickerRuntime.onServiceDisconnected(this)
    }
}
