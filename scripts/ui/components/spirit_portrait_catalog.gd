class_name SpiritPortraitCatalog

const PATHS: Dictionary = {
	"leafbun": "res://assets/ui/portraits/leafbun.png",
	"sproutdeer": "res://assets/ui/portraits/sproutdeer.png",
	"vinerabbit": "res://assets/ui/portraits/vinerabbit.png",
	"bloomwhale": "res://assets/ui/portraits/bloomwhale.png",
	"bubblepup": "res://assets/ui/portraits/bubblepup.png",
	"moonfish": "res://assets/ui/portraits/moonfish.png",
	"rainseal": "res://assets/ui/portraits/rainseal.png",
	"starjelly": "res://assets/ui/portraits/starjelly.png",
	"emberfox": "res://assets/ui/portraits/emberfox.png",
	"lanterncub": "res://assets/ui/portraits/lanterncub.png",
	"candlemoth": "res://assets/ui/portraits/candlemoth.png",
	"sunlion": "res://assets/ui/portraits/sunlion.png",
	"sparkmouse": "res://assets/ui/portraits/sparkmouse.png",
	"bellvolt": "res://assets/ui/portraits/bellvolt.png",
	"coilowl": "res://assets/ui/portraits/coilowl.png",
	"stormalpaca": "res://assets/ui/portraits/stormalpaca.png",
	"pebbletot": "res://assets/ui/portraits/pebbletot.png",
	"mudturtle": "res://assets/ui/portraits/mudturtle.png",
	"crystalbadger": "res://assets/ui/portraits/crystalbadger.png",
	"mountainseed": "res://assets/ui/portraits/mountainseed.png",
	"cloudchick": "res://assets/ui/portraits/cloudchick.png",
	"kitehare": "res://assets/ui/portraits/kitehare.png",
	"whistlecrane": "res://assets/ui/portraits/whistlecrane.png",
	"auroradrake": "res://assets/ui/portraits/auroradrake.png"
}

static func get_texture(spirit_id: String) -> Texture2D:
	var path: String = String(PATHS.get(spirit_id, ""))
	return load(path) as Texture2D if not path.is_empty() else null
