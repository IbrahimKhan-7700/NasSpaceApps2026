extends Node3D
## Builds the flat-shaded low-poly Mars terrain mesh and its collision.

const SIZE := 470.0
const SEG := 170

func _ready() -> void:
	var step := SIZE / SEG
	var half := SIZE * 0.5
	var hs := PackedFloat32Array()
	hs.resize((SEG + 1) * (SEG + 1))
	for j in SEG + 1:
		for i in SEG + 1:
			hs[j * (SEG + 1) + i] = WorldData.height_at(-half + i * step, -half + j * step)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	for j in SEG:
		for i in SEG:
			var x0 := -half + i * step
			var z0 := -half + j * step
			var v00 := Vector3(x0, hs[j * (SEG + 1) + i], z0)
			var v10 := Vector3(x0 + step, hs[j * (SEG + 1) + i + 1], z0)
			var v01 := Vector3(x0, hs[(j + 1) * (SEG + 1) + i], z0 + step)
			var v11 := Vector3(x0 + step, hs[(j + 1) * (SEG + 1) + i + 1], z0 + step)
			for v in [v00, v10, v01, v10, v11, v01]:
				st.set_color(WorldData.color_at(v.x, v.z, v.y))
				st.add_vertex(v)
	st.generate_normals()
	var mesh := st.commit()
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.vertex_color_is_srgb = true
	m.roughness = 1.0
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	add_child(mi)
	mi.create_trimesh_collision()
