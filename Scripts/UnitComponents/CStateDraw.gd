extends Sprite2D
class_name CStateDraw

var state_machine:CStateMachine

# Called when the node enters the scene tree for the first time.
func hook_to_actor(machine:CStateMachine) -> void:
	state_machine = machine
	self.position.y += -32


	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if state_machine:
		texture = CStateMachine.STATE_SPRITE[state_machine.current_state_id]
