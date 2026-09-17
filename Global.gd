extends Node

var total_players: int = 1
var selected_side: String = "white"

var difficulty: String = "medium"

var is_dark_mode_active: bool = false

var show_guide_arrows: bool = false

var current_set_name: String = "comun"

var piece_sets = {
	"comun": {
		"white_king": "res://scenes/king/White King.png",
		"black_king": "res://scenes/king/Black King.png",
		"white_queen": "res://scenes/queen/White Queen.png",
		"black_queen": "res://scenes/queen/Black Queen.png",
		"white_rook": "res://scenes/rook/White Rook.png",
		"black_rook": "res://scenes/rook/Black Rook.png",
		"white_bishop": "res://scenes/bishop/White Bishop.png",
		"black_bishop": "res://scenes/bishop/Black Bishop.png",
		"white_knight": "res://scenes/knight/White Knight.png",
		"black_knight": "res://scenes/knight/Black Knight.png",
		"white_pawn": "res://scenes/pawn/White Pawn.png",
		"black_pawn": "res://scenes/pawn/Black Pawn.png",
		"white_tile": "res://Game assets/tile_white.png",
		"black_tile": "res://Game assets/tile_black.png"
	},
	"beige": {
		"white_king": "res://scenes/king/White King Beige.png",
		"black_king": "res://scenes/king/Black King Beige.png",
		"white_queen": "res://scenes/queen/White Queen Beige.png",
		"black_queen": "res://scenes/queen/Black Queen Beige.png",
		"white_rook": "res://scenes/rook/White Rook Beige.png",
		"black_rook": "res://scenes/rook/Black Rook Beige.png",
		"white_bishop": "res://scenes/bishop/White Bishop Beige.png",
		"black_bishop": "res://scenes/bishop/Black Bishop Beige.png",
		"white_knight": "res://scenes/knight/White Knight Beige.png",
		"black_knight": "res://scenes/knight/Black Knight Beige.png",
		"white_pawn": "res://scenes/pawn/White Pawn Beige.png",
		"black_pawn": "res://scenes/pawn/Black Pawn Beige.png",
		"white_tile": "res://Game assets/tile_white_beige.png",
		"black_tile": "res://Game assets/tile_black_beige.png"
	},
	"warhol": {
		"white_king": "res://scenes/king/White King Warhol.png",
		"black_king": "res://scenes/king/Black King Warhol.png",
		"white_queen": "res://scenes/queen/White Queen Warhol.png",
		"black_queen": "res://scenes/queen/Black Queen Warhol.png",
		"white_rook": "res://scenes/rook/White Rook Warhol.png",
		"black_rook": "res://scenes/rook/Black Rook Warhol.png",
		"white_bishop": "res://scenes/bishop/White Bishop Warhol.png",
		"black_bishop": "res://scenes/bishop/Black Bishop Warhol.png",
		"white_knight": "res://scenes/knight/White Knight Warhol.png",
		"black_knight": "res://scenes/knight/Black Knight Warhol.png",
		"white_pawn": "res://scenes/pawn/White Pawn Warhol.png",
		"black_pawn": "res://scenes/pawn/Black Pawn Warhol.png",
		"white_tile": "res://Game assets/tile_white_warhol.png",
		"black_tile": "res://Game assets/tile_black_warhol.png"
	},
	"retro": {
		"white_king": "res://scenes/king/White King Retro.png",
		"black_king": "res://scenes/king/Black King Retro.png",
		"white_queen": "res://scenes/queen/White Queen Retro.png",
		"black_queen": "res://scenes/queen/Black Queen Retro.png",
		"white_rook": "res://scenes/rook/White Rook Retro.png",
		"black_rook": "res://scenes/rook/Black Rook Retro.png",
		"white_bishop": "res://scenes/bishop/White Bishop Retro.png",
		"black_bishop": "res://scenes/bishop/Black Bishop Retro.png",
		"white_knight": "res://scenes/knight/White Knight Retro.png",
		"black_knight": "res://scenes/knight/Black Knight Retro.png",
		"white_pawn": "res://scenes/pawn/White Pawn Retro.png",
		"black_pawn": "res://scenes/pawn/Black Pawn Retro.png",
		"white_tile": "res://Game assets/tile_white_retro.png",
		"black_tile": "res://Game assets/tile_black_retro.png"
	}
}
