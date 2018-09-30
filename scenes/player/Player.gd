extends "res://scripts/state_machine.gd"

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

var velocity = Vector2()

var jumping = false

# References to child nodes
var body = null
var sprite = null
var animation_player = null

# State const for memory optimzation
var idle_state = null
var walk_state = null
var jump_state = null


# Debug
var info = null

func _ready():
    body = $KinematicBody2D
    sprite = $KinematicBody2D/Sprite
    animation_player = $KinematicBody2D/Sprite/AnimationPlayer
    
    if self.debug:
        var scene = preload("res://scenes/debug_tools/PlayerInfo.tscn")
        self.info = scene.instance()
        self.body.add_child(self.info)
    
    self.calculate_jump_forces()
    
    idle_state = Idle.new(self)
    walk_state = Walk.new(self)
    jump_state = Jump.new(self)
        
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


func is_grounded():
    return self.body.test_move(self.body.global_transform, Vector2(0, 1))
    

func change_state(new_state):
    .change_state(new_state)
    if self.debug:
        self.info.set_state_label(new_state.name)

    
##### States 

class Idle extends State:
    
    func _init(parent).(parent):
        self.name = "Idle"
    
    func on_enter():
        self.parent.animation_player.current_animation = "Idle"
        
    func physics_step(delta):
        if Input.is_action_just_pressed("a_button"):
            self.parent.change_state(self.parent.jump_state)
            
        var velocity = self.parent.get_input_velocity()
        velocity.y = self.parent.gravity
        
        self.parent.body.move_and_slide(velocity)
        
        if velocity.x != 0:
            self.parent.change_state(self.parent.walk_state)


class Walk extends State:
    
    func _init(parent).(parent):
        self.name = "Walk"
    
    func on_enter():
        self.parent.animation_player.current_animation = "Walk"
        
    func physics_step(delta):
        if Input.is_action_just_pressed("a_button"):
            self.parent.change_state(self.parent.jump_state)
        
        var velocity = self.parent.get_input_velocity()
        velocity.y = self.parent.gravity
        
        if velocity.x != 0:
            self.parent.sprite.flip_h = velocity.x < 0
            self.parent.body.move_and_slide(velocity)
        else:
            self.parent.change_state(self.parent.idle_state)
    

class Jump extends State:
    
    var velocity = Vector2()
    var jumpSpeed = Vector2() 
    
    var total_time = 0
    var button_hold_time = 0
    
    func _init(parent).(parent):
        self.name = "Jump"
    
    func on_enter():
        self.parent.animation_player.current_animation = "Jump"
        self.velocity = self.parent.idle_max_jump_force
        self.total_time = 0
        self.button_hold_time = 0
        
        
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
        
        self.parent.body.move_and_slide(velocity)