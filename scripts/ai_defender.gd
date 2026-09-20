extends Node

@export var reaction_time := 0.45
@export var accuracy := 0.78

func choose_defensive_action(ball: Vector2, runner: Vector2, left_plate: Vector2, right_plate: Vector2) -> String:
    var target := left_plate if runner.distance_to(left_plate) < runner.distance_to(right_plate) else right_plate
    if ball.distance_to(target) < 180.0 and randf() < accuracy:
        return "THROW_TO_PLATE"
    return "CHASE_BALL"
