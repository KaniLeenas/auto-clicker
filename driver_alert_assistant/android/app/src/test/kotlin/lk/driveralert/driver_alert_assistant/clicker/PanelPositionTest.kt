package lk.driveralert.driver_alert_assistant.clicker

import org.junit.Assert.assertEquals
import org.junit.Test

class PanelPositionTest {

    @Test
    fun clampKeepsPanelOnScreen() {
        assertEquals(0, PanelPosition.clamp(-50, 200, 1080))
        assertEquals(880, PanelPosition.clamp(5000, 200, 1080))
        assertEquals(300, PanelPosition.clamp(300, 200, 1080))
    }

    @Test
    fun panelBiggerThanScreenSticksToEdge() {
        assertEquals(0, PanelPosition.clamp(100, 1200, 1080))
        assertEquals(0f, PanelPosition.toFraction(100, 1200, 1080))
        assertEquals(0, PanelPosition.fromFraction(1f, 1200, 1080))
    }

    @Test
    fun fractionRoundTrip() {
        val f = PanelPosition.toFraction(440, 200, 1080)
        assertEquals(0.5f, f, 0.001f)
        assertEquals(440, PanelPosition.fromFraction(f, 200, 1080))
    }

    @Test
    fun rightEdgeStaysRightEdgeAfterRotation() {
        // Portrait 1080 wide -> landscape 2400 wide.
        val f = PanelPosition.toFraction(880, 200, 1080)
        assertEquals(2200, PanelPosition.fromFraction(f, 200, 2400))
    }

    @Test
    fun badSavedFractionIsMadeSafe() {
        assertEquals(0, PanelPosition.fromFraction(Float.NaN, 200, 1080))
        assertEquals(880, PanelPosition.fromFraction(7f, 200, 1080))
        assertEquals(0, PanelPosition.fromFraction(-3f, 200, 1080))
    }
}
