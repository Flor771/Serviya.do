extends Node2D

# PLATE RUSH MVP
# A compact, playable 2D prototype designed to run well on Android.

enum State { READY, PITCH, BALL_IN_PLAY, RUNNING, DEFENDING, RESULT }

var state: State = State.READY
var score_player := 0
var score_ai := 0
var outs_player := 0
var outs_ai := 0
var inning := 1
var player_at_left := true
var ball_pos := Vector2.ZERO
var ball_velocity := Vector2.ZERO
var ball_in_play := false
var runner_pos := Vector2.ZERO
var runner_speed := 330.0
var pitch_timer := 0.0
var hit_cooldown := 0.0
var result_text := ""
var rng := RandomNumberGenerator.new()

const LEFT_PLATE := Vector2(250, 430)
const RIGHT_PLATE := Vector2(1030, 430)
const PITCHER := Vector2(640, 190)
const BATTER := Vector2(250, 350)
const FIELD_RECT := Rect2(80, 100, 1120, 500)

func _ready() -> void:
    rng.randomize()
    queue_redraw()
    _start_play()

func _start_play() -> void:
    state = State.PITCH
    pitch_timer = 0.0
    hit_cooldown = 0.0
    ball_in_play = false
    ball_pos = PITCHER
    ball_velocity = Vector2.ZERO
    runner_pos = LEFT_PLATE
    result_text = ""
    queue_redraw()

func _process(delta: float) -> void:
    hit_cooldown = max(0.0, hit_cooldown - delta)

    if state == State.PITCH:
        pitch_timer += delta
        # Pitch travels toward batter automatically.
        ball_pos = PITCHER.lerp(BATTER, min(pitch_timer / 0.9, 1.0))
        if pitch_timer >= 0.9:
            _resolve_miss()

    elif state == State.BALL_IN_PLAY:
        ball_pos += ball_velocity * delta
        ball_velocity.y += 520.0 * delta
        if not FIELD_RECT.grow(80).has_point(ball_pos):
            _begin_run()

    elif state == State.RUNNING:
        _update_runner(delta)

    elif state == State.DEFENDING:
        _defend(delta)

    queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("bat"):
        _bat()
    elif event.is_action_pressed("run"):
        _run_command()
    elif event.is_action_pressed("return"):
        _return_command()
    elif event.is_action_pressed("throw_ball"):
        _throw()

    if event is InputEventScreenTouch and event.pressed:
        var p := event.position
        if Rect2(930, 585, 280, 100).has_point(p):
            _bat()
        elif Rect2(610, 585, 280, 100).has_point(p):
            _run_command()
        elif Rect2(290, 585, 280, 100).has_point(p):
            _return_command()

func _bat() -> void:
    if state != State.PITCH or hit_cooldown > 0.0:
        return

    hit_cooldown = 0.25
    var timing := abs(pitch_timer - 0.72)
    var quality := 1.0 - clamp(timing / 0.45, 0.0, 1.0)
    var power := lerp(520.0, 980.0, quality)
    var angle := deg_to_rad(rng.randf_range(-32.0, 32.0))

    ball_pos = BATTER
    ball_velocity = Vector2(cos(angle), sin(angle)) * power
    # Give the ball an upward arc.
    ball_velocity.y = -abs(ball_velocity.y) - 260.0
    state = State.BALL_IN_PLAY
    result_text = quality > 0.86 ? "PERFECT HIT!" : quality > 0.55 ? "GOOD HIT!" : "HIT!"

func _resolve_miss() -> void:
    outs_player += 1
    result_text = "MISS — OUT"
    _next_turn()

func _begin_run() -> void:
    state = State.RUNNING
    runner_pos = LEFT_PLATE if player_at_left else RIGHT_PLATE

func _update_runner(delta: float) -> void:
    var target := RIGHT_PLATE if player_at_left else LEFT_PLATE
    var direction := (target - runner_pos).normalized()
    runner_pos += direction * runner_speed * delta

    # Automatic defensive pressure: AI occasionally reaches the plate.
    if runner_pos.distance_to(target) < 28.0:
        if player_at_left:
            score_player += 1
        else:
            score_ai += 1
        result_text = "RUN SCORED!"
        _next_turn()

func _run_command() -> void:
    if state == State.RUNNING:
        runner_speed = 410.0

func _return_command() -> void:
    if state != State.RUNNING:
        return
    var target := LEFT_PLATE if player_at_left else RIGHT_PLATE
    runner_pos = runner_pos.move_toward(target, 120.0)
    runner_speed = 330.0

