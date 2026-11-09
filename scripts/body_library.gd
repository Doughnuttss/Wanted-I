class_name CrowdBodyLibrary
extends RefCounted
## Placeholder humanoids. Tripo reported 0 credits, so the meshes are block rigs.
## Blend: res://assets/raw/blender/character_gym.blend
## Glb: res://assets/generated/base_bodies.glb
##
## Armature_Neutral plays Walk_Neutral. Armature_Stocky plays Idle_Stocky.
## Each body also has the other action, plus Weight and Height shape keys.
## Attachment empties (swap a trait by replacing that slot's children):
## slot_hat, slot_glasses, slot_shirt, slot_pants, slot_held, slot_shoe_L, slot_shoe_R.

const BODY_PATH := "res://assets/generated/base_bodies.glb"

const SLOTS: PackedStringArray = [
	"slot_hat",
	"slot_glasses",
	"slot_shirt",
	"slot_pants",
	"slot_held",
	"slot_shoe_L",
	"slot_shoe_R",
]

static func instantiate() -> Node:
	var packed := load(BODY_PATH) as PackedScene
	if packed == null:
		return null
	return packed.instantiate()

static func find_slot(root: Node, slot_name: String) -> Node:
	for node in root.find_children("*", "", true, false):
		var node_name := String(node.name)
		if node_name == slot_name or node_name.ends_with("_" + slot_name):
			return node
	return null

static func apply_variation(root: Node, height: float, weight: float, tint: Color) -> void:
	var h := clampf(height, 0.0, 1.0)
	var w := clampf(weight, 0.0, 1.0)
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_node := node as MeshInstance3D
		if mesh_node.mesh == null:
			continue
		for i in mesh_node.mesh.get_blend_shape_count():
			var bname := String(mesh_node.mesh.get_blend_shape_name(i))
			if bname.ends_with("Weight"):
				mesh_node.set_blend_shape_value(i, w)
			elif bname.ends_with("Height"):
				mesh_node.set_blend_shape_value(i, h)
		if "Body_" in String(mesh_node.name):
			var mat := mesh_node.get_active_material(0)
			if mat is StandardMaterial3D:
				var copy := (mat as StandardMaterial3D).duplicate() as StandardMaterial3D
				copy.albedo_color = tint
				mesh_node.set_surface_override_material(0, copy)
