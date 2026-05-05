extends RefCounted
class_name TooltipConfiguration


var title:String
var hotkey:Key
var description:String
var costs:Array[TooltipCost] = []
var immediate_cost:TooltipCost
var required_tag:ActorTag
var requirements:Array[WorkOrderData.Requirement]

class TooltipCost:
	var cost_resource:GameResource
	var cost_amount:int
	var validate_on_wallet:bool = true
