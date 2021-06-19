extends Panel

var main_key: String
var row_data: Dictionary
var columns: Array
var is_header: bool = false
var file_data: Dictionary = {}
var menu_node: Node = null
onready var holder: Node = get_node("holder")

func _ready():
	get_node("id").text = main_key
	if not is_header:
		for index in range(0, columns.size()):
			var target = holder.get_node(str(index))
			target.text = to_json(row_data[columns[index]])
			target.hint_tooltip = (
				to_json(row_data[columns[index]])
			)
			target.show()
			target.connect(
				"pressed", self, "cell_selected", [index]
			)
	else:
		for index in range(0, columns.size()):
			var target = holder.get_node(str(index))
			target.text = String(columns[index])
			target.disabled = true
			target.show()
		for index in range(columns.size(), holder.get_child_count()):
			var target = holder.get_node(str(index))
			target.text = ""
			target.hide()
		yield(get_tree(), "idle_frame")
		get_parent().rect_size.x = holder.rect_size.x + 110
	
	rect_min_size = holder.rect_size + Vector2(104, 4)

func cell_selected(cell: int):
	if menu_node and weakref(menu_node).get_ref():
		menu_node.preview_cell_to_edit(
			name, cell, to_json(row_data[columns[cell]])
		)

func update_cell_value(cell: int, new_value: String, keys: Dictionary):
	var target = holder.get_node(str(cell))
	target.text = new_value
	target.hint_tooltip = new_value
	var converted_value = convert_value(new_value, keys[columns[cell]])
	if not converted_value == null:
		row_data[columns[cell]] = converted_value

func convert_value(value, type):
	if type == TYPE_STRING:
		return String(value)
	elif type == TYPE_INT:
		return int(value)
	elif type == TYPE_ARRAY:
		return Array(value)
	elif type == TYPE_DICTIONARY:
		return parse_json(value)
	elif type == TYPE_REAL:
		return float(value)
	else:
		if menu_node and weakref(menu_node).get_ref():
			menu_node.show_err("Value is of non-defined type")
		return null

func get_data() -> Dictionary:
	return row_data
