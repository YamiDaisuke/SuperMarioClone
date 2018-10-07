extends Node2D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
    $OW/AnimationPlayer.current_animation = "Blink"
    $OW/AnimationPlayer.play()


