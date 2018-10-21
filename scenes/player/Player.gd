extends "res://scripts/state_machine.gd"

signal died

const State = preload("res://scripts/state_machine.gd").State

# force makes the player jump about one square
const ONE_SQUARE_JUMP_FORCE = 195.12

export (bool) var debug = false

export (float) var gravity = 1200.0
export (int) var speed = 300

export (float) var idle_min_jump_height = 1.2
export (float) var idle_max_jump_height = 4.1

export (float) var walk_min_jump_height = 4.4
export (float) var walk_max_jump_height = 1.4

export (float) var run_min_jump_height = 5.1
export (float) var run_max_jump_height = 1.5

export (float) var jump_button_hold_time = 0.3


var idle_max_jump_force = Vector2()
var idle_min_jump_force = Vector2()

var walk_max_jump_force = Vector2()
var walk_min_jump_force = Vector2()

var run_max_jump_force = Vector2()
var run_min_jump_force = Vector2()

# References to child nodes
onready var body = $KinematicBody2D
onready var sprite = $KinematicBody2D/Sprite
onready var animation_player = $KinematicBody2D/Sprite/AnimationPlayer

# State const for memory optimzation
onready var idle_state = Idle.new(self)
onready var walk_state = Walk.new(self)
onready var jump_state = Jump.new(self)
onready var fall_state = Fall.new(self)
onready var dead_state = Dead.new(self)
onready var cinematic_cut = CinematicCut.new(self)


# Debug
var info = null

func _ready():

    if self.debug:
        var scene = preload("res://scenes/debug_tools/PlayerInfo.tscn")
        self.info = scene.instance()
        self.body.add_child(self.info)

    self.calculate_jump_forces()
    self.change_state(self.idle_state)
    animation_player.play()


func calculate_jump_forces():
    self.idle_max_jump_force = Vector2(
        0,
        -ONE_SQUARE_JUMP_FORCE * self.idle_max_jump_height
    )
    self.idle_min_jump_force = Vector2(
        0,
        -ONE_SQUARE_JUMP_FORCE * self.idle_min_jump_height
    )

    self.walk_max_jump_force = Vector2(
        0,
        -ONE_SQUARE_JUMP_FORCE * self.walk_max_jump_height
    )
    self.walk_min_jump_force = Vector2(
        0,
        -ONE_SQUARE_JUMP_FORCE * self.walk_min_jump_height
    )

    self.run_max_jump_force = Vector2(
        0,
        -ONE_SQUARE_JUMP_FORCE * self.run_max_jump_height
    )
    self.run_min_jump_force = Vector2(
        0,
        -ONE_SQUARE_JUMP_FORCE * self.run_min_jump_height
    )


func get_input_velocity():
    var input_velocity = Vector2()

    if Input.is_action_pressed('ui_right'):
        input_velocity.x += 1
    if Input.is_action_pressed('ui_left'):
        input_velocity.x -= 1

    input_velocity.x = input_velocity.normalized().x * self.speed
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


# func _process(delta):
#     ._process(delta)
#     print("On Floor? %s" % self.body.is_on_floor())
#     print("On Ceiling? %s" % self.body.is_on_ceiling())
#     print("On Wall? %s" % self.body.is_on_wall())

##### States

class Idle extends State:

    func _init(parent).(parent):
        self.name = "Idle"

    func on_enter():
        self.parent.animation_player.current_animation = "Idle"

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

        # TODO: Avoid horizontal movement
        if not self.parent.is_grounded():
            self.parent.change_state(self.parent.fall_state)


class Walk extends State:

    func _init(parent).(parent):
        self.name = "Walk"

    func on_enter():
        self.parent.animation_player.current_animation = "Walk"

    func physics_step(delta):
        if Input.is_action_just_pressed("a_button"):
            self.parent.change_state(self.parent.jump_state)
            return

        var velocity = self.parent.get_input_velocity()
        velocity.y = self.parent.calculate_y_velocity(delta)

        if velocity.x != 0:
            self.parent.sprite.flip_h = velocity.x < 0
            self.parent.body.move_and_slide(velocity, UP_NORMAL)
        else:
            self.parent.change_state(self.parent.idle_state)
            return

        # TODO: Avoid horizontal movement
        if not self.parent.is_grounded():
            self.parent.change_state(self.parent.fall_state)


class Jump extends State:

    var velocity = Vector2()

    var total_time = 0
    var button_hold_time = 0

    var x_move_time = 0.6
    # How long can the player move horizontally after start falling
    var x_move_threshold = 0.6
    var x_direction_locked = false

    var direction = false

    func _init(parent).(parent):
        self.name = "Jump"

    func on_enter():
        self.parent.animation_player.current_animation = "Jump"
        self.velocity = self.parent.idle_max_jump_force
        self.total_time = 0
        self.button_hold_time = 0
        self.x_direction_locked = false
        self.x_move_time = self.x_move_threshold
        #self.parent.sprite.flip_h = velocity.x < 0
        if self.parent.sprite.flip_h:
            self.direction = -1
        else:
            self.direction = 1


    """
    x = vx * t
    vx = vxi
    y = vyi*t + (g * t^2) / 2
    vy = vyo + g*t

    H = (vi^2 * sin^2 (a)) / 2 * g
    R = (vi^2 * sin (2*a)) / g
    """
    func physics_step(delta):


        var input_velocity = self.parent.get_input_velocity()
        self.velocity.x = input_velocity.x

        if sign(self.velocity.x) != direction or self.x_direction_locked:

            if sign(self.velocity.x) == direction:
                self.velocity.x *= -1

            self.x_direction_locked = true
            self.x_move_time -= delta
            var x_movement_allowed = max(
                self.x_move_time / self.x_move_threshold, 0)
            self.velocity.x *= x_movement_allowed


        if Input.is_action_pressed("a_button"):
            self.button_hold_time = min(
                self.button_hold_time + delta,
                self.parent.jump_button_hold_time
            ) / self.parent.jump_button_hold_time

        var target_jump_force = self.parent.idle_min_jump_force \
                .linear_interpolate(
                    self.parent.idle_max_jump_force,
                    self.button_hold_time
                )

        if not self.parent.is_grounded():
            self.total_time += delta
            velocity.y = target_jump_force.y + self.parent.gravity * total_time
        elif self.total_time > 0:
            self.velocity.y = self.parent.gravity
            self.parent.change_state(self.parent.idle_state)

        var collision = self.parent.body.move_and_collide(velocity * delta)
        if collision:
            var object = collision.collider.get_parent()
            if object.is_in_group("bricks"):
                if collision.normal == DOWN_NORMAL:
                    object.hitted(collision.normal)
                    # Make this hit the highest point in the jump, so the player start
                    # falling after hit a brick from down
                    total_time = (0 - target_jump_force.y) / self.parent.gravity
                else:
                    self.parent.body.move_and_slide(velocity)

            if object.is_in_group("enemies"):
                print("Enemy??? %s" % collision.normal)
                if collision.normal == UP_NORMAL:
                    object.hitted(collision.normal)


class Fall extends State:

    var velocity = Vector2()
    var x_move_time = 0.5
    # How long can the player move horizontally after start falling
    var x_move_threshold = 0.5

    func _init(parent).(parent):
        self.name = "Fall"

    func on_enter():
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


    func on_enter():
        self.parent.animation_player.current_animation = "Die"
        time = 0


    func step(delta):
        time += delta
        if time > 1 and not emitted:
            emitted = true
            self.parent.emit_signal("died")


###### End states
