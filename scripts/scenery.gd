extends RefCounted
# Décors "pixel art" : forêt mystérieuse, étangs, blocs de terre, herbe et plantes.
# Tout est dessiné par code avec des rectangles (aucune image nécessaire).

const PALETTES := [
    {
        "dark": false,
        "sky": [Color("4fb8d0"), Color("6fcad4"), Color("8ddccf"), Color("aee8c8"), Color("cdf2c2")],
        "far": Color("3d9a8c"), "mid": Color("2f7d63"), "leaf": Color("276a52"), "leaf_hi": Color("57b886"),
        "trunk": Color("4a3a2e"), "dirt": Color("6b4a35"), "dirt_hi": Color("85603f"), "dirt_dark": Color("4f3526"),
        "grass": Color("4fb85a"), "grass_hi": Color("86e07a"), "water": Color("2f95ad"), "water_hi": Color("7fd8e8"),
        "glow": Color("fff2a0"), "moon": Color("ffeeb0"),
        "flower": [Color("ff7b9c"), Color("ffd166"), Color("ffffff")],
    },
    {
        "dark": true,
        "sky": [Color("141a45"), Color("24286a"), Color("3a3a86"), Color("5a4f9c"), Color("8a73ae")],
        "far": Color("2b3a73"), "mid": Color("1f4660"), "leaf": Color("193a52"), "leaf_hi": Color("3a7a86"),
        "trunk": Color("2d2438"), "dirt": Color("4a3a52"), "dirt_hi": Color("62506c"), "dirt_dark": Color("33273d"),
        "grass": Color("2f9a7a"), "grass_hi": Color("5fe0b0"), "water": Color("1d3f86"), "water_hi": Color("6fa8ff"),
        "glow": Color("b8ff8a"), "moon": Color("e8e8ff"),
        "flower": [Color("a994ec"), Color("7cf0ff"), Color("ffb0e0")],
    },
    {
        "dark": true,
        "sky": [Color("0f0820"), Color("1f0f33"), Color("3a1540"), Color("5c1d44"), Color("8a2a4a")],
        "far": Color("24133a"), "mid": Color("2e1a4a"), "leaf": Color("3a2060"), "leaf_hi": Color("6a3a96"),
        "trunk": Color("1c1028"), "dirt": Color("3d2a4a"), "dirt_hi": Color("56396a"), "dirt_dark": Color("271833"),
        "grass": Color("3a8a5a"), "grass_hi": Color("74ffb0"), "water": Color("2a1a5a"), "water_hi": Color("7a4aff"),
        "glow": Color("7cf0ff"), "moon": Color("e0504a"),
        "flower": [Color("7cf0ff"), Color("ff6bd6"), Color("b8ff8a")],
    },
]

static func hrand(n: int) -> float:
    return fposmod(sin(float(n) * 12.9898 + 78.233) * 43758.5453, 1.0)

static func _disc(c: CanvasItem, cx: float, cy: float, r: float, col: Color) -> void:
    var y := -r
    while y < r:
        var w := snappedf(sqrt(maxf(0.0, r * r - (y + 4.0) * (y + 4.0))), 8.0)
        c.draw_rect(Rect2(cx - w, cy + y, w * 2.0, 8.0), col)
        y += 8.0

# ---------------------------------------------------------------- ARBRES
static func _pine(c: CanvasItem, x: float, base: float, tiers: int, px: float, col: Color, hi: Color, trunk: Color) -> void:
    c.draw_rect(Rect2(x - px * 0.5, base - px * 2.0, px, px * 2.0), trunk)
    for k in range(tiers):
        var w := float((tiers - k) * 2 + 2) * px
        var y := base - px * 2.0 - float(k + 1) * px * 2.0
        c.draw_rect(Rect2(x - w * 0.5, y, w, px * 2.0), col)
        c.draw_rect(Rect2(x - w * 0.5, y, px, px * 2.0), hi)
    c.draw_rect(Rect2(x - px * 0.5, base - px * 2.0 - float(tiers + 1) * px * 2.0, px, px * 2.0), col)

