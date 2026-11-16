class_name Argument
extends Resource
## A political statement built from emotes, e.g. [PEACE, GOOD] = "Peace is good".
##
## Scoring against a group: add up the group's belief in every topic emote, then
## multiply by the sign of every judgement emote (Good = +1, Bad = -1).
## "Peace is good" to a group with Peace +8 scores +8, "Peace is bad" scores -8.
## An argument without a judgement simply promotes its topics (+1).

const MAX_EMOTES := 3

@export var emotes: Array[int] = []


static func create(emote_ids: Array) -> Argument:
	var argument := Argument.new()
	for id in emote_ids:
		argument.emotes.append(int(id))
	return argument


## An argument needs at least one topic to be about something.
func is_valid() -> bool:
	return not get_topics().is_empty() and emotes.size() <= MAX_EMOTES


func get_topics() -> Array[int]:
	var topics: Array[int] = []
	for id in emotes:
		if not Emote.is_judgement(id):
			topics.append(id)
	return topics


func has_judgement() -> bool:
	for id in emotes:
		if Emote.is_judgement(id):
			return true
	return false


## +1 if the argument praises its topics, -1 if it condemns them.
func get_sign() -> int:
	var sign_value := 1
	for id in emotes:
		if Emote.is_judgement(id):
			sign_value *= Emote.get_judgement_sign(id)
	return sign_value


## Raw score (before the group's persuasion multiplier). `get_belief` is a
## Callable(emote_id: int) -> int returning the listener's belief in that topic.
func evaluate(get_belief: Callable) -> float:
	var total := 0.0
	for topic in get_topics():
		total += get_belief.call(topic)
	return total * get_sign()


func get_text() -> String:
	var topics := get_topics()
	if topics.is_empty():
		return "..."
	var names: PackedStringArray = []
	for topic in topics:
		names.append(Emote.get_display_name(topic))
	var subject := " & ".join(names)
	if not has_judgement():
		return "%s!" % subject
	var verb := "are" if topics.size() > 1 else "is"
	return "%s %s %s" % [subject, verb, "good" if get_sign() > 0 else "bad"]


func is_same_as(other: Argument) -> bool:
	return other != null and other.emotes == emotes
