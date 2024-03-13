extends Control


func _on_start_pressed():
	GlobalLoader.goto_next_scene()


func _on_quit_pressed():
	get_tree().quit()
