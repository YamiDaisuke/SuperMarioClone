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
export (float) var run_deaccel = -731.25

export (float) var skid_turn = -1462.5

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
onready var walk_state = Move.new(self)
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
            self.parent.change_state(self.parent.walk_state)

            return

        if not self.parent.is_grounded():
            return self.parent.change_state(self.parent.fall_state)


class Move extends State:

    var last_direction = 1
    var new_direction = 0.0
    var change_direction = false
    var locked_velocity = 0
    # How many frames we wait before start deacceleration
    # after b button is released
    var b_release_threshold = 10

    var b_released_frames = 0

    func _init(parent).(parent):
        self.name = "Walk"

    func on_enter(previous):
        self.parent.animation_player.current_animation = "Walk"
        self.last_direction = -1 if self.parent.velocity.x < 0 else 1
        self.b_released_frames = 0
        self.new_direction = 0.0
        self.change_direction = false
        self.locked_velocity = 0

    func physics_step(delta):

        if self.jump():
            return

        var input_velocity = self.parent.get_input_velocity()
        input_velocity.y = self.parent.calculate_y_velocity(delta)

        var accel = self.parent.walk_accel
        var max_vel = self.parent.walk_max_speed
        var min_vel = self.parent.walk_min_speed
        self.name = "Walk"

        if Input.is_action_pressed("b_button"):
            self.b_released_frames = 0
        else:
            self.b_released_frames += 1


        if self.b_released_frames < self.b_release_threshold:
            accel = self.parent.run_accel
            max_vel = self.parent.run_max_speed
            self.name = "Run"
        elif self.parent.velocity.x > max_vel and !self.change_direction:
            accel = self.parent.run_deaccel
            max_vel = self.parent.velocity.x
            input_velocity.x = self.last_direction
        elif input_velocity.x == 0:
            accel = self.parent.run_deaccel
            min_vel = 0

        # TODO: Avoid skid if the player is stuck in a wall
        if not self.change_direction:
            var x = self.calculate_x_velocity(
                self.parent.velocity,
                min_vel,
                max_vel,
                accel,
                delta
            )

            if input_velocity.x == 0:
                input_velocity.x = self.last_direction * x
            elif input_velocity.x != self.last_direction:
                self.change_direction = true
                self.parent.animation_player.current_animation = "Skid"
                self.locked_velocity = x
                self.new_direction = locked_velocity
            else:
                input_velocity.x *= x

        elif self.new_direction > -self.locked_velocity:
            self.new_direction += self.parent.skid_turn * delta
            input_velocity.x = self.last_direction * clamp(
                self.new_direction,
                -self.locked_velocity,
                self.locked_velocity
            )

            if sign(input_velocity.x) != self.last_direction:
                self.parent.animation_player.current_animation = "Walk"

        else:
            self.last_direction = input_velocity.x
            self.change_direction = false
            self.locked_velocity = 0
            self.new_direction = 0

            var x = self.calculate_x_velocity(
                self.parent.velocity,
                min_vel,
                max_vel,
                accel,
                delta
            )

            input_velocity.x *= x
            if input_velocity.x == 0:
                self.parent.change_state(self.parent.idle_state)
                self.parent.velocity = input_velocity
                return

        self.parent.sprite.flip_h = input_velocity.x < 0
        self.parent.body.move_and_slide(input_velocity, UP_NORMAL)
        self.parent.velocity = input_velocity

        if input_velocity.x == 0 and !self.change_direction:
            self.parent.change_state(self.parent.idle_state)
            return

        if not self.parent.is_grounded():
            return self.parent.change_state(self.parent.fall_state)


    func jump():
        if Input.is_action_just_pressed("a_button"):
            self.parent.change_state(self.parent.jump_state)
            return true
        else:
            return false


    func calculate_x_velocity(current_velocity, min_velocity, max_velocity, acceleration, time_delta):
        return clamp(
            abs(current_velocity.x) + acceleration * time_delta,
            min_velocity,
            max_velocity
        )


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

    var previous

    func _init(parent).(parent):
        self.name = "Jump"

    func on_enter(previous):
        self.previous = previous
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
            return self.parent.change_state(self.previous)

        var collision = self.parent.body.move_and_collide(velocity * delta)
        self.parent.velocity = velocity
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
                    var kickback = object.hitted(collision.normal)

                    if kickback:
                        self.total_time = 0
                        self.min_jump_velocity = self.calculate_velocity(kickback)
                        self.max_jump_velocity = self.calculate_velocity(kickback)

                    if not self.parent.audio_player.is_playing():
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
