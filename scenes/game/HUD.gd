extends Node

signal hud_ready

var player_name
var score
var coins
var world
var time

func _ready():
    self.player_name = $Container/Score/PlayerName
    self.score = $Container/Score/Highscore
    self.coins = $Container/Coins/Coins
    self.world = $Container/World/World
    self.time = $Container/Time/Time
    
    self.emit_signal("hud_ready")


func set_player_name(name):
    self.player_name.text = name    


func set_coins(count):
    self.coins.text = "x%02d" % count
    

func set_score(score):
    self.score.text = "%06d" % score
    

func set_world(world_name):
    self.world.text = world_name
    

func set_time(current_time):
    self.time.text = "%03d" % current_time
        