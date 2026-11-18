extends Node2D
# Rubis et le Royaume des Amis : 6 niveaux (2 faciles, 2 moyens, 2 difficiles).
# Les décors, personnages et histoire sont générés par code.
const Player = preload("res://scripts/player.gd")
const Art = preload("res://scripts/art.gd")
const Cutscene = preload("res://scripts/cutscene.gd")
const Scenery = preload("res://scripts/scenery.gd")
const Sfx = preload("res://scripts/sfx.gd")
const FramePanel = preload("res://scripts/frame_panel.gd")
const HudBar = preload("res://scripts/hud_bar.gd")
const UIStyle = preload("res://scripts/ui_style.gd")
const TRACK_BY_LEVEL := ["bright", "bright", "dusk", "dusk", "night", "night"]
const KEYS_NEEDED := 3
const LEVEL_COUNT := 6
const TITLES := ["1 - LES COLLINES VERTES", "2 - LE SENTIER DES GLUANTS", "3 - LA FORÊT MURMURANTE", "4 - LA CLAIRIÈRE HANTÉE", "5 - LES GORGES SOMBRES", "6 - L'ANTRE DE GROGOTH"]
const TIERS := ["FACILE", "FACILE", "MOYEN", "MOYEN", "DIFFICILE", "DIFFICILE"]
const TIER_COLORS := [Color("a8f0b0"), Color("ffd27a"), Color("ff9a8f")]
const WIDTHS := [2700.0, 3000.0, 3300.0, 3500.0, 3800.0, 3700.0]
const FRIEND_AT := [-1, 0, -1, 1, -1, 2]
const FRIEND_FREED := ["Bolt le robot est libéré !", "Robin l'archère est libérée !", "Mira la magicienne est libérée !"]
const HINTS := [
	"Récupère les 3 clés pour ouvrir le portail ! Saute sur les ennemis.",
	"Trouve 3 clés pour ouvrir la cage de Bolt, prisonnier sur les hauteurs !",
	"Niveau MOYEN : 3 clés à trouver. Gobelins rapides et pics !",
	"Trouve 3 clés pour libérer Robin, tout en haut de la dernière plateforme.",
	"Niveau DIFFICILE : 3 clés à trouver. Gouffres, pics et chauves-souris !",
	"Prends l'Épée de lumière (F / X pour tirer) et les 3 clés, puis bats Grogoth !",
]
var player: CharacterBody2D
var terrain: Node2D
var camera: Camera2D
var interface: CanvasLayer
var cs_layer: CanvasLayer
var hud: HudBar
var sfx: Sfx
var vol_slider: HSlider
var vol_value: Label
var was_exit_open := false
var hint: Label
var panel: FramePanel
var panel_title: Label
var panel_body: Label
var action_button: Button
var platforms: Array[Rect2] = []
var hazards: Array[Rect2] = []
var enemies: Array[Dictionary] = []
var keys: Array[Vector2] = []
var keys_have := 0
var freed_t := -10.0
var has_weapon := false
var weapon_pos := Vector2.ZERO
var shots: Array[Dictionary] = []
var shot_cd := 0.0
var particles: Array[Dictionary] = []
var checkpoints: Array[Vector2] = []
var cp_flags: Array[bool] = []
var friend_pos := Vector2.ZERO
var friend_kind := -1
var friend_saved := false
var checkpoint := Vector2(110, 480)
var exit_pos := Vector2.ZERO
var level := 0
var health := 3
var score := 0
var rescued := 0
var state := "title"
var elapsed := 0.0
var toast := ""
var toast_time := 0.0
var boss_level := false
var boss_max := 4
var boss_hp := 4
var boss_hit_timer := 0.0
var boss_origin := Vector2(2950, 483)
var boss_pos := Vector2.ZERO
var boss_clock := 0.0
var world_width := 2700.0
var level_start_score := 0
var level_start_rescued := 0

func _ready() -> void:
	setup_input()
	sfx = Sfx.new()
	add_child(sfx)
	terrain = Node2D.new()
	add_child(terrain)
	player = Player.new()
	add_child(player)
	player.jumped.connect(on_player_jumped)
	camera = Camera2D.new()
	camera.position = Vector2(576, 324)
	add_child(camera)
	camera.make_current()
	setup_ui()
	load_level(0)
	show_panel("RUBIS ET LES TROIS AMIS", "Le monstre Grogoth a capturé tes trois amis !\n\nTraverse 6 niveaux, du plus facile au plus difficile,\nsaute sur les ennemis pour les vaincre\net libère Bolt, Robin et Mira.\n\nDéplacer : flèches ou Q D     Sauter : ESPACE, Z ou flèche haut", "COMMENCER L'AVENTURE", "title")
	sfx.play_music("gentle")

