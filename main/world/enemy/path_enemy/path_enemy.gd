extends Enemy
class_name PathEnemy

func _ready() -> void:
	$Tween.connect("tween_completed", self, "tween_completed")
	unpause()

func tween_completed(_object: Object, _key: NodePath) -> void:
	unpause()

func body_entered(player: KinematicBody2D) -> void:
	.body_entered(player)
	pause()

func pause() -> void:
	$Tween.stop_all()

func unpause() -> void:
	$Tween.interpolate_property(get_parent(), "unit_offset", null, 1+get_parent().unit_offset, 5.0, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$Tween.start()
