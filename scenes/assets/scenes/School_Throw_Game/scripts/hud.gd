extends CanvasLayer

var prompt: Label
var message: Label
var timer: Timer

func _ready() -> void:
	add_to_group("hud")
	var objective := Label.new()
	objective.text = "Objective: Explore the school. Pick up objects with E. Throw with left click."
	objective.position = Vector2(12, 12)
	objective.add_theme_font_size_override("font_size", 16)
	add_child(objective)

	var crosshair := Label.new()
	crosshair.text = "+"
	crosshair.anchor_left = 0.5
	crosshair.anchor_top = 0.5
	crosshair.anchor_right = 0.5
	crosshair.anchor_bottom = 0.5
	crosshair.offset_left = -6
	crosshair.offset_top = -10
	crosshair.add_theme_font_size_override("font_size", 18)
	add_child(crosshair)

	prompt = Label.new()
	prompt.text = ""
	prompt.anchor_left = 0.5
	prompt.anchor_top = 0.85
	prompt.anchor_right = 0.5
	prompt.anchor_bottom = 0.85
	prompt.offset_left = -220
	prompt.offset_right = 220
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 18)
	add_child(prompt)

	message = Label.new()
	message.text = ""
	message.anchor_left = 0.5
	message.anchor_top = 0.75
	message.anchor_right = 0.5
	message.anchor_bottom = 0.75
	message.offset_left = -320
	message.offset_right = 320
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.add_theme_font_size_override("font_size", 20)
	add_child(message)

	timer = Timer.new()
	timer.one_shot = true
	timer.timeout.connect(func(): message.text = "")
	add_child(timer)

func show_prompt(text: String) -> void:
	prompt.text = text

func hide_prompt() -> void:
	prompt.text = ""

func show_message(text: String, seconds := 2.5) -> void:
	message.text = text
	timer.start(seconds)
