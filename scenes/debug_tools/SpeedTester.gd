extends Node

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

onready var body = $KinematicBody2D
onready var timer = $Timer
onready var label = $Label

var velocity = Vector2(64,64)

var move = true

func _ready():
    timer.wait_time = 1
    timer.start()


func _physics_process(delta):
    if move:
        # body.move_and_slide(velocity)
        body.move_and_collide(velocity * delta)

func _on_timeout():
    move = false
    label.text = "Time out"
#func _process(delta):
#    # Called every frame. Delta is time since last frame.
#    # Update game logic here.
#    pass
