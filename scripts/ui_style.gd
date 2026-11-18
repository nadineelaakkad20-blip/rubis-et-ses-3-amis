extends RefCounted
# Styles des boutons et du curseur de volume (couleurs du jeu : or, turquoise, rubis).

static func gem_texture(color: Color) -> ImageTexture:
	var img := Image.create(22, 26, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in range(26):
		for x in range(22):
			var dx := absf(float(x) - 10.5) / 10.5
			var dy := absf(float(y) - 12.5) / 12.5
			var d := dx + dy
			if d <= 1.0:
				var c := color
				if d > 0.8:
					c = Color("f8d780")
				elif x > 10 and y < 12:
					c = color.lightened(0.35)
				elif y > 12:
					c = color.darkened(0.25)
				img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)

static func _box(bg: Color, border: Color, radius: int, border_w: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(border_w)
	box.set_corner_radius_all(radius)
	return box

static func style_button(button: Button, accent: Color) -> void:
	var dark := Color("10242c")
	var normal := _box(accent, dark, 6, 3)
	normal.shadow_color = Color(0, 0, 0, 0.45)
	normal.shadow_size = 0
	normal.shadow_offset = Vector2(0, 4)
	var hover := _box(accent.lightened(0.25), Color.WHITE, 6, 3)
	hover.shadow_color = Color(0, 0, 0, 0.45)
	hover.shadow_offset = Vector2(0, 4)
	var pressed := _box(accent.darkened(0.2), dark, 6, 3)
	var focus := _box(accent.lightened(0.15), Color.WHITE, 6, 3)
	focus.shadow_color = Color(0, 0, 0, 0.45)
	focus.shadow_offset = Vector2(0, 4)
	for box in [normal, hover, focus]:
		box.shadow_size = 1
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", focus)
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(key, dark)

static func style_slider(slider: HSlider, accent: Color) -> void:
	var track := _box(Color("07161d"), accent.darkened(0.35), 5, 2)
	track.content_margin_top = 6
	track.content_margin_bottom = 6
	var fill := _box(accent, accent.darkened(0.2), 5, 2)
	fill.content_margin_top = 6
	fill.content_margin_bottom = 6
	var tex := gem_texture(Color("e8384f"))
	slider.add_theme_stylebox_override("slider", track)
	slider.add_theme_stylebox_override("grabber_area", fill)
	slider.add_theme_stylebox_override("grabber_area_highlight", fill)
	slider.add_theme_icon_override("grabber", tex)
	slider.add_theme_icon_override("grabber_highlight", tex)
	slider.add_theme_icon_override("grabber_disabled", tex)
