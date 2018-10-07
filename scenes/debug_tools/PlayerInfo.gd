extends Node2D

var time = 0.0
var _timer_running = false

func _ready():
    # Called when the node is added to the scene for the first time.
    # Initialization here
    pass

func set_state_label(text):
    $StateLabel.text = text

func is_timer_running():
    return self._timer_running # not $Timer.is_stopped()

func start_timer():
    time = 0
    self._timer_running = true
    $Timer.start()

func stop_timer():
    self._timer_running = false
    $Timer.stop()

func _on_Timer_timeout():
    time += $Timer.wait_time
    $TimerLabel.text = "%.3f" % time