func setup_input() -> void:
	var bindings := {"left": [KEY_LEFT, KEY_A], "right": [KEY_RIGHT, KEY_D], "jump": [KEY_SPACE, KEY_W, KEY_UP], "attack": [KEY_F, KEY_X, KEY_K]}
	for action in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in bindings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)

func make_label(size: int, color := Color("eaf7ee")) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label

func setup_ui() -> void:
	interface = CanvasLayer.new()
	add_child(interface)
	# Barre du haut (niveau, vies, clés, amis, score + guide des touches).
	hud = HudBar.new()
	hud.position = Vector2(20, 10)
	hud.size = Vector2(1112, 76)
	hud.audio = sfx
	interface.add_child(hud)
	hint = make_label(22)
	hint.position = Vector2(176, 105)
	hint.size = Vector2(800, 42)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_shadow_color", Color("193a40"))
	hint.add_theme_constant_override("shadow_offset_y", 2)
	interface.add_child(hint)
	# Cadre des menus (titre, pause, niveau terminé, défaite, victoire).
	panel = FramePanel.new()
	panel.position = Vector2(196, 130)
	panel.size = Vector2(760, 440)
	interface.add_child(panel)
	panel_title = make_label(30, Color("fff3c4"))
	panel_title.position = Vector2(70, -26)
	panel_title.size = Vector2(620, 56)
	panel_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel_title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	panel_title.add_theme_constant_override("shadow_offset_y", 3)
	panel.add_child(panel_title)
	panel_body = make_label(18)
	panel_body.position = Vector2(50, 86)
	panel_body.size = Vector2(660, 190)
	panel_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(panel_body)
	action_button = Button.new()
	action_button.position = Vector2(190, 286)
	action_button.size = Vector2(380, 52)
	action_button.add_theme_font_size_override("font_size", 22)
	action_button.pressed.connect(on_action)
	panel.add_child(action_button)
	# Réglage du volume de la musique.
	var vol_label := make_label(16, Color("cfeee4"))
	vol_label.text = "MUSIQUE"
	vol_label.position = Vector2(100, 376)
	panel.add_child(vol_label)
	vol_slider = HSlider.new()
	vol_slider.min_value = 0
	vol_slider.max_value = 100
	vol_slider.step = 5
	vol_slider.position = Vector2(208, 373)
	vol_slider.size = Vector2(330, 26)
	vol_slider.value_changed.connect(on_volume_changed)
	panel.add_child(vol_slider)
	vol_value = make_label(16, Color("f8d780"))
	vol_value.position = Vector2(556, 376)
	vol_value.size = Vector2(64, 24)
	panel.add_child(vol_value)
	var mute_hint := make_label(14, Color("8fb7ae"))
	mute_hint.text = "M : muet"
	mute_hint.position = Vector2(626, 378)
	panel.add_child(mute_hint)
	sfx.volume_changed.connect(refresh_volume_ui)
	refresh_volume_ui()

func refresh_volume_ui() -> void:
	panel.volume = sfx.music_volume
	panel.muted = sfx.muted
	vol_slider.set_value_no_signal(sfx.music_volume * 100.0)
	vol_value.text = "muet" if (sfx.muted or sfx.music_volume <= 0.001) else "%d %%" % int(round(sfx.music_volume * 100.0))

func on_volume_changed(value: float) -> void:
	sfx.set_music_volume(value / 100.0)
	sfx.play("tick")

func on_player_jumped() -> void:
	sfx.play("jump")

func show_panel(title: String, body: String, button: String, kind := "title") -> void:
	panel_title.text = title
	panel_body.text = body
	action_button.text = button
	panel.set_kind(kind)
	UIStyle.style_button(action_button, panel.accent())
	UIStyle.style_slider(vol_slider, panel.accent())
	hint.text = ""
	panel.show()
	action_button.grab_focus()
	player.enabled = false

func start_cutscene(ids: Array) -> void:
	cs_layer = CanvasLayer.new()
	cs_layer.layer = 20
	add_child(cs_layer)
	var scene := Cutscene.new()
	scene.setup(ids)
	scene.finished.connect(on_cutscene_finished)
	cs_layer.add_child(scene)
	scene.next_button.pressed.connect(on_ui_click)
	scene.skip_button.pressed.connect(on_ui_click)

