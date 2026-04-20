extends PanelContainer
class_name IdView



func configure(actor_data:ActorData):
	if (actor_data):
		%Image_ActorSprite.texture = actor_data.sprite
		%Label_Name.text = actor_data.actor_name

	
