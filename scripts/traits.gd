class_name TraitCatalog
extends RefCounted
## Extensible trait slots: Hat, Glasses, Held Item.

enum Slot { HAT, GLASSES, HELD }

const SLOT_NAMES := {
	Slot.HAT: "Hat",
	Slot.GLASSES: "Glasses",
	Slot.HELD: "Held",
}

## id -> { slot, color, label }
const DEFS := {
	"beanie_orange": {"slot": Slot.HAT, "color": Color(0.95, 0.45, 0.15), "label": "Orange Beanie"},
	"cap_red": {"slot": Slot.HAT, "color": Color(0.85, 0.15, 0.18), "label": "Red Cap"},
	"hat_brown": {"slot": Slot.HAT, "color": Color(0.45, 0.28, 0.15), "label": "Brown Hat"},
	"glasses_black": {"slot": Slot.GLASSES, "color": Color(0.08, 0.08, 0.1), "label": "Black Glasses"},
	"glasses_round": {"slot": Slot.GLASSES, "color": Color(0.35, 0.2, 0.1), "label": "Round Glasses"},
	"shades": {"slot": Slot.GLASSES, "color": Color(0.15, 0.15, 0.2), "label": "Shades"},
	"item_briefcase": {"slot": Slot.HELD, "color": Color(0.4, 0.28, 0.15), "label": "Briefcase"},
	"item_bag": {"slot": Slot.HELD, "color": Color(0.2, 0.45, 0.75), "label": "Blue Bag"},
	"item_flower": {"slot": Slot.HELD, "color": Color(0.9, 0.35, 0.55), "label": "Flower"},
}

const BODY_TINTS := [
	Color(0.25, 0.45, 0.85),
	Color(0.85, 0.35, 0.3),
	Color(0.3, 0.65, 0.4),
	Color(0.9, 0.75, 0.25),
	Color(0.55, 0.35, 0.7),
	Color(0.2, 0.2, 0.25),
	Color(0.95, 0.95, 0.95),
	Color(0.55, 0.35, 0.2),
]

static func ids_for_slot(slot: int) -> Array[String]:
	var out: Array[String] = []
	for id in DEFS.keys():
		if int(DEFS[id]["slot"]) == slot:
			out.append(String(id))
	return out

static func random_trait_for_slot(slot: int, rng: RandomNumberGenerator) -> String:
	var ids := ids_for_slot(slot)
	return ids[rng.randi_range(0, ids.size() - 1)]

static func color_of(id: String) -> Color:
	return DEFS[id]["color"]

static func label_of(id: String) -> String:
	return String(DEFS[id]["label"])

static func slot_of(id: String) -> int:
	return int(DEFS[id]["slot"])