extends Control
# Scènes d'histoire animées, dessinées par code. Affichées avant le jeu (0 à 4) et à la fin (5).
signal finished

const Art = preload("res://scripts/art.gd")
const W := 1152.0
const ART_H := 470.0
const FLOWERS := [Color("ff7b9c"), Color("ffd166"), Color("ffffff")]
const CONFETTI := [Color("ff7b9c"), Color("ffd166"), Color("72e4c0"), Color("a994ec"), Color("f35e61"), Color("7cf0ff")]

const SCENES := [
	{"title": "CHAPITRE 1 - LE ROYAUME DE VERDALIA", "button": "SUIVANT",
		"text": "Dans le paisible royaume de Verdalia, quatre amis inséparables vivaient de grandes aventures : Rubis le chevalier, Robin l'archère, Mira la magicienne et Bolt le robot."},
	{"title": "CHAPITRE 2 - UNE NUIT TROP CALME", "button": "SUIVANT",
		"text": "Un soir, après une longue journée, les quatre amis se reposent autour du feu de camp en riant. Mais dans l'ombre de la forêt, des yeux rouges les observent..."},
	{"title": "CHAPITRE 3 - L'ATTAQUE DE GROGOTH", "button": "SUIVANT",
		"text": "Soudain, le terrible monstre Grogoth surgit des ténèbres ! D'un geste de sa griffe, il enferme Robin, Mira et Bolt dans des cages magiques !"},
	{"title": "CHAPITRE 4 - LA FORTERESSE NOIRE", "button": "SUIVANT",
		"text": "Grogoth emporte ses prisonniers vers sa sombre forteresse. Rubis, le seul à lui avoir échappé, jure de sauver ses trois amis !"},
	{"title": "CHAPITRE 5 - LE LONG CHEMIN", "button": "COMMENCER L'AVENTURE !",
		"text": "Pour les délivrer, Rubis devra relever 6 défis de plus en plus difficiles (FACILE, MOYEN, puis DIFFICILE) et trouver 3 clés par niveau pour ouvrir les cages. Es-tu prêt ?"},
	{"title": "FINAL - LA LIBÉRATION", "button": "SUIVANT",
		"text": "Grogoth s'effondre dans une pluie d'étincelles ! Les cages s'ouvrent une à une et Bolt, Robin et Mira courent retrouver leur ami Rubis."},
	{"title": "FINAL - VICTOIRE !", "button": "CONTINUER",
		"text": "Grâce à ton courage, les quatre amis sont enfin réunis et le royaume de Verdalia retrouve la paix. Bravo, héros !"},
]

var ids: Array = []
var index := 0
var t := 0.0
var shown := 0.0
var fade := 1.0
var caption: Label
var title_label: Label
var next_button: Button
var skip_button: Button

func setup(scene_ids: Array) -> void:
	ids = scene_ids

func _ready() -> void:
	position = Vector2.ZERO
	size = Vector2(1152, 648)
	mouse_filter = Control.MOUSE_FILTER_STOP
	title_label = Label.new()
	title_label.position = Vector2(30, 14)
	title_label.add_theme_font_size_override("font_size", 26)
	title_label.add_theme_color_override("font_color", Color("fff3c4"))
	title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	title_label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(title_label)
	caption = Label.new()
	caption.position = Vector2(50, 488)
	caption.size = Vector2(1052, 96)
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.add_theme_font_size_override("font_size", 22)
	caption.add_theme_color_override("font_color", Color("eaf7ee"))
	add_child(caption)
	skip_button = Button.new()
	skip_button.text = "PASSER L'HISTOIRE"
	skip_button.position = Vector2(50, 596)
	skip_button.size = Vector2(250, 40)
	skip_button.add_theme_font_size_override("font_size", 17)
	skip_button.pressed.connect(_on_skip)
	add_child(skip_button)
	next_button = Button.new()
	next_button.position = Vector2(792, 594)
	next_button.size = Vector2(310, 44)
	next_button.add_theme_font_size_override("font_size", 19)
	next_button.pressed.connect(_on_next)
	add_child(next_button)
	if not ids.is_empty():
		_show_scene(0)
	next_button.grab_focus()

