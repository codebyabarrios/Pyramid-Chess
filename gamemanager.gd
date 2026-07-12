extends Node

var white_points: float = 10.0
var black_points: float = 10.0

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
	
	if current_points < 0:
		current_points = 0.0
	
	if rider_color == "white":
		white_points = current_points
	else:
		black_points = current_points
		
func format_points(points: float) -> String:
	if is_nan(points) or points < 0.0:
		return "0"
	if is_inf(points):
		return "MAX"

	if points < 1000.0:
		return str(int(points))

	var suffixes = ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"]
	var index_suffix = 0
	var reduced_value = points

	while reduced_value >= 1000.0 and index_suffix < suffixes.size() - 1:
		reduced_value /= 1000.0
		index_suffix += 1

	return "%.1f" % reduced_value + suffixes[index_suffix]