static func _oak(c: CanvasItem, x: float, base: float, px: float, h: float, pal: Dictionary) -> void:
    var trunk: Color = pal.trunk
    var leaf: Color = pal.leaf
    var hi: Color = pal.leaf_hi
    var trunk_h := px * (6.0 + floorf(h * 5.0))
    c.draw_rect(Rect2(x - px, base - trunk_h, px * 2.0, trunk_h), trunk)
    c.draw_rect(Rect2(x - px, base - trunk_h, px * 0.5, trunk_h), trunk.lightened(0.12))
    var rows := [4, 8, 10, 12, 12, 10, 8, 4]
    var top := base - trunk_h - px * float(rows.size()) + px * 2.0
    for r in range(rows.size()):
        var w := float(rows[r]) * px
        var col := leaf if r < rows.size() - 2 else leaf.darkened(0.25)
        c.draw_rect(Rect2(x - w * 0.5, top + float(r) * px, w, px), col)
    var rows2 := [2, 6, 8, 6, 2]
    for r in range(rows2.size()):
        var w2 := float(rows2[r]) * px
        c.draw_rect(Rect2(x + px * 5.0 - w2 * 0.5, top + px * 2.0 + float(r) * px, w2, px), leaf)
    for j in range(7):
        var jx := snappedf(x - px * 4.0 + hrand(int(x) + j) * px * 8.0, px)
        var jy := snappedf(top + px * (1.0 + float(j % 4) * 1.5), px)
        c.draw_rect(Rect2(jx, jy, px, px), hi)

static func _dead_tree(c: CanvasItem, x: float, base: float, px: float, h: float, pal: Dictionary) -> void:
    var trunk: Color = pal.trunk
    var hi: Color = pal.mid
    var trunk_h := px * (14.0 + floorf(h * 8.0))
    c.draw_rect(Rect2(x - px, base - trunk_h, px * 2.0, trunk_h), trunk)
    c.draw_rect(Rect2(x - px, base - trunk_h, px * 0.5, trunk_h), hi)
    for b in range(3):
        var by := base - trunk_h + px * (2.0 + float(b) * 4.0)
        var dir := 1.0 if (b + int(h * 10.0)) % 2 == 0 else -1.0
        for s in range(1, 5):
            c.draw_rect(Rect2(x + dir * px * (1.0 + float(s)) - (px if dir < 0.0 else 0.0), by - px * float(s) * 0.6, px, px), trunk)
        c.draw_rect(Rect2(x + dir * px * 6.0 - (px if dir < 0.0 else 0.0), by - px * 4.0, px, px * 2.0), trunk)

static func _tree_layer(c: CanvasItem, left: float, pal: Dictionary, theme: int, f: float, period: float, px: float, base: float, kind: int, seed_off: int) -> void:
    var off := left * f
    var start := floori(off / period)
    var count := int(1200.0 / period) + 3
    for k in range(-1, count):
        var idx := start + k
        var h := hrand(idx + seed_off)
        var x := float(idx) * period + h * period * 0.5 + left - off
        if kind == 0:
            var col: Color = pal.far
            _pine(c, x, base, 6 + int(h * 4.0), px, col, col.lightened(0.08), pal.trunk)
        elif theme == 2:
            _dead_tree(c, x, base, px, h, pal)
        else:
            _oak(c, x, base, px, h, pal)

static func _bushes(c: CanvasItem, left: float, pal: Dictionary, t: float) -> void:
    var f := 0.9
    var period := 190.0
    var off := left * f
    var start := floori(off / period)
    var leaf: Color = pal.leaf
    var hi: Color = pal.leaf_hi
    var fl: Array = pal.flower
    for k in range(-1, 8):
        var idx := start + k
        var h := hrand(idx + 900)
        var x := float(idx) * period + h * period * 0.6 + left - off
        var rows := [4, 8, 10, 8]
        for r in range(rows.size()):
            var w := float(rows[r]) * 8.0
            c.draw_rect(Rect2(x - w * 0.5, 540.0 - 32.0 + float(r) * 8.0, w, 8.0), leaf if r < 3 else leaf.darkened(0.25))
        c.draw_rect(Rect2(x - 16.0, 516.0, 8.0, 8.0), hi)
        var fc: Color = fl[posmod(idx, 3)]
        if h > 0.5:
            c.draw_rect(Rect2(x + 8.0, 520.0, 8.0, 8.0), fc)
            c.draw_rect(Rect2(x + 10.0, 522.0, 4.0, 4.0), Color("fff4b0"))

