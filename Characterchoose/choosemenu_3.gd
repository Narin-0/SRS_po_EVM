extends Control


func _on_button_4_pressed() -> void:
	var error = get_tree().change_scene_to_file("res://Characterchoose/choosemenu_4.tscn") 


func _on_button_pressed() -> void:
	var error = get_tree().change_scene_to_file("res://Characterchoose/choosemenu_2.tscn") 
