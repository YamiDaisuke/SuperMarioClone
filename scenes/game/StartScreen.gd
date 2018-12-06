extends CanvasLayer

func _process(delta):
    if Input.is_action_just_pressed("ui_accept"):
        Director.start_game()
