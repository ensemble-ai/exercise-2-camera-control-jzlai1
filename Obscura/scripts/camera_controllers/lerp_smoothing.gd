class_name LerpSmoothing
extends CameraControllerBase

@export var box_width: float = 5.0
@export var box_height: float = 5.0
@export var follow_speed: float = 7.5
@export var catchup_speed: float = 15.0
@export var leash_distance: float = 7.0

func _ready() -> void:
	super()
	reset_position()

func _process(delta: float) -> void:
	if !current:
		reset_position()
		return
	
	if draw_camera_logic:
		draw_logic()

	update_camera_position(delta)
	super(delta)

func update_camera_position(delta: float) -> void:
	var target_position = Vector3(target.global_position.x, position.y, target.global_position.z)
	var distance_to_target = position.distance_to(target_position)

	# Adjust position based on leash distance
	if distance_to_target >= leash_distance:
		position = position.move_toward(target_position, distance_to_target - leash_distance)

	if distance_to_target > 0:
		# Determine speed based on player movement status
		var movement_speed = follow_speed
		if target.velocity == Vector3.ZERO:
			movement_speed = catchup_speed
		var move_distance = min(movement_speed * delta, distance_to_target)
		position = position.move_toward(target_position, move_distance)

func reset_position() -> void:
	position = target.position

func draw_logic() -> void:
	var mesh_instance := MeshInstance3D.new()
	var immediate_mesh := ImmediateMesh.new()
	var material := ORMMaterial3D.new()
	
	mesh_instance.mesh = immediate_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	var left:float = -box_width / 2
	var right:float = box_width / 2
	var top:float = -box_height / 2
	var bottom:float = box_height / 2
	
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	immediate_mesh.surface_add_vertex(Vector3(0, 0, top))
	immediate_mesh.surface_add_vertex(Vector3(0, 0, bottom))
	immediate_mesh.surface_add_vertex(Vector3(right, 0, 0))
	immediate_mesh.surface_add_vertex(Vector3(left, 0, 0))
	
	immediate_mesh.surface_end()

	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color.BLACK
	
	add_child(mesh_instance)
	mesh_instance.global_transform = Transform3D.IDENTITY
	mesh_instance.global_position = Vector3(global_position.x, target.global_position.y, global_position.z)
	
	#mesh is freed after one update of _process
	await get_tree().process_frame
	mesh_instance.queue_free()
