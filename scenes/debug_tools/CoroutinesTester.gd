extends Node

onready var Coroutine = get_node("/root/Coroutines") # preload("res://scripts/coroutines.gd").new()

func _ready():
    self.add_child(Coroutine)
    Coroutine.start(one())
    print("Am I blocked???")
    print("No I'm not")
#    Coroutine.start(two())
    print("How about now??")


func one():
    print("1 Start....")
    var i = 0
    while true:
        print("1 Step %d delta %f" % [i, Coroutine.process_delta])
        i += 1
#        yield(get_tree().create_timer(5.0), "timeout")
        yield(Coroutine.wait_for_frames(1), "completed")


func two():
    print("2 Start....")
    var i = 0
    while true:
        print("2 Step %d" % i)
        i += 1
        yield(get_tree().create_timer(3.0), "timeout")
