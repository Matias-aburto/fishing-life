extends MultiplayerSpawner
## El servidor spawnea un Player por peer con autoridad correcta.

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")

const SPAWN_POSITIONS: Array[Vector2] = [
	Vector2(560, 520),
	Vector2(640, 520),
	Vector2(480, 520),
	Vector2(560, 440),
]


func _spawn_custom(peer_id: int) -> Node:
	var player: GamePlayer = PLAYER_SCENE.instantiate()
	player.name = str(peer_id)
	player.global_position = SPAWN_POSITIONS[(peer_id - 1) % SPAWN_POSITIONS.size()]
	player.set_multiplayer_authority(peer_id)
	return player
