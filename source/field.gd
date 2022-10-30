extends TextureRect

# holds all the values of highlights
var HighlightTextures = [preload("res://textures/available_marker.png"),
						preload("res://textures/current_marker.png"),
						preload("res://textures/attack_marker.png")]
var col_row = Vector2(0, 0) # fields posittion on the board (column, row)
var base_texture # basic texture that field goes back to after being un-highlighted
var piece = null # piece that is occupying the field
var highlighted = false # simple bool to check if field is highlighted (redundant, but shortens the code)
var highlight_type = 100 # determines the type of a highlight, based on indexes in HighlightTextures
var id = 0; # id of a field on the board (redundant, but its easier to access it directly rather than calculating it)
var board # board in wich the field exists
 
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

# checks weather given field is connected to the current field with highlights that are not red
func isConnectedTo(d_col_row):
	var result = true
	var curr_field = null
	# ---------------------- same column -----------------------------
	if col_row[0] == d_col_row[0]:
		var row_diff = col_row[1] - d_col_row[1]
		if row_diff < 0:
			for i in range(abs(row_diff)):
				curr_field = board.field_table[id + (8*(i+1))]
				if !curr_field.highlighted or curr_field.highlight_type == 2:
					result = false
					break
		else:
			for i in range(abs(row_diff)):
				curr_field = board.field_table[id - (8*(i+1))]
				if !curr_field.highlighted or curr_field.highlight_type == 2:
					result = false
					break
	# ---------------------- same row -----------------------------
	elif col_row[1] == d_col_row[1]:
		var col_diff = col_row[0] - d_col_row[0]
		if col_diff < 0:
			for i in range(abs(col_diff)):
				curr_field = board.field_table[id + (i+1)]
				if !curr_field.highlighted or curr_field.highlight_type == 2:
					result = false
					break
		else:
			for i in range(abs(col_diff)):
				curr_field = board.field_table[id - (i+1)]
				if !curr_field.highlighted or curr_field.highlight_type == 2:
					result = false
					break
	else:
		#------------------------ diagonal ---------------------------
		var diff = col_row[1] - d_col_row[1]
		
		if d_col_row[0] < col_row[0]: #left
			if d_col_row[1] < col_row[1]: #left-up
				for i in range(abs(diff)):
					curr_field = board.field_table[id - (9*(i+1))]
					if !curr_field.highlighted or curr_field.highlight_type == 2:
						result = false
						break
			else: #left-down
				for i in range(abs(diff)):
					curr_field = board.field_table[id + (7*(i+1))]
					if !curr_field.highlighted or curr_field.highlight_type == 2:
						result = false
						break
		else: #right
			if d_col_row[1] < col_row[1]: #right-up
				for i in range(abs(diff)):
					curr_field = board.field_table[id - (7*(i+1))]
					if !curr_field.highlighted or curr_field.highlight_type == 2:
						result = false
						break
			else: #right-down
				for i in range(abs(diff)):
					curr_field = board.field_table[id + (9*(i+1))]
					if !curr_field.highlighted or curr_field.highlight_type == 2:
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
