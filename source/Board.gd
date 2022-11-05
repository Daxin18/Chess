extends Node2D

const FieldClass = preload("res://source/field.gd") # semi-needed for click detection function
const FieldScene = preload("res://scenes/Field.tscn") # needed to make instances
const ChessPiece = preload("res://scenes/ChessPiece.tscn") # needed to fill the fields with pieces
# needed to determine the texture of a field with smart math instead of typing it myself
const FieldTextures = ["res://textures/black_field.png","res://textures/white_field.png"]
const sides = ["white", "black"]

export var highlights := [] # all the highlighted fields are stored there, for ease of un-highlighting them
onready var board_fields = $GridContainer # you can access all the fields by calling .get_children
# a table where index corresponds to id of a field, good if we want to reduce looping through all the fields
export var field_table := [] #array of all the fields on the board (by ID)
var holding_piece = null # piece being held at the moment
var turn = "white"

func _ready():
	generate_fields()
	highlights = [] # this fixes the issue with all enemy pieces being highlighted in the first move
					# that's some serious array and memory shit
	fill()
	for field in board_fields.get_children():
		field.connect("gui_input", self, "field_gui_input", [field])

# highlights all fields that can be visited by holding_piece
func highlight_fields():
	var highlight_data = fields_available_for_piece(holding_piece)
	for idx in highlight_data.keys():
		field_table[idx].highlight(highlight_data[idx])

# returns the dictionary of fields that the given piece can move to
# in a format of "field_id : highlight_type"
func fields_available_for_piece(piece):
	var dict : Dictionary = {}
	var available_fields = piece.availableFields()
	for field in board_fields.get_children():
		if available_fields.has(field.col_row):
			dict[field.id] = 0
		if field.col_row == piece.board_position:
			dict[field.id] = 1
	check_collisions(dict, piece)
	pawn_check(dict, piece)
	check_collision_followup(dict, piece)
	castling(dict, piece)
	return dict

# highlights fields for castling
func castling(dict : Dictionary, piece):
	if piece.type == "king" && !piece.was_moved:
		var rook_fields = get_fields_containing("rook", piece.color)
		var king_id = piece.getID()
		for i in rook_fields:
			var field = field_table[i]
			if !field.piece.was_moved && field.checkCastlingForObstructions(king_id):
				if king_id < field.id:
					dict[king_id + 2] = 3
				else:
					dict[king_id - 2] = 3

# returns the array containing id of all the fields that has the specified piece on them
func get_fields_containing(piece_type, piece_color):
	var result = []
	for field in field_table:
		if field.piece:
			if field.piece.type == piece_type && field.piece.color == piece_color:
				result.append(field.id)
	return result

# un-highlights all the fields in highlights, then clears the table
func off_highlights():
	for field in highlights:
		field.offHighlight()
	highlights = []

# un-highlights all the fields occupied by the same color pieces
# changes highlight to red for all the opposing pieces
func check_collisions(dict : Dictionary, piece):
	for idx in dict.keys():
		var field = field_table[idx]
		if field.piece != null:
			if field.piece.color != piece.color:
				dict[field.id] = 2
			else:
				dict.erase(idx)

# special function for pawns, cause their movement and attack patterns are different
# i hate pawns
# they are the only pieces that require separate logic for that
# damn, it's 2am and I decided it's perfect time to finally add some comments in the code
func pawn_check(dict : Dictionary, piece):
	var id = piece.getID()
	if piece.type == "pawn":
		if piece.color == "white":
			for idx in dict.keys():
				var field = field_table[idx]
				if (field.id == id-8 or field.id == id-16) and dict[idx] == 2:
					dict.erase(idx)
				elif (field.id == id-9 or field.id == id-7) and dict[idx] == 0:
					dict.erase(idx)
		else:
			for idx in dict.keys():
				var field = field_table[idx]
				if (field.id == id+8 or field.id == id+16) and dict[idx] == 2:
					dict.erase(idx)
				elif (field.id == id+9 or field.id == id+7) and dict[idx] == 0:
					dict.erase(idx)

