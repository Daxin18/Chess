extends Node2D

const FieldClass = preload("res://source/field.gd") # semi-needed for click detection function
var FieldScene = preload("res://scenes/Field.tscn") # needed to make instances
var ChessPiece = preload("res://scenes/ChessPiece.tscn") # needed to fill the fields with pieces
# needed to determine the texture of a field with smart math instead of typing it myself
var FieldTextures = ["res://textures/black_field.png","res://textures/white_field.png"]
export var highlights = [] # all the highlighted fields are stored there, for ease of un-highlighting them
onready var board_fields = $GridContainer # you can access all the fields by calling .get_children
# a table where index corresponds to id of a field, good if we want to reduce looping through all the fields
export var field_table = []
var holding_piece = null # piece being held at the moment

func _ready():
	generate_fields()
	highlights = [] # this fixes the issue with all enemy pieces being highlighted in the first move
					# that's some serious array and memory shit
	fill()
	for field in board_fields.get_children():
		field.connect("gui_input", self, "field_gui_input", [field])

# highlights all fields that can be visited by holding_piece
func highlight_fields():
	var available_fields = holding_piece.availableFields()
	for field in board_fields.get_children():
		if available_fields.has(field.col_row):
			field.highlight(0)
		if field.col_row == holding_piece.board_position:
			field.highlight(1)
	check_collisions()
	pawn_check()
	check_collision_followup()

# un-highlights all the fields in highlights, then clears the table
func off_highlights():
	for field in highlights:
		field.offHighlight()
	highlights = []

# un-highlights all the fields occupied by the same color pieces
# changes highlight to red for all the opposing pieces
func check_collisions():
	for field in highlights:
		if field.piece != null:
			if field.piece.color != holding_piece.color:
				field.changeHighlightToAttack()
			else:
				field.offHighlight()

# special function for pawns, cause their movement and attack patterns are different
# i hate pawns
# they are the only pieces that require separate logic for that
# damn, it's 2am and I decided it's perfect time to finally add some comments in the code
func pawn_check():
	var id = holding_piece.getID()
	if holding_piece.type == "pawn":
		if holding_piece.color == "white":
			for field in highlights:
				if (field.id == id-8 or field.id == id-16) and field.highlight_type == 2:
					field.offHighlight()
				elif (field.id == id-9 or field.id == id-7) and field.highlight_type == 0:
					field.offHighlight()
		else:
			for field in highlights:
				if (field.id == id+8 or field.id == id+16) and field.highlight_type == 2:
					field.offHighlight()
				elif (field.id == id+9 or field.id == id+7) and field.highlight_type == 0:
					field.offHighlight()

# un-highlights the fields, that are blocked from current position by other pieces
func check_collision_followup():
	var starting_point = holding_piece.board_position
	if holding_piece.type != "knight":
		for field in highlights:
			if !field.isConnectedTo(starting_point):
				field.offHighlight()

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

# this is function connected to all the fields, it basically detects clicks
# and acts accordingly
func field_gui_input(event: InputEvent, field: FieldClass):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT && event.pressed:
			if holding_piece != null:
				if !field.piece: # Putting piece into field
					if field.highlighted: #piece placed into highlighted field
						place_piece(field)
					else:	#piece placed into illegal field
						snap_back()
				elif field.highlighted: # Swapping pieces
					kill_piece(field)
				else:	#piece placed into illegal field
					snap_back()
			elif field.piece:
				pickup_piece(field)

# deletes the piece from a specified field and places holding_piece in its place
func kill_piece(field):
	field.remove_child(field.piece)
	field.piece.queue_free()
	field.piece = null
	field.putIntoField(holding_piece)
	remove_child(holding_piece)
	holding_piece = null
	off_highlights()

# snaps the piece back to its board_position
func snap_back():
	var s_field = field_table[holding_piece.getID()]
	s_field.putIntoField(holding_piece)
	holding_piece = null
	off_highlights()

# places the piece into specified field
func place_piece(field):
	field.putIntoField(holding_piece)
	holding_piece = null
	off_highlights()

# picks up the piece from the specified field
func pickup_piece(field):
	holding_piece = field.piece
	field.pickFromField()
	holding_piece.global_position = get_global_mouse_position() - Vector2(8,8)
	highlight_fields()

# holding_piece actually follows a cursor, impressive
func _input(event):
	if holding_piece:
		holding_piece.global_position = get_global_mouse_position() - Vector2(8,8)
