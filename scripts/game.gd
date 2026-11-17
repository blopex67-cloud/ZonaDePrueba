extends Node3D

const PLAYER_SPEED := 5.2
const LOOK_SENS := 0.004
var player: CharacterBody3D
var camera: Camera3D
var target: Node3D
var target_dead := false
var ammo := 30
var reserve := 120
var health := 100
var reloading := false
var move_vector := Vector2.ZERO
var look_finger := -1
var last_look := Vector2.ZERO
var stick_finger := -1
var stick_origin := Vector2.ZERO
var fire_down := false
var fire_timer := 0.0
var hud: CanvasLayer
var ammo_label: Label
var status_label: Label
var health_bar: ProgressBar
var stick_base: Control
var stick_knob: Control
var sound_player: AudioStreamPlayer
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng_seed()
	_build_world()
	_build_player()
	_build_target()
	_build_hud()
	_build_audio()
	if OS.has_feature("android"):
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func _rng_seed() -> void:
	rng.randomize()

func _mat(color: Color, rough := 0.8, metal := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	m.metallic = metal
	return m

func _box(parent: Node, name: String, pos: Vector3, size: Vector3, color: Color, rough := 0.8, metal := 0.0) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.name = name
	var mesh := BoxMesh.new()
	mesh.size = size
	n.mesh = mesh
	n.position = pos
	n.material_override = _mat(color, rough, metal)
	parent.add_child(n)
	return n

func _build_world() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.07,0.13,0.2)
	sky_mat.sky_horizon_color = Color(0.42,0.48,0.52)
	sky_mat.ground_bottom_color = Color(0.12,0.13,0.14)
	sky_mat.ground_horizon_color = Color(0.42,0.48,0.52)
	sky.sky_material = sky_mat
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55,0.61,0.7)
	e.ambient_light_energy = 0.7
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48,-25,0)
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	add_child(sun)
	var floor_mesh := _box(self,"Piso",Vector3(0,-0.18,-9),Vector3(30,0.35,44),Color(0.16,0.19,0.21),0.92)
	floor_mesh.create_trimesh_collision()
	_box(self,"ParedFondo",Vector3(0,3,-30),Vector3(30,6,0.5),Color(0.24,0.29,0.33))
	_box(self,"ParedIzquierda",Vector3(-15,3,-9),Vector3(0.5,6,42),Color(0.19,0.23,0.27))
	_box(self,"ParedDerecha",Vector3(15,3,-9),Vector3(0.5,6,42),Color(0.19,0.23,0.27))
	for z in [-2.0,-9.0,-16.0,-23.0]:
		_box(self,"Viga",Vector3(0,5.3,z),Vector3(29,0.22,0.28),Color(0.27,0.32,0.36),0.55,0.45)
		for x in [-12.0,-8.0,8.0,12.0]:
			_box(self,"LuzIndustrial",Vector3(x,5.05,z),Vector3(1.8,0.09,0.35),Color(0.82,0.9,1.0),0.3)
	for i in range(11):
		var z := -4.0 - float(i)*2.2
		_box(self,"LineaPiso",Vector3(0,0.005,z),Vector3(0.055,0.012,1.0),Color(0.9,0.66,0.22),0.45,0.2)
	for x in [-10.5,10.5]:
		for z in [-7.0,-17.0,-25.0]:
			var crate := _box(self,"Cobertura",Vector3(x,0.8,z),Vector3(2.2,1.6,2.2),Color(0.25,0.3,0.32),0.82)
			crate.create_trimesh_collision()

func _build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Jugador"
	player.position = Vector3(0,0.15,7)
	add_child(player)
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.38
	capsule.height = 1.75
	collision.shape = capsule
	collision.position.y = 0.86
	player.add_child(collision)
	var pivot := Node3D.new()
	pivot.name = "Vista"
	pivot.position.y = 1.55
	player.add_child(pivot)
	camera = Camera3D.new()
	camera.current = true
	camera.fov = 78
	pivot.add_child(camera)
	# Arma de prueba de geometría original; se reemplazará por el asset seleccionado tras validar licencia.
	var gun := _box(camera,"ArmaPlaceholder",Vector3(0.32,-0.28,-0.62),Vector3(0.18,0.16,0.66),Color(0.12,0.15,0.17),0.4,0.75)
	_box(gun,"Empuñadura",Vector3(0,-0.13,0.1),Vector3(0.12,0.25,0.14),Color(0.09,0.1,0.1),0.65)
	_box(gun,"Mira",Vector3(0,0.115,-0.12),Vector3(0.08,0.06,0.2),Color(0.2,0.24,0.26),0.4,0.7)

