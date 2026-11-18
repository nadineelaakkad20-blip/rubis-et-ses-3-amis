extends RefCounted
# Tous les personnages sont dessinés par code (aucune image nécessaire).
# L'origine (0, 0) est le centre du personnage ; les pieds touchent y = +23.
# "face" = 1.0 regarde à droite, -1.0 regarde à gauche. "s" = échelle.

const SKIN := Color("f0c9a4")
const DARK := Color("253445")

static func _begin(c: CanvasItem, p: Vector2, face: float, s: float) -> void:
	c.draw_set_transform(p, 0.0, Vector2(face * s, s))

static func _end(c: CanvasItem) -> void:
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

static func _eyes(c: CanvasItem, y: float, spread: float, r: float, look := 0.4) -> void:
	for sx in [-1.0, 1.0]:
		c.draw_circle(Vector2(sx * spread, y), r, Color.WHITE)
		c.draw_circle(Vector2(sx * spread + look * r, y + 1.0), r * 0.5, DARK)

# ---------------------------------------------------------------- HÉROS
# Rubis, le chevalier rouge (cape, casque à plumet, épée).
static func hero(c: CanvasItem, p: Vector2, face := 1.0, phase := 0.0, air := false, s := 1.0, armed := false) -> void:
	_begin(c, p, face, s)
	var swing := 0.0 if air else sin(phase) * 4.0
	var sway := sin(phase * 0.7) * 3.0
	# cape
	c.draw_colored_polygon(PackedVector2Array([Vector2(-5, -2), Vector2(-21, 7 + sway), Vector2(-18, 21), Vector2(0, 16)]), Color("8e1f35"))
	# bottes
	c.draw_rect(Rect2(-11 + swing, 15, 11, 8), Color("45282f"))
	c.draw_rect(Rect2(0 - swing, 15, 11, 8), Color("45282f"))
	# tunique et ceinture
	c.draw_rect(Rect2(-12, 2, 24, 15), Color("d9414b"))
	c.draw_rect(Rect2(-12, 11, 24, 3), Color("f8d780"))
	c.draw_rect(Rect2(-2, 10, 4, 5), Color("fff0a8"))
	# bras et épée
	if armed:
		c.draw_circle(Vector2(32, -19), 14.0, Color(0.5, 0.97, 1.0, 0.25))
		c.draw_line(Vector2(13, 7), Vector2(34, -21), Color("9ff6ff"), 6.0)
		c.draw_line(Vector2(13, 7), Vector2(34, -21), Color.WHITE, 2.0)
	else:
		c.draw_line(Vector2(13, 7), Vector2(28, -13), Color("e6ecf5"), 4.0)
	c.draw_line(Vector2(9, 5), Vector2(19, 9), Color("f8d780"), 3.0)
	c.draw_circle(Vector2(11, 8), 4.5, SKIN)
	# casque et visière
	c.draw_circle(Vector2(0, -8), 16, Color("8f9cb3"))
	c.draw_circle(Vector2(0, -10), 14, Color("c4cfe0"))
	c.draw_rect(Rect2(-11, -14, 22, 12), Color("2b3148"))
	_eyes(c, -8, 5.0, 3.6)
	# plumet rouge
	c.draw_colored_polygon(PackedVector2Array([Vector2(-4, -21), Vector2(0, -35), Vector2(13, -31), Vector2(5, -21)]), Color("f35e61"))
	_end(c)

# ---------------------------------------------------------------- AMIS
# kind 0 = Bolt le robot (jaune), 1 = Robin l'archère (verte), 2 = Mira la magicienne (violette)
static func friend(c: CanvasItem, p: Vector2, kind: int, face := 1.0, t := 0.0, s := 1.0) -> void:
	_begin(c, p, face, s)
	match kind:
		0:
			_robot(c, t)
		1:
			_archer(c, t)
		_:
			_mage(c, t)
	_end(c)

