extends Area3D
# EnemyBase - base class for all enemy types

@export var player: Node3D
@export var max_health: float = 50.0
@export var max_shield: float = 0.0
@export var move_speed: float = 3.0
@export var attack_damage: float = 5.0
@export var attack_range: float = 15.0
@export var attack_cooldown: float = 1.5
@export var score_value: int = 10

var health: float
var shield: float
var destroyed: bool = false
var attack_timer: float = 0.0
var time: float = 0.0
var target_position: Vector3
var initial_y: float = 0.0

@onready var raycast = $RayCast
@onready var muzzle_a = $MuzzleA
@onready var muzzle_b = $MuzzleB

signal enemy_destroyed

func _ready():
    health = max_health
    shield = max_shield
    target_position = position
    initial_y = position.y

func _process(delta):
    if destroyed or not player:
        return
    
    # Face the player
    look_at(player.position + Vector3(0, 0.5, 0), Vector3.UP, true)
    
    # Movement behavior - override in subclasses
    ai_behavior(delta)
    
    # Apply position
    position = target_position
    
    # Attack logic
    attack_timer -= delta
    if attack_timer <= 0:
        try_attack()
    
    time += delta

func ai_behavior(delta):
    pass  # Override in subclasses

func try_attack():
    if not player:
        return
    
    var dist = global_position.distance_to(player.global_position)
    if dist > attack_range:
        return
    
    raycast.force_raycast_update()
    
    if raycast.is_colliding():
        var collider = raycast.get_collider()
        if collider.has_method("damage"):
            # Play muzzle flash
            if muzzle_a:
                muzzle_a.frame = 0
                muzzle_a.play("default")
                muzzle_a.rotation_degrees.z = randf_range(-45, 45)
            if muzzle_b:
                muzzle_b.frame = 0
                muzzle_b.play("default")
                muzzle_b.rotation_degrees.z = randf_range(-45, 45)
            
            Audio.play("sounds/enemy_attack.ogg")
            collider.damage(attack_damage)
            attack_timer = attack_cooldown

func damage(amount):
    if destroyed:
        return
    
    Audio.play("sounds/enemy_hurt.ogg")
    
    var remaining = amount
    
    # Shield absorbs first
    if shield > 0:
        var shield_dmg = min(shield, remaining)
        shield -= shield_dmg
        remaining -= shield_dmg
    
    if remaining > 0:
        health -= remaining
    
    if health <= 0 and not destroyed:
        destroy()

func destroy():
    Audio.play("sounds/enemy_destroy.ogg")
    destroyed = true
    enemy_destroyed.emit()
    
    if GameManager:
        GameManager.on_enemy_killed()
        GameManager.add_score(score_value)
    
    queue_free()