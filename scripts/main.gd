extends Node3D

const FighterScript = preload("res://scripts/fighter.gd")

var team_a: Array = []
var team_b: Array = []
var active_a := 0
var active_b := 0
var hud: CanvasLayer
var health_a: ProgressBar
var health_b: ProgressBar
var power_a: ProgressBar
var status_label: Label

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
    plane.size = Vector2(22, 16)
    floor.mesh = plane
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.075, 0.09, 0.13)
    mat.roughness = 0.82
    floor.material_override = mat
    add_child(floor)

    var ring := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = Vector3(12, 0.12, 9)
    ring.mesh = box
    var rm := StandardMaterial3D.new()
    rm.albedo_color = Color(0.08, 0.45, 0.72)
    rm.emission_enabled = true
    rm.emission = Color(0.02, 0.22, 0.55)
    ring.material_override = rm
    ring.position.y = 0.08
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
            pmat.albedo_color = Color(0.12, 0.17, 0.24)
            pillar.material_override = pmat
            pillar.position = Vector3(x, 1.75, z)
            add_child(pillar)

func _make_lighting() -> void:
    var world := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_SKY
    env.sky = Sky.new()
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.38, 0.46, 0.62)
    env.ambient_light_energy = 0.65
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    world.environment = env
    add_child(world)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-48, -28, 0)
    sun.light_energy = 1.7
    sun.shadow_enabled = true
    add_child(sun)

func _make_camera() -> void:
    var camera := Camera3D.new()
    camera.position = Vector3(0, 7.5, 13.5)
    camera.look_at(Vector3(0, 1, 0), Vector3.UP)
    camera.fov = 48
    add_child(camera)
    camera.current = true

func _spawn_teams() -> void:
    var a1 = _new_fighter("VOLT", Color(0.12, 0.58, 1.0), Vector3(-2.4, 0, 1.2))
    var a2 = _new_fighter("BLAZE", Color(1.0, 0.35, 0.12), Vector3(-3.4, 0, 1.2))
    var b1 = _new_fighter("SHADE", Color(0.65, 0.25, 0.95), Vector3(2.4, 0, -1.2))
    var b2 = _new_fighter("TITAN", Color(0.95, 0.72, 0.12), Vector3(3.4, 0, -1.2))
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

    var title := Label.new()
    title.text = "TAG FIGHTER 3D   |   PROTOTYPE"
    title.position = Vector2(22, 12)
    title.add_theme_font_size_override("font_size", 22)
    title.add_theme_color_override("font_color", Color(0.75, 0.9, 1))
    hud.add_child(title)

    health_a = _bar(Vector2(22, 54), Vector2(430, 24), Color(0.1, 0.65, 1))
    health_b = _bar(Vector2(828, 54), Vector2(430, 24), Color(1, 0.3, 0.18))
    power_a = _bar(Vector2(22, 84), Vector2(260, 12), Color(0.15, 0.95, 0.75))
    status_label = Label.new()
    status_label.position = Vector2(510, 58)
    status_label.add_theme_font_size_override("font_size", 18)
    hud.add_child(status_label)

    _add_button("PUNCH", Vector2(950, 570), Vector2(130, 62), "punch")
    _add_button("KICK", Vector2(1090, 500), Vector2(130, 62), "kick")
    _add_button("SPECIAL", Vector2(1080, 640), Vector2(150, 54), "special")
    _add_button("TAG", Vector2(40, 590), Vector2(130, 62), "tag")
    _add_button("MOVE ◀", Vector2(200, 610), Vector2(120, 54), "left")
    _add_button("MOVE ▶", Vector2(330, 610), Vector2(120, 54), "right")

func _bar(pos: Vector2, size: Vector2, color: Color) -> ProgressBar:
    var bar := ProgressBar.new()
    bar.position = pos
    bar.size = size
    bar.min_value = 0
    bar.max_value = 100
    bar.show_percentage = false
    var fill := StyleBoxFlat.new()
    fill.bg_color = color
    fill.corner_radius_top_left = 5
    fill.corner_radius_top_right = 5
    fill.corner_radius_bottom_left = 5
    fill.corner_radius_bottom_right = 5
    bar.add_theme_stylebox_override("fill", fill)
    var bg := StyleBoxFlat.new()
    bg.bg_color = Color(0.06, 0.07, 0.1, 0.9)
    bar.add_theme_stylebox_override("background", bg)
    hud.add_child(bar)
    return bar

func _add_button(label: String, pos: Vector2, size: Vector2, action: String) -> void:
    var button := Button.new()
    button.text = label
    button.position = pos
    button.size = size
    button.add_theme_font_size_override("font_size", 18)
    button.pressed.connect(_on_action.bind(action))
    hud.add_child(button)

func _on_action(action: String) -> void:
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
        "left":
            fighter.position.x = maxf(-4.0, fighter.position.x - 0.45)
        "right":
            fighter.position.x = minf(-0.8, fighter.position.x + 0.45)
    _refresh_hud()

func _tag_switch() -> void:
    team_a[active_a].visible = false
    team_a[active_a].is_active = false
    active_a = 1 - active_a
    team_a[active_a].visible = true
    team_a[active_a].is_active = true
    _connect_opponents()
    status_label.text = "TAG: " + team_a[active_a].fighter_name

func _process(_delta: float) -> void:
    _refresh_hud()

func _refresh_hud() -> void:
    if team_a.is_empty() or team_b.is_empty():
        return
    health_a.value = team_a[active_a].health
    health_b.value = team_b[active_b].health
    power_a.value = team_a[active_a].power
    if status_label.text == "":
        status_label.text = team_a[active_a].fighter_name + "  VS  " + team_b[active_b].fighter_name
