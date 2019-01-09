extends "res://scripts/state_machine.gd"

signal died

const State = preload("res://scripts/state_machine.gd").State

export (bool) var debug = false

export (float) var gravity = 1200.0

export (float) var walk_min_speed = 17.8125
export (float) var walk_max_speed = 375
export (float) var walk_accel = 956.25

export (float) var run_max_speed = 615
export (float) var run_accel = 1012.5

export (Vector2) var idle_min_jump_distance = Vector2(0, 1.2)
export (Vector2) var idle_max_jump_distance = Vector2(3, 4.1)

export (Vector2) var walk_min_jump_distance = Vector2(2, 1.4)
export (Vector2) var walk_max_jump_distance = Vector2(5, 4.4)

export (Vector2) var run_min_jump_distance = Vector2(3, 1.5)
export (Vector2) var run_max_jump_distance = Vector2(8, 5.1)

export (float) var jump_button_hold_time = 0.3

# Audio Streams
export (AudioStream) var jump_fx
export (AudioStream) var stomp_fx

var jump_distances = {}

# References to child nodes
onready var body = $KinematicBody2D
onready var sprite = $KinematicBody2D/Sprite
onready var animation_player = $KinematicBody2D/Sprite/AnimationPlayer
onready var camera = $KinematicBody2D/Camera2D
onready var audio_player = $AudioStreamPlayer

onready var limit_wall = $Limit

# State const for memory optimzation
onready var idle_state = Idle.new(self)
onready var walk_state = Walk.new(self)
onready var run_state = Run.new(self)
onready var jump_state = Jump.new(self)
onready var fall_state = Fall.new(self)
onready var dead_state = Dead.new(self)
onready var cinematic_cut = CinematicCut.new(self)


var velocity = Vector2()

# Debug
var info = null

func _ready():
    self.camera.limit_smoothed = true
    self.limit_wall.global_position.x = self.camera.limit_left
    if self.debug:
        var scene = preload("res://scenes/debug_tools/PlayerInfo.tscn")
        self.info = scene.instance()
        self.body.add_child(self.info)

    self.organize_jump_distances()
    self.change_state(self.idle_state)
    animation_player.play()

# Organize jump distances for easier in code use
func organize_jump_distances():
    self.jump_distances["Idle"] = {}
    self.jump_distances["Idle"].min = idle_min_jump_distance
    self.jump_distances["Idle"].max = idle_max_jump_distance

    self.jump_distances["Walk"] = {}
    self.jump_distances["Walk"].min = walk_min_jump_distance
    self.jump_distances["Walk"].max = walk_max_jump_distance

    self.jump_distances["Run"] = {}
    self.jump_distances["Run"].min = run_min_jump_distance
    self.jump_distances["Run"].max = run_max_jump_distance


func get_input_velocity():
    var input_velocity = Vector2()

    if Input.is_action_pressed('ui_right'):
        input_velocity.x = 1
    if Input.is_action_pressed('ui_left'):
        input_velocity.x = -1

    return input_velocity


var y_velocity = 0
func calculate_y_velocity(delta):
    if self.is_grounded():
        y_velocity = 0
        return 0
    else:
        y_velocity += self.gravity * delta
        return y_velocity


func is_grounded():
    return self.body.test_move(self.body.global_transform, Vector2(0, 1))


func change_state(new_state):
    .change_state(new_state)
    if self.debug:
        self.info.set_state_label(new_state.name)


func die():
    self.change_state(dead_state)


func start_cinematic_cut():
    self.change_state(cinematic_cut)


func _process(delta):
    ._process(delta)
    var new_limit_left = self.camera.get_camera_position().x - get_viewport().get_visible_rect().size.x / 2

    if new_limit_left != self.camera.limit_left:
        self.camera.limit_left = new_limit_left
        self.limit_wall.global_position.x = new_limit_left


##### States