func on_ui_click() -> void:
	sfx.play("click")

func on_cutscene_finished() -> void:
	if is_instance_valid(cs_layer):
		cs_layer.queue_free()
	if state == "intro":
		score = 0
		rescued = 0
		load_level(0)
		state = "playing"
		panel.hide()
		player.enabled = true
	elif state == "ending":
		state = "win"
		show_panel("VICTOIRE !", "Grogoth est vaincu et tes trois amis sont libres !\n\nBolt, Robin et Mira sont à nouveau avec Rubis.\nVerdalia a retrouvé la paix.\n\nAmis libérés : %d / 3\nSCORE FINAL : %d" % [rescued, score], "REJOUER", "win")
		sfx.play("win")
		sfx.play_music("bright")

func on_action() -> void:
	if state != "paused":
		sfx.play("click")
	match state:
		"title":
			state = "intro"
			panel.hide()
			player.enabled = false
			start_cutscene([0, 1, 2, 3, 4])
		"paused":
			resume()
		"dead":
			retry_level()
		"clear":
			load_level(level + 1)
			state = "playing"
			panel.hide()
			player.enabled = true
		"win":
			score = 0
			rescued = 0
			load_level(0)
			state = "playing"
			panel.hide()
			player.enabled = true

func resume() -> void:
	sfx.play("resume")
	state = "playing"
	panel.hide()
	player.enabled = true

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_P, KEY_ESCAPE]:
			if state == "playing":
				state = "paused"
				show_panel("RESPIRE UN PEU", "Tes amis comptent sur toi.\n\nSaute sur les ennemis par le haut pour les vaincre.\nTouche une cage pour libérer ton ami.\nLes cristaux dorés donnent des points bonus.", "CONTINUER", "pause")
				sfx.play("pause_open")
			elif state == "paused":
				resume()
		elif event.keycode == KEY_R and state in ["playing", "dead", "paused"]:
			retry_level()
		elif event.keycode == KEY_M:
			sfx.toggle_mute()
		elif event.keycode in [KEY_KP_ADD, KEY_EQUAL, KEY_PLUS]:
			sfx.set_music_volume(sfx.music_volume + 0.1)
			sfx.play("tick")
		elif event.keycode in [KEY_KP_SUBTRACT, KEY_MINUS]:
			sfx.set_music_volume(sfx.music_volume - 0.1)
			sfx.play("tick")

# ---------------------------------------------------------------- OUTILS DE CONSTRUCTION DES NIVEAUX
func add_platform(rect: Rect2) -> void:
	platforms.append(rect)
	var body := StaticBody2D.new()
	body.position = rect.get_center()
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	body.add_child(collision)
	terrain.add_child(body)

# Sol : de x = a à x = b (le sol est à y = 540).
func ground(a: float, b: float) -> void:
	add_platform(Rect2(a, 540, b - a, 160))

# Plateforme flottante : bord gauche x, hauteur y, largeur w.
func plat(x: float, y: float, w: float) -> void:
	add_platform(Rect2(x, y, w, 24))

# Pics posés sur le sol.
func spikes(x: float, w: float) -> void:
	hazards.append(Rect2(x, 520, w, 20))

# Ennemi marcheur : kind 0 = gluant, 1 = gobelin. "top" = hauteur du sol ou de la plateforme.
func foe(kind: int, x: float, top: float, left: float, right: float, speed := 80.0) -> void:
	enemies.append({"kind": kind, "pos": Vector2(x, top - 22), "left": left, "right": right, "dir": 1.0, "speed": speed, "alive": true, "base_y": top - 22, "amp": 0.0, "phase": 0.0})

# Chauve-souris volante : monte et descend en patrouillant.
func bat(x: float, y: float, left: float, right: float, speed := 85.0, amp := 28.0) -> void:
	enemies.append({"kind": 2, "pos": Vector2(x, y), "left": left, "right": right, "dir": 1.0, "speed": speed, "alive": true, "base_y": y, "amp": amp, "phase": x * 0.01})

func add_cp(x: float) -> void:
	checkpoints.append(Vector2(x, 540))
	cp_flags.append(false)

# Clé à ramasser (3 par niveau).
func add_key(x: float, y: float) -> void:
	keys.append(Vector2(x, y))

