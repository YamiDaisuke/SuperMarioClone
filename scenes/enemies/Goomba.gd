extends "res://scripts/state_machine.gd"

const State = preload("res://scripts/state_machine.gd").State

# This should  be an enum but godot is not
# allowing negative numbers
export (int) var direction = -1

export (float) var trigger_distance = 64 * 18
export (Vector2) var walk_speed = Vector2(150,0)

export (Vector2) var stomp_kickback = Vector2(2, 1.4)

onready var animation_player = $KinematicBody2D/AnimationPlayer
onready var collider_animation = $KinematicBody2D/CollisionShape2D/AnimationPlayer
onready var body = $KinematicBody2D

onready var idle_state = Idle.new(self)
onready var walk_state = Walk.new(self)
onready var die_state = Die.new(self)


func _ready():
    $Trigger/CollisionShape2D.shape.extents = Vector2(trigger_distance, trigger_distance)
    self.change_state(self.idle_state)


func hitted(normal):
    self.change_state(self.die_state)
    return self.stomp_kickback * 64


func _on_Trigger_body_entered(body):
    if body.get_parent().is_in_group("player"):
        self.change_state(self.walk_state)


# TODO: Replace this with an exit collider :D
# func _on_VisibilityNotifier2D_screen_exited():
    # Only kill this element if is moving left
    # if self.direction == -1:
    #     self.change_state(self.idle_state)
    #     self.queue_free()

# func _on_VisibilityNotifier2D_viewport_exited(viewport):
#     print("End?? %s" % viewport.get_visible_rect().end)
#     print("Position?? %s" % viewport.get_visible_rect().position)


class Idle extends State:

    func _init(parent).(parent):
        self.name = "Idle"

    func on_enter(previous):
        self.parent.animation_player.current_animation = "Idle"


class Walk extends State:

    func _init(parent).(parent):
        self.name = "Walk"

    func on_enter(previous):
        self.parent.animation_player.play()
        self.parent.animation_player.current_animation = "Walk"


    func physics_step(delta):
        var collision = self.parent.body.move_and_collide(self.parent.walk_speed * delta * self.parent.direction)
        if collision:
            var object = collision.collider.get_parent()

            if object.is_in_group("player") and collision.normal != DOWN_NORMAL:
                object.die()
                return self.parent.change_state(self.parent.idle_state)

            if collision.normal == LEFT_NORMAL or collision.normal == RIGHT_NORMAL:
                self.parent.direction *= -1

            var r = collision.remainder
            var n = collision.normal
            var nm = r.slide(n)
            self.parent.body.move_and_collide(nm)


class Die extends State:

    var time = 0

    func _init(parent).(parent):
        self.name = "Die"

    func on_enter(previous):
        self.parent.collider_animation.current_animation = "Die"
        self.parent.collider_animation.play()
        self.parent.animation_player.current_animation = "Die"


    func physics_step(delta):
        time += delta
        if (time > self.parent.animation_player.current_animation_length):
            self.parent.change_state(self.parent.idle_state)
            self.parent.queue_free()
