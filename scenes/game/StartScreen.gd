extends CanvasLayer

onready var Director = get_node("/root/Director")


func _process(delta):
    if Input.is_action_just_pressed("ui_accept"):
        Director.start_game()
