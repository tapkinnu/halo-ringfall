extends CharacterBody3D

@export_subgroup("Properties")
@export var movement_speed = 6
@export_range(0, 100) var number_of_jumps: int = 2
@export var jump_strength = 8

@export_subgroup("Weapons")
@export var weapons: Array[Weapon] = []

var weapon: Weapon
var weapon_index := 0

var mouse_sensitivity = 700
var gamepad_sensitivity := 0.075

var mouse_captured := true

var movement_velocity: Vector3
var rotation_target: Vector3

var input_mouse: Vector2

# Halo-style shield + health system
var shield: float = 100.0
var max_shield: float = 100.0
var health: float = 100.0
var max_health: float = 100.0
var shield_recharge_delay: float = 3.0
var shield_recharge_rate: float = 25.0
var shield_recharge_timer: float = 0.0
var shield_recharging: bool = false

var gravity := 0.0

var previously_floored := false

var jumps_remaining: int

var container_offset = Vector3(1.2, -1.1, -2.75)

var tween: Tween

# Ammo system
var current_ammo: int = 0
var reserve_ammo: int = 0
var is_reloading: bool = false
var reload_timer: float = 0.0

signal health_updated(health: float)
signal shield_updated(shield: float)
signal ammo_updated(current: int, reserve: int)
signal weapon_changed(weapon_name: String)
signal grenade_updated(count: int)

@onready var camera = $Head/Camera
@onready var raycast = $Head/Camera/RayCast
@onready var muzzle = $Head/Camera/SubViewportContainer/SubViewport/CameraItem/Muzzle
@onready var container = $Head/Camera/SubViewportContainer/SubViewport/CameraItem/Container
@onready var sound_footsteps = $SoundFootsteps
@onready var blaster_cooldown = $Cooldown
@onready var reload_timer_node = $ReloadTimer

@export var crosshair: TextureRect

var grenades: int = 3
var grenade_scene: PackedScene = preload("res://objects/grenade.tscn")

# Functions

func _ready():
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    
    weapon = weapons[weapon_index]
    initiate_change_weapon(weapon_index)
    
    shield_updated.emit(shield)
    health_updated.emit(health)

func _process(delta):
    # Handle functions
    handle_controls(delta)
    handle_gravity(delta)
    handle_shield_recharge(delta)
    handle_reload(delta)
    
    # Movement
    
    var applied_velocity: Vector3
    
    movement_velocity = transform.basis * movement_velocity
    
    applied_velocity = velocity.lerp(movement_velocity, delta * 10)
    applied_velocity.y = -gravity
    
    velocity = applied_velocity
    move_and_slide()
    
    # Rotation
    container.position = lerp(container.position, container_offset - (basis.inverse() * applied_velocity / 30), delta * 10)
    
    # Movement sound
    sound_footsteps.stream_paused = true
    
    if is_on_floor():
        if abs(velocity.x) > 1 or abs(velocity.z) > 1:
            sound_footsteps.stream_paused = false
    
    # Landing after jump or falling
    camera.position.y = lerp(camera.position.y, 0.0, delta * 5)
    
    if is_on_floor() and gravity > 1 and !previously_floored:
        Audio.play("sounds/land.ogg")
        camera.position.y = -0.1
    
    previously_floored = is_on_floor()
    
    # Falling/respawning
    if position.y < -10:
        get_tree().reload_current_scene()

# Mouse movement

func _input(event):
    if event is InputEventMouseMotion and mouse_captured:
        input_mouse = event.relative / mouse_sensitivity
        handle_rotation(event.relative.x, event.relative.y, false)

func handle_controls(delta):
    # Mouse capture
    if Input.is_action_just_pressed("mouse_capture"):
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
        mouse_captured = true
    
    if Input.is_action_just_pressed("mouse_capture_exit"):
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
        mouse_captured = false
        input_mouse = Vector2.ZERO
    
    # Movement
    var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    movement_velocity = Vector3(input.x, 0, input.y).normalized() * movement_speed
    
    # Handle Controller Rotation
    var rotation_input := Input.get_vector("camera_right", "camera_left", "camera_down", "camera_up")
    if rotation_input:
        handle_rotation(rotation_input.x, rotation_input.y, true, delta)
    
    # Shooting
    action_shoot()
    
    # Jumping
    if Input.is_action_just_pressed("jump"):
        if jumps_remaining:
            action_jump()
    
    # Weapon switching
    action_weapon_toggle()
    
    # Reload
    if Input.is_action_just_pressed("reload"):
        start_reload()
    
    # Throw grenade
    if Input.is_action_just_pressed("throw_grenade"):
        action_throw_grenade()