# ---------------------------------------------------------------- ÉTANG LOINTAIN
static func _far_pond(c: CanvasItem, left: float, pal: Dictionary, t: float) -> void:
    var f := 0.7
    var period := 900.0
    var off := left * f
    var start := floori(off / period)
    var water: Color = pal.water
    var wh: Color = pal.water_hi
    var wh2 := Color(wh.r, wh.g, wh.b, 0.6)
    var grass: Color = pal.grass
    for k in range(-1, 3):
        var idx := start + k
        if hrand(idx + 500) < 0.3:
            continue
        var sx := float(idx) * period + 120.0 + hrand(idx) * 200.0 + left - off
        var w := 380.0 + hrand(idx + 7) * 240.0
        c.draw_rect(Rect2(sx, 500.0, w, 48.0), water)
        c.draw_rect(Rect2(sx + 8.0, 500.0, w - 16.0, 4.0), wh)
        c.draw_rect(Rect2(sx - 8.0, 496.0, 16.0, 52.0), grass.darkened(0.3))
        c.draw_rect(Rect2(sx + w - 8.0, 496.0, 16.0, 52.0), grass.darkened(0.3))
        for j in range(int(w / 40.0)):
            var rx := sx + 12.0 + float(j) * 40.0 + sin(t * 1.2 + float(j) + float(idx)) * 6.0
            c.draw_rect(Rect2(rx, 512.0 + float(j % 3) * 10.0, 20.0, 4.0), wh2)
        for j in range(int(w / 120.0)):
            var lx := sx + 30.0 + float(j) * 110.0 + hrand(idx + j) * 30.0
            c.draw_rect(Rect2(lx, 502.0, 28.0, 6.0), grass)
            c.draw_rect(Rect2(lx + 4.0, 498.0, 20.0, 4.0), grass.lightened(0.2))

# ---------------------------------------------------------------- FOND COMPLET
static func draw_background(c: CanvasItem, left: float, theme: int, t: float) -> void:
    var pal: Dictionary = PALETTES[theme]
    var sky: Array = pal.sky
    var n := sky.size()
    var band := 700.0 / float(n)
    for i in range(n):
        c.draw_rect(Rect2(left - 20.0, -30.0 + float(i) * band, 1200.0, band + 2.0), sky[i])
    for i in range(n - 1):
        var yb := -30.0 + float(i + 1) * band
        for k in range(75):
            var x := left - 20.0 + float(k) * 16.0
            if k % 2 == 0:
                c.draw_rect(Rect2(x, yb - 8.0, 16.0, 8.0), sky[i + 1])
            else:
                c.draw_rect(Rect2(x, yb, 16.0, 8.0), sky[i])
    # soleil ou lune en pixels
    var moon: Color = pal.moon
    if theme == 0:
        _disc(c, left + 928.0, 110.0, 72.0, Color(1.0, 0.95, 0.7, 0.25))
        _disc(c, left + 928.0, 110.0, 48.0, Color("ffe9a3"))
    elif theme == 1:
        _disc(c, left + 900.0, 100.0, 48.0, moon)
        c.draw_rect(Rect2(left + 880.0, 84.0, 12.0, 12.0), Color(0.7, 0.7, 0.9, 0.7))
        c.draw_rect(Rect2(left + 912.0, 112.0, 8.0, 8.0), Color(0.7, 0.7, 0.9, 0.7))
    else:
        _disc(c, left + 860.0, 130.0, 72.0, Color(0.9, 0.2, 0.2, 0.2))
        _disc(c, left + 860.0, 130.0, 56.0, moon)
        c.draw_rect(Rect2(left + 836.0, 112.0, 16.0, 16.0), Color(0.6, 0.15, 0.2, 0.8))
        c.draw_rect(Rect2(left + 872.0, 144.0, 12.0, 12.0), Color(0.6, 0.15, 0.2, 0.8))
    if theme > 0:
        for i in range(30):
            var sx := left + fposmod(float(i) * 97.0, 1152.0)
            var sy := fposmod(float(i) * 47.0, 220.0)
            var a := clampf(0.4 + 0.6 * sin(t * 2.0 + float(i)), 0.1, 1.0)
            c.draw_rect(Rect2(sx, sy, 4.0, 4.0), Color(1.0, 1.0, 0.9, a))
    # rayons de lumière dans la forêt de jour
    if theme == 0:
        for i in range(3):
            var rx := left + fposmod(float(i) * 420.0 + 120.0 - left * 0.1, 1300.0) - 100.0
            c.draw_colored_polygon(PackedVector2Array([Vector2(rx, 0), Vector2(rx + 70.0, 0), Vector2(rx + 300.0, 540), Vector2(rx + 170.0, 540)]), Color(1.0, 1.0, 0.8, 0.07))
    # couches de forêt (parallaxe)
    _tree_layer(c, left, pal, theme, 0.25, 140.0, 10.0, 560.0, 0, 11)
    _far_pond(c, left, pal, t)
    _tree_layer(c, left, pal, theme, 0.55, 230.0, 8.0, 560.0, 1, 77)
    _bushes(c, left, pal, t)
    # brume mystérieuse
    var mc: Color = sky[3]
    mc.a = 0.12 if theme == 0 else 0.2
    for k in range(5):
        var mx := left - 300.0 + fposmod(float(k) * 330.0 + t * (10.0 + float(k) * 3.0), 1600.0)
        c.draw_rect(Rect2(mx, 430.0 + float(k) * 22.0, 420.0, 16.0), mc)
        c.draw_rect(Rect2(mx + 40.0, 446.0 + float(k) * 22.0, 340.0, 8.0), mc)
    # lucioles
    var glow: Color = pal.glow
    var count := 8 if theme == 0 else 20
    for i in range(count):
        var fx := left + fposmod(float(i) * 97.0 - left * 0.3 + sin(t * 0.7 + float(i)) * 30.0, 1152.0)
        var fy := 150.0 + fposmod(float(i) * 53.0, 330.0) + sin(t * 1.1 + float(i) * 1.7) * 20.0
        var blink := clampf(0.5 + 0.5 * sin(t * 3.0 + float(i) * 2.0), 0.0, 1.0)
        c.draw_rect(Rect2(fx - 4.0, fy - 4.0, 12.0, 12.0), Color(glow.r, glow.g, glow.b, 0.12 * blink))
        c.draw_rect(Rect2(fx, fy, 4.0, 4.0), Color(glow.r, glow.g, glow.b, 0.4 + 0.6 * blink))

