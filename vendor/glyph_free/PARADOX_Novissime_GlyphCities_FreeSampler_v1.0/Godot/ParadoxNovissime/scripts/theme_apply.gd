@tool
extends Node3D
## Recolours every mesh under this node with one theme material (e.g. themes/M_Novissime_Gold.tres).
## Put it on a model (or a whole level section) and pick the material; works in the editor and in game.
@export var theme_material: Material:
	set(v):
		theme_material = v
		_apply()

func _ready() -> void:
	_apply()

func _apply() -> void:
	if not is_inside_tree():
		return
	for mi in find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).material_override = theme_material
