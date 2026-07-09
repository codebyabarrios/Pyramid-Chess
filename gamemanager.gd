extends Node

var white_points: float = 100.0
var black_points: float = 100.0

func process_capture(tipe_piece: String, same_color: bool, rider_color: String):
	var current_points: float = white_points if rider_color == "white" else black_points
	
	match tipe_piece:
		"pawn":
			if not same_color: 
				current_points += 1
			else:
				current_points -= 1
		"horse":
			if not same_color:
				current_points *= 2
			else:
				current_points /= 2
		"bishop":
			if not same_color:
				current_points *= 3
			else:
				current_points /= 3
		"rook":
			if not same_color:
				current_points = pow(current_points, 2)
			else:
				current_points = sqrt(current_points)
		"queen":
			if not same_color:
				current_points = pow(current_points, 3)
			else:
				current_points = pow(current_points, 1.0 / 3.0)
	
	if rider_color == "white":
		white_points = current_points
	else:
		black_points = current_points
	
