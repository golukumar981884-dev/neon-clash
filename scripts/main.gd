extends Node3D

const FighterScript = preload("res://scripts/fighter.gd")

var team_a: Array = []
var team_b: Array = []
var active_a := 0
var active_b := 0
var hud: CanvasLayer
var ui: Control
var health_a: ProgressBar
var health_b: ProgressBar
var power_a: ProgressBar
var status_label: Label
var held_left := false
var held_right := false
var ai_timer := 0.0
var match_over := false

func _ready() -> void:
    _make_arena()
    _make_lighting()
    _make_camera()
    _spawn_teams()
    _make_hud()
    _connect_opponents()
    _refresh_hud()

func _make_arena() -> void:
    var floor := MeshInstance3D.new()
    var plane := PlaneMesh.new()
    plane.size = Vector2(24, 18)
    floor.mesh = plane
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.055, 0.075, 0.11)
    mat.roughness = 0.78
    floor.material_override = mat
    floor.position.y = -0.08
    add_child(floor)

    var ring := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = Vector3(12, 0.12, 9)
    ring.mesh = box
    var rm := StandardMaterial3D.new()
    rm.albedo_color = Color(0.015, 0.22, 0.32)
    rm.emission_enabled = true
    rm.emission = Color(0.0, 0.45, 0.75)
    rm.emission_energy_multiplier = 1.4
    ring.material_override = rm
    ring.position.y = 0.02
    add_child(ring)

    for x in [-6.0, 6.0]:
        for z in [-4.5, 4.5]:
            var pillar := MeshInstance3D.new()
            var pm := CylinderMesh.new()
            pm.top_radius = 0.18
            pm.bottom_radius = 0.24
            pm.height = 3.5
            pillar.mesh = pm
            var pmat := StandardMaterial3D.new()
            pmat.albedo_color = Color(0.08, 0.18, 0.3)
            pmat.emission_enabled = true
            pmat.emission = Color(0.015, 0.08, 0.2)
            pillar.material_override = pmat
            pillar.position = Vector3(x, 1.75, z)
            add_child(pillar)

func _make_lighting() -> void:
    var world := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.012, 0.022, 0.045)
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.58, 0.66, 0.82)
    env.ambient_light_energy = 1.0
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    world.environment = env
    add_child(world)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-48, -28, 0)
    sun.light_energy = 2.0
    sun.shadow_enabled = true
    add_child(sun)

    var fill := OmniLight3D.new()
    fill.position = Vector3(0, 5, 3)
    fill.light_color = Color(0.2, 0.55, 1.0)
    fill.light_energy = 2.2
    fill.omni_range = 14.0
    add_child(fill)

func _make_camera() -> void:
    var camera := Camera3D.new()
    camera.position = Vector3(0, 6.8, 13.2)
    camera.look_at(Vector3(0, 1.15, 0), Vector3.UP)
    camera.fov = 48
    add_child(camera)
    camera.current = true

func _spawn_teams() -> void:
    var a1 = _new_fighter("VOLT", Color(0.12, 0.58, 1.0), Vector3(-2.2, 0, 0))
    var a2 = _new_fighter("BLAZE", Color(1.0, 0.35, 0.12), Vector3(-3.2, 0, 0))
    var b1 = _new_fighter("SHADE", Color(0.75, 0.22, 0.95), Vector3(2.2, 0, 0))
    var b2 = _new_fighter("TITAN", Color(0.95, 0.72, 0.12), Vector3(3.2, 0, 0))
    team_a = [a1, a2]
    team_b = [b1, b2]
    a1.rotation.y = PI
    a2.rotation.y = PI
    b1.rotation.y = 0
    b2.rotation.y = 0
    a1.is_active = true
    b1.is_active = true
    a2.visible = false
    b2.visible = false

func _new_fighter(label: String, tint: Color, pos: Vector3):
    var f = FighterScript.new()
    f.setup(label, tint)
    f.position = pos
    add_child(f)
    return f

func _connect_opponents() -> void:
    for f in team_a:
        f.opponent = team_b[active_b]
    for f in team_b:
        f.opponent = team_a[active_a]

func _make_hud() -> void:
    hud = CanvasLayer.new()
    add_child(hud)
    ui = Control.new()
    ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    ui.mouse_filter = Control.MOUSE_FILTER_PASS
    hud.add_child(ui)

    var title := Label.new()
    title.text = "TAG FIGHTER 3D  |  PROTOTYPE"
    title.anchor_left = 0.035
    title.anchor_top = 0.025
    title.add_theme_font_size_override("font_size", 22)
    title.add_theme_color_override("font_color", Color(0.82, 0.93, 1))
    ui.add_child(title)

    health_a = _bar(0.035, 0.085, 0.34, Color(0.1, 0.65, 1))
    health_b = _bar(0.625, 0.085, 0.34, Color(1, 0.3, 0.18))
    power_a = _bar(0.035, 0.132, 0.21, Color(0.15, 0.95, 0.75))

    status_label = Label.new()
    status_label.anchor_left = 0.39
    status_label.anchor_top = 0.085
    status_label.anchor_right = 0.61
    status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    status_label.add_theme_font_size_override("font_size", 18)
    status_label.add_theme_color_override("font_color", Color.WHITE)
    ui.add_child(status_label)

    _add_button("TAG", 0.035, 0.72, 0.105, 0.11, "tag")
    _add_button("MOVE ◀", 0.035, 0.85, 0.13, 0.11, "left")
    _add_button("MOVE ▶", 0.18, 0.85, 0.13, 0.11, "right")
    _add_button("PUNCH", 0.79, 0.79, 0.105, 0.11, "punch")
    _add_button("KICK", 0.875, 0.66, 0.105, 0.11, "kick")
    _add_button("SPECIAL", 0.875, 0.85, 0.105, 0.11, "special")

