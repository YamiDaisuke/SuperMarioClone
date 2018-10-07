extends "res://scripts/state_machine.gd"

const State = preload("res://scripts/state_machine.gd").State
const Player = preload("res://scenes/player/Player.gd")

onready var Coroutines = get_node("/root/Coroutines")

onready var idle_state = Idle.new(self)
onready var walk_state = Walk.new(self)

var start_point
var end_point

var player

func _ready():
    var start_point = $start
    var end_point = $end
    
    if start_point != null and start_point is Area2D:
        start_point.connect("body_entered", self, "_on_enter_start")
    else:
        printerr("Start point not supplied %s" % end_point)
        
    if end_point != null and end_point is Area2D:
        end_point.connect("body_entered", self, "_on_enter_end")
    else:
        printerr("End point not supplied: %s" % end_point)
        

func _on_enter_start(body):
    if body.get_parent() is Player:
        self.player = body.get_parent()
        Coroutines.start(self.wait_to_fall())


func _on_enter_end(body):
    if body.get_parent() is Player:
        self.change_state(self.idle_state)
        
        
func wait_to_fall():
                          
    while not self.player.is_grounded():
        yield(Coroutines.wait_for_frames(1), "completed")
    
    yield(Coroutines.wait_for_frames(1), "completed")
    self.change_state(self.walk_state)
        
        
class Idle extends State:

    func _init(parent).(parent):
        self.name = "Idle"
        
        
class Walk extends State:
    
    var player 
    
    func _init(parent).(parent):
        self.name = "Walk"
        
    
    func on_enter():
        self.player = self.parent.player
        self.player.start_cinematic_cut()
        self.player.animation_player.play()
        self.player.animation_player.current_animation = "Walk"
                    
        
    func physics_step(delta):
        self.player.body.move_and_slide(Vector2(12000,0) * delta)
        
        
    func on_exit():
        self.player.animation_player.current_animation = "Idle"