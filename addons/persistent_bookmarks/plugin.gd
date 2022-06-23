tool
extends EditorPlugin
# This plugin saves bookmarks into project metadata
# and loads bookmarks when a script is opened


const METADATA_SECTION = "persistent_bookmark"

var script_editor : ScriptEditor = get_editor_interface().get_script_editor()
var text_edit : TextEdit
var current_script_bookmarks = []


func _ready():
	get_viewport().connect("gui_focus_changed", self, "_on_gui_focus_changed")
	script_editor.connect("editor_script_changed", self, "_on_editor_script_changed")
	script_editor.connect("script_close", self, "_on_script_close")


func display_bookmarks():
	if text_edit and current_script_bookmarks:
		for bookmark_line in current_script_bookmarks:
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
	current_script_bookmarks = get_editor_interface().get_editor_settings().get_project_metadata(
			METADATA_SECTION,
			script.get_path(),
			[])
	display_bookmarks()


func save_script_bookmarks(script):
	var lines = get_bookmarked_lines()
	get_editor_interface().get_editor_settings().set_project_metadata(
			METADATA_SECTION,
			script.get_path(),
			lines)


# Callbacks
func _on_editor_script_changed(script) -> void:
	load_script_bookmarks(script)


func _on_script_close(script) -> void:
	save_script_bookmarks(script)


func _on_gui_focus_changed(node: Node):
	if node is TextEdit:
		text_edit = node
		text_edit.bookmark_gutter = true