func _bar(anchor_x: float, anchor_y: float, width: float, color: Color) -> ProgressBar:
    var bar := ProgressBar.new()
    bar.anchor_left = anchor_x
    bar.anchor_top = anchor_y
    bar.anchor_right = anchor_x + width
    bar.anchor_bottom = anchor_y + 0.035
    bar.show_percentage = false
    bar.min_value = 0
    bar.max_value = 100
    var fill := StyleBoxFlat.new()
    fill.bg_color = color
    fill.corner_radius_top_left = 5
    fill.corner_radius_top_right = 5
    fill.corner_radius_bottom_left = 5
    fill.corner_radius_bottom_right = 5
    bar.add_theme_stylebox_override("fill", fill)
    var bg := StyleBoxFlat.new()
    bg.bg_color = Color(0.06, 0.07, 0.1, 0.92)
    bar.add_theme_stylebox_override("background", bg)
    ui.add_child(bar)
    return bar

func _add_button(label: String, x: float, y: float, w: float, h: float, action: String) -> void:
    var button := Button.new()
    button.text = label
    button.anchor_left = x
    button.anchor_top = y
    button.anchor_right = x + w
    button.anchor_bottom = y + h
    button.add_theme_font_size_override("font_size", 17)
    button.add_theme_color_override("font_color", Color.WHITE)
    button.button_down.connect(_on_button_down.bind(action))
    button.button_up.connect(_on_button_up.bind(action))
    button.pressed.connect(_on_action.bind(action))
    ui.add_child(button)

func _on_button_down(action: String) -> void:
    if action == "left":
        held_left = true
    elif action == "right":
        held_right = true

func _on_button_up(action: String) -> void:
    if action == "left":
        held_left = false
    elif action == "right":
        held_right = false

func _on_action(action: String) -> void:
    if match_over:
        return
    var fighter = team_a[active_a]
    match action:
        "punch":
            fighter.attack(8.0)
        "kick":
            fighter.attack(13.0)
        "special":
            fighter.special_attack()
        "tag":
            _tag_switch()
    _refresh_hud()

func _tag_switch() -> void:
    team_a[active_a].visible = false
    team_a[active_a].is_active = false
    active_a = 1 - active_a
    team_a[active_a].position = Vector3(maxf(-3.6, team_a[1 - active_a].position.x - 0.8), 0, 0)
    team_a[active_a].visible = true
    team_a[active_a].is_active = true
    _connect_opponents()
    status_label.text = "TAG: " + team_a[active_a].fighter_name

func _process(delta: float) -> void:
    if match_over:
        return
    var player = team_a[active_a]
    if held_left:
        player.position.x = maxf(-4.5, player.position.x - 4.0 * delta)
    if held_right:
        player.position.x = minf(0.8, player.position.x + 4.0 * delta)

    var enemy = team_b[active_b]
    ai_timer -= delta
    var dx: float = player.global_position.x - enemy.global_position.x
    enemy.rotation.y = PI if dx > 0.0 else 0.0
    if absf(dx) > 1.8:
        enemy.position.x = move_toward(enemy.position.x, player.position.x + (1.25 if dx > 0.0 else -1.25), 2.2 * delta)
    elif ai_timer <= 0.0:
        ai_timer = 0.85
        enemy.attack(9.0)

    _refresh_hud()
    if team_b[active_b].health <= 0.0:
        team_b[active_b].visible = false
        team_b[active_b].is_active = false
        active_b = 1 - active_b
        if team_b[active_b].health <= 0.0:
            match_over = true
            status_label.text = "YOU WIN!"
        else:
            team_b[active_b].position = Vector3(2.8, 0, 0)
            team_b[active_b].visible = true
            team_b[active_b].is_active = true
            _connect_opponents()
            status_label.text = "OPPONENT TAG!"
    if team_a[active_a].health <= 0.0:
        if team_a[1 - active_a].health > 0.0:
            _tag_switch()
        else:
            match_over = true
            status_label.text = "YOU LOSE"

func _refresh_hud() -> void:
    if team_a.is_empty() or team_b.is_empty():
        return
    health_a.value = team_a[active_a].health
    health_b.value = team_b[active_b].health
    power_a.value = team_a[active_a].power
    if status_label.text == "":
        status_label.text = team_a[active_a].fighter_name + "  VS  " + team_b[active_b].fighter_name
