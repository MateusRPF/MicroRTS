extends PanelContainer
class_name Widget_TickControl

@onready var slow_button: BasicButton = %Button_Slower
@onready var fast_button: BasicButton = %Button_Faster
@onready var pause_button: BasicButton = %Button_Pause
@onready var time_indicator: Label = %Label_TimeIndicator

func _ready() -> void:
	slow_button.on_pressed.connect(_on_SpeedDownButton_pressed)
	fast_button.on_pressed.connect(_on_SpeedUpButton_pressed)
	pause_button.on_pressed.connect(_on_PauseButton_pressed)
	self.self_modulate = Color(0, 0, 0,0)

func _process(_delta: float) -> void:
	var is_paused = GlobalTicker.is_paused

	var can_speed_up = !is_paused and GlobalTicker.current_rate_index < GlobalTicker.TICK_RATES.size() - 1
	var can_speed_down = !is_paused and GlobalTicker.current_rate_index > 0

	if not (can_speed_down):
		slow_button.disable_button()
	else:
		slow_button.enable_button()
	if not (can_speed_up):
		fast_button.disable_button()
	else:		
		fast_button.enable_button()

	var speed_indicator = GlobalTicker.current_rate_index - 2  # Center around 0 (default)
	time_indicator.text = "x%s" %[ 0 if is_paused else (speed_indicator+3)]

	if not GlobalTicker.is_paused:
		self.self_modulate = Color(0, 0, 0,0)  # invisible color when unpaused
	else:
		self.self_modulate = Color(1, 1, 1,1)  # Dimmed color when paused



func _on_SpeedUpButton_pressed() -> void:
	GlobalTicker.increase_tick_rate()

func _on_SpeedDownButton_pressed() -> void:
	GlobalTicker.decrease_tick_rate()

func _on_PauseButton_pressed() -> void:
	GlobalTicker.toggle_pause()