func _show_scene(i: int) -> void:
	index = i
	t = 0.0
	shown = 0.0
	fade = 1.0
	var data: Dictionary = SCENES[ids[i]]
	title_label.text = data.title
	caption.text = data.text
	caption.visible_characters = 0
	next_button.text = data.button

func _on_next() -> void:
	if int(shown) < caption.text.length():
		shown = float(caption.text.length())
		return
	if index + 1 < ids.size():
		_show_scene(index + 1)
	else:
		set_process(false)
		finished.emit()

func _on_skip() -> void:
	set_process(false)
	finished.emit()

func _process(delta: float) -> void:
	t += delta
	fade = maxf(0.0, fade - delta * 1.6)
	shown += delta * 40.0
	caption.visible_characters = int(shown)
	queue_redraw()

# ---------------------------------------------------------------- OUTILS DE DESSIN
func _gradient(top: Color, bottom: Color) -> void:
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(W, 0), Vector2(W, ART_H), Vector2(0, ART_H)]), PackedColorArray([top, top, bottom, bottom]))

func _text(pos: Vector2, text: String, font_size: int, color: Color, width := 400.0) -> void:
	var font := ThemeDB.fallback_font
	draw_string(font, pos + Vector2(2.0 - width / 2.0, 2.0), text, HORIZONTAL_ALIGNMENT_CENTER, width, font_size, Color(0, 0, 0, 0.5))
	draw_string(font, pos - Vector2(width / 2.0, 0.0), text, HORIZONTAL_ALIGNMENT_CENTER, width, font_size, color)

func _bubble(pos: Vector2, text: String) -> void:
	var w := float(text.length()) * 14.0 + 30.0
	draw_rect(Rect2(pos.x - w / 2.0, pos.y - 24.0, w, 40.0), Color(1, 1, 1, 0.95))
	draw_colored_polygon(PackedVector2Array([Vector2(pos.x - 8.0, pos.y + 15.0), Vector2(pos.x + 8.0, pos.y + 15.0), Vector2(pos.x, pos.y + 30.0)]), Color(1, 1, 1, 0.95))
	draw_string(ThemeDB.fallback_font, Vector2(pos.x - w / 2.0, pos.y + 6.0), text, HORIZONTAL_ALIGNMENT_CENTER, w, 22, Color("1b2335"))

func _heart(pos: Vector2, r: float, color: Color) -> void:
	draw_circle(pos + Vector2(-r * 0.5, 0), r * 0.55, color)
	draw_circle(pos + Vector2(r * 0.5, 0), r * 0.55, color)
	draw_colored_polygon(PackedVector2Array([pos + Vector2(-r, r * 0.15), pos + Vector2(r, r * 0.15), pos + Vector2(0, r * 1.25)]), color)

func _circle_y(x: float, cx: float, cy: float, r: float) -> float:
	return cy - sqrt(maxf(0.0, r * r - (x - cx) * (x - cx)))

