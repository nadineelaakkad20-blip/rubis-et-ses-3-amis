extends Control
# Cadre des menus (titre, pause, niveau terminé, défaite, victoire).
# Style du jeu : pierre sombre de la forteresse, bordure dorée, rubis aux quatre coins,
# ruban rouge pour le titre et petites lucioles animées comme dans les niveaux.

const THEMES := {
	"title": {"accent": Color("f8d780"), "top": Color("1d4a58"), "bottom": Color("0d2530"), "gem": Color("e8384f"), "ribbon": Color("c0283e"), "glow": Color("fff2a0")},
	"pause": {"accent": Color("72d6be"), "top": Color("1a4a50"), "bottom": Color("0c262e"), "gem": Color("e8384f"), "ribbon": Color("22857a"), "glow": Color("9ff6e0")},
	"clear": {"accent": Color("a8f0b0"), "top": Color("1d5040"), "bottom": Color("0d2a22"), "gem": Color("e8384f"), "ribbon": Color("2f9a52"), "glow": Color("d6ffd0")},
	"dead": {"accent": Color("ff9a8f"), "top": Color("3a2046"), "bottom": Color("180d24"), "gem": Color("e8384f"), "ribbon": Color("8a2338"), "glow": Color("ff7a6a")},
	"win": {"accent": Color("ffd34d"), "top": Color("3a2c5e"), "bottom": Color("17112e"), "gem": Color("e8384f"), "ribbon": Color("d9414b"), "glow": Color("fff2a0")},
}
const CONFETTI := [Color("ff7b9c"), Color("ffd166"), Color("72e4c0"), Color("a994ec"), Color("f35e61"), Color("7cf0ff")]

var kind := "title"
var t := 0.0
var volume := 0.5
var muted := false
var sparks: Array[Vector3] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	for i in range(22):
		sparks.append(Vector3(randf(), randf(), randf()))

func set_kind(new_kind: String) -> void:
	kind = new_kind if THEMES.has(new_kind) else "title"
	queue_redraw()

func accent() -> Color:
	var th: Dictionary = THEMES[kind]
	return th["accent"]

func _process(delta: float) -> void:
	if is_visible_in_tree():
		t += delta
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

func _fill(rect: Rect2, c: float, color: Color) -> void:
	draw_colored_polygon(_chamfer(rect, c), color)

func _gradient(rect: Rect2, c: float, top: Color, bottom: Color) -> void:
	var pts := _chamfer(rect, c)
	var cols := PackedColorArray()
	for p in pts:
		cols.append(top.lerp(bottom, clampf((p.y - rect.position.y) / rect.size.y, 0.0, 1.0)))
	draw_polygon(pts, cols)

func _gem(c: Vector2, r: float, color: Color) -> void:
	var up := c + Vector2(0, -r)
	var right := c + Vector2(r * 0.8, 0)
	var down := c + Vector2(0, r)
	var left := c + Vector2(-r * 0.8, 0)
	draw_colored_polygon(PackedVector2Array([up, right, down, left]), color)
	draw_colored_polygon(PackedVector2Array([up, right, c]), color.lightened(0.35))
	draw_colored_polygon(PackedVector2Array([left, down, c]), color.darkened(0.3))
	draw_polyline(PackedVector2Array([up, right, down, left, up]), Color("f8d780"), 2.0)
	draw_rect(Rect2(c.x - r * 0.3, c.y - r * 0.5, 3, 3), Color(1, 1, 1, 0.9))

# ---------------------------------------------------------------- DESSIN
func _draw() -> void:
	var th: Dictionary = THEMES[kind]
	var accent_c: Color = th["accent"]
	var w := size.x
	var h := size.y
	# Ombre portée et bordure dorée à coins coupés (style pixel art).
	_fill(Rect2(8, 10, w, h), 18.0, Color(0, 0, 0, 0.38))
	_fill(Rect2(0, 0, w, h), 18.0, accent_c.darkened(0.35))
	_fill(Rect2(3, 3, w - 6, h - 6), 16.0, accent_c)
	_fill(Rect2(8, 8, w - 16, h - 16), 13.0, Color(0.04, 0.06, 0.09))
	_gradient(Rect2(12, 12, w - 24, h - 24), 10.0, th["top"], th["bottom"])
	# Rivets sur la bordure.
	var rivet := accent_c.darkened(0.5)
	var x := 48.0
	while x < w - 40.0:
		draw_rect(Rect2(x, 2, 4, 4), rivet)
		draw_rect(Rect2(x, h - 6, 4, 4), rivet)
		x += 36.0
	var y := 48.0
	while y < h - 40.0:
		draw_rect(Rect2(2, y, 4, 4), rivet)
		draw_rect(Rect2(w - 6, y, 4, 4), rivet)
		y += 36.0
	# Filet intérieur.
	var line_col := accent_c
	line_col.a = 0.45
	var inner := _chamfer(Rect2(20, 20, w - 40, h - 40), 8.0)
	inner.append(inner[0])
	draw_polyline(inner, line_col, 2.0)
	_draw_sparks(th)
	# Séparateurs ornés.
	_divider(72.0, accent_c)
	_divider(352.0, accent_c)
	# Rubis aux quatre coins.
	var gem_col: Color = th["gem"]
	for corner in [Vector2(26, 26), Vector2(w - 26, 26), Vector2(26, h - 26), Vector2(w - 26, h - 26)]:
		draw_circle(corner, 15.0, accent_c.darkened(0.3))
		draw_circle(corner, 13.0, accent_c)
		_gem(corner, 11.0, gem_col)
	_ribbon(w, th)
	_speaker(Vector2(72, 386), accent_c)

