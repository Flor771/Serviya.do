extends Node2D

var velocity := Vector2.ZERO
var gravity := 520.0

func launch(direction: Vector2, power: float) -> void:
    velocity = direction.normalized() * power

func _physics_process(delta: float) -> void:
    position += velocity * delta
    velocity.y += gravity * delta
