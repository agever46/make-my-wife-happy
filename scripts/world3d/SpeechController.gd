class_name SpeechController
extends Node
## Every new quest is SAID by someone: a kid for its own requests, otherwise the wife on the couch.
## Listens to the quest logic and puts a SpeechBubble above the speaker's head.

const WIFE_BORDER := Color(0.78, 0.45, 0.85)
const KID_BORDER := {&"kid_a": Color(1.0, 0.6, 0.2), &"kid_b": Color(0.3, 0.75, 0.45)}


func _ready() -> void:
	QuestManager.quest_added.connect(_on_quest_added)


func _on_quest_added(quest: ActiveQuest) -> void:
	var speaker := _find_speaker(quest.data.kid)
	if speaker == null:
		return
	var icon: Texture2D = Item3D.ICONS.get(quest.data.icon_item)
	var border: Color = KID_BORDER.get(speaker.station_id, WIFE_BORDER)
	SpeechBubble.say(speaker, quest.data.title, icon, border, speaker.speech_anchor(), speaker.speech_side())
	_react(speaker)


func _find_speaker(kid_id: StringName) -> Station3D:
	var wife: Station3D = null
	for node in get_tree().get_nodes_in_group("stations"):
		var station := node as Station3D
		if station == null:
			continue
		if kid_id != &"" and station.station_id == kid_id and station.is_visible_in_tree():
			return station
		if station.station_id == &"wife":
			wife = station
	return wife


## A little hop of the speaker as it talks.
func _react(speaker: Station3D) -> void:
	var tw := speaker.create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	speaker.visual_root.scale = Vector3(0.94, 1.1, 0.94)
	tw.tween_property(speaker.visual_root, "scale", Vector3.ONE, 0.5)