# un-highlights the fields, that are blocked from current position by other pieces
func check_collision_followup(dict : Dictionary, piece):
	var starting_point = piece.board_position
	if piece.type != "knight":
		for idx in dict.keys():
			var field = field_table[idx]
			if !field.isConnectedTo(starting_point, dict):
				dict.erase(idx)

# generates all the fields giving them proper indexes, textures and connecting them to the board
func generate_fields(): 
	for i in range(64):
		var new_field = FieldScene.instance()
		var col_row = Vector2(i%8, (i/8)%8)
		new_field.setUp(col_row, FieldTextures[int(int(col_row[1])%2 == int(col_row[0])%2)], self)
		board_fields.add_child(new_field)
		field_table.append(new_field)

# fills the fields with all the necessary pieces
# that are definitely not handwritten in JSONData.piece_array
func fill():
	for field in board_fields.get_children():
		var piece_name = JSONData.piece_array[field.id]
		if piece_name != null:
			field.piece = ChessPiece.instance()
			field.piece.updatePieceData(JSONData.piece_data[piece_name])
			field.piece.updatePieceTexture()
			field.piece.updatePiecePosition(field.col_row)
			field.add_child(field.piece)

# changes the turn aka currently moving color of pieces
func next_turn():
	turn = sides[int(turn == "white")]
	# if true, it rerturns the element at index 1 (aka "black")
	# if false, ... at index 0 (aka "white")

# this is function connected to all the fields, it basically detects clicks
# and acts accordingly
func field_gui_input(event: InputEvent, field: FieldClass):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT && event.pressed:
			if holding_piece != null:
				if !field.piece: # Putting piece into field
					if field.highlight_type == 3: #highlight type for castle-available fields
						castle(field)
					elif field.highlighted: #piece placed into highlighted field
						place_piece(field)
					else:	#piece placed into illegal field
						snap_back()
				elif field.highlighted: # Swapping pieces
					kill_piece(field)
				else:	#piece placed into illegal field
					snap_back()
			elif field.piece:
				if field.piece.color == turn:
					pickup_piece(field)

# moves the king (holding_piece) to specified field and moves rook to the field next to it
# moves game to the next turn
func castle(field):
	#move rook
	if field.id > holding_piece.getID():
		for i in range(8):
			var curr_field = field_table[field.id + i + 1]
			if curr_field.piece:
				curr_field.movePieceTo(field.id - 1)
				break
	else:
		for i in range(8):
			var curr_field = field_table[field.id - (i + 1)]
			if curr_field.piece:
				curr_field.movePieceTo(field.id + 1)
				break
	#move king
	place_piece(field)

# deletes the piece from a specified field and places holding_piece in its place
# moves game to the next turn
func kill_piece(field):
	field.remove_child(field.piece)
	field.piece.queue_free()
	field.piece = null
	field.putIntoField(holding_piece)
	holding_piece.was_moved = true
	remove_child(holding_piece)
	holding_piece = null
	off_highlights()
	next_turn()

# snaps the piece back to its board_position
func snap_back():
	var s_field = field_table[holding_piece.getID()]
	s_field.putIntoField(holding_piece)
	holding_piece = null
	off_highlights()

# places the piece into specified field
# moves game to the next turn
func place_piece(field):
	field.putIntoField(holding_piece)
	if field.highlight_type != 1:
		holding_piece.was_moved = true
		next_turn()
	holding_piece = null
	off_highlights()

# picks up the piece from the specified field
func pickup_piece(field):
	holding_piece = field.piece
	field.pickFromField()
	holding_piece.global_position = get_global_mouse_position() - Vector2(8,8)
	highlight_fields()

# holding_piece actually follows a cursor, impressive
func _input(_event):
	if holding_piece:
		holding_piece.global_position = get_global_mouse_position() - Vector2(8,8)
