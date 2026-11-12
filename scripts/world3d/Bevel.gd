class_name Bevel
extends RefCounted
## Builds a box mesh with chamfered (beveled) edges and flat shading. Origin = centre of the box.
## Beveled edges catch the light, which gives the clean "toy" look of Overcooked-style props.

static var _cache := {}


static func box(size: Vector3, bevel: float = 0.04) -> ArrayMesh:
	var key := "%s|%s" % [size, bevel]
	if _cache.has(key):
		return _cache[key]
	var b := minf(bevel, minf(size.x, minf(size.y, size.z)) * 0.45)
	var h := size * 0.5
	var i := h - Vector3(b, b, b)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var signs := [-1.0, 1.0]
	# 6 faces
	for a in 3:
		var u := (a + 1) % 3
		var v := (a + 2) % 3
		for s in signs:
			var pts: Array[Vector3] = []
			for uv in [[-1.0, -1.0], [1.0, -1.0], [1.0, 1.0], [-1.0, 1.0]]:
				var p := Vector3.ZERO
				p[a] = s * h[a]
				p[u] = uv[0] * i[u]
				p[v] = uv[1] * i[v]
				pts.append(p)
			_quad(st, pts[0], pts[1], pts[2], pts[3])
	# 12 chamfer strips along the edges
	for a in 3:
		for bb in range(a + 1, 3):
			var c := 3 - a - bb
			for sa in signs:
				for sb in signs:
					var p1 := Vector3.ZERO
					p1[a] = sa * h[a]; p1[bb] = sb * i[bb]; p1[c] = -i[c]
					var p2 := p1
					p2[c] = i[c]
					var p3 := Vector3.ZERO
					p3[a] = sa * i[a]; p3[bb] = sb * h[bb]; p3[c] = i[c]
					var p4 := p3
					p4[c] = -i[c]
					_quad(st, p1, p2, p3, p4)
	# 8 corner triangles
	for sx in signs:
		for sy in signs:
			for sz in signs:
				_tri(st, Vector3(sx * h.x, sy * i.y, sz * i.z), Vector3(sx * i.x, sy * h.y, sz * i.z), Vector3(sx * i.x, sy * i.y, sz * h.z))
	var mesh := st.commit()
	_cache[key] = mesh
	return mesh


static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	_tri(st, a, b, c)
	_tri(st, a, c, d)


## Emits one triangle, wound clockwise as seen from outside (Godot's front face), with a flat normal.
static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	var n := (b - a).cross(c - a)
	var centroid := (a + b + c) / 3.0
	var out := n.normalized()
	if n.dot(centroid) > 0.0:
		# counter-clockwise from outside: swap to make it clockwise
		var t := b
		b = c
		c = t
	else:
		out = -out
	st.set_normal(out)
	st.add_vertex(a)
	st.set_normal(out)
	st.add_vertex(b)
	st.set_normal(out)
	st.add_vertex(c)