# ---------------------------------------------------------------- ÉTANG DANS LES GOUFFRES
# Les trous du sol laissent voir une eau sombre et mystérieuse.
static func draw_water(c: CanvasItem, left: float, theme: int, t: float) -> void:
    var pal: Dictionary = PALETTES[theme]
    var water: Color = pal.water
    var wh: Color = pal.water_hi
    var grass: Color = pal.grass
    c.draw_rect(Rect2(left - 20.0, 596.0, 1200.0, 120.0), water)
    c.draw_rect(Rect2(left - 20.0, 596.0, 1200.0, 4.0), wh)
    c.draw_rect(Rect2(left - 20.0, 628.0, 1200.0, 40.0), water.darkened(0.25))
    for i in range(40):
        var sx := left - 20.0 + fposmod(float(i) * 61.0 + t * (6.0 + float(i % 3) * 3.0), 1200.0)
        c.draw_rect(Rect2(sx, 606.0 + float(i % 4) * 10.0, 12.0 + float(i % 3) * 4.0, 3.0), Color(wh.r, wh.g, wh.b, 0.55))
    var first := floori((left - 40.0) / 140.0)
    for k in range(first, first + 10):
        if hrand(k + 321) < 0.45:
            continue
        var x := float(k) * 140.0 + hrand(k) * 80.0
        var bob := sin(t * 1.5 + float(k)) * 1.5
        c.draw_rect(Rect2(x, 590.0 + bob, 32.0, 6.0), grass)
        c.draw_rect(Rect2(x + 4.0, 586.0 + bob, 24.0, 4.0), grass.lightened(0.2))
        c.draw_rect(Rect2(x + 14.0, 590.0 + bob, 4.0, 3.0), water)
        if hrand(k + 9) > 0.6:
            c.draw_rect(Rect2(x + 12.0, 580.0 + bob, 8.0, 6.0), Color("ff9fd6"))
            c.draw_rect(Rect2(x + 14.0, 578.0 + bob, 4.0, 4.0), Color.WHITE)
    var glow: Color = pal.glow
    if theme >= 1:
        for i in range(6):
            var wx := left + fposmod(float(i) * 211.0 + t * 14.0, 1152.0)
            var frac := fposmod(t * 0.4 + float(i) * 0.23, 1.0)
            c.draw_rect(Rect2(wx, 596.0 - frac * 90.0, 6.0, 6.0), Color(glow.r, glow.g, glow.b, 1.0 - frac))
    var mist := Color(1.0, 1.0, 1.0, 0.1)
    for k in range(4):
        var mx := left - 200.0 + fposmod(float(k) * 380.0 + t * 12.0, 1500.0)
        c.draw_rect(Rect2(mx, 566.0 + float(k % 2) * 12.0, 320.0, 12.0), mist)

