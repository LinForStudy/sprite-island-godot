class_name BattleActionResult
extends RefCounted

## Immutable data structure describing a single battle action's calculated result.
## BattleManager creates this before presentation; BattlePresentation reads it to play animations.
## UI never modifies HP directly -- it reads this result for display only.

var attacker_side: String = ""
var defender_side: String = ""
var skill: SpiritSkill = null
var skill_display_name: String = ""

var damage: int = 0
var heal: int = 0
var multiplier: float = 1.0

var defender_hp_before: int = 0
var defender_hp_after: int = 0
var attacker_hp_before: int = 0
var attacker_hp_after: int = 0

var defender_defeated: bool = false
var is_heal: bool = false

var guard_gained: int = 0
var guard_consumed: bool = false
var new_energy: int = 0

var log_messages: Array[String] = []
