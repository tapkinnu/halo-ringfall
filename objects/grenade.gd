extends RigidBody3D

const EXPLOSION_DELAY = 2.5
const EXPLOSION_RADIUS = 5.0
const EXPLOSION_DAMAGE = 100.0

var exploded := false

@onready var timer: Timer = $Timer
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D


func _ready():
	timer.timeout.connect(_on_timer_timeout)
	timer.start()


func _on_timer_timeout():
	explode()


func explode():
	if exploded:
		return
	exploded = true
	
	# Hide the physical grenade
	mesh_instance.visible = false
	collision_shape.disabled = true
	freeze = true
	
	# Play explosion sound
	Audio.play("sounds/enemy_destroy.ogg")
	
	# --- Damage enemies in radius via Area3D overlap ---
	var area = Area3D.new()
	var shape_node = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = EXPLOSION_RADIUS
	shape_node.shape = sphere_shape
	area.add_child(shape_node)
	get_tree().root.add_child(area)
	area.global_position = global_position
	
	await get_tree().physics_frame
	
	if not is_instance_valid(area):
		return
	
	# Damage overlapping bodies
	for body in area.get_overlapping_bodies():
		if body.has_method("damage"):
			body.damage(EXPLOSION_DAMAGE)
	
	# Damage overlapping areas (enemies use Area3D)
	for other_area in area.get_overlapping_areas():
		if other_area.has_method("damage"):
			other_area.damage(EXPLOSION_DAMAGE)
	
	area.queue_free()
	
	# --- Visual explosion VFX ---
	var light = OmniLight3D.new()
	light.light_energy = 5.0
	light.omni_range = EXPLOSION_RADIUS * 2
	light.light_color = Color(1.0, 0.7, 0.2)
	add_child(light)
	
	var explosion_mesh = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.5
	sphere_mesh.height = 1.0
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1.0, 0.5, 0.1, 0.8)
	explosion_mesh.material_override = mat
	explosion_mesh.mesh = sphere_mesh
	add_child(explosion_mesh)
	
	# Animate: expand sphere, fade light and alpha
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(light, "light_energy", 0.0, 0.5)
	tween.tween_property(explosion_mesh, "scale", Vector3.ONE * (EXPLOSION_RADIUS * 2), 0.5)
	tween.tween_method(func(alpha):
		if is_instance_valid(explosion_mesh):
			var m = explosion_mesh.material_override
			if m is StandardMaterial3D:
				m.albedo_color.a = alpha
	, 0.8, 0.0, 0.5)
	tween.finished.connect(queue_free)
