extends Node

export var piece_data: Dictionary
# for testing king movement block
export var piece_array := [
	null, "Knight_black", "Bishop_black", "Queen_black", "King_black", "Bishop_black","Knight_black", "Rook_black",
	null, null, null, null, null, null, null, null,
	null, null, null, null, null, null, null, null,
	null, null, null, null, "Pawn_black", null, null, null,
	null, null, null, null, null, null, null, null,
	null, null, null, null, null, null, null, null,
	null, null, null, null, null, null, null, null,
	"King_white", "King_white", "King_white", "King_white", "King_white", "King_white", "King_white", "King_white"
	]
#export var piece_array := [
#	"Rook_black", "Knight_black", "Bishop_black", "Queen_black", "King_black", "Bishop_black", "Knight_black", "Rook_black",
#	"Pawn_black", "Pawn_black", "Pawn_black", "Pawn_black", "Pawn_black", "Pawn_black", "Pawn_black", "Pawn_black",
#	null, null, null, null, null, null, null, null,
#	null, null, null, null, null, null, null, null,
#	null, null, null, null, null, null, null, null,
#	null, null, null, null, null, null, null, null,
#	"Pawn_white", "Pawn_white", "Pawn_white", "Pawn_white", "Pawn_white", "Pawn_white", "Pawn_white", "Pawn_white",
#	"Rook_white", "Knight_white", "Bishop_white", "Queen_white", "King_white", "Bishop_white", "Knight_white", "Rook_white"
#	]


func _ready():
	piece_data = LoadData("res://PieceData.json")

func LoadData(file_path):
	var json_data
	var file_data = File.new()
	
	file_data.open(file_path, File.READ)
	json_data = JSON.parse(file_data.get_as_text())
	file_data.close()
	return json_data.result
