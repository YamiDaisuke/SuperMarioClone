extends "res://scripts/state_machine.gd"

const UP_NORMAL = Vector2(0,-1)
const DOWN_NORMAL = Vector2(0,1)
const LEFT_NORMAL = Vector2(-1,0)
const RIGHT_NORMAL = Vector2(1,0)

const State = preload("res://scripts/state_machine.gd").State

export (float) var bounce_time = 0.15
export (Vector2) var bounce_force = Vector2(0, 550)

onready var body = $KinematicBody2D
onready var tween = $Tween
onready var idle_state = Idle.new(self)
onready var hitted_state = Hitted.new(self)

var velocity = Vector2(0, -250)

func _ready():
    $KinematicBody2D/Sprite/AnimationPlayer.current_animation = "Blink"
    $KinematicBody2D/Sprite/AnimationPlayer.play()

func hitted(normal):
    print("hit? %s" % normal)
    if normal == DOWN_NORMAL:
        self.change_state(self.hitted_state)


class Idle extends State:

    func _init(parent).(parent):
        self.name = "Idle"


class Hitted extends State:

    var velocity = Vector2(0, 0)
    var step = 0
    var original_position

    func _init(parent).(parent):
        self.name = "Hitted"
        self.parent.tween.connect("tween_completed", self, "_on_tween_completed")

    func on_enter():
        self.original_position = self.parent.body.position
        self.step = 0
        self.parent.tween.interpolate_property(
                self,
                "velocity",
                -self.parent.bounce_force,
                Vector2(),
                self.parent.bounce_time,
                Tween.TRANS_LINEAR,
                Tween.EASE_IN_OUT
            )

        self.parent.tween.start()


    func on_exit():
        self.parent.body.position = self.original_position

    func _on_tween_completed(obj, key):
        if step == 0:
            step += 1
            self.parent.tween.interpolate_property(
                    self,
                    "velocity",
                    self.parent.bounce_force,
                    Vector2(),
                    self.parent.bounce_time,
                    Tween.TRANS_LINEAR,
                    Tween.EASE_IN_OUT
                )
            self.parent.tween.start()
        else:
            self.parent.change_state(self.parent.idle_state)

    func physics_step(delta):
        self.parent.body.move_and_collide(velocity * delta)
