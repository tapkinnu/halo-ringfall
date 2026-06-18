extends Node

signal score_changed(score: int)
signal wave_changed(wave: int)
signal enemies_remaining_changed(count: int)
signal intermission_started(duration: float)
signal intermission_tick(time_remaining: float)

var score: int = 0
var wave: int = 0
var enemies_remaining: int = 0
var total_kills: int = 0

var intermission: bool = false
var intermission_timer: float = 0.0
var intermission_duration: float = 8.0

var _last_tick_second: int = -1

@onready var enemy_container: Node = null

func _ready():
    enemy_container = get_tree().current_scene.get_node_or_null("Enemies")
    start_next_wave()

func _process(delta: float) -> void:
    if intermission:
        intermission_timer -= delta
        var current_second: int = ceil(intermission_timer)
        if current_second != _last_tick_second:
            _last_tick_second = current_second
            intermission_tick.emit(intermission_timer)
        if intermission_timer <= 0.0:
            intermission = false
            _last_tick_second = -1
            start_next_wave()

func add_score(amount: int) -> void:
    score += amount
    score_changed.emit(score)

func on_enemy_killed() -> void:
    total_kills += 1
    enemies_remaining -= 1
    if enemies_remaining < 0:
        enemies_remaining = 0
    enemies_remaining_changed.emit(enemies_remaining)
    if enemies_remaining == 0:
        intermission = true
        intermission_timer = intermission_duration
        _last_tick_second = ceil(intermission_duration)
        intermission_started.emit(intermission_duration)

func start_next_wave() -> void:
    wave += 1
    wave_changed.emit(wave)
    spawn_wave(wave)

func spawn_wave(wave_num: int) -> void:
    if not enemy_container:
        enemy_container = get_tree().current_scene.get_node_or_null("Enemies")
        if not enemy_container:
            push_warning("GameManager: No Enemies container found")
            return
    
    var grunt_scene: PackedScene = preload("res://objects/enemy_grunt.tscn")
    var elite_scene: PackedScene = preload("res://objects/enemy_elite.tscn")
    var hunter_scene: PackedScene = preload("res://objects/enemy_hunter.tscn")
    
    var grunt_count = 3 + wave_num
    var elite_count = 1 + int(wave_num / 2)
    var hunter_count = int(wave_num / 3)
    
    var player_node = get_tree().current_scene.get_node_or_null("Player")
    var spawns: Array[Vector3] = [
        Vector3(-15, 2, -10),
        Vector3(15, 2, -10),
        Vector3(-10, 2, 10),
        Vector3(10, 2, 10),
        Vector3(-20, 3, -5),
        Vector3(20, 3, 5),
        Vector3(-5, 2, -15),
        Vector3(5, 2, 15),
        Vector3(-12, 4, 0),
        Vector3(12, 4, 0),
    ]
    
    var spawn_idx = 0
    for i in range(grunt_count):
        var e = grunt_scene.instantiate()
        e.player = player_node
        e.position = spawns[spawn_idx % spawns.size()] + Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))
        enemy_container.add_child(e)
        spawn_idx += 1
    
    for i in range(elite_count):
        var e = elite_scene.instantiate()
        e.player = player_node
        e.position = spawns[spawn_idx % spawns.size()] + Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))
        enemy_container.add_child(e)
        spawn_idx += 1
    
    for i in range(hunter_count):
        var e = hunter_scene.instantiate()
        e.player = player_node
        e.position = spawns[spawn_idx % spawns.size()] + Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))
        enemy_container.add_child(e)
        spawn_idx += 1
    
    enemies_remaining = grunt_count + elite_count + hunter_count
    enemies_remaining_changed.emit(enemies_remaining)