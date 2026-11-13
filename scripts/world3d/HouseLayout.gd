class_name HouseLayout
extends RefCounted
## The whole day-1 map as data. Edit this file to change the house; HouseBuilder turns it into 3D.
## Every character of MAP is one 1 m x 1 m tile (x grows to the right, z grows downwards / towards the camera).
##   k = kitchen tile    w = living-room wood    D = doorway (wood, with a gap in the east wall)
##   g = grass           p = stone path          r = road      R = road with a lane marking
## Cells k, w and D are "inside the house": walls are generated along every edge where inside meets outside.

const MAP := [
	"kkkkkkkwwwwwwwgggggrRr", # z 0
	"kkkkkkkwwwwwwwgggggrrr",
	"kkkkkkkwwwwwwwgggggrRr",
	"kkkkkkkwwwwwwwgggggrrr",
	"kkkkkkkwwwwwwwgggggrRr",
	"kkkkkkkwwwwwwDppppprrr", # z 5
	"kkkkkkkwwwwwwDppppprRr",
	"kkkkkkkwwwwwwwgggpgrrr",
	"kkkkkkkwwwwwwwgggggrRr",
	"kkkkkkkwwwwwwwgggggrrr",
	"kkkkkkkwwwwwwwgggggrRr", # z 10
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
	{"id": &"dumpster", "model": "Interact_Dumpster", "cell": Vector2(16, 8), "size": Vector2(2, 1), "rot": 180.0, "height": 1.2, "bubble": 2.0},
	{"id": &"stove", "model": "Interact_Stove", "cell": Vector2(2, 0), "size": Vector2(1, 1), "rot": 0.0, "height": 1.0, "bubble": 1.9},
	# Cooking: the wife cooks at the stove; the husband fetches ingredients from the pantry, the fridge and the garden.
	{"id": &"pantry", "model": "Interact_Pantry", "cell": Vector2(6, 0), "size": Vector2(1, 1), "rot": 0.0, "height": 1.7, "bubble": 2.3},
	{"id": &"tomato_bed", "model": "Interact_TomatoBed", "cell": Vector2(14, 2.9), "size": Vector2(1, 0.7), "rot": 0.0, "height": 0.5, "bubble": 1.4, "zone_margin": 0.9},
	{"id": &"carrot_bed", "model": "Interact_CarrotBed", "cell": Vector2(15.3, 2.9), "size": Vector2(0.9, 0.7), "rot": 0.0, "height": 0.5, "bubble": 1.4, "zone_margin": 0.9},
	{"id": &"herb_bed", "model": "Interact_HerbBed", "cell": Vector2(14, 4.35), "size": Vector2(1, 0.6), "rot": 0.0, "height": 0.5, "bubble": 1.4, "zone_margin": 0.9},
	# Chores stations. Kitchen: washing machine + sink. Yard: clothesline, mailbox, dog, car. Hall: leash hook.
	{"id": &"washing_machine", "model": "Interact_WashingMachine", "cell": Vector2(0, 7), "size": Vector2(1, 1), "rot": 90.0, "height": 0.95, "bubble": 1.6},
	{"id": &"sink", "model": "Interact_Sink", "cell": Vector2(1, 0), "size": Vector2(1, 1), "rot": 0.0, "height": 1.2, "bubble": 1.9},
	{"id": &"stain", "model": "Interact_Stain", "cell": Vector2(10, 4.5), "size": Vector2(1, 1), "rot": 0.0, "height": 0.05,
		"solid": false, "shadow": false, "needed_only": true, "bubble": 1.0},
	{"id": &"clothesline", "model": "Interact_Clothesline", "cell": Vector2(14.5, 1), "size": Vector2(2, 1), "rot": 0.0, "height": 1.9, "bubble": 2.5, "solid": false},
	{"id": &"mailbox", "model": "Interact_Mailbox", "cell": Vector2(17, 3), "size": Vector2(1, 1), "rot": 270.0, "height": 1.2, "bubble": 1.9},
	{"id": &"leash_hook", "model": "Interact_LeashHook", "cell": Vector2(13.6, 3), "size": Vector2(0.4, 1), "rot": 270.0, "height": 1.6, "bubble": 2.0, "zone_margin": 1.0},
	{"id": &"dog", "model": "Interact_Dog", "cell": Vector2(15, 7), "size": Vector2(1, 1), "rot": 0.0, "height": 0.8, "bubble": 1.4},
	{"id": &"car", "model": "Interact_Car", "cell": Vector2(14, 9), "size": Vector2(2, 1), "rot": 0.0, "height": 1.0, "bubble": 1.8},
	{"id": &"toy_box", "model": "Interact_ToyBox", "cell": Vector2(12, 9), "size": Vector2(1, 1), "rot": 0.0, "height": 0.6, "bubble": 1.4},
	# The wife sits on the couch. No collider of her own (the couch is solid); her zone reaches the floor in front of it.
	{"id": &"wife", "model": "Char_Wife", "cell": Vector2(9, 1.1), "size": Vector2(1, 1), "rot": 0.0, "height": 1.5, "bubble": 2.2,
		"solid": false, "shadow": false, "zone_margin": 1.3, "script": "wife"},
]