# ---------------------------------------------------------------- PLANTES
static func _plant(c: CanvasItem, kind: int, x: float, top: float, pal: Dictionary, t: float) -> void:
    var grass: Color = pal.grass
    var gh: Color = pal.grass_hi
    var glow: Color = pal.glow
    var fl: Array = pal.flower
    match kind:
        0, 1:
            c.draw_rect(Rect2(x, top - 12.0, 4.0, 12.0), grass)
            c.draw_rect(Rect2(x + 4.0, top - 18.0, 4.0, 18.0), gh)
            c.draw_rect(Rect2(x + 8.0, top - 10.0, 4.0, 10.0), grass)
        2:
            var fc: Color = fl[int(x) % 3]
            c.draw_rect(Rect2(x + 2.0, top - 16.0, 4.0, 16.0), grass)
            c.draw_rect(Rect2(x - 2.0, top - 24.0, 12.0, 8.0), fc)
            c.draw_rect(Rect2(x + 2.0, top - 22.0, 4.0, 4.0), Color("fff4b0"))
        3:
            c.draw_rect(Rect2(x + 4.0, top - 20.0, 4.0, 20.0), grass)
            for j in range(3):
                var ly := top - 8.0 - float(j) * 6.0
                var lw := 14.0 - float(j) * 3.0
                c.draw_rect(Rect2(x + 8.0, ly, lw, 4.0), gh)
                c.draw_rect(Rect2(x + 4.0 - lw, ly - 2.0, lw, 4.0), grass)
        4:
            c.draw_rect(Rect2(x + 4.0, top - 8.0, 4.0, 8.0), Color("e8dcc0"))
            if pal.dark:
                c.draw_circle(Vector2(x + 6.0, top - 10.0), 16.0, Color(glow.r, glow.g, glow.b, 0.12 + 0.06 * sin(t * 2.0 + x)))
                c.draw_rect(Rect2(x, top - 14.0, 12.0, 6.0), glow)
                c.draw_rect(Rect2(x + 4.0, top - 14.0, 4.0, 2.0), Color.WHITE)
            else:
                c.draw_rect(Rect2(x, top - 14.0, 12.0, 6.0), Color("e04a4a"))
                c.draw_rect(Rect2(x + 2.0, top - 12.0, 3.0, 3.0), Color.WHITE)
                c.draw_rect(Rect2(x + 7.0, top - 13.0, 3.0, 3.0), Color.WHITE)
        _:
            c.draw_rect(Rect2(x, top - 10.0, 14.0, 10.0), grass.darkened(0.2))
            c.draw_rect(Rect2(x + 2.0, top - 14.0, 10.0, 4.0), grass)
            c.draw_rect(Rect2(x + 4.0, top - 12.0, 4.0, 4.0), gh)

static func _reed(c: CanvasItem, x: float, top: float, pal: Dictionary, t: float) -> void:
    var stem: Color = pal.grass
    stem = stem.darkened(0.3)
    var sway := sin(t * 1.5 + x) * 1.5
    c.draw_rect(Rect2(x, top - 30.0, 4.0, 30.0), stem)
    c.draw_rect(Rect2(x - 2.0 + sway, top - 42.0, 8.0, 14.0), Color("7a4a2a"))
    c.draw_rect(Rect2(x + 8.0, top - 22.0, 4.0, 22.0), stem)
    c.draw_rect(Rect2(x + 6.0 + sway, top - 32.0, 8.0, 10.0), Color("8a5a32"))

