extends Node2D
## Alpha bootstrap scene: starts the game and prints GameManager signals for debugging.

func _ready() -> void:
	GameManager.happiness_changed.connect(func(n: float, _o: float) -> void: print("Wife-O-Meter: %.1f" % n))
	GameManager.game_over.connect(func(score: int) -> void: print("GAME OVER. Score: %d" % score))
	GameManager.start_game()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if GameManager.state == GameManager.GameState.PLAYING:
			GameManager.pause_game()
		elif GameManager.state == GameManager.GameState.PAUSED:
			GameManager.resume_game()
	elif event.is_action_pressed("ui_accept") and GameManager.state == GameManager.GameState.GAME_OVER:
		GameManager.start_game()
