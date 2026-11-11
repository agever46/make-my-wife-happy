extends Node2D
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
	elif event.is_action_pressed("ui_accept") and GameManager.state == GameManager.GameState.GAME_OVER:
		GameManager.start_game()
