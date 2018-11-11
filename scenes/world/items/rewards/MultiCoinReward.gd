extends "res://scenes/world/items/rewards/CoinReward.gd"

export(float) var time = 2

func grant():
    coinInstance.animation_player.current_animation = "Pick"
    coinInstance.animation_player.play()
    coinInstance.emit_signal("coin_grabbed", coinInstance, false)

    if $Timer.is_stopped():
        $Timer.wait_time = self.time
        $Timer.start()

    return self.available

func _on_timer_end():
    self.available = false