## Furniture and decoration without interaction.
const PROPS := [
	{"model": "Prop_Counter", "cell": Vector2(0, 0), "size": Vector2(1, 1), "rot": 0.0, "height": 1.0},
	{"model": "Prop_Counter", "cell": Vector2(4, 0), "size": Vector2(1, 1), "rot": 0.0, "height": 1.0},
	{"model": "Prop_DiningTable", "cell": Vector2(3, 7), "size": Vector2(2, 1), "rot": 0.0, "height": 0.8},
	{"model": "Prop_Chair", "cell": Vector2(3.2, 6.25), "size": Vector2(0.6, 0.6), "rot": 0.0, "height": 1.0},
	{"model": "Prop_Chair", "cell": Vector2(4.2, 6.25), "size": Vector2(0.6, 0.6), "rot": 0.0, "height": 1.0},
	{"model": "Prop_Chair", "cell": Vector2(3.2, 8.15), "size": Vector2(0.6, 0.6), "rot": 180.0, "height": 1.0},
	{"model": "Prop_Chair", "cell": Vector2(4.2, 8.15), "size": Vector2(0.6, 0.6), "rot": 180.0, "height": 1.0},
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
	Vector2(8, 6), Vector2(16, 2), Vector2(13, 9), Vector2(18, 3),
]

## The school bus event: the bus drives along the road (x), stops with its door at the end of the yard path,
## and the kids walk to their chairs. door_z = where each kid leaves the bus / enters the house (row of the door).
const BUS_ROAD_X := 20.5
const BUS_START_Z := -8.0
const BUS_STOP_Z := 4.0
const BUS_EXIT_Z := 22.0
const KIDS := [
	{"id": &"kid_a", "name": "Mia", "model": "Char_Kid_A", "seat": Vector2(3.5, 6.55), "door_z": 5.3},
	{"id": &"kid_b", "name": "Noah", "model": "Char_Kid_B", "seat": Vector2(4.5, 6.55), "door_z": 5.9},
]

## Where the kids run around and play after dinner (living room, away from the furniture).
const PLAY_POINTS := [
	Vector2(11.7, 2.6), Vector2(12.6, 4.2), Vector2(11.9, 6.3), Vector2(12.4, 8.2),
	Vector2(10.9, 9.2), Vector2(9.0, 9.3), Vector2(8.3, 8.4), Vector2(8.4, 5.8), Vector2(11.2, 5.6),
]

## Where the wife cooks, and the places she walks to while serving dinner (see Wife3D.gd).
const WIFE_COUCH := Vector3(9.5, 0.0, 1.6)
const WIFE_STOVE := Vector3(2.5, 0.0, 1.5)
const WIFE_TABLE := Vector3(2.35, 0.0, 7.5)
## Path from the couch to the stove and back (through the opening of the half wall at x = 7).
const WIFE_PATH_TO_STOVE := [Vector3(9.5, 0.0, 2.5), Vector3(8.3, 0.0, 3.5), Vector3(6.3, 0.0, 3.7), Vector3(3.6, 0.0, 2.6), Vector3(2.5, 0.0, 1.5)]
const WIFE_PATH_TO_TABLE := [Vector3(2.0, 0.0, 3.2), Vector3(2.0, 0.0, 6.0), Vector3(2.35, 0.0, 7.5)]
const WIFE_PATH_TO_COUCH := [Vector3(2.0, 0.0, 6.0), Vector3(2.4, 0.0, 3.8), Vector3(6.3, 0.0, 3.7), Vector3(8.3, 0.0, 3.5), Vector3(9.5, 0.0, 2.5), Vector3(9.5, 0.0, 1.6)]
