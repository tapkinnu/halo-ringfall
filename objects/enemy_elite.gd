extends "res://objects/enemy_base.gd"

# Elite: Has energy shield, faster, aggressive pursuit, higher damage
# When shield breaks, becomes more aggressive (rage mode)

var shield_broken: bool = false
var rage_speed_mult: float = 1.0

func _ready():
    super._ready()

func ai_behavior(delta):
    # Aggressive sine movement
    target_position.y = initial_y + sin(time * 6) * 0.5
    
    var dist = global_position.distance_to(player.global_position)
    var dir = (player.global_position - global_position).normalized()
    
    # Rage mode when shield is down
    if shield <= 0 and not shield_broken:
        shield_broken = true
        rage_speed_mult = 1.5
        move_speed *= rage_speed_mult
    
    if dist > attack_range * 0.6:
        # Close distance aggressively
        target_position.x += dir.x * move_speed * delta
        target_position.z += dir.z * move_speed * delta
    else:
        # Circle strafe while shooting
        var strafe_dir = Vector3(-dir.z, 0, dir.x).normalized()
        if int(time) % 2 == 0:
            strafe_dir = -strafe_dir  # Reverse direction periodically
        target_position.x += strafe_dir.x * move_speed * 0.8 * delta
        target_position.z += strafe_dir.z * move_speed * 0.8 * delta
    
    # Keep within bounds
    target_position.x = clamp(target_position.x, -28, 28)
    target_position.z = clamp(target_position.z, -28, 28)