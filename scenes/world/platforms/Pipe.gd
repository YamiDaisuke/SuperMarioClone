tool
extends Node2D

# Height without the opening
export(int) var height = 1

onready var tilemap = $TileMap

var tileset
var left_tile
var right_tile

func _ready():
    self.tileset = tilemap.get_tileset()
    self.left_tile = self.tileset.find_tile_by_name("pipes_foliage26")
    self.right_tile = self.tileset.find_tile_by_name("pipes_foliage27")
    for i in range(self.height):
        self.tilemap.set_cellv(Vector2(-1, i), self.left_tile)
        self.tilemap.set_cellv(Vector2(0, i), self.right_tile)

# func _process(delta):
#    # Called every frame. Delta is time since last frame.
#    # Update game logic here.
#    pass

"""
extends TileMap

var _tileset

func _ready():
    _tileset = get_tileset()
    set_process_input(true)

func _input(event):
    var tile_pos = world_to_map(event.pos)
    if event.is_action_pressed("add_tower"):
        set_cellv(tile_pos, _tileset.find_tile_by_name("FireTower"))
"""