# ---------------------------------------------------------------- LES 6 NIVEAUX
# FACILE 1 : apprendre à courir et à sauter.
func build_0() -> void:
	add_key(505, 408)
	add_key(1155, 408)
	add_key(2400, 495)
	ground(0, 700)
	ground(860, 1500)
	ground(1650, 2700)
	plat(430, 445, 150)
	plat(1080, 445, 150)
	spikes(2060, 70)
	foe(0, 1000, 540, 900, 1300, 60)
	foe(0, 1950, 540, 1700, 1980, 60)
	foe(0, 2350, 540, 2200, 2500, 65)
	add_cp(1760)

# FACILE 2 : premier ami à libérer (Bolt le robot).
func build_1() -> void:
	add_key(450, 408)
	add_key(975, 408)
	add_key(1635, 408)
	ground(0, 600)
	ground(760, 1300)
	ground(1460, 2000)
	ground(2160, 3000)
	plat(380, 445, 140)
	plat(900, 445, 150)
	plat(1100, 355, 140)
	plat(1560, 445, 150)
	plat(1790, 445, 120)
	spikes(1760, 70)
	spikes(2400, 80)
	friend_pos = Vector2(1170, 328)
	foe(0, 850, 540, 800, 1250, 70)
	foe(0, 1530, 540, 1480, 1700, 70)
	foe(0, 1900, 540, 1850, 1980, 70)
	foe(0, 2280, 540, 2200, 2380, 75)
	foe(0, 2650, 540, 2520, 2820, 75)
	add_cp(1480)

# MOYEN 1 : gobelins plus rapides, plus de pics, plateforme dans un gouffre.
func build_2() -> void:
	add_key(385, 403)
	add_key(1100, 313)
	add_key(2915, 313)
	ground(0, 520)
	ground(700, 1200)
	ground(1380, 1800)
	ground(1980, 2380)
	ground(2560, 3300)
	plat(320, 440, 130)
	plat(820, 440, 140)
	plat(1030, 350, 140)
	plat(1500, 440, 150)
	plat(1850, 470, 80)
	plat(2100, 440, 150)
	plat(2640, 440, 140)
	plat(2840, 350, 150)
	spikes(980, 80)
	spikes(1560, 90)
	spikes(2200, 90)
	spikes(2760, 100)
	foe(1, 780, 540, 720, 940, 90)
	foe(0, 1130, 540, 1080, 1190, 80)
	foe(1, 1575, 440, 1520, 1630, 70)
	foe(1, 1720, 540, 1670, 1790, 95)
	foe(1, 2040, 540, 2000, 2180, 95)
	foe(1, 2700, 540, 2650, 2740, 100)
	foe(1, 2950, 540, 2880, 3150, 100)
	add_cp(1420)
	add_cp(2600)

# MOYEN 2 : un pont de plateformes au-dessus du vide, puis Robin l'archère.
func build_3() -> void:
	add_key(365, 403)
	add_key(1385, 403)
	add_key(2445, 403)
	ground(0, 500)
	ground(680, 1100)
	ground(1280, 1660)
	ground(1840, 2160)
	ground(2580, 3500)
	plat(300, 440, 130)
	plat(790, 440, 140)
	plat(1330, 440, 110)
	plat(1900, 440, 140)
	plat(2240, 470, 90)
	plat(2400, 440, 90)
	plat(2700, 440, 130)
	plat(2900, 350, 130)
	spikes(950, 80)
	spikes(1440, 90)
	spikes(2000, 80)
	spikes(3100, 100)
	friend_pos = Vector2(2965, 323)
	foe(1, 760, 540, 700, 920, 95)
	foe(1, 1320, 540, 1290, 1420, 100)
	foe(1, 1590, 540, 1550, 1640, 100)
	foe(1, 1890, 540, 1850, 1980, 100)
	foe(1, 2735, 540, 2690, 2790, 105)
	foe(1, 3010, 540, 2960, 3080, 105)
	foe(1, 3330, 540, 3220, 3340, 110)
	add_cp(1060)
	add_cp(2620)

