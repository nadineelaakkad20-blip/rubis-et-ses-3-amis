extends Control
# Barre du haut : niveau, vies (cœurs), clés, amis libérés, score,
# et guide des touches sous forme de petites touches de clavier.
# Les couleurs de la bordure suivent la difficulté du niveau (vert, orange, rouge).

const Sfx = preload("res://scripts/sfx.gd")
const FRIEND_COLORS := [Color("f8d35a"), Color("6fd36f"), Color("b48cf0")]
const GUIDE := [
	[["FLÈCHES", "Q", "D"], "Bouger"],
	[["ESPACE", "Z"], "Sauter"],
	[["F", "X"], "Tirer (épée)"],
	[["P"], "Pause"],
	[["R"], "Recommencer"],
	[["M"], "Musique"],
]

var audio: Sfx
var level_title := ""
var tier_text := ""
var tier_color := Color("a8f0b0")
var health := 3
var keys_have := 0
var keys_needed := 3
var rescued := 0
var score := 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(1112, 76)

func set_data(title: String, tier: String, color: Color, lives: int, keys: int, keys_total: int, friends: int, points: int) -> void:
	level_title = title
	tier_text = tier
	tier_color = color
	health = lives
	keys_have = keys
	keys_needed = keys_total
	rescued = friends
	score = points
	queue_redraw()

func _process(_delta: float) -> void:
	queue_redraw()

# ---------------------------------------------------------------- OUTILS
func _chamfer(rect: Rect2, c: float) -> PackedVector2Array:
	var x := rect.position.x
	var y := rect.position.y
	var w := rect.size.x
	var h := rect.size.y
	return PackedVector2Array([
		Vector2(x + c, y), Vector2(x + w - c, y), Vector2(x + w, y + c), Vector2(x + w, y + h - c),
		Vector2(x + w - c, y + h), Vector2(x + c, y + h), Vector2(x, y + h - c), Vector2(x, y + c)])

func _gem(c: Vector2, r: float, color: Color) -> void:
	var up := c + Vector2(0, -r)
	var right := c + Vector2(r * 0.8, 0)
	var down := c + Vector2(0, r)
	var left := c + Vector2(-r * 0.8, 0)
	draw_colored_polygon(PackedVector2Array([up, right, down, left]), color)
	draw_colored_polygon(PackedVector2Array([up, right, c]), color.lightened(0.35))
	draw_colored_polygon(PackedVector2Array([left, down, c]), color.darkened(0.3))
	draw_polyline(PackedVector2Array([up, right, down, left, up]), Color("f8d780"), 1.5)

func _heart(c: Vector2, r: float, color: Color) -> void:
	draw_circle(c + Vector2(-r * 0.5, -r * 0.1), r * 0.55, color)
	draw_circle(c + Vector2(r * 0.5, -r * 0.1), r * 0.55, color)
	draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 1.02, r * 0.05), c + Vector2(r * 1.02, r * 0.05), c + Vector2(0, r * 1.2)]), color)

func _key_icon(c: Vector2, color: Color) -> void:
	draw_circle(c + Vector2(-8, 0), 7.0, color)
	draw_circle(c + Vector2(-8, 0), 3.0, Color("0d2530"))
	draw_rect(Rect2(c.x - 2, c.y - 2, 18, 4), color)
	draw_rect(Rect2(c.x + 9, c.y + 1, 3, 7), color)
	draw_rect(Rect2(c.x + 14, c.y + 1, 3, 5), color)

func _separator(x: float) -> void:
	draw_line(Vector2(x, 11), Vector2(x, 40), Color(1, 1, 1, 0.18), 2.0)

func _text(pos: Vector2, text: String, font_size: int, color: Color) -> void:
	var font := ThemeDB.fallback_font
	draw_string(font, pos + Vector2(1, 2), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0, 0, 0, 0.45))
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _cap(x: float, y: float, text: String) -> float:
	var font := ThemeDB.fallback_font
	var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	var w := maxf(20.0, tw + 12.0)
	draw_rect(Rect2(x, y + 2, w, 20), Color("6b8a86"))
	draw_rect(Rect2(x, y, w, 19), Color("eaf7ee"))
	draw_rect(Rect2(x, y, w, 2), Color.WHITE)
	draw_string(font, Vector2(x + (w - tw) * 0.5, y + 14), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("17323a"))
	return w

