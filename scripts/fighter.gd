extends Node3D
class_name Fighter

var fighter_name := "Fighter"
var team_color := Color(0.2, 0.65, 1.0)
var health := 100.0
var power := 0.0
var attack_cooldown := 0.0
var is_active := false
var opponent: Node3D

func setup(label: String, tint: Color) -> void:
    fighter_name = label
    team_color = tint
    _build_body()

func _build_body() -> void:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = team_color
    mat.metallic = 0.18
    mat.roughness = 0.34
    mat.emission_enabled = true
    mat.emission = team_color * 0.12

    var body := MeshInstance3D.new()
    var capsule := CapsuleMesh.new()
    capsule.radius = 0.42
    capsule.height = 1.45
    body.mesh = capsule
    body.material_override = mat
    body.position.y = 1.05
    add_child(body)

    var head := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = 0.31
    sphere.height = 0.62
    head.mesh = sphere
    head.material_override = mat
    head.position.y = 2.02
    add_child(head)

    for side in [-1.0, 1.0]:
        var limb := MeshInstance3D.new()
        var limb_mesh := CapsuleMesh.new()
        limb_mesh.radius = 0.16
        limb_mesh.height = 0.95
        limb.mesh = limb_mesh
        limb.material_override = mat
        limb.position = Vector3(side * 0.52, 1.18, 0.0)
        limb.rotation.z = side * -0.25
        add_child(limb)

        var leg := MeshInstance3D.new()
        var leg_mesh := CapsuleMesh.new()
        leg_mesh.radius = 0.19
        leg_mesh.height = 0.9
        leg.mesh = leg_mesh
        leg.material_override = mat
        leg.position = Vector3(side * 0.22, 0.38, 0.0)
        add_child(leg)

func _process(delta: float) -> void:
    attack_cooldown = maxf(0.0, attack_cooldown - delta)

func take_hit(amount: float) -> void:
    health = maxf(0.0, health - amount)
    power = minf(100.0, power + amount * 0.7)

func attack(amount: float) -> bool:
    if attack_cooldown > 0.0 or health <= 0.0:
        return false
    attack_cooldown = 0.42
    if is_instance_valid(opponent) and opponent.has_method("take_hit"):
        if global_position.distance_to(opponent.global_position) <= 3.0:
            opponent.take_hit(amount)
            power = minf(100.0, power + 8.0)
            return true
    return false

func special_attack() -> bool:
    if power < 35.0 or attack_cooldown > 0.0 or health <= 0.0:
        return false
    if not is_instance_valid(opponent) or global_position.distance_to(opponent.global_position) > 3.5:
        return false
    power -= 35.0
    attack_cooldown = 0.9
    if opponent.has_method("take_hit"):
        opponent.take_hit(24.0)
    return true
