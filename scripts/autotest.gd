extends Node
## Developer smoke test: godot --path . -- --autotest  (saves screenshots to user://shots)
func run(main: Node3D) -> void:
	DirAccess.make_dir_recursive_absolute("user://shots")
	await get_tree().create_timer(1.0).timeout
	main.begin()
	var spots := ["base", "greenhouse", "crash", "anomaly", "hollow", "ridge"]
	for id in spots:
		main.teleport_to(id)
		await get_tree().create_timer(2.2).timeout
		get_viewport().get_texture().get_image().save_png("user://shots/%s.png" % id)
	main.player.global_position = Vector3(54, 1, -46)
	main.player.yaw = 1.57
	main.player.cam_dist_t = 4.0
	main.toggle_night()
	await get_tree().create_timer(2.5).timeout
	get_viewport().get_texture().get_image().save_png("user://shots/greenhouse_night.png")
	main.toggle_night()
	main.ui.open_places()
	await get_tree().create_timer(1.0).timeout
	get_viewport().get_texture().get_image().save_png("user://shots/places.png")
	print("AUTOTEST DONE")
	get_tree().quit()