# ---------------------------------------------------------------- DESSIN
func _draw() -> void:
	var w := size.x
	var h := size.y
	var font := ThemeDB.fallback_font
	# Cadre : bordure de la couleur de difficulté, fond pierre sombre.
	draw_colored_polygon(_chamfer(Rect2(5, 7, w, h), 12.0), Color(0, 0, 0, 0.3))
	draw_colored_polygon(_chamfer(Rect2(0, 0, w, h), 12.0), tier_color.darkened(0.4))
	draw_colored_polygon(_chamfer(Rect2(2, 2, w - 4, h - 4), 10.0), tier_color)
	draw_colored_polygon(_chamfer(Rect2(5, 5, w - 10, h - 10), 8.0), Color(0.04, 0.06, 0.09))
	var pts := _chamfer(Rect2(7, 7, w - 14, h - 14), 7.0)
	var cols := PackedColorArray()
	for p in pts:
		cols.append(Color("1d4a58").lerp(Color("0d2530"), clampf((p.y - 7.0) / (h - 14.0), 0.0, 1.0)))
	draw_polygon(pts, cols)
	draw_line(Vector2(20, 45), Vector2(w - 20, 45), Color(1, 1, 1, 0.12), 2.0)
	# Rivets.
	var x := 40.0
	while x < w - 30.0:
		draw_rect(Rect2(x, 1, 3, 3), tier_color.darkened(0.5))
		draw_rect(Rect2(x, h - 4, 3, 3), tier_color.darkened(0.5))
		x += 40.0

	# --- Ligne 1 : niveau
	_gem(Vector2(32, 26), 11.0, Color("e8384f"))
	_text(Vector2(52, 33), level_title, 19, tier_color)
	var title_w := font.get_string_size(level_title, HORIZONTAL_ALIGNMENT_LEFT, -1, 19).x
	var pill_x := 52.0 + title_w + 12.0
	var pill_w := font.get_string_size(tier_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x + 18.0
	draw_rect(Rect2(pill_x, 16, pill_w, 22), tier_color)
	draw_rect(Rect2(pill_x, 36, pill_w, 2), tier_color.darkened(0.3))
	draw_string(font, Vector2(pill_x + 9, 32), tier_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("10242c"))

	# --- Vies
	_separator(500.0)
	for i in range(3):
		var full := i < health
		_heart(Vector2(536 + i * 36, 24), 11.0, Color("ff4d63") if full else Color("2a3a4a"))
		if full:
			draw_circle(Vector2(531 + i * 36, 19), 2.5, Color(1, 1, 1, 0.7))
	# --- Clés
	_separator(662.0)
	for i in range(keys_needed):
		_key_icon(Vector2(696 + i * 40, 26), Color("ffd34d") if i < keys_have else Color("2a3a4a"))
	# --- Amis libérés
	_separator(830.0)
	for i in range(3):
		var c := Vector2(862 + i * 40, 26)
		if i < rescued:
			var fc: Color = FRIEND_COLORS[i]
			draw_circle(c, 15.0, Color("ffd34d"))
			draw_circle(c, 12.0, fc)
			draw_circle(c + Vector2(-4, -2), 2.0, Color("1b2335"))
			draw_circle(c + Vector2(4, -2), 2.0, Color("1b2335"))
			draw_arc(c + Vector2(0, 1), 5.0, 0.3, PI - 0.3, 8, Color("1b2335"), 1.5)
		else:
			draw_circle(c, 15.0, Color("3a4a5a"))
			draw_circle(c, 12.0, Color("1a2836"))
			draw_string(font, c + Vector2(-4, 6), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("6b7f90"))
	# --- Score
	_separator(980.0)
	draw_string(font, Vector2(996, 19), "SCORE", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("8fb7ae"))
	_text(Vector2(996, 41), "%04d" % score, 22, Color("f8d780"))

	# --- Ligne 2 : guide des touches
	var gx := 24.0
	var gy := 48.0
	for item in GUIDE:
		var caps: Array = item[0]
		var label: String = item[1]
		for cap_text in caps:
			gx += _cap(gx, gy, str(cap_text)) + 4.0
		if label == "Musique":
			if audio != null and (audio.muted or audio.music_volume <= 0.001):
				label = "Musique : coupée"
			elif audio != null:
				label = "Musique : %d %%" % int(round(audio.music_volume * 100.0))
		draw_string(font, Vector2(gx + 2, gy + 15), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("b6d9ce"))
		gx += font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x + 26.0
