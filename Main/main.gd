extends Node3D

@export var npcCount = 10
var npcScene = preload("res://Spawnables/npc.tscn")

func _ready():
	var npcs = []
	
	for i in range(npcCount):
		var npc = npcScene.instantiate()
		add_child(npc)
		npc.global_position = Vector3(randf_range(-10,10), 1, randf_range(-10,10))
		npcs.append(npc)
		if i%2 == 1:
			npcs[i].pair = npcs[i-1]
			npcs[i-1].pair = npcs[i]
			
			
