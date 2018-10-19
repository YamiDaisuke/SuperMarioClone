extends Node2D

var current_state = null

func change_state(new_state):

    if not new_state is State:
        printerr("new_state must inherit from State")
        return

    if new_state == self.current_state:
        return

    if current_state != null:
        current_state.on_exit()

    new_state.on_enter()
    current_state = new_state

func _process(delta):
    if current_state != null:
        current_state.step(delta)

func _physics_process(delta):
    if current_state != null:
        current_state.physics_step(delta)

class State:
    var name = "Base State"
    var parent = null

    func _init(parent):
        self.parent = parent

    func on_enter():
        pass
    func step(delta):
        pass
    func physics_step(delta):
        pass
    func on_exit():
        pass