func _build_target() -> void:
	target = Node3D.new()
	target.name = "ObjetivoDePrueba"
	target.position = Vector3(0,0,-12)
	add_child(target)
	# Dummy provisional articulado para validar disparo y ragdoll antes de incorporar el personaje riggeado.
	var torso := _rigid_part("Torso",Vector3(0,1.2,0),Vector3(0.62,0.8,0.32),Color(0.23,0.31,0.36),1.5)
	var head := _rigid_part("CascoCabeza",Vector3(0,1.86,0),Vector3(0.4,0.4,0.38),Color(0.32,0.38,0.4),0.5)
	var chest := _rigid_part("Chaleco",Vector3(0,1.27,-0.18),Vector3(0.66,0.52,0.12),Color(0.14,0.2,0.2),0.3)
	var left_arm := _rigid_part("BrazoIzquierdo",Vector3(-0.46,1.24,0),Vector3(0.2,0.72,0.22),Color(0.3,0.35,0.35),0.4)
	var right_arm := _rigid_part("BrazoDerecho",Vector3(0.46,1.24,0),Vector3(0.2,0.72,0.22),Color(0.3,0.35,0.35),0.4)
	var left_leg := _rigid_part("PiernaIzquierda",Vector3(-0.17,0.45,0),Vector3(0.24,0.78,0.3),Color(0.18,0.23,0.24),0.2)
	var right_leg := _rigid_part("PiernaDerecha",Vector3(0.17,0.45,0),Vector3(0.24,0.78,0.3),Color(0.18,0.23,0.24),0.2)
	var weapon := _rigid_part("Rifle",Vector3(0.44,1.03,-0.3),Vector3(0.14,0.14,0.82),Color(0.08,0.09,0.1),0.55)
	for p in [torso,head,chest,left_arm,right_arm,left_leg,right_leg,weapon]:
		p.freeze = true
		p.sleeping = true

func _rigid_part(n: String, pos: Vector3, size: Vector3, color: Color, _dummy: float) -> RigidBody3D:
	var body := RigidBody3D.new()
	body.name = n
	body.position = pos
	body.mass = 1.0
	body.continuous_cd = true
	var mesh := BoxMesh.new()
	mesh.size = size
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = _mat(color,0.65,0.15)
	body.add_child(visual)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	target.add_child(body)
	return body

func _build_audio() -> void:
	sound_player = AudioStreamPlayer.new()
	sound_player.volume_db = -7
	add_child(sound_player)
	var wav := AudioStreamWAV.new()
	var rate := 22050
	var samples := PackedByteArray()
	for i in range(2205):
		var t := float(i)/rate
		var envelope := exp(-t*42.0)
		var sample := sin(TAU*(95.0+35.0*t)*t)*envelope*0.55
		var value := int(clampf(sample,-1.0,1.0)*32767.0)
		samples.append(value & 255)
		samples.append((value >> 8) & 255)
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = samples
	sound_player.stream = wav

