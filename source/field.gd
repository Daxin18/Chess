extends TextureRect

# holds all the values of highlights
const HighlightTextures = [preload("res://textures/available_marker.png"),
						preload("res://textures/current_marker.png"),
						preload("res://textures/attack_marker.png"),
						preload("res://textures/castle_marker.png")]
var col_row := Vector2(0, 0) # fields posittion on the board (column, row)
var base_texture # basic texture that field goes back to after being un-highlighted
var piece = null # piece that is occupying the field
var highlighted := false # simple bool to check if field is highlighted (redundant, but shortens the code)
var highlight_type := 100 # determines the type of a highlight, based on indexes in HighlightTextures
var id := 0; # id of a field on the board (redundant, but its easier to access it directly rather than calculating it)
var board # board in which the field exists
 
func _ready():
	highlighted = false
	highlight_type = 100

# sets up the field by passing it all the needed info
func setUp(given_col_row, directory, s_board):
	col_row = given_col_row
	base_texture = load(directory)
	texture = base_texture
	board = s_board
	id = col_row[0] + (col_row[1] * 8)

# highlights the field of a given index
func highlight(idx):
	highlighted = true
	board.highlights.append(self)
	texture = HighlightTextures[idx]
	highlight_type = idx

# makes the highlight red
func changeHighlightToAttack():
	highlighted = true
	texture = HighlightTextures[2]
	highlight_type = 2

# makes the fild not highlighted
func offHighlight():
	highlighted = false
	texture = base_texture
	highlight_type = 100

# checks wheather there are no pieces between king and rook while castling
# only use in castling function in board script
func checkCastlingForObstructions(f_id):
	if f_id < id:
		for i in range(id - (f_id + 1)):
			if board.field_table[id - (i + 1)].piece:
				return false
	else:
		for i in range(f_id - (id + 1)):
			if board.field_table[id + (i + 1)].piece:
				return false
	return true

# function that moves piece from field to field skipping the board part aka
# adding and removing it as its child in order for it to follow the cursor
# only used in automatic movement (such as castling)
func movePieceTo(f_id):
	#placing into new field
	var destination = board.field_table[f_id]
	destination.piece = piece
	destination.piece.updatePiecePosition(destination.col_row)
	destination.piece.position = Vector2(0, 0)
	remove_child(piece) # a node cant be a child of 2 nodes at once
						# that caused the bug with rook being invisible
	destination.add_child(piece)
	#removing from old field
	piece.was_moved = true
	piece = null

# checks weather given field is connected to the current field with highlights that are not red
# after the rework it is based on highlight data provided by the given dictionary
func isConnectedTo(d_col_row, dict: Dictionary):
	var result = true
	var curr_field = null
	# ---------------------- same column -----------------------------
	if col_row[0] == d_col_row[0]:
		var row_diff = col_row[1] - d_col_row[1]
		if row_diff < 0: # going down on the board
			for i in range(abs(row_diff)):
				curr_field = id + (8*(i+1))
				if !dict.keys().has(curr_field) or dict[curr_field] == 2:
					result = false
					break
		else:	# going up on the board
			for i in range(abs(row_diff)):
				curr_field = id - (8*(i+1))
				if !dict.keys().has(curr_field) or dict[curr_field] == 2:
					result = false
					break
	# ---------------------- same row -----------------------------
	elif col_row[1] == d_col_row[1]:
		var col_diff = col_row[0] - d_col_row[0]
		if col_diff < 0: # going right on the board
			for i in range(abs(col_diff)):
				curr_field = id + (i+1)
				if !dict.keys().has(curr_field) or dict[curr_field] == 2:
					result = false
					break
		else: # going left on the board
			for i in range(abs(col_diff)):
				curr_field = id - (i+1)
				if !dict.keys().has(curr_field) or dict[curr_field] == 2:
					result = false
					break
	else:
		#------------------------ diagonal ---------------------------
		var diff = col_row[1] - d_col_row[1]
		
		if d_col_row[0] < col_row[0]: #left
			if d_col_row[1] < col_row[1]: #left-up
				for i in range(abs(diff)):
					curr_field = id - (9*(i+1))
					if !dict.keys().has(curr_field) or dict[curr_field] == 2:
						result = false
						break
			else: #left-down
				for i in range(abs(diff)):
					curr_field = id + (7*(i+1))
					if !dict.keys().has(curr_field) or dict[curr_field] == 2:
						result = false
						break
		else: #right
			if d_col_row[1] < col_row[1]: #right-up
				for i in range(abs(diff)):
					curr_field = id - (7*(i+1))
					if !dict.keys().has(curr_field) or dict[curr_field] == 2:
						result = false
						break
			else: #right-down
				for i in range(abs(diff)):
					curr_field = id + (9*(i+1))
					if !dict.keys().has(curr_field) or dict[curr_field] == 2:
						result = false
						break
	return result

# picks up a piece from field
func pickFromField():
	remove_child(piece)
	board.add_child(piece)
	piece = null

# puts piece into field
func putIntoField(new_piece):
	piece = new_piece
	piece.updatePiecePosition(col_row)
	piece.position = Vector2(0, 0)
	board.remove_child(piece)
	piece.doPawnTransform()
	add_child(piece)
