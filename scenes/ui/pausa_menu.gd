extends Control


func resume():
	get_tree().paused =false
	$AnimationPlayer.play_backwards("blur")

func pause():
	get_tree().paused = true
	$AnimationPlayer.play("blur")

func testEsc():
	if Input.is_action_just_pressed("esq") and !get_tree().paused:
		pause()
	elif Input.is_action_just_pressed("esq") and !get_tree().paused:
		resume()
		
func _on_jugar_pressed() -> void:
	resume()


func _on_opciones_pressed() -> void:
	get_tree().reload_current_scene()


func _on_salir_pressed() -> void:
	get_tree().quit()


func _process(delta):
	testEsc() 