static func _robot(c: CanvasItem, t: float) -> void:
	var blink := 1.0 if fmod(t, 2.4) < 2.2 else 0.15
	c.draw_rect(Rect2(-10, 16, 8, 7), Color("6f7a8a"))
	c.draw_rect(Rect2(2, 16, 8, 7), Color("6f7a8a"))
	c.draw_rect(Rect2(-18, 3, 6, 13), Color("9aa5b5"))
	c.draw_rect(Rect2(12, 3, 6, 13), Color("9aa5b5"))
	c.draw_rect(Rect2(-12, 1, 24, 16), Color("f2c94c"))
	c.draw_rect(Rect2(-8, 5, 16, 8), Color("c99a1f"))
	c.draw_circle(Vector2(0, 9), 3.0, Color(0.4, 0.95, 1.0, 0.55 + 0.45 * sin(t * 4.0)))
	c.draw_line(Vector2(0, -22), Vector2(0, -31), Color("9aa5b5"), 2.0)
	c.draw_circle(Vector2(0, -33), 3.5, Color("ff5a5a") if fmod(t, 1.0) < 0.5 else Color("a33a3a"))
	c.draw_rect(Rect2(-14, -22, 28, 22), Color("f2c94c"))
	c.draw_rect(Rect2(-10, -18, 20, 13), Color("2a3447"))
	c.draw_rect(Rect2(-7, -15, 5, 7.0 * blink), Color("6ff0ff"))
	c.draw_rect(Rect2(2, -15, 5, 7.0 * blink), Color("6ff0ff"))

static func _archer(c: CanvasItem, t: float) -> void:
	c.draw_colored_polygon(PackedVector2Array([Vector2(-11, 0), Vector2(11, 0), Vector2(16, 22), Vector2(-16, 22)]), Color("2f7d4f"))
	c.draw_rect(Rect2(-9, 16, 8, 7), Color("5a3a28"))
	c.draw_rect(Rect2(1, 16, 8, 7), Color("5a3a28"))
	c.draw_rect(Rect2(-11, 2, 22, 14), Color("4caf6e"))
	c.draw_rect(Rect2(-11, 11, 22, 3), Color("8a5a2b"))
	# carquois et flèches
	c.draw_rect(Rect2(-18, -1, 6, 17), Color("6b4a32"))
	for i in range(3):
		c.draw_line(Vector2(-17 + i * 2, -1), Vector2(-17 + i * 2, -7), Color("f0f0f0"), 1.5)
	# arc
	c.draw_arc(Vector2(13, 3), 17.0, -1.2, 1.2, 14, Color("8a5a2b"), 3.0, true)
	c.draw_line(Vector2(13.0 + 17.0 * cos(-1.2), 3.0 + 17.0 * sin(-1.2)), Vector2(13.0 + 17.0 * cos(1.2), 3.0 + 17.0 * sin(1.2)), Color("eeeeee"), 1.5)
	# capuche, visage, plume
	c.draw_circle(Vector2(0, -10), 16, Color("2f7d4f"))
	c.draw_circle(Vector2(1, -8), 11, SKIN)
	_eyes(c, -8, 4.2, 3.0)
	c.draw_colored_polygon(PackedVector2Array([Vector2(-13, -18), Vector2(2, -33), Vector2(14, -17)]), Color("2f7d4f"))
	c.draw_line(Vector2(2, -33), Vector2(10, -38 + sin(t * 3.0) * 1.5), Color("ff7b7b"), 3.0)

static func _mage(c: CanvasItem, t: float) -> void:
	# robe
	c.draw_colored_polygon(PackedVector2Array([Vector2(-11, 1), Vector2(11, 1), Vector2(17, 23), Vector2(-17, 23)]), Color("7a54c8"))
	c.draw_rect(Rect2(-12, 11, 24, 3), Color("f8d780"))
	c.draw_rect(Rect2(-17, 21, 34, 3), Color("5a3a9c"))
	# bâton lumineux
	c.draw_line(Vector2(18, 24), Vector2(18, -16), Color("8a5a2b"), 3.0)
	var glow := 6.0 + sin(t * 4.0) * 1.5
	c.draw_circle(Vector2(18, -21), glow + 5.0, Color(0.5, 1.0, 1.0, 0.25))
	c.draw_circle(Vector2(18, -21), glow, Color("7cf0ff"))
	c.draw_circle(Vector2(16, 6), 4.0, SKIN)
	# tête, cheveux, yeux
	c.draw_circle(Vector2(-11, -4), 5.0, Color("ff9fd6"))
	c.draw_circle(Vector2(11, -4), 5.0, Color("ff9fd6"))
	c.draw_circle(Vector2(0, -8), 12, SKIN)
	_eyes(c, -6, 4.5, 3.2)
	# chapeau pointu avec étoile
	c.draw_colored_polygon(PackedVector2Array([Vector2(-20, -14), Vector2(20, -14), Vector2(12, -19), Vector2(-12, -19)]), Color("5a3a9c"))
	c.draw_colored_polygon(PackedVector2Array([Vector2(-12, -17), Vector2(12, -17), Vector2(5, -36), Vector2(-1, -42)]), Color("7a54c8"))
	c.draw_circle(Vector2(0, -26), 3.0, Color("ffe299"))

