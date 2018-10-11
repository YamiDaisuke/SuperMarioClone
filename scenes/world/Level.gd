extends Node

export (int) var time = 100

func _ready():
    $HUD.set_time(self.time)
    $HUD.set_score(0)
    $HUD.set_world("0 - 0")
    $HUD.set_player_name("FRANK")
    $HUD.set_coins(0)
    
    $Timer.start()

func _on_Player_died():
    print("Game Over...")
    get_tree().change_scene("res://scenes/game/GameOver.tscn")


func _on_Timer_timeout():
    self.time -= 1
    if self.time < 0:
        return $Player.die()
    
    $HUD.set_time(self.time)
    
