extends Control

## Landscape touch controls. This layer never reads gameplay input directly; it only
## writes semantic touch intents into InputRouter.

@onready var joystick: PanelContainer = $Joystick
@onready var joystick_knob: PanelContainer = $Joystick/Knob
@onready var interact_button: Button = $InteractButton
@onready var confirm_button: Button = $ConfirmButton
@onready var back_button: Button = $BackButton
@onready var menu_button: Button = $MenuButton

var _touch_index: int = -1
var _mouse_dragging: bool = false
var _menu_open: bool = false
var _last_context_key: String = ""


func _ready() -> void:
	joystick.gui_input.connect(_on_joystick_gui_input)
	interact_button.pressed.connect(InputRouter.queue_touch_interact)
	confirm_button.pressed.connect(InputRouter.queue_touch_confirm)
	back_button.pressed.connect(InputRouter.queue_touch_cancel)
	menu_button.pressed.connect(InputRouter.queue_touch_menu)
	DisplayManager.profile_changed.connect(_apply_display_profile)
	_apply_display_profile(DisplayManager.get_active_profile())
	set_process(true)


func _exit_tree() -> void:
	InputRouter.set_touch_move(Vector2.ZERO)
	if DisplayManager.profile_changed.is_connected(_apply_display_profile):
		DisplayManager.profile_changed.disconnect(_apply_display_profile)


func _process(_delta: float) -> void:
	_refresh_context_visibility()


func set_menu_open(open: bool) -> void:
	_menu_open = open
	_refresh_context_visibility(true)


func _apply_display_profile(_profile: DeviceProfile) -> void:
	visible = DisplayManager.uses_virtual_controls()
	if not visible:
		InputRouter.set_touch_move(Vector2.ZERO)
		return
	var safe: Vector4i = DisplayManager.get_safe_margins()
	var scale_factor: float = clamp(DisplayManager.get_ui_scale(), 0.9, 1.15)
	var joystick_size: float = 116.0 * scale_factor
	joystick.offset_left = float(safe.x) + 18.0
	joystick.offset_top = -float(safe.w) - 18.0 - joystick_size
	joystick.offset_right = joystick.offset_left + joystick_size
	joystick.offset_bottom = -float(safe.w) - 18.0
	var action_size: float = 88.0 * scale_factor
	interact_button.offset_left = -float(safe.z) - 18.0 - action_size
	interact_button.offset_top = -float(safe.w) - 18.0 - action_size
	interact_button.offset_right = -float(safe.z) - 18.0
	interact_button.offset_bottom = -float(safe.w) - 18.0
	var small_width: float = 72.0 * scale_factor
	var small_height: float = 54.0 * scale_factor
	confirm_button.offset_left = interact_button.offset_left - 16.0 - small_width
	confirm_button.offset_top = -float(safe.w) - 18.0 - small_height
	confirm_button.offset_right = interact_button.offset_left - 16.0
	confirm_button.offset_bottom = -float(safe.w) - 18.0
	back_button.offset_left = confirm_button.offset_left - 10.0 - small_width
	back_button.offset_top = confirm_button.offset_top
	back_button.offset_right = confirm_button.offset_left - 10.0
	back_button.offset_bottom = confirm_button.offset_bottom
	menu_button.offset_left = -float(safe.z) - 266.0
	menu_button.offset_top = float(safe.y) + 10.0
	menu_button.offset_right = menu_button.offset_left + 64.0
	menu_button.offset_bottom = menu_button.offset_top + 54.0
	_reset_joystick_visual()
	_refresh_context_visibility(true)


func _refresh_context_visibility(force: bool = false) -> void:
	if not visible:
		return
	var dialogue_open: bool = bool(WorldState.dialogue_open)
	var panel_name: String = String(GameState.current_panel)
	var context_key: String = "%s|%s|%s" % [panel_name, dialogue_open, _menu_open]
	if not force and context_key == _last_context_key:
		return
	_last_context_key = context_key
	var exploration_active: bool = panel_name == "hud" and not dialogue_open and not _menu_open
	joystick.visible = exploration_active
	interact_button.visible = exploration_active
	confirm_button.visible = dialogue_open or panel_name != "hud" or _menu_open
	back_button.visible = dialogue_open or panel_name != "hud" or _menu_open
	menu_button.visible = panel_name == "hud" and not dialogue_open and not _menu_open
	if not exploration_active:
		InputRouter.set_touch_move(Vector2.ZERO)
		_reset_joystick_visual()


func _on_joystick_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index < 0:
			_touch_index = event.index
			_update_joystick(event.position)
		elif not event.pressed and event.index == _touch_index:
			_touch_index = -1
			InputRouter.set_touch_move(Vector2.ZERO)
			_reset_joystick_visual()
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_update_joystick(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_mouse_dragging = event.pressed
		if _mouse_dragging:
			_update_joystick(event.position)
		else:
			InputRouter.set_touch_move(Vector2.ZERO)
			_reset_joystick_visual()
	elif event is InputEventMouseMotion and _mouse_dragging:
		_update_joystick(event.position)


func _update_joystick(local_position: Vector2) -> void:
	var center: Vector2 = joystick.size * 0.5
	var radius: float = max(1.0, min(joystick.size.x, joystick.size.y) * 0.34)
	var delta: Vector2 = (local_position - center).limit_length(radius)
	InputRouter.set_touch_move(delta / radius)
	joystick_knob.position = center + delta - joystick_knob.size * 0.5


func _reset_joystick_visual() -> void:
	if not is_instance_valid(joystick_knob):
		return
	joystick_knob.position = joystick.size * 0.5 - joystick_knob.size * 0.5