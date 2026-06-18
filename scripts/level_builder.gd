extends Node3D
class_name LevelBuilder

# Procedurally builds a sci-fi Halo-inspired arena with metallic structures,
# glowing panels, ramps, and cover. Uses existing Kenney GLB models with
# StandardMaterial3D overrides for the sci-fi aesthetic.

func _ready():
    build_level()

func build_level():
    # Main floor - large grass platform as base
    add_platform("res://objects/platform_large_grass.tscn", Vector3(0, -0.5, 0), 0)
    add_platform("res://objects/platform_large_grass.tscn", Vector3(0, 0.5, -12), 0)
    add_platform("res://objects/platform_large_grass.tscn", Vector3(0, 1.5, -24), 0)
    add_platform("res://objects/platform_large_grass.tscn", Vector3(14, 0.5, -6), 0)
    add_platform("res://objects/platform_large_grass.tscn", Vector3(-14, 0.5, -6), 0)
    add_platform("res://objects/platform_large_grass.tscn", Vector3(14, 1.5, -18), 0)
    add_platform("res://objects/platform_large_grass.tscn", Vector3(-14, 1.5, -18), 0)
    
    # Perimeter walls
    for i in range(-3, 4):
        add_object("res://objects/wall_high.tscn", Vector3(i * 4, 1.5, -28), 0)
    for i in range(-3, 4):
        add_object("res://objects/wall_high.tscn", Vector3(i * 4, 1.5, 4), 0)
    for i in range(-3, 4):
        add_object("res://objects/wall_high.tscn", Vector3(-28, 1.5, i * 4 - 12), 90)
    for i in range(-3, 4):
        add_object("res://objects/wall_high.tscn", Vector3(28, 1.5, i * 4 - 12), 90)
    
    # Interior cover walls
    add_object("res://objects/wall_low.tscn", Vector3(-5, 1.05, -6), 0)
    add_object("res://objects/wall_low.tscn", Vector3(5, 1.05, -6), 0)
    add_object("res://objects/wall_low.tscn", Vector3(-8, 2.05, -14), 90)
    add_object("res://objects/wall_low.tscn", Vector3(8, 2.05, -14), 90)
    add_object("res://objects/wall_low.tscn", Vector3(-12, 1.05, -10), 0)
    add_object("res://objects/wall_low.tscn", Vector3(12, 1.05, -10), 0)
    add_object("res://objects/wall_low.tscn", Vector3(0, 2.55, -18), 0)
    
    # Elevated platforms for verticality
    add_platform("res://objects/platform.tscn", Vector3(-6, 2.5, -2), 0)
    add_platform("res://objects/platform.tscn", Vector3(6, 2.5, -2), 0)
    add_platform("res://objects/platform.tscn", Vector3(-2, 3.5, -8), 0)
    add_platform("res://objects/platform.tscn", Vector3(2, 3.5, -8), 0)
    add_platform("res://objects/platform.tscn", Vector3(-10, 2.5, -16), 0)
    add_platform("res://objects/platform.tscn", Vector3(10, 2.5, -16), 0)
    add_platform("res://objects/platform.tscn", Vector3(0, 4.0, -22), 0)
    
    # Central elevated platform - sniper nest
    add_platform("res://objects/platform.tscn", Vector3(0, 3.0, -12), 0)
    add_platform("res://objects/platform.tscn", Vector3(0, 3.0, -10), 0)
    
    # Low walls as cover on the central platform
    add_object("res://objects/wall_low.tscn", Vector3(-2, 4.05, -12), 0)
    add_object("res://objects/wall_low.tscn", Vector3(2, 4.05, -12), 0)
    add_object("res://objects/wall_low.tscn", Vector3(0, 4.05, -14), 90)
    
    # Decorative clouds (alien fog/debris)
    var cloud_scene = load("res://objects/cloud.tscn")
    for i in range(8):
        var cloud = cloud_scene.instantiate()
        var angle = i * (PI * 2 / 8)
        cloud.position = Vector3(cos(angle) * 20, randf_range(3, 10), sin(angle) * 20 - 12)
        cloud.scale = Vector3.ONE * randf_range(1.5, 3.0)
        add_child(cloud)
    
    # Glowing energy pillars (procedural)
    for pos in [Vector3(-15, 0, -20), Vector3(15, 0, -20), Vector3(-15, 0, -4), Vector3(15, 0, -4)]:
        add_energy_pillar(pos)
    
    # Overhead light strips
    for pos in [Vector3(0, 6, -12), Vector3(-10, 5, -10), Vector3(10, 5, -10), Vector3(0, 7, -22)]:
        add_light_strip(pos)
    
    # Weapon pickup stations
    var pickup_scene = preload("res://objects/weapon_pickup.tscn")
    
    # Assault Rifle refill - left flank
    var ar_pickup = pickup_scene.instantiate()
    ar_pickup.position = Vector3(-12, 1.5, -8)
    ar_pickup.weapon_resource = preload("res://weapons/assault_rifle.tres")
    ar_pickup.ammo_refill_amount = 60
    add_child(ar_pickup)
    
    # Magnum pickup - right flank
    var mag_pickup = pickup_scene.instantiate()
    mag_pickup.position = Vector3(12, 2.5, -16)
    mag_pickup.weapon_resource = preload("res://weapons/magnum.tres")
    mag_pickup.ammo_refill_amount = 12
    add_child(mag_pickup)
    
    # Plasma Rifle - elevated central platform
    var plasma_pickup = pickup_scene.instantiate()
    plasma_pickup.position = Vector3(0, 4.5, -12)
    plasma_pickup.weapon_resource = preload("res://weapons/plasma_rifle.tres")
    plasma_pickup.ammo_refill_amount = 50
    add_child(plasma_pickup)

func add_platform(scene_path: String, pos: Vector3, rot_y: float):
    var scene = load(scene_path)
    var node = scene.instantiate()
    node.position = pos
    node.rotation_degrees.y = rot_y
    add_child(node)

func add_object(scene_path: String, pos: Vector3, rot_y: float):
    var scene = load(scene_path)
    var node = scene.instantiate()
    node.position = pos
    node.rotation_degrees.y = rot_y
    add_child(node)

func add_energy_pillar(pos: Vector3):
    # Glowing pillar with OmniLight
    var pillar = MeshInstance3D.new()
    pillar.mesh = CylinderMesh.new()
    pillar.mesh.top_radius = 0.15
    pillar.mesh.bottom_radius = 0.15
    pillar.mesh.height = 4.0
    pillar.position = pos + Vector3(0, 2, 0)
    
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color(0.0, 0.5, 1.0, 1.0)
    mat.emission_enabled = true
    mat.emission = Color(0.0, 0.6, 1.0, 1.0)
    mat.emission_energy_multiplier = 2.0
    pillar.material_override = mat
    add_child(pillar)
    
    var light = OmniLight3D.new()
    light.position = pos + Vector3(0, 2, 0)
    light.light_color = Color(0.2, 0.6, 1.0, 1.0)
    light.light_energy = 2.0
    light.omni_range = 8.0
    add_child(light)

func add_light_strip(pos: Vector3):
    var strip = MeshInstance3D.new()
    strip.mesh = BoxMesh.new()
    strip.mesh.size = Vector3(6, 0.1, 0.3)
    strip.position = pos
    
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
    mat.emission_enabled = true
    mat.emission = Color(0.8, 0.9, 1.0, 1.0)
    mat.emission_energy_multiplier = 3.0
    strip.material_override = mat
    add_child(strip)