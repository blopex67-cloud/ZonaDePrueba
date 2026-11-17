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
	print("RAGDOLL DEBUG: bodies=", bodies.size(), " bones=", game.get("target_skeleton").get_bone_count() if game.get("target_skeleton") else -1)
	for body in bodies:
		var pb := body as PhysicalBone3D
		print("RAGDOLL BONE: ", body.name, " bone_name=", pb.get("bone_name"), " id=", pb.get_bone_id())
	if bodies.size() < 10:
		printerr("RAGDOLL CHECK FAILED: too few physical bones: ", bodies.size())
		var skeleton := game.get("target_skeleton") as Skeleton3D
		if skeleton:
			var names: PackedStringArray = []
			for i in range(skeleton.get_bone_count()): names.append(skeleton.get_bone_name(i))
			printerr("RAGDOLL BONE NAMES: ", ", ".join(names))
		quit(1)
		return
	for body in bodies:
		if (body as PhysicalBone3D).get_bone_id() < 0:
			printerr("RAGDOLL CHECK FAILED: bone not bound: ", body.name)
			quit(1)
			return
	game.call("_kill_target", Vector3(0,1,-4), Vector3(0,0,1))
	await physics_frame
	await physics_frame
	var simulating := false
	for body in bodies:
		if (body as PhysicalBone3D).is_simulating_physics(): simulating = true
	if not simulating:
		printerr("RAGDOLL CHECK FAILED: simulation did not start")
		quit(1)
		return
	print("RAGDOLL CHECK OK: physical bones=", bodies.size(), "; simulation running")
	quit(0)