class Idle extends State:

    func _init(parent).(parent):
        self.name = "Idle"

    func on_enter(previous):
        self.parent.animation_player.current_animation = "Idle"
        self.parent.velocity.x = 0

    func physics_step(delta):
        if Input.is_action_just_pressed("a_button"):
            self.parent.change_state(self.parent.jump_state)
            return

        var velocity = self.parent.get_input_velocity()
        velocity.y = self.parent.calculate_y_velocity(delta)

        self.parent.body.move_and_slide(velocity, UP_NORMAL)

        if velocity.x != 0:
            if Input.is_action_pressed("b_button"):
                self.parent.change_state(self.parent.run_state)
            else:
                self.parent.change_state(self.parent.walk_state)
            return

        if not self.parent.is_grounded():
            return self.parent.change_state(self.parent.fall_state)


class Walk extends State:

    var time = 0

    func _init(parent).(parent):
        self.name = "Walk"

    func on_enter(previous):
        self.parent.animation_player.current_animation = "Walk"
        self.time = 0

    func physics_step(delta):

        if Input.is_action_just_pressed("a_button"):
            self.parent.change_state(self.parent.jump_state)
            return

        if Input.is_action_pressed("b_button"):
            self.parent.change_state(self.parent.run_state)
            return

        var velocity = self.parent.get_input_velocity()
        velocity.y = self.parent.calculate_y_velocity(delta)

        if velocity.x != 0:
            velocity.x *= clamp(
                self.parent.walk_min_speed + self.parent.walk_accel * self.time,
                self.parent.walk_min_speed,
                self.parent.walk_max_speed
            )

            self.parent.sprite.flip_h = velocity.x < 0
            self.parent.body.move_and_slide(velocity, UP_NORMAL)
            self.parent.velocity = velocity
        else:
            self.parent.change_state(self.parent.idle_state)
            return

        if not self.parent.is_grounded():
            return self.parent.change_state(self.parent.fall_state)

        if velocity.x < self.parent.walk_max_speed:
            time += delta


class Run extends State:

    var lapsed_time = 0.0
    var min_velocity = 0

    func _init(parent).(parent):
        self.name = "Run"

    func on_enter(previous):
        self.parent.animation_player.current_animation = "Walk"
        self.parent.animation_player.playback_speed = 2
        self.min_velocity = self.parent.velocity.x
        self.lapsed_time = 0


    func on_exit():
        self.parent.animation_player.playback_speed = 1

    func physics_step(delta):

        if Input.is_action_just_pressed("a_button"):
            self.parent.change_state(self.parent.jump_state)
            return

        # Give grace time with the b button released before change state
        if Input.is_action_just_released("b_button"):
            print("Break!!!!")
            self.parent.change_state(self.parent.idle_state)
            return

        var velocity = self.parent.get_input_velocity()
        velocity.y = self.parent.calculate_y_velocity(delta)

        if velocity.x != 0:
            velocity.x *= clamp(
                self.min_velocity + self.parent.run_accel * self.lapsed_time,
                self.min_velocity,
                self.parent.run_max_speed
            )

            self.parent.sprite.flip_h = velocity.x < 0
            self.parent.body.move_and_slide(velocity, UP_NORMAL)
            self.parent.velocity = velocity
        else:
            self.parent.change_state(self.parent.idle_state)
            return

        if not self.parent.is_grounded():
            return self.parent.change_state(self.parent.fall_state)

        if velocity.x < self.parent.run_max_speed:
            self.lapsed_time += delta