# DIFFICILE 1 : grands sauts, pics en série, chauves-souris.
func build_4() -> void:
	add_key(1280, 403)
	add_key(1670, 500)
	add_key(2600, 403)
	ground(0, 480)
	ground(680, 980)
	ground(1180, 1400)
	ground(1590, 1750)
	ground(1940, 2300)
	ground(2900, 3800)
	plat(2390, 470, 80)
	plat(2560, 440, 80)
	plat(2730, 470, 80)
	plat(1230, 440, 100)
	spikes(790, 90)
	spikes(2030, 70)
	spikes(2190, 70)
	spikes(3000, 90)
	spikes(3250, 100)
	foe(1, 300, 540, 200, 420, 120)
	foe(1, 1320, 540, 1250, 1390, 120)
	foe(1, 3175, 540, 3120, 3230, 125)
	foe(1, 3480, 540, 3400, 3620, 130)
	bat(1670, 420, 1580, 1760, 80, 30)
	bat(2600, 310, 2420, 2780, 90, 25)
	bat(3430, 430, 3360, 3600, 100, 30)
	add_cp(1210)
	add_cp(2940)

# DIFFICILE 2 : dernier gouffre, puis le combat contre Grogoth et Mira à libérer.
func build_5() -> void:
	add_key(1220, 500)
	add_key(1555, 500)
	add_key(2130, 393)
	ground(0, 450)
	ground(650, 950)
	ground(1140, 1300)
	ground(1490, 1830)
	ground(2450, 3700)
	plat(1920, 470, 80)
	plat(2090, 430, 80)
	plat(2260, 470, 80)
	spikes(1620, 90)
	friend_pos = Vector2(3380, 513)
	weapon_pos = Vector2(2620, 505)
	boss_origin = Vector2(2950, 483)
	foe(1, 300, 540, 200, 420, 125)
	foe(1, 800, 540, 760, 940, 125)
	bat(1220, 420, 1120, 1320, 90, 30)
	bat(2175, 330, 2050, 2380, 90, 25)
	add_cp(690)
	add_cp(2480)

func load_level(index: int) -> void:
	level = index
	level_start_score = score
	level_start_rescued = rescued
	for body in terrain.get_children():
		terrain.remove_child(body)
		body.queue_free()
	platforms.clear()
	hazards.clear()
	enemies.clear()
	keys.clear()
	keys_have = 0
	freed_t = -10.0
	particles.clear()
	checkpoints.clear()
	cp_flags.clear()
	health = 3
	friend_kind = FRIEND_AT[level]
	friend_saved = friend_kind < 0
	friend_pos = Vector2.ZERO
	boss_level = level == 5
	boss_max = 6 if boss_level else 4
	has_weapon = false
	weapon_pos = Vector2.ZERO
	shots.clear()
	shot_cd = 0.0
	player.armed = false
	player.swing = 0.0
	boss_hp = boss_max
	boss_hit_timer = 0.0
	boss_clock = 0.0
	boss_origin = Vector2(2950, 483)
	world_width = WIDTHS[level]
	exit_pos = Vector2(world_width - 120.0, 540)
	checkpoint = Vector2(110, 480)
	match level:
		0:
			build_0()
		1:
			build_1()
		2:
			build_2()
		3:
			build_3()
		4:
			build_4()
		_:
			build_5()
	boss_pos = boss_origin
	player.position = checkpoint
	player.velocity = Vector2.ZERO
	player.invulnerable = 1.2
	player.previous_bottom = player.position.y + 23
	camera.position = Vector2(576, 324)
	toast_message(HINTS[level])
	was_exit_open = false
	if state != "title":
		sfx.play_music(TRACK_BY_LEVEL[level])
	update_hud()
	queue_redraw()

func retry_level() -> void:
	score = level_start_score
	rescued = level_start_rescued
	load_level(level)
	state = "playing"
	panel.hide()
	player.enabled = true

func toast_message(text: String) -> void:
	toast = text
	toast_time = 4.0

func update_hud() -> void:
	hud.set_data(TITLES[level], TIERS[level], TIER_COLORS[floori(level / 2.0)], health, keys_have, KEYS_NEEDED, rescued, score)

func exit_open() -> bool:
	return keys_have >= KEYS_NEEDED and friend_saved and (not boss_level or boss_hp <= 0)