# Camera rotation

func handle_rotation(xRot: float, yRot: float, isController: bool, delta: float = 0.0):
    if isController:
        rotation_target -= Vector3(-yRot, -xRot, 0).limit_length(1.0) * gamepad_sensitivity
        rotation_target.x = clamp(rotation_target.x, deg_to_rad(-90), deg_to_rad(90))
        camera.rotation.x = lerp_angle(camera.rotation.x, rotation_target.x, delta * 25)
        rotation.y = lerp_angle(rotation.y, rotation_target.y, delta * 25)
    else:
        rotation_target += (Vector3(-yRot, -xRot, 0) / mouse_sensitivity)
        rotation_target.x = clamp(rotation_target.x, deg_to_rad(-90), deg_to_rad(90))
        camera.rotation.x = rotation_target.x;
        rotation.y = rotation_target.y;

# Handle gravity

func handle_gravity(delta):
    gravity += 20 * delta
    
    if gravity < 0 and is_on_ceiling():
        gravity = 0
    
    if gravity > 0 and is_on_floor():
        jumps_remaining = number_of_jumps
        gravity = 0

# Jumping

func action_jump():
    Audio.play("sounds/jump_a.ogg, sounds/jump_b.ogg, sounds/jump_c.ogg")
    gravity = - jump_strength
    jumps_remaining -= 1

# Halo-style shield recharge system

func handle_shield_recharge(delta):
    if shield < max_shield and not is_reloading:
        shield_recharge_timer += delta
        if shield_recharge_timer >= shield_recharge_delay:
            shield_recharging = true
            shield = min(shield + shield_recharge_rate * delta, max_shield)
            shield_updated.emit(shield)
    else:
        shield_recharge_timer = 0.0

# Reload system

func handle_reload(delta):
    if is_reloading:
        reload_timer -= delta
        if reload_timer <= 0:
            finish_reload()

func start_reload():
    if is_reloading:
        return
    if current_ammo >= weapon.max_ammo:
        return
    if reserve_ammo <= 0:
        return
    
    is_reloading = true
    reload_timer = weapon.reload_time
    Audio.play(weapon.sound_reload)
    
    # Reload animation - lower weapon
    if tween:
        tween.kill()
    tween = get_tree().create_tween()
    tween.set_ease(Tween.EASE_OUT_IN)
    tween.tween_property(container, "position", container_offset - Vector3(0, 1, 0), 0.15)

func finish_reload():
    var needed = weapon.max_ammo - current_ammo
    var taken = min(needed, reserve_ammo)
    current_ammo += taken
    reserve_ammo -= taken
    is_reloading = false
    ammo_updated.emit(current_ammo, reserve_ammo)
    
    # Raise weapon back
    if tween:
        tween.kill()
    tween = get_tree().create_tween()
    tween.tween_property(container, "position", container_offset, 0.15)

# Shooting

func action_shoot():
    if is_reloading:
        return
    
    var shooting = false
    if weapon.auto_fire:
        shooting = Input.is_action_pressed("shoot")
    else:
        shooting = Input.is_action_just_pressed("shoot")
    
    if shooting:
        if !blaster_cooldown.is_stopped():
            return
        
        # Check ammo
        if current_ammo <= 0:
            # Auto reload when empty
            start_reload()
            return
        
        current_ammo -= 1
        ammo_updated.emit(current_ammo, reserve_ammo)
        
        Audio.play(weapon.sound_shoot)
        
        # Set muzzle flash position, play animation
        muzzle.play("default")
        muzzle.rotation_degrees.z = randf_range(-45, 45)
        muzzle.scale = Vector3.ONE * randf_range(0.40, 0.75)
        muzzle.position = container.position - weapon.muzzle_position
        
        blaster_cooldown.start(weapon.cooldown)
        
        # Shoot the weapon, amount based on shot count
        for n in weapon.shot_count:
            raycast.target_position.x = randf_range(-weapon.spread, weapon.spread)
            raycast.target_position.y = randf_range(-weapon.spread, weapon.spread)
            
            raycast.force_raycast_update()
            
            if !raycast.is_colliding():
                continue
            
            var collider = raycast.get_collider()
            
            # Hitting an enemy
            if collider.has_method("damage"):
                collider.damage(weapon.damage)
            
            # Creating an impact animation
            var impact = preload("res://objects/impact.tscn")
            var impact_instance = impact.instantiate()
            
            impact_instance.play("shot")
            
            get_tree().root.add_child(impact_instance)
            
            impact_instance.position = raycast.get_collision_point() + (raycast.get_collision_normal() / 10)
            impact_instance.look_at(camera.global_transform.origin, Vector3.UP, true)
        
        var knockback = random_vec2(weapon.min_knockback, weapon.max_knockback)
        container.position.z += 0.25
        camera.rotation.x += knockback.x
        rotation.y += knockback.y
        rotation_target.x += knockback.x
        rotation_target.y += knockback.y
        movement_velocity += Vector3(0, 0, weapon.knockback)

