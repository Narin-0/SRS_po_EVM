extends Control


func _on_button_pressed() -> void:
	var error = get_tree().change_scene_to_file("res://Characterchoose/choosemenu_3.tscn")


func _on_button_6_pressed() -> void:
	var error = get_tree().change_scene_to_file("res://main_menu/mainmenu.tscn")
