extends Node3D
## Day 1 scene: starts the game and handles pause / restart keys.

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # so Esc can un-pause
	GameManager.start_game()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if GameManager.state == GameManager.GameState.PLAYING:
			GameManager.pause_game()
		elif GameManager.state == GameManager.GameState.PAUSED:
			GameManager.resume_game()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT \
			and (GameManager.state == GameManager.GameState.GAME_OVER or GameManager.state == GameManager.GameState.VICTORY):
		GameManager.start_game() # click anywhere on the result screen
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT \
			and GameManager.state == GameManager.GameState.PAUSED and not DebugConsole.is_open():
		GameManager.resume_game()
	elif event.is_action_pressed("ui_accept") and (GameManager.state == GameManager.GameState.GAME_OVER or GameManager.state == GameManager.GameState.VICTORY):
		GameManager.start_game()