# Toggle between available weapons (listed in 'weapons')

func action_throw_grenade():
    if grenades <= 0:
        return
    
    grenades -= 1
    grenade_updated.emit(grenades)
    
    var grenade = grenade_scene.instantiate()
    get_tree().root.add_child(grenade)
    grenade.global_position = camera.global_position
    
    var forward: Vector3 = -camera.global_transform.basis.z
    grenade.linear_velocity = forward * 15.0 + Vector3.UP * 3.0

func action_weapon_toggle():
    if Input.is_action_just_pressed("weapon_toggle"):
        weapon_index = wrap(weapon_index + 1, 0, weapons.size())
        initiate_change_weapon(weapon_index)
        Audio.play("sounds/weapon_change.ogg")
    
    # Number key weapon switching
    if Input.is_action_just_pressed("weapon_1") and weapons.size() > 0:
        switch_to_weapon(0)
    if Input.is_action_just_pressed("weapon_2") and weapons.size() > 1:
        switch_to_weapon(1)
    if Input.is_action_just_pressed("weapon_3") and weapons.size() > 2:
        switch_to_weapon(2)

func switch_to_weapon(index: int):
    if index == weapon_index:
        return
    if is_reloading:
        is_reloading = false
    weapon_index = index
    initiate_change_weapon(index)
    Audio.play("sounds/weapon_change.ogg")

# Initiates the weapon changing animation (tween)

func initiate_change_weapon(index):
    weapon_index = index
    
    tween = get_tree().create_tween()
    tween.set_ease(Tween.EASE_OUT_IN)
    tween.tween_property(container, "position", container_offset - Vector3(0, 1, 0), 0.1)
    tween.tween_callback(change_weapon)

# Switches the weapon model (off-screen)

func change_weapon():
    weapon = weapons[weapon_index]
    
    # Step 1. Remove previous weapon model(s) from container
    for n in container.get_children():
        container.remove_child(n)
    
    # Step 2. Place new weapon model in container
    var weapon_model = weapon.model.instantiate()
    container.add_child(weapon_model)
    
    weapon_model.position = weapon.position
    weapon_model.rotation_degrees = weapon.rotation
    
    # Step 3. Set model to only render on layer 2 (the weapon camera)
    for child in weapon_model.find_children("*", "MeshInstance3D"):
        child.layers = 2
    
    # Set weapon data
    raycast.target_position = Vector3(0, 0, -1) * weapon.max_distance
    crosshair.texture = weapon.crosshair
    
    # Update ammo display
    current_ammo = weapon.max_ammo
    reserve_ammo = weapon.reserve_ammo
    is_reloading = false
    ammo_updated.emit(current_ammo, reserve_ammo)
    weapon_changed.emit(weapon.display_name)

# Pick up a weapon from a pickup station
func pickup_weapon(new_weapon: Weapon, ammo_refill: int):
    # Check if weapon is already in inventory by display_name
    for i in range(weapons.size()):
        if weapons[i].display_name == new_weapon.display_name:
            # Already have this weapon — just refill reserve ammo
            reserve_ammo += ammo_refill
            ammo_updated.emit(current_ammo, reserve_ammo)
            weapon_changed.emit(new_weapon.display_name)
            return
    
    # New weapon — add to inventory and switch to it
    weapons.append(new_weapon)
    var new_index = weapons.size() - 1
    switch_to_weapon(new_index)

# Take damage - shield absorbs first, then health

func damage(amount):
    shield_recharge_timer = 0.0
    shield_recharging = false
    
    var remaining_damage = amount
    
    if shield > 0:
        var shield_damage = min(shield, remaining_damage)
        shield -= shield_damage
        remaining_damage -= shield_damage
        shield_updated.emit(shield)
    
    if remaining_damage > 0:
        health -= remaining_damage
        health_updated.emit(health)
    
    if health <= 0:
        get_tree().reload_current_scene()

# Create a random knockback vector

static func random_vec2(_min: Vector2, _max: Vector2) -> Vector2:
    var _sign = -1 if randi() % 2 == 0 else 1
    return Vector2(randf_range(_min.x, _max.x), randf_range(_min.y, _max.y) * _sign)