class Jump extends State:

    var velocity = Vector2()

    var max_jump_distance = Vector2()
    var min_jump_distance = Vector2()

    var min_jump_velocity = Vector2()
    var max_jump_velocity = Vector2()

    var total_time = 0
    var jump_button_hold_time = 0
    var xmove_button_hold_time = 0

    var x_direction = 0

    func _init(parent).(parent):
        self.name = "Jump"

    func on_enter(previous):
        self.parent.animation_player.current_animation = "Jump"

        if previous != null:
            self.max_jump_distance = self.parent.jump_distances[previous.name].max
            self.min_jump_distance = self.parent.jump_distances[previous.name].min

        # TODO: Should we add Mario size to the distance
        self.min_jump_velocity = self.calculate_velocity(self.min_jump_distance * 64)
        self.max_jump_velocity = self.calculate_velocity(self.max_jump_distance * 64)
        self.velocity = self.min_jump_velocity
        self.total_time = 0

        self.jump_button_hold_time = 0
        self.xmove_button_hold_time = 0
        self.x_direction = self.parent.get_input_velocity().x

        self.parent.audio_player.stop()
        self.parent.audio_player.stream = self.parent.jump_fx
        self.parent.audio_player.play()

    func calculate_velocity(distance):
        # v=sqrt(2gh)
        var vy = sqrt( (2 * self.parent.gravity ) * distance.y )
        # var time = ( 2 * vy * sin(deg2rad(45)) ) / self.parent.gravity
        # Times 2, to count for the time to reach the height
        var time = sqrt( (distance.y * 2) / self.parent.gravity ) * 2
        var vx = distance.x / time
        return Vector2(vx, -vy)

    func physics_step(delta):

        var input_velocity = self.parent.get_input_velocity()

        if Input.is_action_pressed("a_button"):
            self.jump_button_hold_time = min(
                self.jump_button_hold_time + delta,
                self.parent.jump_button_hold_time
            ) / self.parent.jump_button_hold_time


        if input_velocity.x != 0:
            self.xmove_button_hold_time = min(
                self.xmove_button_hold_time + delta,
                self.parent.jump_button_hold_time
            ) / self.parent.jump_button_hold_time

        var target_jump_velocity = Vector2(
            Utils.f_linear_interpolate(self.min_jump_velocity.x, self.max_jump_velocity.x, self.xmove_button_hold_time),
            Utils.f_linear_interpolate(self.min_jump_velocity.y, self.max_jump_velocity.y, self.jump_button_hold_time)
        )

        if not self.parent.is_grounded():
            self.total_time += delta
            self.velocity.x = target_jump_velocity.x * input_velocity.x
            self.velocity.y = target_jump_velocity.y + self.parent.gravity * total_time
        elif self.total_time > 0:
            self.velocity.y = self.parent.gravity
            return self.parent.change_state(self.parent.idle_state)

        var collision = self.parent.body.move_and_collide(velocity * delta)
        if collision:
            var object = collision.collider.get_parent()

            if object.is_in_group("bricks"):
                if collision.normal == DOWN_NORMAL:
                    object.hitted(collision.normal)

                    # Make this hit the highest point in the jump, so the player start
                    # falling after hit any obstacle
                    total_time = (0 - target_jump_velocity.y) / self.parent.gravity
                else:
                    self.parent.slide_reminder(self.parent.body, collision)

            elif object.is_in_group("enemies"):
                if collision.normal == UP_NORMAL:
                    object.hitted(collision.normal)
                    if not self.parent.audio_player.is_playing():
                        self.parent.audio_player.stop()
                        self.parent.audio_player.stream = self.parent.stomp_fx
                        self.parent.audio_player.play()
            else:
                # Non interactable items should just slide?
                self.parent.slide_reminder(self.parent.body, collision)


class Fall extends State:

    var velocity = Vector2()
    var x_move_time = 0.5
    # How long can the player move horizontally after start falling
    var x_move_threshold = 0.5

    func _init(parent).(parent):
        self.name = "Fall"

    func on_enter(previous):
        print("Faling from grace!")
        self.parent.animation_player.current_animation = "Jump"
        self.x_move_time = self.x_move_threshold

    func physics_step(delta):
        self.x_move_time -= delta
        var velocity = self.parent.get_input_velocity()
        velocity.y = self.parent.calculate_y_velocity(delta)

        if velocity.x != 0:
            self.parent.sprite.flip_h = velocity.x < 0

        var x_movement_allowed = max(self.x_move_time / self.x_move_threshold, 0)
        velocity.x *= x_movement_allowed
        self.parent.body.move_and_slide(velocity, UP_NORMAL)

        if self.parent.is_grounded():
            print("Going Idle")
            self.parent.change_state(self.parent.idle_state)



class CinematicCut extends State:

    func _init(parent).(parent):
        self.name = "CinematicCut"


class Dead extends State:

    var time = 0
    var emitted = false

    func _init(parent).(parent):
        self.name = "Dead"


    func on_enter(previous):
        self.parent.animation_player.current_animation = "Die"
        time = 0


    func step(delta):
        time += delta
        if time > 1 and not emitted:
            emitted = true
            self.parent.emit_signal("died")


###### End states
