extends CanvasLayer

@onready var restart_btn = %RestartButton
@onready var menu_btn = %MenuButton

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 120
	hide()
	
	if is_instance_valid(restart_btn):
		restart_btn.process_mode = Node.PROCESS_MODE_ALWAYS
		if not restart_btn.pressed.is_connected(_on_restart_pressed):
			restart_btn.pressed.connect(_on_restart_pressed)
	
	if is_instance_valid(menu_btn):
		menu_btn.process_mode = Node.PROCESS_MODE_ALWAYS
		if not menu_btn.pressed.is_connected(_on_menu_pressed):
			menu_btn.pressed.connect(_on_menu_pressed)
		menu_btn.text = "MAIN MENU"

func show_game_over(winner_text: String, reason: String, stats: Dictionary):
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 120
	
	if is_instance_valid(restart_btn):
		if stats.get("current_board", 1) >= 3:
			restart_btn.text = "SEE FINAL WINNER"
		else:
			restart_btn.text = "NEXT ROUND"
	
	var title_lbl = find_child("TitleLabel", true, false) as Label
	var motif_lbl = find_child("MotifLabel", true, false) as Label
	
	if title_lbl != null:
		title_lbl.text = "ROUND %d" % stats.get("current_board", 1)
	
	var p1_pts = stats.get("points_j1", 0.0)
	var p2_pts = stats.get("points_j2", 0.0)
	var t1 = stats.get("time_j1", 180.0)
	var t2 = stats.get("time_j2", 180.0)
	
	var faster = "PLAYER 1" if t1 > t2 else "PLAYER 2"
	var time_text = ""
	if int(t1) == int(t2):
		time_text = "TIME MANAGEMENT: PERFECT EQUALITY"
	else:
		time_text = "BETTER TIME MANAGEMENT: %s" % faster
	
	if motif_lbl != null:
		motif_lbl.text = "%s\n(%s)\n\n⚡ %s" % [winner_text, reason.to_upper(), time_text]

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
	
	visible = true
	show()
	var panel_container = find_child("PanelContainer", true, false)
	if is_instance_valid(panel_container):
		panel_container.visible = true
		panel_container.show()

func format_time(seconds: float) -> String:
	seconds = max(0, seconds)
	var minutes := int(seconds) / 60
	var segs := int(seconds) % 60
	return "%02d:%02d" % [minutes, segs]

func _on_restart_pressed():
	Gamemanager._on_next_round_pressed()

func _on_menu_pressed():
	Gamemanager._on_menu_button_pressed()
