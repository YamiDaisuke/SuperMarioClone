extends Node2D

const CoinScene = preload("res://scenes/world/items/Coin.tscn")

var available = true
var coinInstance

func _ready():
    self.coinInstance = CoinScene.instance()
    self.coinInstance.collide = false
    self.add_child(self.coinInstance)
    self.coinInstance.position.y = 0



func grant():
    coinInstance.emit_signal("coin_grabbed", coinInstance)
    coinInstance.consume(true, true, true)
    self.available = false

    return self.available

