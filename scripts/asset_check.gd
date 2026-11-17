extends SceneTree

func _initialize() -> void:
	call_deferred("_run_checks")

func _run_checks() -> void:
	var weapon_scene := load("res://assets/fps_ak-74m_animations.glb") as PackedScene
	if weapon_scene == null:
		printerr("ASSET CHECK FAILED: weapon PackedScene not imported")
		quit(1)
		return
	var weapon := weapon_scene.instantiate()
	root.add_child(weapon)
	var weapon_anim := weapon.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if weapon_anim == null:
		printerr("ASSET CHECK FAILED: FPS weapon AnimationPlayer missing")
		quit(1)
		return
	var weapon_names := weapon_anim.get_animation_list()
	for required in ["Idle", "Shot", "Reload"]:
		var found := false
		for name in weapon_names:
			if String(name).contains(required): found = true
		if not found:
			printerr("ASSET CHECK FAILED: weapon animation missing: ", required, " | ", weapon_names)
			quit(1)
			return
	var soldier_scene := load("res://assets/police.glb") as PackedScene
	if soldier_scene == null:
		printerr("ASSET CHECK FAILED: soldier PackedScene not imported")
		quit(1)
		return
	var soldier := soldier_scene.instantiate()
	root.add_child(soldier)
	var skeleton := soldier.find_child("Skeleton3D", true, false) as Skeleton3D
	var meshes := soldier.find_children("*", "MeshInstance3D", true, false)
	if skeleton == null or skeleton.get_bone_count() < 20 or meshes.is_empty():
		printerr("ASSET CHECK FAILED: soldier skeleton/mesh missing, bones=", skeleton.get_bone_count() if skeleton else -1, " meshes=", meshes.size())
		quit(1)
		return
	print("ASSET CHECK OK: FPS weapon animations=", weapon_names.size(), "; soldier bones=", skeleton.get_bone_count(), "; meshes=", meshes.size())
	quit(0)
