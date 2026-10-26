package lk.driveralert.driver_alert_assistant.clicker

/** What the auto clicker is doing right now. */
enum class RunState { STOPPED, RUNNING, PAUSED, EMERGENCY_STOPPED }

/** Answer to a control command (Start, Pause, ...). */
enum class CommandResult {
    OK,
    BLOCKED_EMERGENCY,
    BLOCKED_NO_SERVICE,
    NOT_ALLOWED_NOW,
    UNKNOWN_COMMAND,
}

/**
 * The rules for moving between states. Plain Kotlin with no Android code,
 * so it can be unit tested on the computer.
 *
 * Safety rules:
 * - Emergency Stop always works, from any state.
 * - After Emergency Stop nothing starts until [clearEmergency] is called.
 * - Clearing Emergency Stop leaves the clicker STOPPED (no auto restart).
 * - Losing the accessibility service stops a running or paused clicker.
 */
class ClickerStateMachine(emergencyActive: Boolean = false) {

    var state: RunState =
        if (emergencyActive) RunState.EMERGENCY_STOPPED else RunState.STOPPED
        private set

    val isEmergency: Boolean get() = state == RunState.EMERGENCY_STOPPED

    val isActive: Boolean get() = state == RunState.RUNNING || state == RunState.PAUSED

    fun start(serviceReady: Boolean): CommandResult = when {
        isEmergency -> CommandResult.BLOCKED_EMERGENCY
        !serviceReady -> CommandResult.BLOCKED_NO_SERVICE
        state != RunState.STOPPED -> CommandResult.NOT_ALLOWED_NOW
        else -> move(RunState.RUNNING)
    }

    fun pause(): CommandResult =
        if (state == RunState.RUNNING) move(RunState.PAUSED) else CommandResult.NOT_ALLOWED_NOW

    fun resume(serviceReady: Boolean): CommandResult = when {
        state != RunState.PAUSED -> CommandResult.NOT_ALLOWED_NOW
        !serviceReady -> CommandResult.BLOCKED_NO_SERVICE
        else -> move(RunState.RUNNING)
    }

    /** Stop is always safe to press. It never clears an Emergency Stop. */
    fun stop(): CommandResult {
        if (isActive) state = RunState.STOPPED
        return CommandResult.OK
    }

    fun emergencyStop(): CommandResult = move(RunState.EMERGENCY_STOPPED)

    fun clearEmergency(): CommandResult =
        if (isEmergency) move(RunState.STOPPED) else CommandResult.NOT_ALLOWED_NOW

    /** Returns true when a running or paused clicker had to be stopped. */
    fun serviceLost(): Boolean {
        if (!isActive) return false
        state = RunState.STOPPED
        return true
    }

    private fun move(next: RunState): CommandResult {
        state = next
        return CommandResult.OK
    }
}
