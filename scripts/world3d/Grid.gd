class_name Grid
extends RefCounted
## The house sits on a grid of 1 m cells. x = east, z = south (towards the camera), y = up.

const CELL := 1.0


## World position of the CENTRE of a rectangle of cells (cell = top-left corner, size in cells), at floor level.
static func center(cell: Vector2, size: Vector2 = Vector2.ONE) -> Vector3:
	return Vector3((cell.x + size.x * 0.5) * CELL, 0.0, (cell.y + size.y * 0.5) * CELL)