func _divider(y: float, color: Color) -> void:
	var cx := size.x * 0.5
	var c := color
	c.a = 0.55
	draw_line(Vector2(56, y), Vector2(cx - 22, y), c, 2.0)
	draw_line(Vector2(cx + 22, y), Vector2(size.x - 56, y), c, 2.0)
	_gem(Vector2(cx, y), 7.0, Color("e8384f"))
	for sx in [-1.0, 1.0]:
		var p := Vector2(cx + sx * 36.0, y)
		draw_colored_polygon(PackedVector2Array([p + Vector2(0, -4), p + Vector2(4, 0), p + Vector2(0, 4), p + Vector2(-4, 0)]), color)

func _ribbon(w: float, th: Dictionary) -> void:
	var accent_c: Color = th["accent"]
	var rc: Color = th["ribbon"]
	var rw := minf(w - 130.0, 620.0)
	var x0 := (w - rw) * 0.5
	var x1 := x0 + rw
	var y0 := -26.0
	var y1 := 30.0
	var mid := (y0 + y1) * 0.5 + 12.0
	# Queues du ruban (en arrière).
	draw_colored_polygon(PackedVector2Array([Vector2(x0 - 40, y0 + 12), Vector2(x0 + 18, y0 + 12), Vector2(x0 + 18, y1 + 12), Vector2(x0 - 40, y1 + 12), Vector2(x0 - 24, mid)]), rc.darkened(0.35))
	draw_colored_polygon(PackedVector2Array([Vector2(x1 + 40, y0 + 12), Vector2(x1 - 18, y0 + 12), Vector2(x1 - 18, y1 + 12), Vector2(x1 + 40, y1 + 12), Vector2(x1 + 24, mid)]), rc.darkened(0.35))
	# Plis.
	draw_colored_polygon(PackedVector2Array([Vector2(x0, y1), Vector2(x0 + 18, y1), Vector2(x0 + 18, y1 + 12)]), rc.darkened(0.6))
	draw_colored_polygon(PackedVector2Array([Vector2(x1, y1), Vector2(x1 - 18, y1), Vector2(x1 - 18, y1 + 12)]), rc.darkened(0.6))
	# Ruban principal.
	draw_rect(Rect2(x0, y0, rw, y1 - y0), rc)
	draw_rect(Rect2(x0, y0 + 4, rw, 6), rc.lightened(0.22))
	draw_rect(Rect2(x0, y1 - 8, rw, 8), rc.darkened(0.2))
	draw_rect(Rect2(x0, y0, rw, 4), accent_c)
	draw_rect(Rect2(x0, y1 - 4, rw, 4), accent_c)
	draw_rect(Rect2(x0, y0, 4, y1 - y0), accent_c)
	draw_rect(Rect2(x1 - 4, y0, 4, y1 - y0), accent_c)
	_gem(Vector2(x0 + 20, (y0 + y1) * 0.5), 8.0, Color("ffd34d"))
	_gem(Vector2(x1 - 20, (y0 + y1) * 0.5), 8.0, Color("ffd34d"))

func _speaker(c: Vector2, color: Color) -> void:
	draw_rect(Rect2(c.x - 12, c.y - 5, 7, 10), color)
	draw_colored_polygon(PackedVector2Array([Vector2(c.x - 5, c.y - 5), Vector2(c.x + 4, c.y - 12), Vector2(c.x + 4, c.y + 12), Vector2(c.x - 5, c.y + 5)]), color)
	var off := muted or volume <= 0.001
	if off:
		draw_line(Vector2(c.x + 9, c.y - 7), Vector2(c.x + 21, c.y + 7), Color("ff7a7a"), 3.0)
		draw_line(Vector2(c.x + 21, c.y - 7), Vector2(c.x + 9, c.y + 7), Color("ff7a7a"), 3.0)
		return
	var waves := 1 + int(volume * 2.99)
	for i in range(waves):
		var r := 8.0 + 6.0 * float(i)
		draw_arc(c + Vector2(3, 0), r, -0.7, 0.7, 8, color, 2.5)

func _draw_sparks(th: Dictionary) -> void:
	var glow: Color = th["glow"]
	var w := size.x
	var h := size.y
	for i in range(sparks.size()):
		var s := sparks[i]
		var px := 24.0 + fposmod(s.x * (w - 48.0) + sin(t * 0.7 + s.y * 9.0) * 14.0, w - 48.0)
		var py := 0.0
		match kind:
			"win":
				py = 20.0 + fposmod(s.y * (h - 40.0) + t * (30.0 + s.z * 50.0), h - 40.0)
			"dead":
				py = 20.0 + fposmod(s.y * (h - 40.0) - t * (16.0 + s.z * 26.0), h - 40.0)
			_:
				py = 30.0 + s.y * (h - 60.0) + sin(t * (0.8 + s.z) + s.x * 12.0) * 10.0
		var alpha := 0.25 + 0.35 * (0.5 + 0.5 * sin(t * 2.5 + s.x * 20.0))
		if kind == "win":
			var cc: Color = CONFETTI[i % CONFETTI.size()]
			cc.a = 0.75
			draw_rect(Rect2(px, py, 6, 4), cc)
		else:
			var gc := glow
			gc.a = alpha
			draw_rect(Rect2(px, py, 3, 3), gc)
