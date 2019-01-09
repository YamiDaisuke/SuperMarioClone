extends Node2D

signal coin_grabbed

const Player = preload("res://scenes/player/Player.gd")

export(int, 0, 1000000) var value = 1
export(bool) var collide = true
export (AudioStream) var grab_fx

onready var animation_player = $OW/AnimationPlayer
onready var audio_player = $AudioStreamPlayer

func _ready():
    self.animation_player.current_animation = "Blink"
    self.animation_player.play()

    self.connect("coin_grabbed", Director, Director.COIN_GRABBED_FUNC)


func _on_Area2D_body_entered(body):
    if self.collide and body.get_parent().is_in_group("player"):
        emit_signal("coin_grabbed", self)
        self.consume(false, true, true)


func consume(animate, play_sound, dequeue):
    Coroutines.start(consume_coroutine(animate, play_sound, dequeue))


func consume_coroutine(animate, play_sound, dequeue):
    var wait_time = 0
    if animate:
        self.animation_player.stop()
        self.animation_player.current_animation = "Pick"
        self.animation_player.play()
        wait_time = self.animation_player.current_animation_length
    else:
        self.hide()

    if play_sound:
        self.audio_player.stream = grab_fx
        self.audio_player.play()
        wait_time = max(wait_time, self.audio_player.stream.get_length())

    yield(Coroutines.wait_for_seconds(wait_time), "completed")

    if dequeue:
        self.queue_free()


