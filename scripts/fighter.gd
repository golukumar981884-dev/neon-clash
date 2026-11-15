extends Node3D
class_name Fighter

var fighter_name := "Fighter"
var team_color := Color(0.2, 0.65, 1.0)
var health := 100.0
var power := 0.0
var attack_cooldown := 0.0
var is_active := false
var opponent: Node3D
var body_material: StandardMaterial3D
var body_root: Node3D

func setup(label: String, tint: Color) -> void:
    fighter_name = label
    team_color = tint
    _build_body()

func _build_body() -> void:
    body_root = Node3D.new()
    add_child(body_root)
    body_material = StandardMaterial3D.new()
    body_material.albedo_color = team_color
    body_material.metallic = 0.18
    body_material.roughness = 0.34
    body_material.emission_enabled = true
    body_material.emission = team_color * 0.12

    var body := MeshInstance3D.new()
    var capsule := CapsuleMesh.new()
    capsule.radius = 0.42
    capsule.height = 1.45
    body.mesh = capsule
    body.material_override = body_material
    body.position.y = 1.05
    body_root.add_child(body)

    var head := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = 0.31
    sphere.height = 0.62
    head.mesh = sphere
    head.material_override = body_material
    head.position.y = 2.02
    body_root.add_child(head)

    for side in [-1.0, 1.0]:
        var limb := MeshInstance3D.new()
        var limb_mesh := CapsuleMesh.new()
        limb_mesh.radius = 0.16
        limb_mesh.height = 0.95
        limb.mesh = limb_mesh
        limb.material_override = body_material
        limb.position = Vector3(side * 0.52, 1.18, 0.0)
        limb.rotation.z = side * -0.25
        body_root.add_child(limb)

        var leg := MeshInstance3D.new()
        var leg_mesh := CapsuleMesh.new()
        leg_mesh.radius = 0.19
        leg_mesh.height = 0.9
        leg.mesh = leg_mesh
        leg.material_override = body_material
        leg.position = Vector3(side * 0.22, 0.38, 0.0)
        body_root.add_child(leg)

func _process(delta: float) -> void:
    attack_cooldown = maxf(0.0, attack_cooldown - delta)

func take_hit(amount: float) -> void:
    if health <= 0.0:
        return
    health = maxf(0.0, health - amount)
    power = minf(100.0, power + amount * 0.7)
    _show_hit_reaction()

func _show_hit_reaction() -> void:
    if not is_instance_valid(body_root):
        return
    body_material.albedo_color = Color.WHITE
    var tween := create_tween()
    tween.tween_property(body_root, "position:x", -0.22 if rotation.y == 0.0 else 0.22, 0.07)
    tween.tween_property(body_root, "position:x", 0.0, 0.12)
    tween.parallel().tween_property(body_material, "albedo_color", team_color, 0.18)

func attack(amount: float) -> bool:
    if attack_cooldown > 0.0 or health <= 0.0:
        return false
    attack_cooldown = 0.38
    if is_instance_valid(opponent) and opponent.has_method("take_hit"):
        var distance := Vector2(global_position.x, global_position.z).distance_to(Vector2(opponent.global_position.x, opponent.global_position.z))
        if distance <= 5.2:
            opponent.take_hit(amount)
            power = minf(100.0, power + 8.0)
            return true
    return false

func special_attack() -> bool:
    if attack_cooldown > 0.0 or health <= 0.0:
        return false
    if not is_instance_valid(opponent) or power < 20.0:
        return false
    var distance := Vector2(global_position.x, global_position.z).distance_to(Vector2(opponent.global_position.x, opponent.global_position.z))
    if distance > 5.8:
        return false
    power -= 20.0
    attack_cooldown = 0.85
    opponent.take_hit(24.0)
    return true
