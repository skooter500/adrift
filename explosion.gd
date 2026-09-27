extends GPUParticles3D

## Colour of the particles. Set this before adding the explosion to the tree.
@export var color:Color = Color(0.843481, 0.0660814, 0.812292, 1)
## Skip the sound (used by the start-up shader warm-up).
@export var silent:bool = false

var _pending:int = 0

func _ready() -> void:
	# Each explosion gets its own copy of the material, otherwise changing the
	# colour would recolour every explosion that shares the resource.
	material_override = material_override.duplicate()
	material_override.albedo_color = color

	# Free ourselves once the particles and the sound are both done.
	_pending = 1
	finished.connect(_on_part_finished)
	if silent:
		$explosion.stop()
	else:
		_pending += 1
		$explosion.finished.connect(_on_part_finished)

func _on_part_finished() -> void:
	_pending -= 1
	if _pending <= 0:
		queue_free()
