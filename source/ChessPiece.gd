extends Node2D

var color := "black"
var type := "pawn"
var texture := "black_pawn.png"
var board_position := Vector2(0, 0) # current postition on board (column, row)
var was_moved := false

func _ready():
	pass

# basic data update, piece_data should be from JSONData.piece_data["NAME_OF_A_PIECE"]
func updatePieceData(piece_data):
	color = piece_data.color
	type = piece_data.type
	texture = piece_data.texture

# simple texture update, preatty useless tbh, should include it in updatePieceData()
func updatePieceTexture():
	$piece_texture.texture = load("res://textures/"+texture)

# also a simple update
func updatePiecePosition(new_pos):
	board_position = new_pos

# calculates the ID of a current field based on position. Goood for quickly finding it
func getID():
	return int(board_position[0] + (board_position[1] * 8))

# replaces pawn with a proper queen upon getting to end of a board
func doPawnTransform():
	if type == "pawn" and board_position[1] in [0, 7]:
		updatePieceData(JSONData.piece_data["Queen_" + color])
		updatePieceTexture()

# returns the array of all the fields that could potentially be a viable move for a certain piece
func availableFields():
	var field_list := []
	var list_tmp := []
	
	match type:
		"pawn":
			if color == "white":
				field_list.append(board_position + Vector2(0,-1))
				if board_position[1] == 6:
					field_list.append(board_position + Vector2(0,-2))
				field_list.append(board_position + Vector2(-1, -1))
				field_list.append(board_position + Vector2(1, -1))
			else:
				field_list.append(board_position + Vector2(0,1))
				if board_position[1] == 1:
					field_list.append(board_position + Vector2(0,2))
				field_list.append(board_position + Vector2(-1, 1))
				field_list.append(board_position + Vector2(1, 1))
		"rook":
			for i in range(8):
				field_list.append(Vector2(board_position[0], i))
				field_list.append(Vector2(i, board_position[1]))
		"knight":
			field_list.append(board_position + Vector2(2, 1))
			field_list.append(board_position + Vector2(1, 2))
			field_list.append(board_position + Vector2(2, -1))
			field_list.append(board_position + Vector2(1, -2))
			field_list.append(board_position + Vector2(-2, 1))
			field_list.append(board_position + Vector2(-1, 2))
			field_list.append(board_position + Vector2(-2, -1))
			field_list.append(board_position + Vector2(-1, -2))
		"bishop":
			for i in range(8):
				field_list.append(board_position + Vector2(i, i))
				field_list.append(board_position + Vector2(-i, i))
				field_list.append(board_position + Vector2(i, -i))
				field_list.append(board_position + Vector2(-i, -i))
		"queen":
			for i in range(8):
				field_list.append(board_position + Vector2(i, i))
				field_list.append(board_position + Vector2(-i, i))
				field_list.append(board_position + Vector2(i, -i))
				field_list.append(board_position + Vector2(-i, -i))
				field_list.append(Vector2(board_position[0], i))
				field_list.append(Vector2(i, board_position[1]))
		"king":
			field_list.append(board_position + Vector2(0,1))
			field_list.append(board_position + Vector2(0,-1))
			field_list.append(board_position + Vector2(-1,0))
			field_list.append(board_position + Vector2(1,0))
			field_list.append(board_position + Vector2(1,1))
			field_list.append(board_position + Vector2(1,-1))
			field_list.append(board_position + Vector2(-1,1))
			field_list.append(board_position + Vector2(-1,-1))
		
	for field in field_list:
		if !(field[0] < 0 or  field[0] > 7 or field[1] < 0 or field[1] > 7): 
			list_tmp.append(field)
	
	field_list = list_tmp
	field_list.erase(board_position)
	
	return field_list
