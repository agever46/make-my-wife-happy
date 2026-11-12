class_name HouseLayout
extends RefCounted
## The whole day-1 map as data. Edit this file to change the house; HouseBuilder turns it into 3D.
## Every character of MAP is one 1 m x 1 m tile (x grows to the right, z grows downwards / towards the camera).
##   k = kitchen tile    w = living-room wood    D = doorway (wood, with a gap in the east wall)
##   g = grass           p = stone path          . = nothing
## Cells k, w and D are "inside the house": walls are generated along every edge where inside meets outside.

const MAP := [
	"kkkkkkkwwwwwwwgggggg", # z 0  (north, back wall)
	"kkkkkkkwwwwwwwgggggg",
	"kkkkkkkwwwwwwwgggggg",
	"kkkkkkkwwwwwwwgggggg",
	"kkkkkkkwwwwwwwgggggg",
	"kkkkkkkwwwwwwDpppppp", # z 5  door row 1
	"kkkkkkkwwwwwwDpppppp", # z 6  door row 2
	"kkkkkkkwwwwwwwgggpgg",
	"kkkkkkkwwwwwwwgggggg",
	"kkkkkkkwwwwwwwgggggg",
	"kkkkkkkwwwwwwwgggggg", # z 10 (south, low cut-away wall)
]

const WALL_THICKNESS := 0.4
const WALL_HEIGHT := 2.4
## The south wall faces the camera, so it is kept low and never blocks the view.
const FRONT_WALL_HEIGHT := 0.55

## Half walls between kitchen and living room: x is the grid line, z0..z1 the range of cells.
const PARTITIONS := [
	{"x": 7.0, "z0": 0.0, "z1": 3.0},
	{"x": 7.0, "z0": 8.0, "z1": 11.0},
]

## Interactive stations. model = file name in res://assets/models/ (Blender export) or a built-in placeholder.
## cell = top-left cell, size = footprint in cells, rot = degrees around Y (model front is +Z), height = for the collider.
const STATIONS := [
	{"id": &"coffee_machine", "model": "Interact_CoffeeMachine", "cell": Vector2(3, 0), "size": Vector2(1, 1), "rot": 0.0, "height": 1.4, "bubble": 2.0},
	{"id": &"fridge", "model": "Interact_Fridge", "cell": Vector2(5, 0), "size": Vector2(1, 1), "rot": 0.0, "height": 1.9, "bubble": 2.6},
	{"id": &"trash_can", "model": "Interact_TrashCan", "cell": Vector2(0, 4), "size": Vector2(1, 1), "rot": 90.0, "height": 0.8, "bubble": 1.5},
	{"id": &"dumpster", "model": "Interact_Dumpster", "cell": Vector2(17, 8), "size": Vector2(2, 1), "rot": 180.0, "height": 1.2, "bubble": 2.0},
	# The wife sits on the couch. No collider of her own (the couch is solid); her zone reaches the floor in front of it.
	{"id": &"wife", "model": "Char_Wife", "cell": Vector2(9, 1.1), "size": Vector2(1, 1), "rot": 0.0, "height": 1.5, "bubble": 2.2,
		"solid": false, "shadow": false, "zone_margin": 1.3, "script": "wife"},
]

## Furniture and decoration without interaction.
const PROPS := [
	{"model": "Prop_Counter", "cell": Vector2(0, 0), "size": Vector2(1, 1), "rot": 0.0, "height": 1.0},
	{"model": "Prop_Counter", "cell": Vector2(1, 0), "size": Vector2(1, 1), "rot": 0.0, "height": 1.0},
	{"model": "Prop_Counter", "cell": Vector2(2, 0), "size": Vector2(1, 1), "rot": 0.0, "height": 1.0},
	{"model": "Prop_Counter", "cell": Vector2(4, 0), "size": Vector2(1, 1), "rot": 0.0, "height": 1.0},
	{"model": "Prop_Counter", "cell": Vector2(6, 0), "size": Vector2(1, 1), "rot": 0.0, "height": 1.0},
	{"model": "Prop_Rug", "cell": Vector2(8, 2.6), "size": Vector2(3, 2), "rot": 0.0, "height": 0.05, "solid": false, "shadow": false},
	{"model": "Prop_Couch", "cell": Vector2(8, 1), "size": Vector2(3, 1), "rot": 0.0, "height": 1.0},
	{"model": "Prop_CoffeeTable", "cell": Vector2(9, 3.4), "size": Vector2(1, 1), "rot": 0.0, "height": 0.5},
	{"model": "Prop_TV", "cell": Vector2(8.5, 7), "size": Vector2(2, 1), "rot": 180.0, "height": 1.2},
]

## Where the first player starts (cell).
const PLAYER_START := Vector2(7, 5)

## Where lost items (keys) can be hidden (cells, must be reachable).
const HIDING_SPOTS := [
	Vector2(2, 2), Vector2(5, 6), Vector2(1, 9), Vector2(12, 2), Vector2(11, 9),
	Vector2(8, 6), Vector2(16, 2), Vector2(15, 9), Vector2(19, 4),
]