# ---------------------------------------------------------------- ENNEMIS
# kind 0 = gluant (slime), 1 = gobelin, 2 = chauve-souris
static func enemy(c: CanvasItem, kind: int, p: Vector2, dir := 1.0, t := 0.0) -> void:
	_begin(c, p, dir, 1.0)
	match kind:
		0:
			_slime(c, t)
		1:
			_goblin(c, t)
		_:
			_bat(c, t)
	_end(c)

static func _slime(c: CanvasItem, t: float) -> void:
	var h := 40.0 + sin(t * 5.0) * 3.0
	var pts := PackedVector2Array()
	for i in range(13):
		var a := PI + PI * float(i) / 12.0
		pts.append(Vector2(cos(a) * 24.0, 22.0 + sin(a) * h))
	c.draw_colored_polygon(pts, Color("5fcf6b"))
	c.draw_circle(Vector2(-11, -6), 4.0, Color(1, 1, 1, 0.45))
	for sx in [-1.0, 1.0]:
		c.draw_circle(Vector2(sx * 8.0, 4.0), 5.5, Color.WHITE)
		c.draw_circle(Vector2(sx * 8.0 + 1.0, 5.0), 2.6, DARK)
		c.draw_line(Vector2(sx * 14.0, -4.0), Vector2(sx * 3.0, 0.0), Color("2d7a3a"), 3.0)
	c.draw_arc(Vector2(0, 18), 6.0, PI + 0.3, TAU - 0.3, 10, Color("2d7a3a"), 2.5)

static func _goblin(c: CanvasItem, t: float) -> void:
	var st := sin(t * 10.0) * 3.0
	c.draw_rect(Rect2(-9 + st, 16, 8, 7), Color("4a3a2a"))
	c.draw_rect(Rect2(1 - st, 16, 8, 7), Color("4a3a2a"))
	c.draw_rect(Rect2(-11, 2, 22, 15), Color("8a5a2b"))
	c.draw_rect(Rect2(-11, 10, 22, 3), Color("4a3a2a"))
	# massue
	c.draw_line(Vector2(12, 8), Vector2(24, -12), Color("6b4a32"), 5.0)
	c.draw_circle(Vector2(25, -14), 7.0, Color("5a3d28"))
	# oreilles pointues
	c.draw_colored_polygon(PackedVector2Array([Vector2(-10, -12), Vector2(-28, -19), Vector2(-11, -2)]), Color("6f9b43"))
	c.draw_colored_polygon(PackedVector2Array([Vector2(10, -12), Vector2(28, -19), Vector2(11, -2)]), Color("6f9b43"))
	c.draw_circle(Vector2(0, -8), 14, Color("7fae4f"))
	for sx in [-1.0, 1.0]:
		c.draw_circle(Vector2(sx * 5.5, -9), 3.6, Color("fff2a0"))
		c.draw_circle(Vector2(sx * 5.5, -9), 1.6, Color("b01e1e"))
		c.draw_line(Vector2(sx * 10.0, -16), Vector2(sx * 2.0, -12), Color("2f4a1c"), 2.5)
	# bouche et dents
	c.draw_rect(Rect2(-6, -1, 12, 5), Color("3a1d1d"))
	c.draw_colored_polygon(PackedVector2Array([Vector2(-5, -1), Vector2(-1, -1), Vector2(-3, 3)]), Color.WHITE)
	c.draw_colored_polygon(PackedVector2Array([Vector2(1, -1), Vector2(5, -1), Vector2(3, 3)]), Color.WHITE)

static func _bat(c: CanvasItem, t: float) -> void:
	var tip := -10.0 + sin(t * 14.0) * 12.0
	for sx in [-1.0, 1.0]:
		c.draw_colored_polygon(PackedVector2Array([Vector2(sx * 6.0, -4.0), Vector2(sx * 30.0, tip), Vector2(sx * 24.0, 6.0), Vector2(sx * 8.0, 8.0)]), Color("3d2b66"))
		c.draw_colored_polygon(PackedVector2Array([Vector2(sx * 3.0, -9.0), Vector2(sx * 9.0, -19.0), Vector2(sx * 11.0, -7.0)]), Color("55407f"))
	c.draw_circle(Vector2(0, 0), 11.0, Color("55407f"))
	for sx in [-1.0, 1.0]:
		c.draw_circle(Vector2(sx * 4.5, -2.0), 2.8, Color("ff4b4b"))
		c.draw_colored_polygon(PackedVector2Array([Vector2(sx * 5.0 - 1.5, 5.0), Vector2(sx * 5.0 + 1.5, 5.0), Vector2(sx * 5.0, 10.0)]), Color.WHITE)

