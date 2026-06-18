extends CanvasLayer

@onready var shield_bar = $ShieldBar
@onready var shield_label = $ShieldLabel
@onready var health_bar = $HealthBar
@onready var health_label = $HealthLabel
@onready var ammo_label = $AmmoLabel
@onready var weapon_label = $WeaponLabel
@onready var score_label = $ScoreLabel
@onready var wave_label = $WaveLabel
@onready var enemies_label = $EnemiesLabel
@onready var grenade_label = $GrenadeLabel

# Store initial offset_right (full width position) for bar scaling
var shield_bar_right: float = 0.0
var shield_bar_left: float = 0.0
var health_bar_right: float = 0.0
var health_bar_left: float = 0.0

const SHIELD_COLOR_FULL = Color(0.2, 0.8, 1.0, 0.9)
const SHIELD_COLOR_LOW = Color(1.0, 0.3, 0.2, 0.9)
const HEALTH_COLOR_FULL = Color(0.9, 0.2, 0.2, 0.9)
const HEALTH_COLOR_LOW = Color(1.0, 0.0, 0.0, 1.0)

func _ready():
    # Store the initial bar boundaries (these define the full-width bars)
    shield_bar_left = shield_bar.offset_left
    shield_bar_right = shield_bar.offset_right
    health_bar_left = health_bar.offset_left
    health_bar_right = health_bar.offset_right
    
    # Connect to player signals
    var player = get_tree().current_scene.get_node_or_null("Player")
    if player:
        player.health_updated.connect(_on_health_updated)
        player.shield_updated.connect(_on_shield_updated)
        player.ammo_updated.connect(_on_ammo_updated)
        player.weapon_changed.connect(_on_weapon_changed)
        player.grenade_updated.connect(_on_grenade_updated)
    
    # Connect to GameManager signals
    if GameManager:
        GameManager.score_changed.connect(_on_score_changed)
        GameManager.wave_changed.connect(_on_wave_changed)
        GameManager.enemies_remaining_changed.connect(_on_enemies_changed)

func _on_health_updated(health_val: float):
    var pct = clamp(health_val / 100.0, 0.0, 1.0)
    # Scale bar by adjusting offset_right toward offset_left
    var full_width = health_bar_right - health_bar_left
    health_bar.offset_right = health_bar_left + full_width * pct
    health_label.text = "HEALTH " + str(int(max(health_val, 0)))
    health_bar.color = HEALTH_COLOR_FULL.lerp(HEALTH_COLOR_LOW, 1.0 - pct)

func _on_shield_updated(shield_val: float):
    var pct = clamp(shield_val / 100.0, 0.0, 1.0)
    var full_width = shield_bar_right - shield_bar_left
    shield_bar.offset_right = shield_bar_left + full_width * pct
    shield_label.text = "SHIELD " + str(int(max(shield_val, 0)))
    shield_bar.color = SHIELD_COLOR_FULL.lerp(SHIELD_COLOR_LOW, 1.0 - pct)

func _on_ammo_updated(current: int, reserve: int):
    ammo_label.text = str(current) + " / " + str(reserve)

func _on_weapon_changed(weapon_name: String):
    weapon_label.text = weapon_name

func _on_score_changed(score_val: int):
    score_label.text = "SCORE: " + str(score_val)

func _on_wave_changed(wave_num: int):
    wave_label.text = "WAVE " + str(wave_num)

func _on_enemies_changed(count: int):
    enemies_label.text = str(count) + " hostiles"

func _on_grenade_updated(count: int):
    grenade_label.text = "GRENADES: " + str(count)