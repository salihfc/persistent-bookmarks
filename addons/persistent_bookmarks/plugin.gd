tool
extends EditorPlugin
# This plugin saves bookmarks into project metadata
# and loads bookmarks when a script is opened


const METADATA_SECTION = "persistent_bookmark"

var script_editor : ScriptEditor = get_editor_interface().get_script_editor()
var text_edit : TextEdit

var already_open_scripts = {}

func _ready():
	get_viewport().connect("gui_focus_changed", self, "_on_gui_focus_changed")
	script_editor.connect("editor_script_changed", self, "_on_editor_script_changed")
	script_editor.connect("script_close", self, "_on_script_close")


func display_bookmarks(script_bookmarks):
	if text_edit and script_bookmarks:
		for bookmark_line in script_bookmarks:
			text_edit.set_line_as_bookmark(bookmark_line, true)


func get_bookmarked_lines() -> Array:
	# [Workaround]
	# Iterating over all lines in the script is inefficient.
	# But 'get_bookmarked_lines' function in cpp was not exposed to GDScript
	var bookmarks = []
	for line in text_edit.get_line_count():
		if text_edit.is_line_set_as_bookmark(line):
			bookmarks.append(line)
	return bookmarks


func load_script_bookmarks(script):
	if text_edit_and_script_match(script):
		var current_script_bookmarks = get_editor_interface().get_editor_settings().get_project_metadata(
				METADATA_SECTION,
				script.get_path(),
				[])

		display_bookmarks(current_script_bookmarks)


func save_script_bookmarks(script):
	var lines = get_bookmarked_lines()
	if script and lines and lines.size() and text_edit_and_script_match(script):
		get_editor_interface().get_editor_settings().set_project_metadata(
				METADATA_SECTION,
				script.get_path(),
				lines)


func text_edit_and_script_match(script) -> bool:
	return script.source_code and text_edit.text and  script.source_code.hash() == text_edit.text.hash()


# Callbacks
func _on_editor_script_changed(script) -> void:
	if script.get_path() in already_open_scripts:
		# No need to load bookmarks script is already open
		return

	load_script_bookmarks(script)
	already_open_scripts[script.get_path()] = true


func _on_script_close(script) -> void:
	if script and text_edit:
		save_script_bookmarks(script)
		already_open_scripts.erase(script.get_path())


func _on_gui_focus_changed(node: Node):
	if node is TextEdit:
		text_edit = node
		text_edit.bookmark_gutter = true