# ---------------------------------------------------------------- BOUCLE DE JEU
func _physics_process(delta: float) -> void:
	if state != "playing":
		return
	elapsed += delta
	toast_time = maxf(0.0, toast_time - delta)
	boss_hit_timer = maxf(0.0, boss_hit_timer - delta)
	hint.text = toast if toast_time > 0 else ""
	for enemy in enemies:
		if not enemy.alive:
			continue
		enemy.pos.x += enemy.dir * enemy.speed * delta
		if enemy.pos.x < enemy.left or enemy.pos.x > enemy.right:
			enemy.dir *= -1.0
			enemy.pos.x = clampf(enemy.pos.x, enemy.left, enemy.right)
		if enemy.kind == 2:
			enemy.pos.y = enemy.base_y + sin(elapsed * 2.2 + enemy.phase) * enemy.amp
		check_enemy(enemy)
	for i in range(keys.size() - 1, -1, -1):
		if player.position.distance_to(keys[i]) < 38:
			burst(keys[i], Color("ffd34d"))
			keys.remove_at(i)
			keys_have += 1
			score += 100
			sfx.play("unlock" if keys_have >= KEYS_NEEDED else "key")
			if keys_have < KEYS_NEEDED:
				toast_message("Clé %d / %d trouvée !" % [keys_have, KEYS_NEEDED])
			elif boss_level:
				toast_message("Toutes les clés ! Vaincs Grogoth pour ouvrir la cage de Mira !")
			elif friend_kind >= 0:
				toast_message("Toutes les clés ! La cage est déverrouillée : va libérer ton ami !")
			else:
				toast_message("Toutes les clés ! Le portail est déverrouillé !")
	shot_cd = maxf(0.0, shot_cd - delta)
	if weapon_pos != Vector2.ZERO and not has_weapon and player.position.distance_to(weapon_pos) < 50:
		has_weapon = true
		player.armed = true
		sfx.play("power")
		burst(weapon_pos, Color("9ff6ff"))
		burst(weapon_pos, Color("ffffff"))
		toast_message("ÉPÉE DE LUMIÈRE obtenue ! Appuie sur F ou X pour tirer des rayons !")
	if has_weapon and shot_cd <= 0.0 and Input.is_action_just_pressed("attack"):
		shot_cd = 0.35
		player.swing = 0.18
		sfx.play("shoot")
		shots.append({"pos": player.position + Vector2(player.face * 30.0, -4.0), "vel": Vector2(player.face * 640.0, 0.0), "life": 1.2})
	for i in range(shots.size() - 1, -1, -1):
		var shot := shots[i]
		shot.pos += shot.vel * delta
		shot.life -= delta
		var hit := false
		if boss_level and boss_hp > 0 and Rect2(boss_pos - Vector2(54, 54), Vector2(108, 108)).has_point(shot.pos):
			damage_boss(0.6)
			hit = true
		if not hit:
			for enemy in enemies:
				if enemy.alive and Rect2(enemy.pos - Vector2(24, 24), Vector2(48, 48)).has_point(shot.pos):
					enemy.alive = false
					score += 50
					sfx.play("pop")
					burst(enemy.pos, Color("b0b6cf"))
					hit = true
					break
		if hit or shot.life <= 0.0 or absf(shot.pos.x - player.position.x) > 800.0:
			shots.remove_at(i)
	for i in range(checkpoints.size()):
		if not cp_flags[i] and absf(player.position.x - checkpoints[i].x) < 36 and player.position.y > 420:
			cp_flags[i] = true
			checkpoint = checkpoints[i] - Vector2(0, 45)
			sfx.play("checkpoint")
			toast_message("Point de passage atteint !")
	if friend_kind >= 0 and not friend_saved and player.position.distance_to(friend_pos) < 58:
		if keys_have >= KEYS_NEEDED and (not boss_level or boss_hp <= 0):
			friend_saved = true
			freed_t = elapsed
			rescued += 1
			score += 200
			sfx.play("free")
			burst(friend_pos, Color("72e4c0"))
			burst(friend_pos, Color("ffd34d"))
			toast_message("%s Va jusqu'au portail lumineux." % FRIEND_FREED[friend_kind])
		elif toast_time <= 0:
			if keys_have < KEYS_NEEDED:
				toast_message("La cage est verrouillée : il faut %d clés !" % KEYS_NEEDED)
			else:
				toast_message("Vaincs d'abord Grogoth pour ouvrir la cage !")
	for hazard in hazards:
		if hazard.intersects(Rect2(player.position - Vector2(18, 18), Vector2(36, 40))):
			hurt(true)
			break
	if player.position.y > 790:
		hurt(true)
	if boss_level and boss_hp > 0:
		boss_clock += delta * (1.0 + 0.15 * float(boss_max - boss_hp))
		var jump_h := 42.0 + 6.0 * float(boss_max - boss_hp)
		boss_pos = boss_origin + Vector2(sin(boss_clock * 1.35) * 170.0, -absf(sin(boss_clock * 1.1)) * jump_h)
		check_boss()
	if absf(player.position.x - exit_pos.x) < 52 and player.position.y > 430:
		if exit_open():
			finish_level()
		elif toast_time <= 0:
			if boss_level and boss_hp > 0:
				toast_message("Vaincs Grogoth avant de partir !")
			elif keys_have < KEYS_NEEDED:
				toast_message("Il te faut les %d clés pour ouvrir le portail !" % KEYS_NEEDED)
			else:
				toast_message("Libère ton ami avant de partir !")
	for i in range(particles.size() - 1, -1, -1):
		particles[i].life -= delta
		particles[i].pos += particles[i].vel * delta
		particles[i].vel.y += 500 * delta
		if particles[i].life <= 0:
			particles.remove_at(i)
	camera.position.x = lerpf(camera.position.x, clampf(player.position.x + 160, 576, world_width - 576), 0.09)
	update_hud()
	queue_redraw()