# ---------------------------------------------------------------- MONSTRE
# Grogoth, le Monstre des Ombres (rage 0..1 : devient rouge quand il est blessé).
static func monster(c: CanvasItem, p: Vector2, s := 1.0, rage := 0.0, t := 0.0, face := 1.0) -> void:
	_begin(c, p, face, s)
	var r := clampf(rage, 0.0, 1.0)
	var body := Color("4a2b6e").lerp(Color("8a1f3c"), r)
	var belly := Color("7a58a8").lerp(Color("c0506a"), r)
	var bone := Color("f0e6c8")
	var bob := sin(t * 3.0) * 3.0
	# pieds
	for sx in [-1.0, 1.0]:
		c.draw_circle(Vector2(sx * 27.0, 44.0), 13.0, body.darkened(0.3))
	# bras et griffes
	for sx in [-1.0, 1.0]:
		c.draw_circle(Vector2(sx * 54.0, 8.0 + bob), 15.0, body.darkened(0.12))
		for k in [-1.0, 0.0, 1.0]:
			var cx: float = sx * 54.0 + k * 8.0
			c.draw_colored_polygon(PackedVector2Array([Vector2(cx - 3.0, 18.0 + bob), Vector2(cx + 3.0, 18.0 + bob), Vector2(cx, 31.0 + bob)]), bone)
	# corps et ventre
	c.draw_circle(Vector2(0, 2), 50.0, body)
	c.draw_circle(Vector2(0, 18), 29.0, belly)
	# pointes sur la tête
	for k in [-1.0, 0.0, 1.0]:
		c.draw_colored_polygon(PackedVector2Array([Vector2(k * 14.0 - 7.0, -46.0), Vector2(k * 14.0, -62.0), Vector2(k * 14.0 + 7.0, -46.0)]), body.darkened(0.25))
	# cornes
	for sx in [-1.0, 1.0]:
		c.draw_colored_polygon(PackedVector2Array([Vector2(sx * 28.0, -34.0), Vector2(sx * 54.0, -80.0), Vector2(sx * 12.0, -46.0)]), bone)
	# yeux furieux
	for sx in [-1.0, 1.0]:
		c.draw_circle(Vector2(sx * 19.0, -14.0), 13.0, Color(1.0, 0.9, 0.2, 0.3))
		c.draw_circle(Vector2(sx * 19.0, -14.0), 10.0, Color("ffe36b"))
		c.draw_rect(Rect2(sx * 19.0 - 2.0, -22.0, 4.0, 16.0), Color("3a0f1c"))
		c.draw_line(Vector2(sx * 34.0, -33.0), Vector2(sx * 6.0, -21.0), body.darkened(0.6), 7.0)
	# gueule et crocs
	c.draw_colored_polygon(PackedVector2Array([Vector2(-28, 12), Vector2(28, 12), Vector2(22, 36), Vector2(-22, 36)]), Color("2a0d1c"))
	for k in range(4):
		var tx := -24.0 + float(k) * 12.0
		c.draw_colored_polygon(PackedVector2Array([Vector2(tx, 12), Vector2(tx + 10.0, 12), Vector2(tx + 5.0, 24)]), Color.WHITE)
	for k in range(3):
		var bx := -17.0 + float(k) * 12.0
		c.draw_colored_polygon(PackedVector2Array([Vector2(bx, 36), Vector2(bx + 10.0, 36), Vector2(bx + 5.0, 26)]), Color.WHITE)
	_end(c)

