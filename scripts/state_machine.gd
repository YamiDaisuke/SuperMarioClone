extends Node2D

const UP_NORMAL = Vector2(0,-1)
const DOWN_NORMAL = Vector2(0,1)
const LEFT_NORMAL = Vector2(-1,0)
const RIGHT_NORMAL = Vector2(1,0)

var current_state = null

func change_state(new_state):

    if not new_state is State:
        printerr("new_state must inherit from State")
        return

    if new_state == self.current_state:
        return

    if current_state != null:
        current_state.on_exit()

    new_state.on_enter(current_state)
    current_state = new_state

func _process(delta):
    if current_state != null:
        current_state.step(delta)

func _physics_process(delta):
    if current_state != null:
        current_state.physics_step(delta)

# Utilities to avoid duplicate code

# Move a body, with the reminder after a coliision
func slide_reminder(body, collision):
    var r = collision.remainder
    var n = collision.normal
    var nm = r.slide(n)
    body.move_and_collide(nm)

class State:
    var name = "Base State"
    var parent = null

    func _init(parent):
        self.parent = parent

    func on_enter(previous):
        pass
    func step(delta):
        pass
    func physics_step(delta):
        pass
    func on_exit():
        pass