# ---------------------------------------------------------------- BLOCS (sol et plateformes)
static func draw_platform(c: CanvasItem, rect: Rect2, theme: int, left: float, t: float) -> void:
    var pal: Dictionary = PALETTES[theme]
    var x0 := maxf(rect.position.x, left - 48.0)
    var x1 := minf(rect.end.x, left + 1200.0)
    if x1 <= x0:
        return
    var top := rect.position.y
    var bottom := minf(rect.end.y, 664.0)
    var sd := int(rect.position.x) * 3 + int(rect.position.y)
    var is_ground := rect.size.y > 40.0
    var dirt: Color = pal.dirt
    var dirt_hi: Color = pal.dirt_hi
    var dirt_dark: Color = pal.dirt_dark
    var grass: Color = pal.grass
    var gh: Color = pal.grass_hi
    c.draw_rect(Rect2(x0, top, x1 - x0, bottom - top), dirt)
    # blocs de 24 px avec joints décalés
    var tile := 24.0
    var row := 0
    var y := top
    while y < bottom:
        var offs := 0.0 if row % 2 == 0 else tile * 0.5
        var ti := int(floorf((x0 - rect.position.x - offs) / tile))
        var xv := rect.position.x + offs + float(ti) * tile
        while xv < x1:
            var hr := hrand(sd + row * 131 + ti * 17)
            if xv >= x0 and xv < x1 - 4.0:
                c.draw_rect(Rect2(xv, y, 3.0, tile), dirt_dark)
            if hr > 0.45 and xv + 16.0 < x1 and xv + 6.0 >= x0:
                c.draw_rect(Rect2(xv + 6.0 + hr * 6.0, y + 6.0 + hr * 4.0, 6.0, 6.0), dirt_hi)
            if hr < 0.2 and xv + 20.0 < x1 and xv + 14.0 >= x0:
                c.draw_rect(Rect2(xv + 14.0, y + 12.0, 4.0, 4.0), dirt_dark)
            ti += 1
            xv += tile
        c.draw_rect(Rect2(x0, y + tile - 3.0, x1 - x0, 3.0), dirt_dark)
        y += tile
        row += 1
    if rect.position.x >= x0:
        c.draw_rect(Rect2(rect.position.x, top, 4.0, bottom - top), dirt_hi)
    if rect.end.x <= x1:
        c.draw_rect(Rect2(rect.end.x - 4.0, top, 4.0, bottom - top), dirt_dark)
    # herbe sur le dessus
    c.draw_rect(Rect2(x0, top, x1 - x0, 8.0), grass)
    c.draw_rect(Rect2(x0, top, x1 - x0, 4.0), gh)
    var gx := floorf(x0 / 8.0) * 8.0
    while gx < x1:
        var hh := hrand(int(gx / 8.0) + sd)
        if gx >= x0 and gx + 8.0 <= x1:
            if hh > 0.5:
                c.draw_rect(Rect2(gx, top - 4.0, 4.0, 4.0), gh)
            if hh > 0.82:
                c.draw_rect(Rect2(gx + 4.0, top - 8.0, 4.0, 8.0), grass)
            if hh < 0.3:
                c.draw_rect(Rect2(gx, top + 8.0, 4.0, 6.0 + hh * 20.0), grass)
        gx += 8.0
    # plantes
    if rect.size.x > 90.0:
        var k := int(ceilf((x0 - rect.position.x) / 44.0))
        while true:
            var px := rect.position.x + float(k) * 44.0 + 14.0 + hrand(sd + k * 7) * 14.0
            if px > x1 - 16.0:
                break
            if px >= x0 + 2.0 and hrand(sd + k * 3) > 0.3:
                _plant(c, int(hrand(sd + k * 29 + 5) * 6.0), px, top, pal, t)
            k += 1
    # roseaux près des gouffres, lianes sous les plateformes flottantes
    if is_ground:
        var rx0 := rect.position.x + 10.0
        var rx1 := rect.end.x - 26.0
        if rx0 >= x0 and rx0 < x1:
            _reed(c, rx0, top, pal, t)
        if rx1 >= x0 and rx1 < x1:
            _reed(c, rx1, top, pal, t)
    else:
        var vk := int(ceilf((x0 - rect.position.x) / 24.0))
        var vine := grass.darkened(0.3)
        while true:
            var vx := rect.position.x + float(vk) * 24.0 + 8.0
            if vx > x1 - 8.0:
                break
            var vh := hrand(sd + vk * 41)
            if vx >= x0 and vh > 0.45:
                c.draw_rect(Rect2(vx, top + 24.0, 4.0, 8.0 + vh * 18.0), vine)
                c.draw_rect(Rect2(vx + 4.0, top + 28.0 + vh * 10.0, 4.0, 4.0), grass)
            vk += 1
