extends CharacterBody2D
# Rubis, le chevalier rouge. Les constantes de mouvement sont en pixels / secondes.
const Art = preload("res://scripts/art.gd")
signal jumped
const SPEED := 290.0
const JUMP_SPEED := -590.0
const GRAVITY := 1550.0
var enabled := false
var invulnerable := 0.0
var coyote := 0.0
var jump_buffer := 0.0
var phase := 0.0
var face := 1.0
var armed := false
var swing := 0.0
var previous_bottom := 0.0

func _ready() -> void:
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 23.0
	collision.shape = shape
	add_child(collision)
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 8.0

func _physics_process(delta: float) -> void:
	swing = maxf(0.0, swing - delta)
	if not enabled:
		return
	invulnerable = maxf(0.0, invulnerable - delta)
	previous_bottom = position.y + 23.0
	coyote = 0.12 if is_on_floor() else maxf(0.0, coyote - delta)
	jump_buffer = maxf(0.0, jump_buffer - delta)
	if Input.is_action_just_pressed("jump"):
		jump_buffer = 0.13
	var axis := Input.get_axis("left", "right")
	if axis != 0.0:
		face = signf(axis)
	velocity.x = move_toward(velocity.x, axis * SPEED, 1800.0 * delta)
	velocity.y = minf(velocity.y + GRAVITY * delta, 950.0)
	if jump_buffer > 0.0 and coyote > 0.0:
		velocity.y = JUMP_SPEED
		jump_buffer = 0.0
		coyote = 0.0
		jumped.emit()
	if Input.is_action_just_released("jump") and velocity.y < -250.0:
		velocity.y = -250.0
	move_and_slide()
	position.x = maxf(position.x, 24.0)
	phase += absf(velocity.x) * delta / 18.0
	queue_redraw()

func _draw() -> void:
	if invulnerable > 0.0 and int(invulnerable * 12.0) % 2 == 0:
		return
	draw_circle(Vector2(0, 24), 13.0, Color(0, 0, 0, 0.12))
	Art.hero(self, Vector2.ZERO, face, phase, not is_on_floor(), 1.0, armed)
	if swing > 0.0:
		var a0 := -1.0 if face > 0.0 else PI - 1.0
		draw_arc(Vector2(face * 14.0, -2.0), 32.0, a0, a0 + 2.0, 12, Color(0.6, 0.97, 1.0, 0.85), 5.0)
