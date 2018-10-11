extends Node

onready var Director = get_node("/root/Director")

signal level_finished

var definition = null

func _ready():
    print("Connecting! %s --- %s" % [$FinishPole, Director])
    $FinishPole.connect("hit_pole", Director, Director.HIT_POLE_FUNC)
    $ExitWalk.connect("finished", self, "_on_exit_walk_end")
    self.connect("level_finished", Director, Director.LEVEL_FINISHED_FUNC)
    

func _on_exit_walk_end():
    self.emit_signal("level_finished")