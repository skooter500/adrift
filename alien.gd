extends CharacterBody3D

var explosion_scene:PackedScene=preload("explosion.tscn")

var color:Color

# The tween moves this target (in the parent's space) exactly like it used to
# move `position`. _physics_process then steers the body towards it with
# move_and_slide(), so the alien slides along the room instead of going through it.
var _target:Vector3
var _moving:bool = false
var _dead:bool = false

func _ready() -> void:
	# Flying alien: no floor/gravity handling in move_and_slide().
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING

	var mesh:MeshInstance3D = get_node("mesh")
	mesh.get_surface_override_material(0).albedo_color = color

	# Grow in. Scale the mesh rather than the physics body, since scaling
	# a CharacterBody3D is not supported by the physics engine.
	var target_scale:Vector3 = mesh.scale
	mesh.scale = Vector3.ZERO
	var tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(mesh, "scale", target_scale, 1)
	tween.connect("finished", movement)

	# vary the pitch
	$synth.pitch_scale = randf_range(0.5, 2)
	$synth.play()

func movement():
	var t:float = 2
	var dist = 0.1
	# Start each cycle from wherever the body actually ended up.
	_target = position
	_moving = true
	var tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "_target", position + Vector3.FORWARD * dist, t)
	tween.tween_property(self, "_target", position + Vector3.UP * dist, t)
	tween.tween_property(self, "_target", position + Vector3.RIGHT * dist, t)
	tween.tween_property(self, "_target", position + Vector3.DOWN * dist, t)
	tween.tween_property(self, "_target", position + Vector3.LEFT * dist, t)
	tween.finished.connect(movement)
	tween.step_finished.connect(move_step)

func _physics_process(delta: float) -> void:
	if not _moving:
		velocity = Vector3.ZERO
		return
	# Velocity that would reach the tweened target this frame; move_and_slide()
	# clips it against walls, floor and furniture so we slide along them.
	var target_global:Vector3 = get_parent().to_global(_target)
	velocity = (target_global - global_position) / delta
	move_and_slide()

	# Touching anything solid (room walls, ceiling, floor, furniture...) blows the alien up.
	if get_slide_collision_count() > 0:
		_hit(get_slide_collision(0).get_collider())

func move_step(i):
	$blip.pitch_scale=randf_range(0.7, 3)
	# $blip.play()

func _process(delta: float) -> void:
	rotate_y(delta)

func _on_area_3d_body_entered(body: Node3D) -> void:
	_hit(body)

## Explode and report the kill. 3 points for the Godot plushy, 1 point for the
## player's hands, 0 for anything else (the room, the ground...).
func _hit(body: Node) -> void:
	if _dead:
		return
	_dead = true

	var exp:GPUParticles3D = explosion_scene.instantiate()
	exp.emitting = true
	exp.color = color
	exp.position = position
	get_parent().add_child(exp)
	self.queue_free()
	if body and body.is_in_group("ball"):
		body.queue_free()

	var points:int = 0
	if body and body.is_in_group("plushy"):
		points = 3
	elif body and body.is_in_group("hand"):
		points = 1
	get_parent().get_parent().get_parent().alien_killed(points)
