extends Command
class_name Command_IssueWorkOrder

var issuer:CWorkOrderIssuer
var work_data:WorkOrderData


func finish_cache() -> void:
	issuer = owner_executor.owner_object.get_component(CWorkOrderIssuer)
	var originaL_data = data as CommandData_IssueWorkOrder
	work_data = originaL_data.order



func start_command() -> bool:
	print("Starting command - Work order Issuing")
	emit_signal("command_started", self)
	issuer.issue_work_order(work_data)


	finish_command()
	return true