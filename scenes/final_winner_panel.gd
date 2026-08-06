extends CanvasLayer

signal menu_requested

@onready var title_label = %TitleLabel
@onready var motif_label = %MotifLabel
@onready var time_record_label = $PanelContainer/VBoxContainer/TimeManagementLabel

@onready var points_j1_node = %"Points J1"
@onready var points_j2_node = %"Points J2"
@onready var rounds_j1_node = %"Rounds J1"
@onready var rounds_j2_node = %"Rounds J2"

@onready var menu_btn = %MenuButton

func _ready():
	hide()
	
	if is_instance_valid(menu_btn):
		menu_btn.text = "MAIN MENU"
		if not menu_btn.pressed.is_connected(_on_menu_pressed):
			menu_btn.pressed.connect(_on_menu_pressed)

func show_final_stats():
	if is_instance_valid(title_label):
		title_label.text  = "THE GRAND FINAL"
	
	var r1 = Gamemanager.rounds_won_p1
	var r2 = Gamemanager.rounds_won_p2
	var grand_winner = "PLAYER 1" if r1 > r2 else "PLAYER 2"
	
	if r1 == r2:
		if Gamemanager.total_points_p1 > Gamemanager.total_points_p2:
			grand_winner = "PLAYER 1"
		elif Gamemanager.total_points_p2 > Gamemanager.total_points_p1:
			grand_winner = "PLAYER 2"
		else:
			grand_winner = "PERFECT TIE"
	
	if is_instance_valid(motif_label):
		motif_label.text = "🏆 FINAL WINNER: %s 🏆\n(THREE ROUNDS COMPLETED)" % grand_winner
	
	if is_instance_valid(points_j1_node): points_j1_node.text = "P1 TOTAL: %s PTS" % Gamemanager.format_points(Gamemanager.total_points_p1)
	if is_instance_valid(points_j2_node): points_j2_node.text = "P2 TOTAL: %s PTS" % Gamemanager.format_points(Gamemanager.total_points_p2)
	if is_instance_valid(rounds_j1_node): rounds_j1_node.text = "P1 ROUNDS: %d" % r1
	if is_instance_valid(rounds_j2_node): rounds_j2_node.text = "P2 ROUNDS: %d" % r2
	
	if is_instance_valid(time_record_label):
		var t1 = Gamemanager.best_time_p1
		var t2 = Gamemanager.best_time_p2
		var speed_king = "PLAYER 1" if t1 > t2 else "PLAYER 2"
		var record_time = t1 if t1 > t2 else t2
		
		time_record_label.text = "⚡ SPEED RECORD: %s (%s)" % [speed_king, format_time(record_time)]
		
	show()
	animate_entry()

func format_time(seconds: float) -> String:
	var minutes := int(seconds) / 60
	var segs := int(seconds) % 60
	return "%02d:%02d" % [minutes, segs]

func animate_entry():
	var panel = $PanelContainer
	if is_instance_valid(panel):
		panel.scale = Vector2(0.6, 0.6)
		panel.pivot_offset = panel.size / 2
		var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.bind_node(self)
		tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.4)

func _on_menu_pressed():
	menu_requested.emit()
