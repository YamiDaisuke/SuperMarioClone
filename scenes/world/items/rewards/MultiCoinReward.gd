extends "res://scenes/world/items/rewards/CoinReward.gd"

export(float) var time = 2

func grant():
    coinInstance.emit_signal("coin_grabbed", coinInstance)
    coinInstance.consume(true, true, !self.available)

    if $Timer.is_stopped():
        $Timer.wait_time = self.time
        $Timer.start()

    return self.available

func _on_timer_end():
    self.available = false