func _build_hud() -> void:
	hud = CanvasLayer.new()
	add_child(hud)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.add_child(root)
	var top := _panel(root,Vector2(22,18),Vector2(330,76),Color(0.02,0.035,0.05,0.78))
	var title := _label(top,"ZONA DE PRUEBA",20,Color(0.86,0.92,0.96),Vector2(15,9),Vector2(280,26))
	title.add_theme_font_size_override("font_size",18)
	var sub := _label(top,"OPERACIÓN • SECTOR 04",13,Color(0.37,0.75,0.86),Vector2(15,42),Vector2(260,18))
	var info := _panel(root,Vector2(22,106),Vector2(200,82),Color(0.02,0.035,0.05,0.65))
	_label(info,"SALUD",12,Color(0.7,0.78,0.82),Vector2(12,8),Vector2(140,18))
	health_bar = ProgressBar.new()
	health_bar.position = Vector2(12,32)
	health_bar.size = Vector2(170,18)
	health_bar.max_value = 100
	health_bar.value = 100
	health_bar.show_percentage = false
	info.add_child(health_bar)
	status_label = _label(info,"OBJETIVO: ACTIVO",12,Color(0.5,0.85,0.64),Vector2(12,56),Vector2(180,18))
	var cross := Label.new()
	cross.text = "+"
	cross.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cross.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cross.add_theme_font_size_override("font_size",28)
	cross.add_theme_color_override("font_color",Color(0.9,0.95,1,0.92))
	cross.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	cross.position = Vector2(-18,-22)
	cross.size = Vector2(36,44)
	root.add_child(cross)
	var right := _panel(root,Vector2(0,0),Vector2(220,88),Color(0.02,0.035,0.05,0.76))
	right.anchor_left = 1
	right.anchor_right = 1
	right.offset_left = -242
	right.offset_top = 18
	right.offset_right = -22
	right.offset_bottom = 106
	_label(right,"RIFLE DE ASALTO",12,Color(0.48,0.78,0.87),Vector2(14,8),Vector2(190,20))
	ammo_label = _label(right,"30  /  120",23,Color(0.94,0.96,0.98),Vector2(14,30),Vector2(190,38))
	var hint := _label(root,"MOVER  •  ARRASTRA IZQUIERDA     MIRAR  •  ARRASTRA DERECHA",12,Color(0.75,0.82,0.86,0.72),Vector2(0,0),Vector2(560,22))
	hint.anchor_left = 0.5
	hint.anchor_right = 0.5
	hint.offset_left = -280
	hint.offset_right = 280
	hint.anchor_top = 1
	hint.anchor_bottom = 1
	hint.offset_top = -36
	hint.offset_bottom = -14
	stick_base = _panel(root,Vector2(34,0),Vector2(154,154),Color(0.15,0.23,0.29,0.48))
	stick_base.anchor_top = 1
	stick_base.anchor_bottom = 1
	stick_base.offset_top = -194
	stick_base.offset_bottom = -40
	stick_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stick_knob = _panel(stick_base,Vector2(45,45),Vector2(64,64),Color(0.38,0.59,0.66,0.78))
	stick_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fire := _button(root,"FIRE",Vector2(0,0),Vector2(102,102),Color(0.67,0.18,0.14,0.9))
	fire.anchor_left=1; fire.anchor_right=1; fire.anchor_top=1; fire.anchor_bottom=1
	fire.offset_left=-148; fire.offset_right=-46; fire.offset_top=-160; fire.offset_bottom=-58
	fire.button_down.connect(func(): fire_down=true)
	fire.button_up.connect(func(): fire_down=false)
	var reload := _button(root,"RECARGAR",Vector2(0,0),Vector2(112,52),Color(0.16,0.26,0.31,0.92))
	reload.anchor_left=1; reload.anchor_right=1; reload.anchor_top=1; reload.anchor_bottom=1
	reload.offset_left=-274; reload.offset_right=-162; reload.offset_top=-128; reload.offset_bottom=-76
	reload.pressed.connect(_reload)
	var aim := _button(root,"APUNTAR",Vector2(0,0),Vector2(94,50),Color(0.13,0.29,0.36,0.92))
	aim.anchor_left=1; aim.anchor_right=1; aim.anchor_top=1; aim.anchor_bottom=1
	aim.offset_left=-270; aim.offset_right=-176; aim.offset_top=-65; aim.offset_bottom=-15
	aim.button_down.connect(func(): camera.fov=60)
	aim.button_up.connect(func(): camera.fov=78)

func _panel(parent: Node, pos: Vector2, size: Vector2, color: Color) -> Panel:
	var p := Panel.new()
	p.position=pos; p.size=size
	var style := StyleBoxFlat.new()
	style.bg_color=color
	style.corner_radius_top_left=12; style.corner_radius_top_right=12
	style.corner_radius_bottom_left=12; style.corner_radius_bottom_right=12
	p.add_theme_stylebox_override("panel",style)
	parent.add_child(p)
	return p

func _label(parent: Node, text: String, font_size: int, color: Color, pos: Vector2, size: Vector2) -> Label:
	var l := Label.new()
	l.text=text; l.position=pos; l.size=size
	l.add_theme_font_size_override("font_size",font_size)
	l.add_theme_color_override("font_color",color)
	parent.add_child(l)
	return l

