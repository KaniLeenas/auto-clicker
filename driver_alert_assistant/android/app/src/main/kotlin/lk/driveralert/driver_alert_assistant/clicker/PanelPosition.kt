package lk.driveralert.driver_alert_assistant.clicker

import kotlin.math.max
import kotlin.math.roundToInt

/**
 * Keeps the floating panel on screen.
 *
 * The position is saved as a fraction (0.0 = left/top edge, 1.0 = right/
 * bottom edge) of the free space, so it stays sensible after rotation or a
 * screen-size change instead of using fixed pixels.
 */
object PanelPosition {

    fun clamp(pos: Int, panelSize: Int, screenSize: Int): Int =
        pos.coerceIn(0, max(0, screenSize - panelSize))

    fun toFraction(pos: Int, panelSize: Int, screenSize: Int): Float {
        val room = screenSize - panelSize
        if (room <= 0) return 0f
        return (clamp(pos, panelSize, screenSize).toFloat() / room).coerceIn(0f, 1f)
    }

    fun fromFraction(fraction: Float, panelSize: Int, screenSize: Int): Int {
        val room = max(0, screenSize - panelSize)
        val safe = if (fraction.isNaN()) 0f else fraction.coerceIn(0f, 1f)
        return (safe * room).roundToInt()
    }
}
