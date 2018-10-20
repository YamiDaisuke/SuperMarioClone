extends "res://scripts/basebrick.gd"

const State = preload("res://scripts/state_machine.gd").State
const Hitted = preload("res://scripts/basebrick.gd").Hitted

onready var Coroutine = get_node("/root/Coroutines")

onready var particles = $KinematicBody2D/Particles2D
onready var sprite = $KinematicBody2D/Sprite

func hitted(normal):
    print("hit? %s" % normal)
    if normal == DOWN_NORMAL:
        self.change_state(self.hitted_state)
        # TODO: Do this if mario is big
        # Coroutine.start(break_anim())
        

func break_anim():
    #TODO: Break only when Mario is big
    self.particles.emitting = true
    self.sprite.hide()
    yield(Coroutines.wait_for_seconds(0.5), "completed")
    self.queue_free()

    