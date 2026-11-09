class_name DifficultyTables
extends RefCounted
## Per-level crowd / quota / timer / decoy / speed.

static func for_level(level: int) -> Dictionary:
	match level:
		1:
			return {"npc_count": 15, "quota": 4, "escape_s": 25.0, "decoy_pct": 0.20, "speed": 55.0}
		2:
			return {"npc_count": 25, "quota": 6, "escape_s": 20.0, "decoy_pct": 0.40, "speed": 60.5}
		_:
			var lvl := maxi(level, 3)
			var speed := 55.0 * pow(1.10, float(lvl - 1))
			return {
				"npc_count": clampi(40 + (lvl - 3) * 5, 40, 50),
				"quota": 8,
				"escape_s": 15.0,
				"decoy_pct": 0.60,
				"speed": speed,
			}