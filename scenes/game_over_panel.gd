extends CanvasLayer

signal restart_requested
signal menu_requested

@onready var title_label = %TitleLabel
@onready var motif_label = %MotifLabel
@onready var time_management_label = %TimeManagementLabel
@onready var points_j1 = %"Points J1"
@onready var points_j2 = %"Points J2"
@onready var time_j1 = %"Time J1"
@onready var time_j2 = %"Time J2" 

@onready var restart_btn = %RestartButton
@onready var menu_btn = %MenuButton

func _ready():
	hide()
	
	if is_instance_valid(restart_btn):
		restart_btn.pressed.connect(func(): restart_requested.emit())
		restart_btn.text = "NEXT ROUND"
	
	if is_instance_valid(menu_btn):
		menu_btn.pressed.connect(func(): menu_requested.emit())
		menu_btn.text = "MAIN MENU"

func show_game_over(winner_name: String, reason: String, stats: Dictionary):
	var title_label = find_child("TitleLabel", true, false) as Label
	var motif_label = find_child("MotifLabel", true, false) as Label
	
	if title_label != null:
		title_label.text = "ROUND %d" % stats.get("current_board", 1)
	
	var p1_pts = stats.get("points_j1", 0.0)
	var p2_pts = stats.get("points_j2", 0.0)
	var t1 = stats.get("time_j1", 180.0)
	var t2 = stats.get("time_j2", 180.0)
	
	var real_winner = "PLAYER 1" if p1_pts > p2_pts else "PLAYER 2"
	if p1_pts == p2_pts: real_winner = "DRAW (TIE)"
	
	var faster = "PLAYER 1" if t1 > t2 else "PLAYER 2"
	
	var time_text = ""
	if int(t1) == int(t2):
		time_text = "TIME MANAGEMENT: PERFECT EQUALITY"
	else:
		time_text = "BETTER TIME MANAGEMENT: %s" % faster
	
	if motif_label != null:
		motif_label.text = "WINNER: %s\n(%s)\n\n⚡ %s" % [real_winner, reason.to_upper(), time_text]
	

	var grid = find_child("GridContainer", true, false)
	if grid != null and grid.get_child_count() >= 4:
		var p1_label = grid.get_child(0) as Label
		var p2_label = grid.get_child(1) as Label
		var t1_label = grid.get_child(2) as Label
		var t2_label = grid.get_child(3) as Label
		
		if p1_label: p1_label.text = "P1 SCORE: %s PTS" % Gamemanager.format_points(p1_pts)
		if p2_label: p2_label.text = "P2 SCORE: %s PTS" % Gamemanager.format_points(p2_pts)
		if t1_label: t1_label.text = "P1 TIME: %s" % format_time(t1)
		if t2_label: t2_label.text = "P2 TIME: %s" % format_time(t2)
	
	var current_board_num = stats.get("current_board", 1)
	if is_instance_valid(restart_btn):
		if current_board_num >= 3:
			restart_btn.text = "SEE FINAL WINNER"
		else:
			restart_btn.text = "NEXT ROUND"
	
	show()
	animate_entry()

func format_time(seconds: float) -> String:
	var minutes := int(seconds) / 60
	var segs := int(seconds) % 60
	return "%02d:%02d" % [minutes, segs]

func animate_entry():
	var panel = find_child("PanelContainer", true, false)
	if is_instance_valid(panel):
		panel.scale = Vector2(0.6, 0.6)
		panel.pivot_offset = panel.size / 2
		
		var tween_panel = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween_panel.bind_node(self)
		tween_panel.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.4)
	
func _on_restart_pressed():
	restart_requested.emit()

func _on_menu_pressed():
	menu_requested.emit()
