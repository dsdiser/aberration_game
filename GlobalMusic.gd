extends Node


func _ready():
	$MainTheme.play()

func _on_main_theme_finished():
	$MainTheme.play()
