extends Node

signal game_started
signal game_over(score: int)
signal block_placed(score: int, is_perfect: bool)
signal score_changed(new_score: int)
signal new_high_score(score: int)
signal theme_changed(theme_name: String)
signal ad_requested(ad_type: String)
