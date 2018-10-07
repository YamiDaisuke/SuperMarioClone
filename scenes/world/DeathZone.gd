extends Area2D

const Player = preload("res://scenes/player/Player.gd")


func _on_DeathZone_body_entered(body):
    if body.get_parent() is Player:
        body.get_parent().die()
