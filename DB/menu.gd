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
	for ch in [" ", "\n", "\t", "\\"]:
		new_value = new_value.replace(ch, "")
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
	else:
		show_err("No value to save!")

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
		else:
			show_err("Non-defined type of a column - cannot create new row")
			return
	header.row_data[new_id] = new_row_data
	var row = row_scene.instance()
	row.main_key = String(new_id)
	row.row_data = new_row_data
	row.columns = header.columns
	row.name = String(new_id)
	row.menu_node = self
	tablespace.add_child(row)
	show_ok_err("New row created Ok with ID: " + String(new_id))

func drop_row():
	if not edit_row:
		show_err("Select any cell in desired row first!")
		return
	if tablespace.has_node(edit_row):
		tablespace.get_node(edit_row).queue_free()
		header.file_data.erase(edit_row)
		show_ok_err("Row ID: " + edit_row + " dropped Ok.")
	else:
		show_err("Selected row ID not found, cannot drop!")

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
	if action == "close":
		get_tree().quit()
	elif action == "load" and get_file_path():
		load_file_from_path(get_file_path())
	elif action == "save":
		collect_row_data()
	elif action == "create":
		show_err("File Creation is Not implemented yet.")
		return
	else:
		show_err("File path is not valid.")

func get_file_path() -> String:
	return path_edit.text

func preview_cell_to_edit(row: String, cell: int, data: String):
	err_label.hide()
	change_edit.clear_undo_history()
	change_edit.text = data.replace("\\", "")
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
	var data = {}
	for row in tablespace.get_children():
		if row.name == "header": continue
		data[row.main_key] = row.get_data()
	save_data_to_file(get_file_path(), data)

func save_data_to_file(path: String, data: Dictionary):
	path = ProjectSettings.globalize_path(path)
	DataParser.write_data(path, data)

#----------------------------------------------------------------------------
# loading data

func load_file_from_path(path: String):
	err_label.hide()
	edit_cell = -1
	edit_row = ""
	var data = DataParser.load_data(path)
	if data:
		clear_cell_preview()
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
		if child.name == "header":
			continue
		# to avoid having new children with the same name as the old ones:
		child.name = child.name + "_exit"
		child.queue_free()
	
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
