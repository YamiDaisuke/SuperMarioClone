extends Node2D

signal coin_grabbed

const Player = preload("res://scenes/player/Player.gd")

export(int, 0, 1000000) var value = 1
export(bool) var collide = true

onready var animation_player = $OW/AnimationPlayer

func _ready():
    $OW/AnimationPlayer.current_animation = "Blink"
    $OW/AnimationPlayer.play()

    self.connect("coin_grabbed", Director, Director.COIN_GRABBED_FUNC)


func _on_Area2D_body_entered(body):
    if self.collide and body.get_parent() is Player:
        emit_signal("coin_grabbed", self)

