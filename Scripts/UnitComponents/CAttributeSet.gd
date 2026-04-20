extends GridObjectComponent
class_name CAttributeSet

enum ATTR_ID
{
	ATTR_MOVE_SPEED,
	ATTR_HARVEST_POWER,
	ATTR_BUILD_POWER,
	ATTR_ATTACK_RANGE,
	ATTR_ATTACK_POWER,
	ATTR_ARMOR,
	ATTR_ATTACK_SPEED,
	ATTR_MAX_WOUNDS,
}

const ATTR_NAMES:Dictionary[ATTR_ID,String] = {
	ATTR_ID.ATTR_MOVE_SPEED:"Speed",
	ATTR_ID.ATTR_HARVEST_POWER:"Harvest",
	ATTR_ID.ATTR_BUILD_POWER:"Build",
	ATTR_ID.ATTR_ATTACK_RANGE:"Range",
	ATTR_ID.ATTR_ATTACK_POWER:"Attack",
	ATTR_ID.ATTR_ARMOR:"Defense",
	ATTR_ID.ATTR_ATTACK_SPEED:"Attack Speed",
	ATTR_ID.ATTR_MAX_WOUNDS:"Max. Wounds"
	}


var attr_map:Dictionary[ATTR_ID,AttributeInstance]


func configure_base_attrs(newAttrs:Dictionary[ATTR_ID,int]):
	attr_map.clear()
	for key in newAttrs:
		var instance = AttributeInstance.new()
		instance.base = newAttrs[key]
		instance.attr_ID = key
		attr_map[key] = instance


func get_attr(id:ATTR_ID):
	if not attr_map.has(id):
		return 0
	return attr_map[id].get_final_value()


func get_attr_instance(id:ATTR_ID)->AttributeInstance:
	return attr_map[id]


class AttributeInstance:

	var base:int
	var flat_bonus: int
	var mult_bonus: float
	var attr_ID:ATTR_ID

	func get_final_value()-> int:
		return roundi((base + flat_bonus) * (mult_bonus +1))

