extends Node

## Constants
const SAVE_FILE_PATH = "user://save_data.json"
const MAX_PLAYERS = 4
const DEBUG_MODE = true

# Constants for chunk system
const CHUNK_SIZE = 50.0  # Size of each chunk in world units
const RENDER_DISTANCE = 2  # How many chunks to render in each direction from player
const UNLOAD_DISTANCE = 3  # How far chunks need to be to get unloaded

## Enums
enum GameState {
	MENU,
	PLAYING,
	PAUSED,
	GAME_OVER
}

## Variables
var current_game_state: int = GameState.MENU
var player_score: int = 0
var high_score: int = 0

## Signals
signal game_state_changed(new_state)
signal score_updated(new_score)

## Lifecycle Methods
func _ready() -> void:
	load_high_score()

## Public Methods
func change_game_state(new_state: int) -> void:
	current_game_state = new_state
	game_state_changed.emit(new_state)

func update_score(points: int) -> void:
	player_score += points
	score_updated.emit(player_score)
	
	if player_score > high_score:
		high_score = player_score
		save_high_score()

## Private Methods
func load_high_score() -> void:
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file:
		var data = JSON.parse_string(file.get_as_text())
		if data and data.has("high_score"):
			high_score = data.high_score
		file.close()

func save_high_score() -> void:
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		var data = {"high_score": high_score}
		file.store_string(JSON.stringify(data))
		file.close() 