# ---------------------------------------------------------------- ARME : ÉPÉE DE LUMIÈRE
# p = point posé sur le socle (le socle touche le sol à p.y + 35).
static func sword(c: CanvasItem, p: Vector2, t := 0.0) -> void:
	var bob := sin(t * 3.0) * 4.0
	c.draw_circle(p + Vector2(0, bob - 10.0), 32.0, Color(0.5, 0.95, 1.0, 0.14 + 0.06 * sin(t * 5.0)))
	c.draw_rect(Rect2(p.x - 18.0, p.y + 25.0, 36.0, 10.0), Color("6f7a8a"))
	c.draw_rect(Rect2(p.x - 12.0, p.y + 15.0, 24.0, 10.0), Color("8f9cb3"))
	c.draw_set_transform(p + Vector2(0, bob), 0.0, Vector2.ONE)
	c.draw_rect(Rect2(-3, -34, 6, 34), Color("c8f8ff"))
	c.draw_rect(Rect2(-1, -34, 2, 34), Color.WHITE)
	c.draw_colored_polygon(PackedVector2Array([Vector2(-3, -34), Vector2(3, -34), Vector2(0, -42)]), Color("c8f8ff"))
	c.draw_rect(Rect2(-10, 0, 20, 4), Color("f8d780"))
	c.draw_rect(Rect2(-2, 4, 4, 10), Color("8a5a2b"))
	c.draw_circle(Vector2(0, 16), 3.0, Color("f35e61"))
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# Rayon de lumière tiré par l'épée (dir = 1.0 vers la droite, -1.0 vers la gauche).
static func beam(c: CanvasItem, p: Vector2, dir := 1.0) -> void:
	c.draw_circle(p + Vector2(dir * 8.0, 0), 18.0, Color(0.5, 1.0, 1.0, 0.18))
	c.draw_set_transform(p, 0.0, Vector2(dir, 1.0))
	c.draw_rect(Rect2(-34, -3, 20, 6), Color(0.6, 0.95, 1.0, 0.35))
	c.draw_rect(Rect2(-22, -5, 28, 10), Color(0.6, 0.97, 1.0, 0.6))
	c.draw_rect(Rect2(-14, -3, 28, 6), Color.WHITE)
	c.draw_colored_polygon(PackedVector2Array([Vector2(14, -8), Vector2(14, 8), Vector2(26, 0)]), Color("c8f8ff"))
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# ---------------------------------------------------------------- CLÉ (pixel art)
static func key(c: CanvasItem, p: Vector2, t := 0.0) -> void:
	var gold := Color("ffd34d")
	var gold_d := Color("c8901a")
	c.draw_circle(p, 22.0, Color(1.0, 0.85, 0.3, 0.12 + 0.06 * sin(t * 4.0)))
	c.draw_set_transform(p, -0.6, Vector2.ONE)
	# anneau
	c.draw_rect(Rect2(-18, -8, 16, 4), gold)
	c.draw_rect(Rect2(-18, 4, 16, 4), gold)
	c.draw_rect(Rect2(-18, -4, 4, 8), gold)
	c.draw_rect(Rect2(-6, -4, 4, 8), gold)
	c.draw_rect(Rect2(-18, 6, 16, 2), gold_d)
	c.draw_rect(Rect2(-16, -6, 4, 2), Color("fff2a8"))
	# tige et dents
	c.draw_rect(Rect2(-2, -2, 22, 4), gold)
	c.draw_rect(Rect2(-2, 0, 22, 2), gold_d)
	c.draw_rect(Rect2(10, 2, 4, 6), gold)
	c.draw_rect(Rect2(16, 2, 4, 8), gold)
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# ---------------------------------------------------------------- CAGE
# locked = true : cadenas fermé. locked = false : cadenas ouvert et cage verdie.
static func cage(c: CanvasItem, r: Rect2, _t := 0.0, locked := true) -> void:
	c.draw_rect(r, Color(0.7, 0.85, 0.95, 0.15) if locked else Color(0.5, 1.0, 0.6, 0.18))
	var bars := Color("b5d4dc") if locked else Color("9af0b0")
	c.draw_rect(r, bars, false, 3.0)
	for i in range(1, 5):
		var x := r.position.x + r.size.x * float(i) / 5.0
		c.draw_line(Vector2(x, r.position.y), Vector2(x, r.end.y), bars, 2.0)
	c.draw_line(Vector2(r.position.x - 4.0, r.position.y), Vector2(r.end.x + 4.0, r.position.y), Color("8fa9b3"), 5.0)
	var m := Vector2(r.get_center().x, r.end.y - 8.0)
	c.draw_rect(Rect2(m - Vector2(6, 3), Vector2(12, 10)), Color("f8d780"))
	if locked:
		c.draw_arc(m - Vector2(0, 3), 5.0, PI, TAU, 8, Color("f8d780"), 2.0)
	else:
		c.draw_arc(m + Vector2(6, -9), 5.0, PI, TAU, 8, Color("f8d780"), 2.0)
