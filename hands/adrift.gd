extends Node3D

	# when the scene is loaded, assign these variables from the scene
@onready var ufo_spawner = $content/alien_spawner
@onready var dude = $XROrigin3D/XRCamera3D

var alien_count:int=0

func _ready():	
	next_level()
	pass
	

var target = 0
var level = 0

func next_level():
	$spawn.play()
	# ufo_spawner.radius = 1
	ufo_spawner.count = level + 1
	ufo_spawner.rate  = level + 1
	# ufo_spawner.position = dude.position
	ufo_spawner.spawn()	
	level = level + 1
	# next target
	target = target + ufo_spawner.count


func _process(delta):
	# if the dude reaches the target, advance to next level
	if alien_count == target:
		next_level()
	pass
