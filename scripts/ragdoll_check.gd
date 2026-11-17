extends SceneTree

func _initialize() -> void:
	call_deferred("_run_check")

func _run_check() -> void:
	var packed := load("res://Main.tscn") as PackedScene
	if packed == null:
		printerr("RAGDOLL CHECK FAILED: Main.tscn missing")
		quit(1)
		return
	var game := packed.instantiate()
	root.add_child(game)
	await process_frame
	await physics_frame
	var simulator := game.find_child("PhysicalBoneSimulator3D", true, false) as PhysicalBoneSimulator3D
	if simulator == null:
		printerr("RAGDOLL CHECK FAILED: simulator not constructed")
		quit(1)
		return
	var bodies := simulator.find_children("*", "PhysicalBone3D", true, false)
	var skeleton_names: PackedStringArray = []
	var skeleton := game.get("target_skeleton") as Skeleton3D
	if skeleton:
		for i in range(skeleton.get_bone_count()): skeleton_names.append(skeleton.get_bone_name(i))
	print("RAGDOLL SKELETON BONES: ", ", ".join(skeleton_names))
	print("RAGDOLL DEBUG: bodies=", bodies.size(), " bones=", game.get("target_skeleton").get_bone_count() if game.get("target_skeleton") else -1)
	for body in bodies:
		var pb := body as PhysicalBone3D
		print("RAGDOLL BONE: ", body.name, " bone_name=", pb.get("bone_name"), " id=", pb.get_bone_id())
	if bodies.size() < 10:
		printerr("RAGDOLL CHECK FAILED: too few physical bones: ", bodies.size())
		var missing_skeleton := game.get("target_skeleton") as Skeleton3D
		if missing_skeleton:
			var names: PackedStringArray = []
			for i in range(missing_skeleton.get_bone_count()): names.append(missing_skeleton.get_bone_name(i))
			printerr("RAGDOLL BONE NAMES: ", ", ".join(names))
		quit(1)
		return
	for body in bodies:
		var bone_body := body as PhysicalBone3D
		if bone_body.collision_layer != 2 or bone_body.collision_mask != 1:
			printerr("RAGDOLL CHECK FAILED: incorrect collision filtering on ", body.name)
			quit(1)
			return
		if bone_body.get_bone_id() < 0:
			printerr("RAGDOLL CHECK FAILED: bone not bound: ", body.name)
			quit(1)
			return
	for body in bodies:
		var bone_body := body as PhysicalBone3D
		var capsule_ok := false
		for child in bone_body.get_children():
			if child is CollisionShape3D:
				var shape_node := child as CollisionShape3D
				if shape_node.shape is CapsuleShape3D:
					var radius := (shape_node.shape as CapsuleShape3D).radius
					print("RAGDOLL COLLIDER: ", body.name, " radius=", radius)
					if radius >= 2.0: capsule_ok = true
		if not capsule_ok:
			printerr("RAGDOLL CHECK FAILED: collision capsule too small/missing on ", body.name, " child_count=", bone_body.get_child_count())
			quit(1)
			return
	var pelvis: PhysicalBone3D = bodies[0] as PhysicalBone3D
	var initial_pelvis_y := pelvis.global_position.y
	game.call("_kill_target", Vector3(0,1,-4), Vector3(0,0,1))
	for frame in range(30):
		await physics_frame
	var pelvis_delta_y := pelvis.global_position.y - initial_pelvis_y
	print("RAGDOLL VERTICAL DELTA: ", pelvis_delta_y)
	if absf(pelvis_delta_y) > 3.5:
		printerr("RAGDOLL CHECK FAILED: mannequin launched out of position, delta_y=", pelvis_delta_y)
		quit(1)
		return
	if not is_instance_valid(game.get("target")):
		printerr("RAGDOLL CHECK FAILED: target node disappeared after death")
		quit(1)
		return
	var target_node := game.get("target") as Node3D
	var meshes := target_node.find_children("*", "MeshInstance3D", true, false)
	if meshes.is_empty():
		printerr("RAGDOLL CHECK FAILED: target meshes missing after death")
		quit(1)
		return
	if target_node.get_node_or_null("ColisionObjetivo") == null:
		printerr("RAGDOLL CHECK FAILED: target root/visual hierarchy lost")
		quit(1)
		return
	var visible_mesh := false
	for mesh in meshes:
		if (mesh as MeshInstance3D).is_visible_in_tree(): visible_mesh = true
	if not visible_mesh:
		printerr("RAGDOLL CHECK FAILED: target became invisible after hit")
		quit(1)
		return
	var simulating := false
	for body in bodies:
		if (body as PhysicalBone3D).is_simulating_physics(): simulating = true
	if not simulating:
		printerr("RAGDOLL CHECK FAILED: simulation did not start")
		quit(1)
		return
	print("RAGDOLL CHECK OK: physical bones=", bodies.size(), "; simulation running")
	quit(0)
