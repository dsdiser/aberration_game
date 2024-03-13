extends Node


func _process(delta):
	var enemies = get_tree().get_nodes_in_group("enemies")
	if not enemies:
		GlobalLoader.goto_next_scene()
		
	var player = get_tree().get_nodes_in_group("player")
	if not player:
		GlobalLoader.reload_scene()
