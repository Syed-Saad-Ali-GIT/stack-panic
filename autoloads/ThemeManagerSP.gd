extends Node

const THEMES := {
	"Classic": {
		"stages": [
			{"name": "Calm",   "score_min": 0,   "bg_top": Color("#1a3a5c"), "bg_bot": Color("#0d2b45"), "block": Color("#4a90d9")},
			{"name": "Steady", "score_min": 11,  "bg_top": Color("#3b1f6b"), "bg_bot": Color("#261445"), "block": Color("#9b59b6")},
			{"name": "Rush",   "score_min": 26,  "bg_top": Color("#8b3a0f"), "bg_bot": Color("#5c2209"), "block": Color("#e67e22")},
			{"name": "Panic",  "score_min": 51,  "bg_top": Color("#7a0c0c"), "bg_bot": Color("#4a0505"), "block": Color("#e74c3c")},
			{"name": "Frenzy", "score_min": 100, "bg_top": Color("#1a1a1a"), "bg_bot": Color("#0d0d0d"), "block": Color("#ffffff")},
		]
	},
	"Neon Night": {
		"stages": [
			{"name": "Calm",   "score_min": 0,   "bg_top": Color("#0a0a1a"), "bg_bot": Color("#050510"), "block": Color("#00ffff")},
			{"name": "Steady", "score_min": 11,  "bg_top": Color("#0a0a1a"), "bg_bot": Color("#050510"), "block": Color("#ff00ff")},
			{"name": "Rush",   "score_min": 26,  "bg_top": Color("#0a0a1a"), "bg_bot": Color("#050510"), "block": Color("#ffff00")},
			{"name": "Panic",  "score_min": 51,  "bg_top": Color("#0a0a1a"), "bg_bot": Color("#050510"), "block": Color("#ff4500")},
			{"name": "Frenzy", "score_min": 100, "bg_top": Color("#0a0a1a"), "bg_bot": Color("#050510"), "block": Color("#ff69b4")},
		]
	},
	"Pastel Pop": {
		"stages": [
			{"name": "Calm",   "score_min": 0,   "bg_top": Color("#e8d5f5"), "bg_bot": Color("#d4b8e0"), "block": Color("#b39ddb")},
			{"name": "Steady", "score_min": 11,  "bg_top": Color("#fce4ec"), "bg_bot": Color("#f8bbd0"), "block": Color("#f48fb1")},
			{"name": "Rush",   "score_min": 26,  "bg_top": Color("#fff3e0"), "bg_bot": Color("#ffe0b2"), "block": Color("#ffcc80")},
			{"name": "Panic",  "score_min": 51,  "bg_top": Color("#fbe9e7"), "bg_bot": Color("#ffccbc"), "block": Color("#ff8a65")},
			{"name": "Frenzy", "score_min": 100, "bg_top": Color("#e8f5e9"), "bg_bot": Color("#c8e6c9"), "block": Color("#a5d6a7")},
		]
	},
}

static func get_stage(theme_name: String, score: int) -> Dictionary:
	var theme: Dictionary = THEMES.get(theme_name, THEMES["Classic"])
	var stages: Array = theme["stages"]
	var best: Dictionary = stages[0]

	for stage: Dictionary in stages:
		if score >= stage["score_min"]:
			best = stage

	return best

func get_block_color(theme_name: String, score: int) -> Color:
	if theme_name == "Classic" and score >= 100:
		var t := fmod(Time.get_ticks_msec() / 1000.0, 1.0)
		return Color.from_hsv(t, 0.8, 1.0)
	return get_stage(theme_name, score)["block"]

func get_all_theme_names() -> Array[String]:
	var names: Array[String] = []
	for k in THEMES.keys():
		names.append(k)
	return names