func check_enemy(enemy: Dictionary) -> void:
	var rect := Rect2(enemy.pos - Vector2(22, 22), Vector2(44, 44))
	if rect.intersects(Rect2(player.position - Vector2(21, 21), Vector2(42, 42))):
		if player.velocity.y > 60 and player.previous_bottom <= rect.position.y + 16:
			enemy.alive = false
			player.velocity.y = -430
			score += 50
			sfx.play("stomp")
			burst(enemy.pos, Color("b0b6cf"))
		else:
			hurt(false)

func check_boss() -> void:
	var rect := Rect2(boss_pos - Vector2(54, 54), Vector2(108, 108))
	if not rect.intersects(Rect2(player.position - Vector2(21, 21), Vector2(42, 42))):
		return
	if player.velocity.y > 60 and player.previous_bottom <= rect.position.y + 44:
		player.velocity.y = -590
		damage_boss(1.0)
	else:
		hurt(false)

func damage_boss(cooldown: float) -> void:
	if boss_hit_timer > 0.0:
		return
	boss_hp -= 1
	boss_hit_timer = cooldown
	sfx.play("boss_down" if boss_hp <= 0 else "boss_hit")
	burst(boss_pos, Color("f8d780"))
	if boss_hp <= 0:
		score += 500
		toast_message("Grogoth est vaincu ! Ouvre la cage de Mira !" if keys_have >= KEYS_NEEDED else "Grogoth est vaincu ! Trouve les clés manquantes !")

func hurt(respawn: bool) -> void:
	if state != "playing" or (player.invulnerable > 0 and not respawn):
		return
	health -= 1
	if health <= 0:
		state = "dead"
		sfx.play("dead")
		show_panel("NE BAISSE PAS LES BRAS", "Même les héros ont droit à un nouvel essai.\n\nRecommence ce niveau avec trois vies.\nTa progression dans les niveaux précédents est conservée.", "RÉESSAYER", "dead")
	else:
		sfx.play("hurt")
		player.position = checkpoint
		player.velocity = Vector2.ZERO
		player.previous_bottom = player.position.y + 23
		player.invulnerable = 1.8
		toast_message("Attention ! Saute sur les ennemis par le haut.")
	update_hud()

func finish_level() -> void:
	if state != "playing":
		return
	if level < LEVEL_COUNT - 1:
		state = "clear"
		sfx.play("clear")
		var head := "Niveau %d terminé !" % (level + 1)
		if friend_kind >= 0:
			head = FRIEND_FREED[friend_kind]
		var warn := ""
		if TIERS[level + 1] != TIERS[level]:
			warn = "\nAttention : la difficulté augmente !"
		show_panel("BRAVO !", "%s\n\nAmis libérés : %d / 3\nScore : %d\n\nProchain niveau : %s (%s)%s" % [head, rescued, score, TITLES[level + 1], TIERS[level + 1], warn], "NIVEAU SUIVANT", "clear")
	else:
		state = "ending"
		player.enabled = false
		sfx.play("clear")
		sfx.play_music("gentle")
		start_cutscene([5, 6])

func burst(pos: Vector2, color: Color) -> void:
	for i in range(12):
		particles.append({"pos": pos, "vel": Vector2(randf_range(-150, 150), randf_range(-240, -50)), "life": 0.65, "color": color})

