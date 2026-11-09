extends Node3D

const NPC_SCRIPT := preload("res://scripts/npc.gd")
## Spawns modular NPCs on the plaza, picks a target, builds decoys sharing 1–2 traits.

signal crowd_ready(target: CrowdNPC)
signal npc_clicked(npc: CrowdNPC)

var plaza: Rect2 = Rect2(-10.2, -10.2, 20.4, 20.4)
var rng := RandomNumberGenerator.new()
var target: CrowdNPC = null
var target_traits: Dictionary = {}
var npcs: Array[CrowdNPC] = []

func _ready() -> void:
	rng.randomize()

func clear_crowd() -> void:
	for n in npcs:
		if is_instance_valid(n):
			n.queue_free()
	npcs.clear()
	target = null
	target_traits.clear()

func spawn_level(cfg: Dictionary, p_plaza: Rect2) -> void:
	clear_crowd()
	plaza = p_plaza
	var count: int = int(cfg.get("npc_count", 15))
	var decoy_pct: float = float(cfg.get("decoy_pct", 0.2))
	var speed: float = float(cfg.get("speed", 55.0))

	target_traits = _roll_full_traits()
	var decoy_count := maxi(1, int(round(float(count - 1) * decoy_pct)))

	target = _make_npc(target_traits, false, true, speed)
	npcs.append(target)

	for i in decoy_count:
		var dtraits := _make_decoy_traits(target_traits)
		npcs.append(_make_npc(dtraits, true, false, speed))

	while npcs.size() < count:
		npcs.append(_make_npc(_roll_filler_traits(target_traits), false, false, speed))

	crowd_ready.emit(target)

func get_npc_at_point(world: Vector2, radius: float = 1.15) -> CrowdNPC:
	var best: CrowdNPC = null
	var best_d := radius * radius
	for n in npcs:
		if not is_instance_valid(n):
			continue
		var d := Vector2(n.position.x, n.position.z).distance_squared_to(world)
		if d <= best_d:
			best_d = d
			best = n
	return best

func scatter(except: CrowdNPC = null) -> void:
	for n in npcs:
		if is_instance_valid(n) and n != except:
			n.panic_t = 1.2
			n._pick_waypoint()

func remove_npc(n: CrowdNPC) -> void:
	npcs.erase(n)

func _make_npc(traits: Dictionary, decoy: bool, is_tgt: bool, speed: float) -> CrowdNPC:
	var n: CrowdNPC = NPC_SCRIPT.new() as CrowdNPC
	var clothing: Color = TraitCatalog.BODY_TINTS[rng.randi_range(0, TraitCatalog.BODY_TINTS.size() - 1)]
	add_child(n)
	n.setup(traits, clothing, plaza, speed, rng)
	n.is_decoy = decoy
	n.is_target = is_tgt
	n.clicked.connect(func(npc): npc_clicked.emit(npc))
	return n

func _roll_full_traits() -> Dictionary:
	return {
		TraitCatalog.Slot.HAT: TraitCatalog.random_trait_for_slot(TraitCatalog.Slot.HAT, rng),
		TraitCatalog.Slot.GLASSES: TraitCatalog.random_trait_for_slot(TraitCatalog.Slot.GLASSES, rng),
		TraitCatalog.Slot.HELD: TraitCatalog.random_trait_for_slot(TraitCatalog.Slot.HELD, rng),
	}

func _make_decoy_traits(base: Dictionary) -> Dictionary:
	var share_n := rng.randi_range(1, 2)
	var slots: Array = base.keys()
	slots.shuffle()
	var out := {}
	for i in slots.size():
		var slot = slots[i]
		if i < share_n:
			out[slot] = base[slot]
		else:
			out[slot] = TraitCatalog.random_trait_for_slot(int(slot), rng)
			if out[slot] == base[slot]:
				var alts := TraitCatalog.ids_for_slot(int(slot))
				for a in alts:
					if a != base[slot]:
						out[slot] = a
						break
	return out

func _roll_filler_traits(avoid: Dictionary) -> Dictionary:
	var out := _roll_full_traits()
	if out[TraitCatalog.Slot.HAT] == avoid[TraitCatalog.Slot.HAT] \
			and out[TraitCatalog.Slot.GLASSES] == avoid[TraitCatalog.Slot.GLASSES] \
			and out[TraitCatalog.Slot.HELD] == avoid[TraitCatalog.Slot.HELD]:
		out[TraitCatalog.Slot.HAT] = TraitCatalog.random_trait_for_slot(TraitCatalog.Slot.HAT, rng)
	return out
