extends Node

var sfx_error = "res://audio/error.mp3"
var sfx_piece_killed = "res://audio/pieces killed.mp3"
var sfx_jump = "res://audio/riders jump.mp3"
var sfx_round_finished = "res://audio/round finished.mp3"
var sfx_slash = "res://audio/sword slash.mp3"

var music_main_menu = "res://audio/Main Menu.mp3"
var music_training = "res://audio/training mode.mp3"
var music_final_round = "res://audio/final-round.mp3"
var music_game_over = "res://audio/game-over.mp3"
var music_countdown = preload("res://audio/Countdown.mp3") 

var music_easy = "res://audio/Easy music level final.mp3"
var music_medium = "res://audio/Medium music level final.mp3"
var music_hard = "res://audio/Hard music level final.mp3"

var music_player = AudioStreamPlayer.new()
var sfx_players: Array = []

func _ready():
	self.process_mode = Node.PROCESS_MODE_ALWAYS 
	music_player.bus = "Master"
	add_child(music_player)
	
	for i in range(8):
		var p = AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		sfx_players.append(p)

func play_music(music_stream):
	if music_stream == null: return
	
	var actual_stream = music_stream
	if music_stream is String:
		actual_stream = load(music_stream)
		
	if actual_stream == null:
		return
		
	if music_player.stream == actual_stream and music_player.playing: 
		return
		
	music_player.stream = actual_stream
	music_player.play()

func stop_music(): 
	music_player.stop()

func play_main_menu(): play_music(music_main_menu)
func play_training(): play_music(music_training)
func play_final_round(): play_music(music_final_round)
func play_game_over(): play_music(music_game_over)
func play_countdown(): play_music(music_countdown)
func play_easy(): play_music(music_easy)
func play_medium(): play_music(music_medium)
func play_hard(): play_music(music_hard)

func play_sfx(sfx_stream):
	if sfx_stream == null: return
	
	var actual_stream = sfx_stream
	if sfx_stream is String:
		actual_stream = load(sfx_stream)
		
	if actual_stream == null:
		return
		
	for p in sfx_players:
		if not p.playing:
			p.stream = actual_stream
			p.play()
			return
			
	sfx_players[0].stream = actual_stream
	sfx_players[0].play()

func play_error(): play_sfx(sfx_error)
func play_killed(): play_sfx(sfx_piece_killed)
func play_jump(): play_sfx(sfx_jump)
func play_slash(): play_sfx(sfx_slash)
func play_round_finish(): play_sfx(sfx_round_finished)