func _defend(delta: float) -> void:
    # Reserved for the expanded defensive phase.
    if ball_pos.distance_to(PITCHER) < 25.0:
        _next_turn()

func _throw() -> void:
    if state == State.BALL_IN_PLAY:
        state = State.DEFENDING
        result_text = "THROW!"

func _next_turn() -> void:
    if score_player >= 5 or score_ai >= 5 or outs_player >= 3 or outs_ai >= 3:
        _finish_match()
        return

    player_at_left = !player_at_left
    runner_speed = 330.0
    await get_tree().create_timer(0.8).timeout
    _start_play()

func _finish_match() -> void:
    state = State.RESULT
    if score_player > score_ai:
        result_text = "VICTORY!"
    elif score_player < score_ai:
        result_text = "DEFEAT"
    else:
        result_text = "DRAW"

func _draw() -> void:
    # Background / field
    draw_rect(Rect2(0, 0, 1280, 720), Color("#10151d"))
    draw_rect(FIELD_RECT, Color("#3b7d3c"))
    draw_arc(Vector2(640, 430), 390, PI, TAU, 64, Color("#76b852"), 4.0)

    # Street / barrio decoration
    draw_rect(Rect2(0, 0, 1280, 80), Color("#202832"))
    draw_string(ThemeDB.fallback_font, Vector2(40, 52), "PLATE RUSH", HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(940, 50), "THE DOMINICAN STREET GAME", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#d7e4ee"))

    # Scoreboard
    draw_rect(Rect2(430, 88, 420, 82), Color("#18202a"), true)
    draw_string(ThemeDB.fallback_font, Vector2(465, 120), "YOU", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(465, 154), str(score_player), HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color("#ffd166"))
    draw_string(ThemeDB.fallback_font, Vector2(690, 120), "AI", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(690, 154), str(score_ai), HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color("#ffd166"))
    draw_string(ThemeDB.fallback_font, Vector2(540, 154), "OUTS " + str(outs_player), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#ff8a8a"))

    # Plates
    _draw_plate(LEFT_PLATE)
    _draw_plate(RIGHT_PLATE)

    # Players
    draw_circle(BATTER, 28, Color("#e8c07d"))
    draw_rect(Rect2(BATTER + Vector2(-18, 28), Vector2(36, 52)), Color("#e63946"), true)
    draw_circle(PITCHER, 28, Color("#e8c07d"))
    draw_rect(Rect2(PITCHER + Vector2(-18, 28), Vector2(36, 52)), Color("#457b9d"), true)

    # Bat
    draw_line(BATTER + Vector2(15, 10), BATTER + Vector2(78, -28), Color("#c58b4e"), 12)

    # Ball
    draw_circle(ball_pos, 10, Color.WHITE)
    draw_circle(ball_pos + Vector2(3, -2), 3, Color("#d62828"))

    # Runner
    if state == State.RUNNING:
        draw_circle(runner_pos, 20, Color("#f1c27d"))
        draw_rect(Rect2(runner_pos + Vector2(-14, 20), Vector2(28, 35)), Color("#f4a261"), true)

    # Message
    if result_text != "":
        draw_string(ThemeDB.fallback_font, Vector2(470, 225), result_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color("#ffffff"))

    # Touch controls
    _button(Rect2(930, 585, 280, 100), "BAT")
    _button(Rect2(610, 585, 280, 100), "RUN")
    _button(Rect2(290, 585, 280, 100), "RETURN")

    if state == State.RESULT:
        draw_string(ThemeDB.fallback_font, Vector2(475, 350), "Tap BAT to start a new match", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#e0e0e0"))

func _draw_plate(pos: Vector2) -> void:
    var pts := PackedVector2Array([
        pos + Vector2(-35, -22),
        pos + Vector2(35, -22),
        pos + Vector2(48, 22),
        pos + Vector2(-48, 22)
    ])
    draw_colored_polygon(pts, Color("#f2f2f2"))
    draw_polyline(pts + PackedVector2Array([pts[0]]), Color("#222222"), 4)

func _button(rect: Rect2, label: String) -> void:
    draw_rect(rect, Color("#263445"), true)
    draw_rect(rect, Color("#ffffff"), false, 3)
    draw_string(ThemeDB.fallback_font, rect.position + Vector2(82, 62), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color.WHITE)
