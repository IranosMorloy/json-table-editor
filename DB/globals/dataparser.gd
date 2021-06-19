extends Node


func load_data(url: String) -> Dictionary:
	var file = File.new()
	if not url or not file.file_exists(url):
		return {}
	file.open(url, File.READ)
	var data = parse_json(file.get_as_text())
	file.close()
	return data
	
func write_data(url: String, dict: Dictionary):
	if not url: return
	var file = File.new()
	file.open(url, File.WRITE)
	file.store_line(to_json(dict))
	file.close()
