class_name UIAppearance
extends Node
## Scene-local Theme adapter. Remaps shared semantic paint, not the world or
## card illustrations. Keeps canonical overrides so repeated switches are lossless.

const Style := preload("res://scripts/ui/ui_style.gd")
const Illustration := preload("res://scripts/ui/card_illustration.gd")
const Postcard := preload("res://scripts/ui/course_postcard.gd")
var mode: StringName = &"dark"
var _root: Node
var _records := {}
var _pending := {}
var _applying := false
var _light_theme: Theme
var _dark_theme: Theme

func setup(root: Node, theme: Theme) -> void:
	_root = root
	_dark_theme = theme
	_light_theme = theme.duplicate(true)
	for property: Dictionary in _light_theme.get_property_list():
		var value = _light_theme.get(property.name)
		if value is StyleBoxTexture:
			_light_theme.set(property.name, Style.frame_appearance(value, &"light"))
		elif value is StyleBoxFlat:
			_light_theme.set(property.name, _style(value, &"light"))
		elif value is Color:
			_light_theme.set(property.name, Style.appearance_color(value, &"foreground", &"light"))
		elif value is Texture2D and value.resource_path.begins_with("res://assets/ui/theme/"):
			_light_theme.set(property.name, _tint_theme_glyph(value, Style.PAPER_INK))
	get_tree().node_added.connect(_on_node_added)
	_watch_tree(root)

func apply_mode(value: StringName) -> void:
	mode = &"light" if value == &"light" else &"dark"
	_applying = true
	for id in _records.keys():
		var node: Control = _records[id].node.get_ref()
		if not node:
			_records.erase(id)
			continue
		_apply(node, _records[id])
	_applying = false

func _on_node_added(node: Node) -> void:
	if _root and _root.is_ancestor_of(node):
		_watch_added.call_deferred(node.get_instance_id())

func _watch_added(id: int) -> void:
	var node := instance_from_id(id)
	if is_instance_valid(node):
		_watch_tree(node)

func _watch_tree(node: Node) -> void:
	if not is_instance_valid(node) or node.is_queued_for_deletion():
		return
	var ancestor := node
	while ancestor and ancestor != _root:
		if ancestor is Illustration or ancestor is Postcard or (ancestor is UILogo and ancestor != node):
			return # Collectible/postcard art retains authored paint; logo owns its light ink.
		ancestor = ancestor.get_parent()
	if node is Control and not _records.has(node.get_instance_id()):
		var id := node.get_instance_id()
		_records[id] = {"node": weakref(node), "properties": {}}
		if not node.theme_changed.is_connected(_queue_refresh.bind(id)):
			node.theme_changed.connect(_queue_refresh.bind(id))
		if node is UIIcon and not node.palette_changed.is_connected(_queue_refresh.bind(id)):
			node.palette_changed.connect(_queue_refresh.bind(id))
		node.tree_exited.connect(_forget.bind(id), CONNECT_ONE_SHOT)
		_queue_refresh(id)
	for child in node.get_children():
		_watch_tree(child)

func _forget(id: int) -> void:
	_records.erase(id)
	_pending.erase(id)

func _queue_refresh(id: int) -> void:
	if _applying or _pending.has(id):
		return
	_pending[id] = true
	_refresh.call_deferred(id)

func _refresh(id: int) -> void:
	_pending.erase(id)
	if not _records.has(id):
		return
	var node: Control = _records[id].node.get_ref()
	if not node or node.is_queued_for_deletion():
		_records.erase(id)
		return
	_applying = true
	_apply(node, _records[id])
	_applying = false

func _apply(node: Control, record: Dictionary) -> void:
	var paint_mode: StringName = &"dark" if _keeps_authored_ink(node) else mode
	if node is UIBackdrop:
		node.appearance = mode
	if node is UILogo:
		node.apply_appearance(paint_mode)
	if node is UIIcon:
		node.apply_appearance(paint_mode)
	if node.theme == _dark_theme or node.theme == _light_theme:
		node.theme = _light_theme if mode == &"light" else _dark_theme
	for property: Dictionary in node.get_property_list():
		var key := String(property.name)
		var role: StringName = &"foreground"
		if key.begins_with("theme_override_styles/"):
			role = &"style"
		elif key.begins_with("theme_override_colors/"):
			role = &"shadow" if key.contains("shadow") else &"foreground"
		elif key == "theme_override_constants/outline_size":
			role = &"outline"
		else:
			continue
		var value = node.get(key)
		if not value is Color and not value is StyleBox and role != &"outline":
			continue
		var entry: Dictionary = record.properties.get(key, {})
		if entry.is_empty() or value != entry.applied:
			entry = {"original": value, "applied": value}
		var painted = entry.original
		if role == &"style":
			if entry.original is StyleBoxTexture:
				painted = Style.frame_appearance(entry.original, paint_mode)
			elif entry.original is StyleBoxFlat:
				painted = _style(entry.original, paint_mode)
		elif role == &"outline":
			painted = 0 if paint_mode == &"light" else entry.original
		else:
			painted = Style.appearance_color(entry.original, role, paint_mode)
		if value != painted:
			node.set(key, painted)
		entry.applied = painted
		record.properties[key] = entry


func _keeps_authored_ink(node: Node) -> bool:
	var ancestor := node
	while ancestor:
		if ancestor.get_meta(&"keep_ui_ink", false): return true
		if ancestor == _root: break
		ancestor = ancestor.get_parent()
	return false

func _style(source: StyleBoxFlat, appearance: StringName) -> StyleBoxFlat:
	if appearance == &"dark":
		return source
	var result := source.duplicate() as StyleBoxFlat
	result.bg_color = Style.appearance_color(source.bg_color, &"background", appearance)
	result.border_color = Style.appearance_color(source.border_color, &"border", appearance)
	result.shadow_color = Style.appearance_color(source.shadow_color, &"shadow", appearance)
	return result


func _tint_theme_glyph(source: Texture2D, ink: Color) -> Texture2D:
	# A few native Theme icons have no CanvasItem to modulate. Tint their shared
	# 16px masks once when constructing the light Theme, not per control/frame.
	var image := source.get_image().duplicate() as Image
	image.convert(Image.FORMAT_RGBA8)
	for y in image.get_height():
		for x in image.get_width():
			image.set_pixel(x, y, Color(ink, image.get_pixel(x, y).a))
	return ImageTexture.create_from_image(image)
