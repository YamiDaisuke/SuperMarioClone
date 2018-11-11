tool
extends Node2D

# Height without the opening
export(int) var height = 1 setget _set_height

var tilemap

var tileset
var left_tile
var right_tile

func _ready():
    self.tilemap = $TileMap
    self.draw_shaft()

func draw_shaft():
    if self.tilemap == null:
        return

    self.tileset = tilemap.get_tileset()
    self.left_tile = self.tileset.find_tile_by_name("pipes_foliage26")
    self.right_tile = self.tileset.find_tile_by_name("pipes_foliage27")
    for i in range(self.height):
        self.tilemap.set_cellv(Vector2(-1, i), self.left_tile)
        self.tilemap.set_cellv(Vector2(0, i), self.right_tile)

func _set_height(new_height):
    height = new_height
    if Engine.is_editor_hint():
        self.tilemap = $TileMap
        self.draw_shaft()

