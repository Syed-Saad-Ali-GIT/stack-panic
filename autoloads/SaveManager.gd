extends Node

const SAVE_PATH := "user://save.cfg"

var high_score: int = 0
var tokens: int = 0
var unlocked_themes: Array[String] = ["Classic"]
var active_theme: String = "Classic"
var sfx_enabled: bool = true
var music_enabled: bool = true
var ghost_enabled: bool = true

func _ready() -> void:
	load_data()

func save_data() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("player", "high_score", high_score)
	cfg.set_value("player", "tokens", tokens)
	cfg.set_value("player", "unlocked_themes", unlocked_themes)
	cfg.set_value("player", "active_theme", active_theme)
	cfg.set_value("settings", "sfx", sfx_enabled)
	cfg.set_value("settings", "music", music_enabled)
	cfg.set_value("settings", "ghost", ghost_enabled)
	cfg.save(SAVE_PATH)

func load_data() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	high_score = cfg.get_value("player", "high_score", 0)
	tokens = cfg.get_value("player", "tokens", 0)
	unlocked_themes = cfg.get_value("player", "unlocked_themes", ["Classic"])
	active_theme = cfg.get_value("player", "active_theme", "Classic")
	sfx_enabled = cfg.get_value("settings", "sfx", true)
	music_enabled = cfg.get_value("settings", "music", true)
	ghost_enabled = cfg.get_value("settings", "ghost", true)

func add_tokens(amount: int) -> void:
	tokens += amount
	save_data()

func check_and_save_high_score(score: int) -> bool:
	if score > high_score:
		high_score = score
		save_data()
		return true
	return false
