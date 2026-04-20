extends GridObjectComponent
class_name CInventory

var max_storage_per_entry:int = 10
var _storage:Dictionary[GameResource,int]


func has_room_for(newResource:GameResource)->bool:
	if (_storage.has(newResource)):
		return _storage[newResource] < max_storage_per_entry
	return true

func get_stored_qty(resource:GameResource)->int:
	if (_storage.has(resource)):
		return _storage[resource] 
	return 0

func deposit(newResource:GameResource,value:int):
	if (_storage.has(newResource)):
		_storage[newResource] = min(_storage[newResource]+value,max_storage_per_entry)
	else:
		_storage[newResource] = min(value,max_storage_per_entry)

func withdrawal(newResource:GameResource,value:int)->int:

	if (_storage.has(newResource)):
		var withdrawal_value = min(_storage[newResource],value)
		_storage[newResource] = max(_storage[newResource]-withdrawal_value,0)
		return withdrawal_value;

	return 0
