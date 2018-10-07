extends Node

var process_delta = 0
var physics_delta = 0

func _process(delta):
    self.process_delta = delta
    

func _physics_process(delta):
    self.physics_delta = delta

func start(coroutine):
    yield(coroutine, "completed")


func wait_for_seconds(seconds):
    yield(get_tree().create_timer(seconds), "timeout")
    
    
func wait_for_frames(frames):
    var current = 0
    while current < frames:
        yield(get_tree(), "idle_frame")
        current += 1