# ---------------------------------------------------------------- DESSIN
func label_at(pos: Vector2, text: String, size := 18, color := Color.WHITE) -> void:
	draw_string(ThemeDB.fallback_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _draw() -> void:
	if not is_instance_valid(camera):
		return
	var theme := floori(level / 2.0)
	var left := camera.position.x - 576
	Scenery.draw_background(self, left, theme, elapsed)
	Scenery.draw_water(self, left, theme, elapsed)
	for rect in platforms:
		Scenery.draw_platform(self, rect, theme, left, elapsed)
	# Pics en pixel art.
	for hazard in hazards:
		for x in range(int(hazard.position.x), int(hazard.end.x), 24):
			var by := hazard.end.y
			draw_rect(Rect2(x + 2, by - 8, 20, 8), Color("c9d2e4"))
			draw_rect(Rect2(x + 6, by - 16, 12, 8), Color("e6ecf8"))
			draw_rect(Rect2(x + 10, by - 24, 4, 8), Color("ffffff"))
			draw_rect(Rect2(x + 2, by - 2, 20, 2), Color("8e98b0"))
	# Arme au sol (niveau 6) et rayons de lumière.
	if weapon_pos != Vector2.ZERO and not has_weapon:
		Art.sword(self, weapon_pos, elapsed)
		label_at(weapon_pos + Vector2(-70, -62), "ÉPÉE DE LUMIÈRE", 16, Color("c8f8ff"))
	for shot in shots:
		Art.beam(self, shot.pos, signf(shot.vel.x))
	# Clés à ramasser.
	for k in keys:
		Art.key(self, k + Vector2(0, sin(elapsed * 3 + k.x) * 4), elapsed)
	for enemy in enemies:
		if enemy.alive:
			Art.enemy(self, enemy.kind, enemy.pos, enemy.dir, elapsed + enemy.phase)
	# Drapeaux de points de passage.
	for i in range(checkpoints.size()):
		var cp := checkpoints[i]
		var active := cp_flags[i]
		draw_line(cp, cp - Vector2(0, 105), Color("e9eee0"), 4)
		draw_colored_polygon(PackedVector2Array([cp - Vector2(0, 105), cp + Vector2(55, -88), cp - Vector2(0, 70)]), Color("f8d780") if active else Color("c6dace"))
	# Ami prisonnier (cage verrouillée tant qu'on n'a pas les clés).
	if friend_kind >= 0 and not friend_saved:
		Art.friend(self, friend_pos, friend_kind, -1.0, elapsed)
		Art.cage(self, Rect2(friend_pos - Vector2(34, 42), Vector2(68, 72)), elapsed, keys_have < KEYS_NEEDED)
		label_at(friend_pos + Vector2(-29, -52), "AIDE !", 17)
	elif friend_kind >= 0 and elapsed - freed_t < 1.6:
		var dt := elapsed - freed_t
		var hop := absf(sin(dt * 9.0)) * 26.0
		Art.friend(self, friend_pos + Vector2(0, -hop), friend_kind, 1.0, elapsed)
		if dt < 0.5:
			Art.cage(self, Rect2(friend_pos - Vector2(34, 42 + dt * 240.0), Vector2(68, 72)), elapsed, false)
	# Grogoth.
	if boss_level and boss_hp > 0:
		if boss_hit_timer <= 0 or int(boss_hit_timer * 12) % 2 == 0:
			Art.monster(self, boss_pos, 1.0, 0.2 + 0.8 * float(boss_max - boss_hp) / float(boss_max), elapsed)
		label_at(boss_pos + Vector2(-48, -118), "GROGOTH", 18, Color("f8d780"))
		for i in range(boss_max):
			draw_rect(Rect2(boss_pos + Vector2(-boss_max * 16 + i * 32, -106), Vector2(28, 7)), Color("f35e61") if i < boss_hp else Color("47506b"))
	# Portail de sortie.
	var open := exit_open()
	var portal_color := Color("a2f2ce") if open else Color("7a8b9c")
	draw_rect(Rect2(exit_pos - Vector2(38, 104), Vector2(76, 104)), Color("21444c"))
	draw_arc(exit_pos - Vector2(0, 60), 39, PI, TAU, 30, portal_color, 6, true)
	draw_line(exit_pos - Vector2(39, 60), exit_pos - Vector2(39, 0), portal_color, 6)
	draw_line(exit_pos + Vector2(39, -60), exit_pos + Vector2(39, 0), portal_color, 6)
	label_at(exit_pos + Vector2(-24, -125), "SORTIE", 19, portal_color)
	if open:
		for i in range(7):
			draw_circle(exit_pos + Vector2(sin(elapsed + i) * 24, -15 - fmod(elapsed * 24 + i * 13, 75)), 3, portal_color)
	for particle in particles:
		draw_circle(particle.pos, 4, particle.color)
