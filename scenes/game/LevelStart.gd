extends CanvasLayer

onready var Director = get_node("/root/Director")

func _ready():
    $Container/Lives.text = "     x  %d" % Director.lives
    $Container/World.text = "World %s" % Director.current_level.name



