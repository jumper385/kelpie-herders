class_name CapturePointHUD
extends Control

## Draws on-screen labels for the two capture zones.
## When a zone is visible in the viewport the label hovers near it.
## When it is off-screen the label floats at the screen edge with a
## directional arrow pointing toward the zone.

@export var camera: Camera3D
@export var farmer_zone: CaptureZone
@export var butcher_zone: CaptureZone

const EDGE_MARGIN := 52.0

var _farmer_label: Label
var _butcher_label: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_farmer_label  = _make_label("Barn",    Color(0.25, 0.85, 0.35))
	_butcher_label = _make_label("Butcher", Color(0.90, 0.25, 0.25))


func _make_label(text: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 16)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.65)
	style.corner_radius_top_left    = 5
	style.corner_radius_top_right   = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	style.content_margin_left   = 8
	style.content_margin_right  = 8
	style.content_margin_top    = 4
	style.content_margin_bottom = 4
	label.add_theme_stylebox_override("normal", style)

	add_child(label)
	return label


func _process(_delta: float) -> void:
	if camera == null:
		return
	if farmer_zone:
		_update_indicator(_farmer_label, farmer_zone.global_position, "Barn")
	if butcher_zone:
		_update_indicator(_butcher_label, butcher_zone.global_position, "Butcher")


func _update_indicator(label: Label, world_pos: Vector3, base_text: String) -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var screen_pos: Vector2    = camera.unproject_position(world_pos)

	# Determine if the world point is behind the camera.
	var cam_to_point: Vector3 = world_pos - camera.global_position
	var is_behind: bool = cam_to_point.dot(-camera.global_transform.basis.z) < 0.0

	var m := EDGE_MARGIN
	var on_screen: bool = (
		not is_behind
		and screen_pos.x > m
		and screen_pos.x < viewport_size.x - m
		and screen_pos.y > m
		and screen_pos.y < viewport_size.y - m
	)

	if on_screen:
		label.text = base_text
		# Force layout so label.size is current before positioning.
		label.reset_size()
		label.position = screen_pos - label.size * 0.5
	else:
		# Compute direction from screen centre toward the projected point,
		# reversing it when the point is behind the camera.
		var center: Vector2 = viewport_size * 0.5
		var raw_dir: Vector2 = screen_pos - center
		var direction: Vector2 = (-raw_dir if is_behind else raw_dir).normalized()
		if direction.length() < 0.001:
			direction = Vector2.UP

		var arrow: String = _direction_arrow(direction)
		label.text = "%s %s" % [arrow, base_text]
		label.reset_size()
		label.position = _clamp_to_edge(center, direction, viewport_size, m) - label.size * 0.5


func _direction_arrow(dir: Vector2) -> String:
	# Map direction to the nearest of 8 compass arrows.
	var angle := dir.angle()
	if angle < 0.0:
		angle += 2.0 * PI
	var sector := int(angle / (PI / 4.0) + 0.5) % 8
	const ARROWS: Array[String] = ["→", "↘", "↓", "↙", "←", "↖", "↑", "↗"]
	return ARROWS[sector]


func _clamp_to_edge(
	center: Vector2,
	direction: Vector2,
	viewport_size: Vector2,
	margin: float
) -> Vector2:
	# Scale direction vector until it reaches the margin-inset rectangle edge.
	var half := viewport_size * 0.5 - Vector2(margin, margin)
	var scale_x: float = half.x / max(abs(direction.x), 0.001)
	var scale_y: float = half.y / max(abs(direction.y), 0.001)
	return center + direction * min(scale_x, scale_y)
