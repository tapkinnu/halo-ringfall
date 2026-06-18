extends Area3D
class_name WeaponPickup

## Weapon resource this pickup gives the player
@export var weapon_resource: Weapon
## Amount of reserve ammo granted on pickup
@export var ammo_refill_amount: int = 30

signal picked_up

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var light: OmniLight3D = $OmniLight3D

var _bob_offset: float = 0.0

func _ready():
    # Configure collision so only the player (body layer 1) triggers this
    collision_layer = 0
    collision_mask = 1
    
    # Determine color based on weapon display_name
    var color: Color
    match weapon_resource.display_name:
        "MA5 Assault Rifle":
            color = Color(0.0, 0.9, 0.4, 1.0)  # Green/teal - UNSC
        "M6 Magnum":
            color = Color(1.0, 0.8, 0.1, 1.0)  # Yellow/orange
        "Type-25 Plasma Rifle":
            color = Color(0.3, 0.5, 1.0, 1.0)  # Blue - Covenant
        _:
            color = Color(0.0, 0.6, 1.0, 1.0)  # Default blue
    
    # Create glowing material for the mesh
    var mat = StandardMaterial3D.new()
    mat.albedo_color = color
    mat.emission_enabled = true
    mat.emission = color
    mat.emission_energy_multiplier = 3.0
    mesh_instance.material_override = mat
    
    # Set light color to match
    light.light_color = color
    
    # Connect body_entered signal
    body_entered.connect(_on_body_entered)

func _process(delta):
    # Rotation
    mesh_instance.rotate_y(delta * 1.5)
    
    # Bobbing up/down
    _bob_offset += delta * 2.0
    var bob = sin(_bob_offset) * 0.15
    mesh_instance.position.y = bob
    light.position.y = bob

func _on_body_entered(body: Node3D) -> void:
    # Check if the body is the player (has "damage" method)
    if not body.has_method("damage"):
        return
    
    # Give weapon to player
    if body.has_method("pickup_weapon"):
        body.pickup_weapon(weapon_resource, ammo_refill_amount)
    
    picked_up.emit()
    queue_free()
