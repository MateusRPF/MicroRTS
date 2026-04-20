extends ComponentData
class_name ComponentData_Attacker

func assemble_component(actor:GridObject) -> GridObjectComponent:
	var newAttacker = CAttacker.new()
	actor.add_child(newAttacker)
	newAttacker.initialize_component(actor)
	return newAttacker
