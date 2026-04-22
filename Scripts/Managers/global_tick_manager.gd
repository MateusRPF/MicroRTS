extends Node
class_name TickManager

# Available tick rates in ascending order (slowest to fastest)

const DEFAULT_TICK_RATE: float = 0.1

var TICK_RATES: Array[float] = [
	DEFAULT_TICK_RATE * 1.5,  # Slowest
	DEFAULT_TICK_RATE * 1.2,  # Slow
	DEFAULT_TICK_RATE,   # Default
	DEFAULT_TICK_RATE * 0.7,   # Fast
	DEFAULT_TICK_RATE *0.5,   # Faster
]

signal TickSignal
signal tick_rate_changed(new_rate: float)

var tick_rate: float
var tick_timer: float = 0.0
var current_rate_index: int = 2  # Start at DEFAULT (index 2)
var is_paused: bool = false

func _ready() -> void:
	# Set initial tick rate from default index
	tick_rate = TICK_RATES[current_rate_index]
	DebugSettings.debug_print("Tick", "TickManager initialized with rate: %f" % tick_rate)

func _process(delta: float) -> void:

	if Input.is_action_just_pressed("pause"):
		DebugSettings.debug_print("Tick", "Pause input detected")
		toggle_pause()

	if is_paused:
		return
	tick_timer += delta
	if tick_timer >= tick_rate:
		tick_timer = 0.0
		TickSignal.emit()
		DebugSettings.debug_print("Tick", "Tick at time: %f" % Time.get_ticks_msec())

	# Handle input
	if Input.is_action_just_pressed("speed_up"):
		DebugSettings.debug_print("Tick", "Speed up input detected")
		increase_tick_rate()
	if Input.is_action_just_pressed("speed_down"):
		DebugSettings.debug_print("Tick", "Speed down input detected")
		decrease_tick_rate()


func toggle_pause():
	is_paused = !is_paused
	DebugSettings.debug_print("Tick", "Pause toggled. Now paused: %s" % is_paused)

func increase_tick_rate() -> void:
	if current_rate_index < TICK_RATES.size() - 1:
		current_rate_index += 1
		set_tick_rate(TICK_RATES[current_rate_index])

func decrease_tick_rate() -> void:
	if current_rate_index > 0:
		current_rate_index -= 1
		set_tick_rate(TICK_RATES[current_rate_index])

func set_tick_rate(new_rate: float) -> void:
	tick_rate = new_rate
	tick_rate_changed.emit(tick_rate)
	DebugSettings.debug_print("Tick", "Tick rate changed to: %f" % tick_rate)


