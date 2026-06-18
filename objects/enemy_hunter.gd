extends "res://objects/enemy_base.gd"

# Hunter: Tank enemy, slow, massive health, devastating charge attack
# Walks slowly toward player, high damage, takes lots of hits

var charge_cooldown: float = 5.0
var charge_timer: float = 0.0
var is_charging: bool = false
var charge_dir: Vector3 = Vector3.ZERO

func _ready():
    super._ready()

func ai_behavior(delta):
    # Heavy movement - no floating for hunters
    target_position.y = initial_y
    
    var dist = global_position.distance_to(player.global_position)
    var dir = (player.global_position - global_position).normalized()
    
    charge_timer -= delta
    
    if is_charging:
        # Charge in straight line
        target_position.x += charge_dir.x * move_speed * 4.0 * delta
        target_position.z += charge_dir.z * move_speed * 4.0 * delta
        
        # End charge after traveling a bit or hitting bounds
        if charge_timer <= 0:
            is_charging = false
            charge_timer = charge_cooldown
    else:
        if dist > attack_range * 0.5:
            # Slow advance
            target_position.x += dir.x * move_speed * 0.5 * delta
            target_position.z += dir.z * move_speed * 0.5 * delta
        else:
            # Stop and prepare to charge
            if charge_timer <= 0:
                # Start charging
                is_charging = true
                charge_dir = dir
                charge_timer = 1.5  # Charge duration
    
    # Keep within bounds
    target_position.x = clamp(target_position.x, -25, 25)
    target_position.z = clamp(target_position.z, -25, 25)