func _button(parent: Node, text: String, pos: Vector2, size: Vector2, color: Color) -> Button:
	var b := Button.new()
	b.text=text; b.position=pos; b.size=size
	b.add_theme_font_size_override("font_size",15)
	b.add_theme_color_override("font_color",Color(0.94,0.97,0.99))
	var style := StyleBoxFlat.new()
	style.bg_color=color
	style.corner_radius_top_left=28; style.corner_radius_top_right=28
	style.corner_radius_bottom_left=28; style.corner_radius_bottom_right=28
	b.add_theme_stylebox_override("normal",style)
	var hover := style.duplicate(); hover.bg_color=color.lightened(0.15)
	b.add_theme_stylebox_override("hover",hover)
	parent.add_child(b)
	return b

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.x < get_viewport().get_visible_rect().size.x*0.44 and event.position.y > get_viewport().get_visible_rect().size.y*0.48:
				stick_finger=event.index
				stick_origin=event.position
				_set_stick(event.position)
			elif event.position.x > get_viewport().get_visible_rect().size.x*0.48:
				look_finger=event.index
				last_look=event.position
		else:
			if event.index==stick_finger:
				stick_finger=-1; move_vector=Vector2.ZERO; stick_knob.position=Vector2(45,45)
			if event.index==look_finger: look_finger=-1
	elif event is InputEventScreenDrag:
		if event.index==stick_finger: _set_stick(event.position)
		elif event.index==look_finger:
			var delta := event.position-last_look
			_rotate_view(delta)
			last_look=event.position
	elif event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT and not OS.has_feature("android"):
		_shoot()
	elif event is InputEventMouseMotion and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED:
		_rotate_view(event.relative)
	elif event is InputEventKey and event.pressed and event.keycode==KEY_R:
		_reload()

func _set_stick(at: Vector2) -> void:
	var delta := at-stick_origin
	if delta.length()>48: delta=delta.normalized()*48
	move_vector=Vector2(delta.x,-delta.y)/48.0
	stick_knob.position=Vector2(45,45)+delta

func _rotate_view(delta: Vector2) -> void:
	player.rotate_y(-delta.x*LOOK_SENS*2.0)
	camera.rotation.x=clampf(camera.rotation.x-delta.y*LOOK_SENS*2.0,-1.1,1.1)

func _process(delta: float) -> void:
	if fire_down:
		fire_timer-=delta
		if fire_timer<=0:
			_shoot(); fire_timer=0.16
	if not OS.has_feature("android") and Input.is_key_pressed(KEY_W): move_vector.y=1
	if not OS.has_feature("android") and Input.is_key_pressed(KEY_S): move_vector.y=-1
	if not OS.has_feature("android") and Input.is_key_pressed(KEY_A): move_vector.x=-1
	if not OS.has_feature("android") and Input.is_key_pressed(KEY_D): move_vector.x=1
	if not OS.has_feature("android") and Input.is_key_pressed(KEY_ESCAPE): Input.mouse_mode=Input.MOUSE_MODE_VISIBLE

func _physics_process(_delta: float) -> void:
	var direction := (player.transform.basis*Vector3(move_vector.x,0,-move_vector.y)).normalized()
	player.velocity.x=direction.x*PLAYER_SPEED
	player.velocity.z=direction.z*PLAYER_SPEED
	if not player.is_on_floor(): player.velocity.y-=19.6*get_physics_process_delta_time()
	else: player.velocity.y=0
	player.move_and_slide()

func _shoot() -> void:
	if reloading or ammo<=0: return
	ammo-=1
	ammo_label.text="%02d  /  %03d" % [ammo,reserve]
	sound_player.play()
	var from := camera.global_position
	var to := from-camera.global_transform.basis.z*100.0
	var query := PhysicsRayQueryParameters3D.create(from,to)
	query.collide_with_areas=true
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty() and not target_dead and target.is_ancestor_of(hit.collider):
		_kill_target(hit.position,hit.normal)

func _kill_target(point: Vector3, normal: Vector3) -> void:
	target_dead=true
	status_label.text="OBJETIVO: NEUTRALIZADO"
	status_label.add_theme_color_override("font_color",Color(0.92,0.4,0.3))
	for child in target.get_children():
		if child is RigidBody3D:
			child.freeze=false
			child.sleeping=false
			child.apply_impulse((child.global_position-point).normalized()*rng.randf_range(1.5,3.5)+normal*0.8)
			child.apply_torque_impulse(Vector3(rng.randf_range(-1.5,1.5),rng.randf_range(-1.2,1.2),rng.randf_range(-1.5,1.5)))

func _reload() -> void:
	if reloading or ammo==30 or reserve<=0: return
	reloading=true
	status_label.text="RECARGANDO..."
	await get_tree().create_timer(1.2).timeout
	var take := mini(30-ammo,reserve)
	ammo+=take; reserve-=take
	ammo_label.text="%02d  /  %03d" % [ammo,reserve]
	if not target_dead: status_label.text="OBJETIVO: ACTIVO"
	reloading=false
