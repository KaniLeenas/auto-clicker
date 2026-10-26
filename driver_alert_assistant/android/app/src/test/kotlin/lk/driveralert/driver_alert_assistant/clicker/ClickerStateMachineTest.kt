package lk.driveralert.driver_alert_assistant.clicker

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class ClickerStateMachineTest {

    @Test
    fun startsStopped() {
        assertEquals(RunState.STOPPED, ClickerStateMachine().state)
    }

    @Test
    fun savedEmergencyStartsInEmergency() {
        assertEquals(RunState.EMERGENCY_STOPPED, ClickerStateMachine(emergencyActive = true).state)
    }

    @Test
    fun startNeedsAccessibilityService() {
        val m = ClickerStateMachine()
        assertEquals(CommandResult.BLOCKED_NO_SERVICE, m.start(serviceReady = false))
        assertEquals(RunState.STOPPED, m.state)
        assertEquals(CommandResult.OK, m.start(serviceReady = true))
        assertEquals(RunState.RUNNING, m.state)
    }

    @Test
    fun pauseResumeStop() {
        val m = ClickerStateMachine()
        m.start(true)
        assertEquals(CommandResult.OK, m.pause())
        assertEquals(RunState.PAUSED, m.state)
        assertEquals(CommandResult.NOT_ALLOWED_NOW, m.pause())
        assertEquals(CommandResult.OK, m.resume(true))
        assertEquals(RunState.RUNNING, m.state)
        assertEquals(CommandResult.OK, m.stop())
        assertEquals(RunState.STOPPED, m.state)
    }

    @Test
    fun cannotStartTwiceOrResumeWhenNotPaused() {
        val m = ClickerStateMachine()
        m.start(true)
        assertEquals(CommandResult.NOT_ALLOWED_NOW, m.start(true))
        assertEquals(CommandResult.NOT_ALLOWED_NOW, m.resume(true))
    }

    @Test
    fun emergencyStopWorksFromEveryState() {
        for (setup in listOf<(ClickerStateMachine) -> Unit>(
            {},
            { it.start(true) },
            { it.start(true); it.pause() },
            { it.emergencyStop() },
        )) {
            val m = ClickerStateMachine()
            setup(m)
            assertEquals(CommandResult.OK, m.emergencyStop())
            assertEquals(RunState.EMERGENCY_STOPPED, m.state)
        }
    }

    @Test
    fun emergencyBlocksStartUntilCleared() {
        val m = ClickerStateMachine()
        m.start(true)
        m.emergencyStop()
        assertEquals(CommandResult.BLOCKED_EMERGENCY, m.start(true))
        assertEquals(CommandResult.NOT_ALLOWED_NOW, m.resume(true))
        // Stop never clears an emergency.
        m.stop()
        assertEquals(RunState.EMERGENCY_STOPPED, m.state)

        assertEquals(CommandResult.OK, m.clearEmergency())
        // No automatic restart after clearing.
        assertEquals(RunState.STOPPED, m.state)
    }

    @Test
    fun clearEmergencyOnlyWhenActive() {
        assertEquals(CommandResult.NOT_ALLOWED_NOW, ClickerStateMachine().clearEmergency())
    }

    @Test
    fun losingServiceStopsActiveClicker() {
        val running = ClickerStateMachine().apply { start(true) }
        assertTrue(running.serviceLost())
        assertEquals(RunState.STOPPED, running.state)

        val paused = ClickerStateMachine().apply { start(true); pause() }
        assertTrue(paused.serviceLost())
        assertEquals(RunState.STOPPED, paused.state)

        val emergency = ClickerStateMachine(emergencyActive = true)
        assertFalse(emergency.serviceLost())
        assertEquals(RunState.EMERGENCY_STOPPED, emergency.state)
    }

    @Test
    fun resumeNeedsService() {
        val m = ClickerStateMachine().apply { start(true); pause() }
        assertEquals(CommandResult.BLOCKED_NO_SERVICE, m.resume(false))
        assertEquals(RunState.PAUSED, m.state)
    }
}
