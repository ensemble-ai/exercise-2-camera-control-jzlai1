class_name TargetFocus
extends CameraControllerBase

@export var box_width: float = 5.0
@export var box_height: float = 5.0
@export var lead_speed: float = 1.5
@export var catchup_delay_duration: float = 0.65
@export var catchup_speed: float = 1.0
@export var leash_distance: float = 5.0

var timer: float = 0.0

func _ready() -> void:
	super()
	reset_position()

func _process(delta: float) -> void:
	if !current:
		return
	
	if draw_camera_logic:
		draw_logic()
	
	update_camera_position(delta)
	super(delta)

func update_camera_position(delta: float) -> void:
	var offset_to_target = target.global_position - global_position
	var direction_to_target = offset_to_target.normalized()
	direction_to_target.y = 0  
	
	var adjust_x = false
	var adjust_z = false
	
	if abs(offset_to_target.x) > leash_distance and sign(offset_to_target.x) != sign(target.velocity.x):
		adjust_x = true
	if abs(offset_to_target.z) > leash_distance and sign(offset_to_target.z) != sign(target.velocity.z):
		adjust_z = true

	var camera_movement = Vector3()
	if target.velocity != Vector3.ZERO:
		timer = 0  
		if adjust_x:
			camera_movement.x = target.velocity.x * delta
		else:
			camera_movement.x = lead_speed * target.velocity.x * delta
		if adjust_z:
			camera_movement.z = target.velocity.z * delta
		else:
			camera_movement.z = lead_speed * target.velocity.z * delta
	else:
		timer += delta
		if timer >= catchup_delay_duration:
			camera_movement = direction_to_target * target.BASE_SPEED * catchup_speed * delta

	global_position += camera_movement

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
