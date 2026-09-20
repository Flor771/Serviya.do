extends Node2D

@export var speed := 330.0
@export var power := 1.0
@export var accuracy := 1.0

func move_toward_target(target: Vector2, delta: float) -> void:
    position = position.move_toward(target, speed * delta)
