extends "res://objects/enemy_base.gd"

# Grunt: Weak, slow, wanders randomly, low health, flees when close to death

func _ready():
    super._ready()
    # Grunt properties are set via @export in scene, but we can override here too
    pass

func ai_behavior(delta):
    # Sine bobbing movement
    target_position.y = initial_y + sin(time * 4) * 0.3
    
    var dist = global_position.distance_to(player.global_position)
    
    if health < max_health * 0.3:
        # Flee when low health - move away from player
        var flee_dir = (global_position - player.global_position).normalized()
        target_position.x += flee_dir.x * move_speed * delta
        target_position.z += flee_dir.z * move_speed * delta
    elif dist > attack_range * 0.7:
        # Approach player if too far
        var approach_dir = (player.global_position - global_position).normalized()
        target_position.x += approach_dir.x * move_speed * delta
        target_position.z += approach_dir.z * move_speed * delta
    else:
        # Strafe around player
        var strafe_dir = Vector3(-approach_dir().z, 0, approach_dir().x).normalized()
        target_position.x += strafe_dir.x * move_speed * 0.5 * delta
        target_position.z += strafe_dir.z * move_speed * 0.5 * delta
    
    # Keep within bounds
    target_position.x = clamp(target_position.x, -25, 25)
    target_position.z = clamp(target_position.z, -25, 25)

func approach_dir() -> Vector3:
    return (player.global_position - global_position).normalized()