func _castle(x: float, y: float, s: float) -> void:
	draw_set_transform(Vector2(x, y), 0.0, Vector2(s, s))
	var dark := Color("160c26")
	draw_rect(Rect2(-100, -130, 200, 130), dark)
	var towers := [[-105.0, 200.0, 44.0], [-32.0, 250.0, 50.0], [42.0, 215.0, 46.0], [105.0, 185.0, 40.0]]
	for tw in towers:
		var off: float = tw[0]
		var h: float = tw[1]
		var w: float = tw[2]
		draw_rect(Rect2(off - w / 2.0, -h, w, h), dark)
		draw_colored_polygon(PackedVector2Array([Vector2(off - w / 2.0 - 5.0, -h), Vector2(off, -h - 44.0), Vector2(off + w / 2.0 + 5.0, -h)]), Color("2a1240"))
		var glow := 0.65 + 0.35 * sin(t * 5.0 + off)
		draw_rect(Rect2(off - 4.0, -h + 28.0, 8.0, 14.0), Color(1.0, 0.85, 0.3, glow))
	draw_circle(Vector2(0, -60), 22.0, Color("0c0618"))
	draw_rect(Rect2(-22, -60, 44, 60), Color("0c0618"))
	draw_circle(Vector2(-7, -40), 3.0, Color("ff4b4b"))
	draw_circle(Vector2(7, -40), 3.0, Color("ff4b4b"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# ---------------------------------------------------------------- DESSIN DES SCÈNES
func _draw() -> void:
	if ids.is_empty():
		return
	match ids[index]:
		0:
			_scene_meadow(false)
		1:
			_scene_camp()
		2:
			_scene_attack()
		3:
			_scene_departure()
		4:
			_scene_map()
		5:
			_scene_liberation()
		_:
			_scene_meadow(true)
	draw_rect(Rect2(0, ART_H, W, 648.0 - ART_H), Color("0e1a24"))
	draw_rect(Rect2(0, ART_H, W, 4), Color("72d6be"))
	if fade > 0.0:
		draw_rect(Rect2(0, 0, W, ART_H), Color(0, 0, 0, fade))

# Scène 1 (et épilogue) : les quatre amis sur la colline.
func _scene_meadow(ending: bool) -> void:
	_gradient(Color("7fd6f2"), Color("f3fbdc"))
	var sun := Vector2(930, 95)
	draw_circle(sun, 46.0, Color("ffe9a3"))
	for i in range(12):
		var a := float(i) * TAU / 12.0 + t * 0.25
		var d := Vector2(cos(a), sin(a))
		draw_line(sun + d * 58.0, sun + d * (72.0 + sin(t * 2.0 + float(i)) * 5.0), Color("ffe9a3"), 4.0)
	for i in range(4):
		var cx := fmod(float(i) * 380.0 + t * 16.0, 1500.0) - 200.0
		var cy := 70.0 + float(i % 2) * 55.0
		for o in [Vector2(-28, 6), Vector2(0, 0), Vector2(30, 6), Vector2(8, 12)]:
			draw_circle(Vector2(cx, cy) + o, 24.0, Color(1, 1, 1, 0.85))
	draw_circle(Vector2(180, 560), 260.0, Color("86cfa6"))
	draw_circle(Vector2(1000, 580), 280.0, Color("7cc99b"))
	draw_circle(Vector2(576, 1500), 1200.0, Color("5cb85c"))
	for i in range(24):
		var fx := 20.0 + float(i) * 48.0
		var fy := _circle_y(fx, 576.0, 1500.0, 1200.0) + 14.0 + float(i % 3) * 14.0
		draw_circle(Vector2(fx, fy), 4.0, FLOWERS[i % 3])
	if ending:
		for k in range(5):
			var phase := fmod(t * 0.8 + float(k) * 0.7, 2.0)
			var fc := Vector2(150.0 + float(k) * 220.0, 90.0 + float(k % 2) * 60.0)
			var col := [Color("ff7b9c"), Color("ffd166"), Color("72e4c0"), Color("a994ec"), Color("f35e61")][k] as Color
			col.a = clampf(1.6 - phase, 0.0, 1.0)
			for j in range(10):
				var ang := float(j) * TAU / 10.0
				draw_circle(fc + Vector2(cos(ang), sin(ang)) * phase * 55.0, 3.5, col)
	var xs := [350.0, 510.0, 660.0, 810.0]
	var names := ["RUBIS", "ROBIN", "MIRA", "BOLT"]
	var kinds := [-1, 1, 2, 0]
	for i in range(4):
		var x: float = xs[i]
		var s := 1.8
		var gy := _circle_y(x, 576.0, 1500.0, 1200.0)
		var hop := absf(sin(t * (4.0 if ending else 2.2) + float(i))) * (14.0 if ending else 5.0)
		var p := Vector2(x, gy - 23.0 * s - hop)
		var face := 1.0 if i < 2 else -1.0
		if kinds[i] < 0:
			Art.hero(self, p, face, 0.0, false, s)
		else:
			Art.friend(self, p, kinds[i], face, t, s)
		_text(Vector2(x, gy + 32.0), names[i], 20, Color.WHITE, 140.0)
		if ending and i == 0:
			var cp := p + Vector2(0, -72)
			draw_colored_polygon(PackedVector2Array([cp + Vector2(-13, 0), cp + Vector2(-13, -14), cp + Vector2(-6, -6), cp + Vector2(0, -17), cp + Vector2(6, -6), cp + Vector2(13, -14), cp + Vector2(13, 0)]), Color("ffd34d"))
	if ending:
		for i in range(70):
			var kx := fposmod(float(i) * 83.1 + sin(t * 1.3 + float(i)) * 30.0, W)
			var ky := fposmod(t * (70.0 + float(i % 4) * 25.0) + float(i) * 47.3, ART_H + 20.0) - 10.0
			draw_rect(Rect2(kx, ky, 8.0, 5.0), CONFETTI[i % 6])
		var pulse := 1.0 + sin(t * 4.0) * 0.06
		_text(Vector2(576, 160), "VICTOIRE !", int(68.0 * pulse), Color("ffd34d"), 700.0)
		if t > 4.0:
			_text(Vector2(576, 205), "Merci d'avoir joué !", 30, Color.WHITE, 700.0)

# Scène 2 : le feu de camp, la nuit, et des yeux rouges dans la forêt.
func _scene_camp() -> void:
	_gradient(Color("0a1030"), Color("2e2a5c"))
	for i in range(45):
		var sx := fmod(float(i) * 97.3, W)
		var sy := fmod(float(i) * 53.7, 250.0)
		var a := 0.45 + 0.55 * sin(t * 2.0 + float(i))
		draw_circle(Vector2(sx, sy), 1.4 + float(i % 3) * 0.5, Color(1, 1, 0.9, clampf(a, 0.1, 1.0)))
	draw_circle(Vector2(170, 90), 38.0, Color("f4f1d0"))
	draw_circle(Vector2(158, 80), 7.0, Color(0.85, 0.82, 0.65, 0.6))
	draw_circle(Vector2(184, 100), 5.0, Color(0.85, 0.82, 0.65, 0.6))
	for i in range(13):
		var x := float(i) * 100.0 - 20.0
		draw_colored_polygon(PackedVector2Array([Vector2(x, 400), Vector2(x + 50.0, 190.0 + float(i % 3) * 35.0), Vector2(x + 100.0, 400)]), Color("0a1426"))
	draw_rect(Rect2(0, 385, W, 90), Color("173524"))
	# yeux rouges qui apparaissent peu à peu
	var ea := clampf((t - 1.6) * 0.6, 0.0, 1.0)
	var eye_pos := [Vector2(110, 330), Vector2(1020, 300), Vector2(930, 350)]
	for k in range(3):
		var ep: Vector2 = eye_pos[k]
		var blink := 0.6 + 0.4 * sin(t * 3.0 + float(k))
		draw_circle(ep, 22.0, Color(1.0, 0.1, 0.1, ea * blink * 0.12))
		for dx in [-9.0, 9.0]:
			draw_circle(ep + Vector2(dx, 0), 4.0, Color(1.0, 0.15, 0.1, ea * blink))
	# feu
	draw_circle(Vector2(576, 380), 160.0, Color(1.0, 0.55, 0.15, 0.09))
	draw_circle(Vector2(576, 385), 95.0, Color(1.0, 0.55, 0.15, 0.14))
	draw_line(Vector2(540, 404), Vector2(612, 386), Color("5a3d28"), 9.0)
	draw_line(Vector2(540, 386), Vector2(612, 404), Color("6b4a32"), 9.0)
	for k in range(3):
		var fh := 52.0 + sin(t * 9.0 + float(k) * 2.0) * 10.0 - float(absi(k - 1)) * 14.0
		var fx := 576.0 + float(k - 1) * 14.0
		draw_colored_polygon(PackedVector2Array([Vector2(fx - 12.0, 392), Vector2(fx, 392.0 - fh), Vector2(fx + 12.0, 392)]), Color("ff8a2a"))
		draw_colored_polygon(PackedVector2Array([Vector2(fx - 6.0, 392), Vector2(fx, 392.0 - fh * 0.6), Vector2(fx + 6.0, 392)]), Color("ffe08a"))
	# les amis assis autour du feu
	var xs := [400.0, 480.0, 672.0, 752.0]
	var kinds := [-1, 1, 2, 0]
	for i in range(4):
		var x: float = xs[i]
		var s := 1.5
		var p := Vector2(x, 418.0 - 23.0 * s - absf(sin(t * 2.0 + float(i) * 1.3)) * 4.0)
		var face := 1.0 if i < 2 else -1.0
		if kinds[i] < 0:
			Art.hero(self, p, face, 0.0, false, s)
		else:
			Art.friend(self, p, kinds[i], face, t, s)

# Scène 3 : Grogoth attaque et enferme trois amis.
func _scene_attack() -> void:
	_gradient(Color("2a0a26"), Color("b3392f"))
	for i in range(9):
		var mx := float(i) * 150.0 - 40.0
		draw_colored_polygon(PackedVector2Array([Vector2(mx, 390), Vector2(mx + 75.0, 270.0 + float(i % 3) * 30.0), Vector2(mx + 150.0, 390)]), Color("3a1230"))
	draw_rect(Rect2(0, 388, W, 90), Color("1a0b1a"))
	Art.monster(self, Vector2(920, 258), 2.4, 1.0, t, -1.0)
	var arm_end := Vector2(660.0 + sin(t * 3.0) * 12.0, 338.0)
	draw_line(Vector2(820, 250), arm_end, Color("8a1f3c").darkened(0.15), 34.0)
	for k in [-1.0, 0.0, 1.0]:
		var cx: float = arm_end.x - 14.0
		draw_colored_polygon(PackedVector2Array([Vector2(cx, arm_end.y + k * 11.0 - 5.0), Vector2(cx, arm_end.y + k * 11.0 + 5.0), Vector2(cx - 24.0, arm_end.y + k * 11.0)]), Color("f0e6c8"))
	var xs := [200.0, 340.0, 450.0, 560.0]
	var kinds := [-1, 1, 2, 0]
	for i in range(4):
		var x: float = xs[i]
		var s := 1.5
		var p := Vector2(x, 388.0 - 23.0 * s)
		if i == 0:
			var shake := 0.0
			if t > 0.8 and t < 2.6:
				shake = sin(t * 30.0) * 1.5
			Art.hero(self, p + Vector2(shake, 0), 1.0, 0.0, false, s)
		else:
			Art.friend(self, p, kinds[i], 1.0, t, s)
			if t > 0.8:
				var dy := maxf(0.0, 260.0 - (t - 0.8) * 260.0)
				Art.cage(self, Rect2(x - 44.0, p.y - 62.0 - dy, 88.0, 100.0), t)
	if t > 0.8:
		_text(Vector2(200, 268), "NON !", 30, Color("ffd166"), 160.0)
	if t > 2.4:
		_bubble(Vector2(450, 250), "AU SECOURS !")
	var flash := pow(maxf(0.0, sin(t * 2.3)), 24.0)
	draw_rect(Rect2(0, 0, W, ART_H), Color(1, 1, 1, flash * 0.5))

# Scène 4 : Grogoth s'éloigne avec les cages vers sa forteresse.
func _scene_departure() -> void:
	_gradient(Color("2a1537"), Color("e8885a"))
	draw_circle(Vector2(520, 340), 80.0, Color("ffcf8a"))
	for i in range(8):
		var mx := float(i) * 170.0 - 60.0
		draw_colored_polygon(PackedVector2Array([Vector2(mx, 400), Vector2(mx + 95.0, 290.0 + float(i % 3) * 25.0), Vector2(mx + 190.0, 400)]), Color("3d2150"))
	_castle(1000, 396, 1.0)
	draw_rect(Rect2(0, 395, W, 80), Color("1a1226"))
	var mp := Vector2(770.0 + sin(t * 0.6) * 8.0, 312.0)
	Art.monster(self, mp, 1.3, 0.6, t)
	draw_line(Vector2(mp.x - 40.0, 215), Vector2(380, 215), Color("5a3d28"), 8.0)
	var kinds := [1, 2, 0]
	for i in range(3):
		var cx := 430.0 + float(i) * 100.0
		var sway := sin(t * 2.0 + float(i)) * 7.0
		draw_line(Vector2(cx, 215), Vector2(cx + sway, 250), Color("5a3d28"), 3.0)
		Art.friend(self, Vector2(cx + sway, 308), kinds[i], 1.0, t, 0.85)
		Art.cage(self, Rect2(cx + sway - 34.0, 250.0, 68.0, 84.0), t)
	draw_circle(Vector2(240, 940), 600.0, Color("1d3a2c"))
	var rx := 150.0
	var ry := _circle_y(rx, 240.0, 940.0, 600.0)
	Art.hero(self, Vector2(rx, ry - 23.0 * 1.7 - absf(sin(t * 2.5)) * 5.0), 1.0, 0.0, false, 1.7)
	if t > 1.5:
		_bubble(Vector2(540, 160), "AU SECOURS !")
	if t > 3.0:
		_bubble(Vector2(150, 205), "J'ARRIVE !")

# Scène finale 1 : Grogoth s'effondre, les cages s'ouvrent, les amis courent vers Rubis.
func _scene_liberation() -> void:
	var dawn := clampf(t / 8.0, 0.0, 1.0)
	_gradient(Color("2a1537").lerp(Color("ff9f6e"), dawn), Color("a8322f").lerp(Color("ffe9a3"), dawn))
	draw_circle(Vector2(576, 430.0 - dawn * 180.0), 70.0, Color("ffe9a3"))
	for i in range(9):
		var mx := float(i) * 150.0 - 40.0
		draw_colored_polygon(PackedVector2Array([Vector2(mx, 390), Vector2(mx + 75.0, 270.0 + float(i % 3) * 30.0), Vector2(mx + 150.0, 390)]), Color("3a1230").lerp(Color("6b4a6e"), dawn))
	if t < 3.4:
		var shake := sin(t * 40.0) * 3.0
		Art.monster(self, Vector2(900.0 + shake, 258.0 + t * 26.0), 2.4 - t * 0.35, 1.0, t * 6.0, -1.0)
	draw_rect(Rect2(0, 388, W, 90), Color("1a0b1a").lerp(Color("2d5a3a"), dawn))
	if t > 0.4:
		for i in range(36):
			var ang := float(i) * TAU / 36.0 + float(i % 3) * 0.2
			var dist := (t - 0.4) * (60.0 + float(i % 5) * 25.0)
			var col := Color("ffd166") if i % 2 == 0 else Color("ff7b9c")
			col.a = clampf(1.8 - (t - 0.4) * 0.4, 0.0, 1.0)
			draw_rect(Rect2(Vector2(900, 330) + Vector2(cos(ang), sin(ang)) * dist - Vector2(3, 3), Vector2(6, 6)), col)
	var gy := 388.0
	var s := 1.5
	var kinds := [1, 2, 0]
	var starts := [380.0, 500.0, 620.0]
	var targets := [300.0, 370.0, 440.0]
	Art.hero(self, Vector2(200, gy - 23.0 * s - (absf(sin(t * 4.0)) * 6.0 if t > 4.5 else 0.0)), 1.0, 0.0, false, s)
	if t > 4.2:
		_heart(Vector2(200, gy - 23.0 * s - 70.0 - fposmod(t * 20.0, 30.0)), 8.0, Color("ff6b8b"))
	for i in range(3):
		var open_t := 1.2 + float(i) * 0.8
		var run := clampf((t - open_t - 0.6) / 1.6, 0.0, 1.0)
		var fx := lerpf(starts[i], targets[i], run)
		var hop := 0.0
		if run > 0.0 and run < 1.0:
			hop = absf(sin(t * 12.0)) * 12.0
		elif run >= 1.0:
			hop = absf(sin(t * 5.0 + float(i))) * 8.0
		var p := Vector2(fx, gy - 23.0 * s - hop)
		Art.friend(self, p, kinds[i], -1.0, t, s)
		if t < open_t + 0.7:
			var lift := maxf(0.0, t - open_t) * 260.0
			Art.cage(self, Rect2(starts[i] - 44.0, gy - 23.0 * s - 62.0 - lift, 88.0, 100.0), t, t < open_t)
		if run >= 1.0:
			_heart(Vector2(fx, p.y - 70.0 - fposmod(t * 20.0 + float(i) * 15.0, 30.0)), 7.0, Color("ff6b8b"))
	if t > 5.2:
		_bubble(Vector2(400, 250), "MERCI RUBIS !")

# Scène 5 : la carte des 6 niveaux, du plus facile au plus difficile.
func _scene_map() -> void:
	draw_rect(Rect2(0, 0, W, ART_H), Color("e8d6a8"))
	for i in range(14):
		draw_circle(Vector2(float(i) * 97.0 + 30.0, 30.0 + float(i % 4) * 100.0), 60.0, Color(0.8, 0.65, 0.4, 0.12))
	draw_rect(Rect2(14, 14, W - 28.0, ART_H - 28.0), Color("8a6a3a"), false, 4.0)
	_text(Vector2(576, 66), "LA ROUTE VERS LA FORTERESSE", 28, Color("5a3d1c"), 700.0)
	var xs := [110.0, 270.0, 430.0, 590.0, 750.0, 910.0, 1050.0]
	var ys := [350.0, 290.0, 350.0, 290.0, 350.0, 290.0, 330.0]
	var pts := PackedVector2Array()
	for i in range(7):
		pts.append(Vector2(xs[i], ys[i]))
	draw_polyline(pts, Color("8a6a3a"), 5.0)
	var nodes_shown := mini(int(t * 1.3) + 1, 6)
	var tier_colors := [Color("5cb85c"), Color("5cb85c"), Color("f0a030"), Color("f0a030"), Color("d9414b"), Color("d9414b")]
	var friend_kinds := {1: 0, 3: 1, 5: 2}
	for i in range(nodes_shown):
		var p := Vector2(xs[i], ys[i])
		draw_circle(p, 27.0, Color("5a4224"))
		draw_circle(p, 23.0, tier_colors[i])
		_text(p + Vector2(0, 9), str(i + 1), 26, Color.WHITE, 40.0)
		if friend_kinds.has(i):
			var fp := p + Vector2(0, 92)
			Art.friend(self, fp, friend_kinds[i], 1.0, t, 0.85)
			Art.cage(self, Rect2(fp.x - 32.0, fp.y - 38.0, 64.0, 68.0), t)
	var tiers := [["FACILE", 190.0, Color("3f8f3f"), 0], ["MOYEN", 510.0, Color("c07a10"), 1], ["DIFFICILE", 830.0, Color("b02a35"), 2]]
	for tr in tiers:
		if nodes_shown > 2 * int(tr[3]):
			var tx: float = tr[1]
			var tcol: Color = tr[2]
			_text(Vector2(tx, 178), tr[0], 26, tcol, 300.0)
			draw_line(Vector2(tx - 90.0, 190), Vector2(tx + 90.0, 190), tcol, 4.0)
	Art.hero(self, Vector2(xs[0], 300.0 - absf(sin(t * 3.0)) * 8.0), 1.0, 0.0, false, 1.0)
	if nodes_shown >= 6:
		_castle(1050, 372, 0.5)
