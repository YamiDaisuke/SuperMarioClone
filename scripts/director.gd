extends Node

enum LevelType { OVER_WORLD, UNDER_WORLD, CASTLE }

const LifeLost = "res://scenes/game/LifeLost.tscn"
const GameOver = "res://scenes/game/GameOver.tscn"
const EndScene = "res://scenes/game/EndScene.tscn"


const HIT_POLE_FUNC = "_on_finish_pole_hit"
const LEVEL_FINISHED_FUNC = "_on_level_finished"
const PLAYER_DIED_FUNC = "_on_player_died"
const COIN_GRABBED_FUNC = "_on_coin_grabbed"

var HUD = preload("res://scenes/game/HUD.tscn")

export(int, 100000000) var new_life_point_limit = 100
export(int, 100000000) var points_per_coin = 200

onready var Coroutines = get_node("/root/Coroutines")
onready var level_start_scrn = preload("res://scenes/game/LevelStart.tscn")
onready var timer = Timer.new()

var levels = []
var lives = 3
var score = 4540 setget _set_score
var coins = 0 setget _set_coins
var player_status

var current_level = null
var time_count = 0

var hud_instance

func _ready():
    # TODO: Load from a config file
    var l1 = LevelInfo.new()
    l1.number = 0
    l1.name = "1 - 4"
    l1.time = 400
    l1.type = OVER_WORLD
    l1.pole_points = 2000
    l1.scene = "res://scenes/world/Levels/Level0.tscn"

    var l2 = LevelInfo.new()
    l2.number = 1
    l2.name = "1 - 2"
    l2.time = 400
    l2.type = UNDER_WORLD
    l2.pole_points = 2000
    l2.scene = "res://scenes/world/Levels/Level1.tscn"

    levels.append(l1)
    levels.append(l2)

    timer.connect("timeout",self,"_on_timer_timeout")
    timer.wait_time = 1
    timer.one_shot = false

    add_child(timer)


func start_game():
    var level = levels[0]
    self.current_level = level

    self.hud_instance = HUD.instance()
    self.hud_instance.connect("hud_ready", self, "set_hud_data")
    get_tree().get_root().add_child(self.hud_instance)

    Coroutines.start(self.start_level())


func start_level():
    self.time_count = self.current_level.time
    get_tree().change_scene(self.current_level.scene)
    var start_instance = self.level_start_scrn.instance()
    add_child(start_instance)

    yield(Coroutines.wait_for_seconds(2), "completed")
    start_instance.queue_free()
    yield(Coroutines.wait_for_seconds(1), "completed")

    timer.start()

func _set_score(value):
    score = value
    self.hud_instance.set_score(self.score)


func _set_coins(value):
    coins = value
    self.hud_instance.set_coins(self.coins)


func set_hud_data():
    # TODO: Player name?
    self.hud_instance.set_player_name("MARIO")
    self.hud_instance.set_score(self.score)
    self.hud_instance.set_coins(self.coins)
    self.hud_instance.set_world(self.current_level.name)
    self.hud_instance.set_time(self.current_level.time)


func _on_finish_pole_hit(height):
    var points = self.current_level.pole_points * height
    self.score += points
    self.timer.stop()


func _on_player_died():
    self.timer.stop()
    self.lives += -1

    if self.lives < 0:
        get_tree().change_scene(self.EndScene)
    else:
        self.set_hud_data()
        Coroutines.start(self.start_level())


func _on_coin_grabbed(coin, free = true):
    self.coins += coin.value
    if self.coins == self.new_life_point_limit:
        self.lives += 1
        self.coins = 0

    self.score += coin.value * self.points_per_coin
    # TODO: Animate?
    if free:
        coin.queue_free()


func _on_level_finished():
    if self.current_level.number >= levels.size() - 1:
        get_tree().change_scene(self.EndScene)
    else:
        var next = levels[self.current_level.number+1]
        self.current_level = next
        self.set_hud_data()
        Coroutines.start(self.start_level())



func _on_timer_timeout():
    self.time_count -= 1
    if self.time_count < 0:
        print("End...")
        self.time_count = 0
        self._on_player_died()

    self.hud_instance.set_time(self.time_count)


class LevelInfo:
    var number
    var name
    var time
    var type
    var pole_points
    var scene
