extends "res://scripts/state_machine.gd"

signal hit_pole(height)
signal cinematic_finished

onready var Coroutine = get_node("/root/Coroutines")

const State = preload("res://scripts/state_machine.gd").State
const Player = preload("res://scenes/player/Player.gd")

onready var idle_state = Idle.new(self)
onready var slide_state = Slide.new(self)
onready var jumpoff_state = JumpOff.new(self)

var player_ref = null
var slided = true

func _ready():
    self.current_state = idle_state


func _on_Area2D_body_entered(body):
    if body.get_parent() is Player:
        var player = body.get_parent()
        self.player_ref = player

        var top = $Top.global_position.y
        var base = $Base.global_position.y
        var height = base - top

        var hit_height = body.global_position.y - top
        var hit_percent = min(1, (1 - hit_height / height) + 0.1)
        # Set presicion to two decimals
        hit_percent = (round(hit_percent * 100) / 100)

        self.emit_signal("hit_pole", hit_percent)
        self.change_state(self.slide_state)


class Idle extends State:

    func _init(parent).(parent):
        self.name = "Idle"


class Slide extends State:

    func _init(parent).(parent):
        self.name = "Slide"

    func on_enter():
        self.parent.player_ref.start_cinematic_cut()
        self.parent.player_ref.animation_player.current_animation = "PoleSlide"
        self.parent.player_ref.body.move_and_slide(Vector2(350,0))


    func on_exit():
        self.parent.player_ref.animation_player.stop()
        self.parent.player_ref.sprite.flip_h = true
        self.parent.player_ref.body.move_and_slide(Vector2(3000,0))


    func physics_step(delta):
        self.parent.player_ref.body.move_and_slide(Vector2(0,150))

        if self.parent.player_ref.is_grounded():
            self.parent.change_state(self.parent.jumpoff_state)


class JumpOff extends State:

    func _init(parent).(parent):
        self.name = "Jump Off"

    func on_enter():
        Coroutines.start(execute())

    func execute():
        var player = self.parent.player_ref
        var jump_force = Vector2(75,-400)
        var velocity = Vector2(jump_force.x, jump_force.y)

        player.sprite.flip_h = false
        player.animation_player.current_animation = "Idle"
        yield(Coroutines.wait_for_seconds(0.1), "completed")

        player.animation_player.current_animation = "Jump"
        var total_time = 0
        player.body.move_and_slide(velocity)
        yield(Coroutines.wait_for_frames(1), "completed")

        while not player.is_grounded():
            total_time += Coroutines.get_physics_process_delta_time()
            velocity.y = jump_force.y + player.gravity * total_time
            player.body.move_and_slide(velocity)
            yield(Coroutines.wait_for_frames(1), "completed")

        player.animation_player.current_animation = "Idle"
        self.parent.change_state(self.parent.idle_state)

