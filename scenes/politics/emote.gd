@tool
class_name Emote
extends RefCounted
## Registry of every emote the player can use in an argument.
##
## There are two kinds of emotes:
## - Topics (Peace, Happy, Angry, ...): things a group has a belief about.
## - Judgements (Good, Bad): flip or keep the sign of the topics in an argument.
##
## To add a new emote: add it to `Id`, add its mesh to `_SCENES`, and if it is a
## judgement add its sign to `_JUDGEMENTS`.

enum Id { PEACE, HAPPY, ANGRY, GOOD, BAD }

const _SCENES := {
	Id.PEACE: preload("res://meshes/emotes/Emote_Peace.glb"),
	Id.HAPPY: preload("res://meshes/emotes/Emote_Happy.glb"),
	Id.ANGRY: preload("res://meshes/emotes/Emote_Angry.glb"),
	Id.GOOD: preload("res://meshes/emotes/Emote_Good.glb"),
	Id.BAD: preload("res://meshes/emotes/Emote_Bad.glb"),
}

## Judgement emotes and the sign they apply to an argument's topics.
const _JUDGEMENTS := {
	Id.GOOD: 1,
	Id.BAD: -1,
}


static func all() -> Array:
	return Id.values()


static func get_display_name(id: int) -> String:
	return String(Id.keys()[id]).capitalize()


static func is_judgement(id: int) -> bool:
	return _JUDGEMENTS.has(id)


## +1 / -1 for judgements, 0 for topics.
static func get_judgement_sign(id: int) -> int:
	return _JUDGEMENTS.get(id, 0)


static func instantiate(id: int) -> Node3D:
	var scene: PackedScene = _SCENES.get(id)
	return scene.instantiate() as Node3D if scene else Node3D.new()


## Pops an emote up above `parent` (e.g. over an NPC's head), holds it, then
## shrinks it away. Returns the holder node (already scheduled to free itself).
static func pop_above(parent: Node3D, id: int, height: float = 2.6, duration: float = 1.2, size: float = 0.7) -> Node3D:
	var holder := Node3D.new()
	holder.position = Vector3(0.0, height, 0.0)
	holder.scale = Vector3.ONE * 0.01
	holder.add_child(instantiate(id))
	parent.add_child(holder)

	var tween := holder.create_tween()
	tween.tween_property(holder, "scale", Vector3.ONE * size, 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(holder, "position:y", height + 0.35, duration + 0.25) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(holder, "scale", Vector3.ONE * 0.01, 0.15) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(holder.queue_free)
	return holder
