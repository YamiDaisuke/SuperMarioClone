extends Node

func start(coroutine):
    yield(coroutine, "completed")


func wait_for_seconds(seconds):
    yield(get_tree().create_timer(seconds), "timeout")


func wait_for_frames(frames):
    var current = 0
    while current < frames:
        yield(get_tree(), "idle_frame")
        current += 1
