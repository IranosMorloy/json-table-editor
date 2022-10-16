Hello!

- This is a JSON Table-like-Editor made in  Godot 3.3.2 stable.
- This editor is under the MIT license.
- Input JSON files HAVE to be in a dictionary format and each key has to have up to 16 attributes (to support more attributes, amend the res://DB/row.tscn to have more slots in the holder).
- Hints for usage:

To load a file:
	Put a JSON file inside res://data/ directory and write its name to the file path input on top of this screen.
	Hit 'Load' button in top-left corner

To save loaded data into a file:
	Check the file path for saving and hit 'Save' button in top-left corner

To edit data of a cell in a row in the loaded data:
	Click on a desired cell.
	Change the value of that cell in this text field to whatever you want.
	Hit 'Save' button on the right of this text field to put the change into the loaded data
	(IMPORTANT: This will not add the new entry into the file itself. Hit 'save' button on the top-left to save the new entry into the file)

To clear the value of a cell:
	Select the cell of a row you wish the clear.
	Hit 'clear' button on the right.
	This will change the value for the specific cell and row of the loaded data.

To add a new row into the loaded data:
	Write the new desired ID into this text field (nothing else but the ID itself).
	Hit 'New row' button on the right.
	New record will be created in the loaded data and the default empty values will correspond to the types of the first entry in the JSON file.

To add a new column (attribute for each ID) to the data:
	Write into this text field the arguments in format:		name:TYPE
	Recognised types are (everything has to be uppercase!!!):	 STR, INT, LIST, DICT, BOOL, FLOAT
	For example, with a new attr of bool with name 'this_is_bool', the text you enter (without spaces!!!) will be:
			this_is_bool:BOOL
	Hit 'New Colmn' button on the bottom right of this text field.'

To remove the ID from the loaded data:
	Select any cell on the row you wish to remove and hit 'Drop row' button on the right
