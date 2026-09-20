extends Node2D

@export var plate_id := 0
var occupied := false

func set_occupied(value: bool) -> void:
    occupied = value
    queue_redraw()

func _draw() -> void:
    var points := PackedVector2Array([
        Vector2(-35,-22), Vector2(35,-22), Vector2(48,22), Vector2(-48,22)
    ])
    draw_colored_polygon(points, Color.WHITE)
    draw_polyline(points + PackedVector2Array([points[0]]), Color("#222222"), 4)
