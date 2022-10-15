extends Panel

onready var path_edit: Node = get_node("LineEdit")
onready var err_label: Node = get_node("error")
onready var tablespace: Node = get_parent().get_node("tablespace/scroll/grid")
onready var row_scene: PackedScene = preload("res://DB/row.tscn")
onready var change_edit: Node = get_parent().get_node("change/edit")
onready var header: Node = (
	get_parent().get_node("tablespace/scroll/grid/header")
)

var edit_row: String = ""
var edit_cell: int = -1

#----------------------------------------------------------------------------
# cell edit methods

func save_changed_cell():
	var new_value = change_edit.text
	for ch in ["\n", "\t", "\\"]: new_value = new_value.replace(ch, "")
	if (
		not new_value.empty()
		and edit_cell >= 0
		and edit_row
		and tablespace.has_node(edit_row)
	):
		tablespace.get_node(edit_row).update_cell_value(
			edit_cell, new_value, header.row_data
		)
		show_ok_err("New cell data edited Ok")
	else: show_err("No value to save!")

func clear_cell_data():
	change_edit.text = '""'
	save_changed_cell()

func new_row():
	var new_id = change_edit.text
	if new_id == "":
		show_err("Please put the new ID name into the text field below")
		return
	if new_id in header.file_data:
		show_err("Desired ID is already present in the file. Choose different.")
		return
	var new_row_data = {}
	for column in header.row_data:
		if header.row_data[column] == TYPE_STRING:
			new_row_data[column] = ""
		elif header.row_data[column] == TYPE_INT:
			new_row_data[column] = 0
		elif header.row_data[column] == TYPE_REAL:
			new_row_data[column] = 0.0
		elif header.row_data[column] == TYPE_ARRAY:
			new_row_data[column] = []
		elif header.row_data[column] == TYPE_DICTIONARY:
			new_row_data[column] = {}
		elif header.row_data[column] == TYPE_BOOL:
			new_row_data[column] = true
		else:
			print("failed to identify column: ", column)
			show_err("Non-defined type of a column - cannot create new row")
			return
	header.file_data[new_id] = new_row_data
	var row = row_scene.instance()
	row.main_key = String(new_id)
	row.row_data = new_row_data
	row.columns = header.columns
	row.name = String(new_id)
	row.menu_node = self
	tablespace.add_child(row)
	show_ok_err("New row created Ok with ID: " + String(new_id))

func drop_row():
	if not edit_row: show_err("Select any cell in desired row first!")
	elif tablespace.has_node(edit_row):
		tablespace.get_node(edit_row).queue_free()
		header.file_data.erase(edit_row)
		show_ok_err("Row ID: " + edit_row + " dropped Ok.")
	else: show_err("Selected row ID not found, cannot drop!")

func get_new_column_input():
	var new_col = change_edit.text.split(":")
	if new_col.size() == 2: add_new_column(new_col[0], new_col[1])

func add_new_column(clmn_name: String, clmn_type: String):
	var data: Dictionary = header.file_data
	var first = data.keys().front()
	var validation: bool = true
	for id in data[first]:
		if id == clmn_name:
			validation = false
			break
	if validation and clmn_type in ["STR", "INT", "LIST", "DICT", "FLOAT", "BOOL"]:
		var value
		if clmn_type == "STR": value = ""
		elif clmn_type == "INT": value = 0
		elif clmn_type == "LIST": value = []
		elif clmn_type == "DICT": value = {}
		elif clmn_type == "FLOAT": value = 0.0
		elif clmn_type == "BOOL": value = true
		for id in data: data[id][clmn_name] = value
		display_data(data)

#----------------------------------------------------------------------------
# base methods

func show_ok_err(text: String):
	err_label.self_modulate = Color.green
	err_label.text = text
	err_label.show()

func show_err(text: String):
	err_label.self_modulate = Color.red
	err_label.text = text
	err_label.show()

func perform_action(action: String):
	if action == "close": get_tree().quit()
	elif action == "load" and get_file_path(): load_file_from_path(get_file_path())
	elif action == "save": collect_row_data()
	elif action == "create": show_err("File Creation is Not implemented yet.")
	else: show_err("File path is not valid.")

func get_file_path() -> String: return path_edit.text
func preview_cell_to_edit(row: String, cell: int, data: String):
	err_label.hide()
	change_edit.clear_undo_history()
	change_edit.text = data.replace("\\", "")
	change_edit.grab_focus()
	show_ok_err(
		"Now editing row ID: " + row + ", column: " + header.columns[cell]
	)
	edit_cell = cell
	edit_row = row

func clear_cell_preview():
	change_edit.clear_undo_history()
	change_edit.text = ""
	edit_cell = -1
	edit_row = ""

#----------------------------------------------------------------------------
# saving data

func collect_row_data():
	var data = "{"
	var list = get_sorted_child_names()
	for id in list:
		var row = tablespace.get_node(id)
		data += '"{id}":{data}'.format({
			'id': row.main_key, 'data': row.get_data()
		})
		if not id == list.back(): data += ","
	data += "}"
	save_data_to_file(get_file_path(), data)

func get_sorted_child_names():
	var names_list = []
	var children = tablespace.get_children()
	children.erase(tablespace.get_node("header"))
	if children[0].main_key.is_valid_integer():
		var int_list = []
		for child in children: int_list.append(int(child.main_key))
		int_list.sort()
		for id in int_list: names_list.append(String(id))
	else:
		for child in children: names_list.append(child.main_key)
	return names_list
	

func save_data_to_file(path: String, data: String):
	path = ProjectSettings.globalize_path(path)
	DataParser.write_data(path, data)
	show_ok_err("File saved Ok to path: " + path)

#----------------------------------------------------------------------------
# loading data

func load_file_from_path(path: String):
	err_label.hide()
	edit_cell = -1
	edit_row = ""
	var data = DataParser.load_data(path)
	if data:
		clear_cell_preview()
		show_ok_err("File loaded Ok from path: " + path)
		display_data(data)
	else:
		show_err("File not found or data are unreadable.")

func display_data(data: Dictionary):
	# get all columns and their value type based on the first ID data
	# (check GlobalScope for more info)
	var columns = {}
	var first_id = data.keys().front()
	for key in data[first_id]:
		columns[key] = typeof(data[first_id][key])
	
	# sort columns so all data are displayed in ordered fashion
	var ordered_columns = columns.keys()
	ordered_columns.sort()
	
	# get rid of any old data
	for child in tablespace.get_children():
		if child.name == "header": # ensure the header stays in the table
			continue
		# to avoid having new children with the same name as the old ones:
		child.name = child.name + "_exit"
		child.queue_free()
	
	# reset scrolls, to see everything from the beginning
	var scroll = tablespace.get_parent()
	scroll.scroll_horizontal = 0
	scroll.scroll_vertical = 0
	
	# now set the header with column names and populate data holders
	header.main_key = "ID:"
	header.columns = ordered_columns
	header.row_data = columns
	header.is_header = true
	header.file_data = data
	header._ready()
	
	for id in data:
		var row = row_scene.instance()
		row.main_key = String(id)
		row.row_data = data[id]
		row.columns = ordered_columns
		row.name = String(id)
		row.menu_node = self
		tablespace.add_child(row)
