extends CanvasLayer

var prompt_label: Label
var objective_label: Label
var message_panel: PanelContainer
var message_label: Label
var message_timer: Timer

func _ready() -> void:
	add_to_group("hud")
	_build_ui()
	set_objective("Objective: Explore the school. Find something to interact with.")
	hide_prompt()

func _build_ui() -> void:
	var crosshair := Label.new()
	crosshair.name = "Crosshair"
	crosshair.text = "+"
	crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crosshair.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	crosshair.add_theme_font_size_override("font_size", 24)
	crosshair.set_anchors_preset(Control.PRESET_CENTER)
	crosshair.position = Vector2(-8, -16)
	add_child(crosshair)

	prompt_label = Label.new()
	prompt_label.name = "InteractionPrompt"
	prompt_label.text = ""
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.add_theme_font_size_override("font_size", 22)
	prompt_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	prompt_label.position = Vector2(-250, -90)
	prompt_label.size = Vector2(500, 40)
	add_child(prompt_label)

	var objective_panel := PanelContainer.new()
	objective_panel.name = "ObjectivePanel"
	objective_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	objective_panel.position = Vector2(20, 20)
	objective_panel.size = Vector2(520, 64)
	add_child(objective_panel)

	objective_label = Label.new()
	objective_label.name = "ObjectiveLabel"
	objective_label.text = ""
	objective_label.add_theme_font_size_override("font_size", 18)
	objective_panel.add_child(objective_label)

	message_panel = PanelContainer.new()
	message_panel.name = "MessagePanel"
	message_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	message_panel.position = Vector2(-360, -170)
	message_panel.size = Vector2(720, 100)
	message_panel.visible = false
	add_child(message_panel)

	message_label = Label.new()
	message_label.name = "MessageLabel"
	message_label.text = ""
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.add_theme_font_size_override("font_size", 20)
	message_panel.add_child(message_label)

	message_timer = Timer.new()
	message_timer.name = "MessageTimer"
	message_timer.one_shot = true
	message_timer.timeout.connect(_on_message_timer_timeout)
	add_child(message_timer)

func show_prompt(text: String) -> void:
	prompt_label.text = "[E] " + text
	prompt_label.visible = true

func hide_prompt() -> void:
	prompt_label.visible = false

func show_message(text: String, seconds: float = 4.0) -> void:
	message_label.text = text
	message_panel.visible = true
	message_timer.start(seconds)

func set_objective(text: String) -> void:
	objective_label.text = text

func _on_message_timer_timeout() -> void:
	message_panel.visible = false
