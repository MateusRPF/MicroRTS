extends RefCounted
class_name TooltipConfiguration


var title:String
var description:String
var icon:Texture2D
var costs:Array[TooltipCost] = []


class TooltipCost:
	var cost_type:String
	var cost_amount:int
	var validate_on_wallet:bool = true
