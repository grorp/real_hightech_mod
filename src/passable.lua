local S = minetest.get_translator("hightech")

minetest.register_node(
	"hightech:dark_passable",
	{
		description = S("Passable Dark Hightech"),
		tiles = {"hightech_dark.png"},
		walkable = false,
		groups = {cracky = 3},
		sounds = default.node_sound_stone_defaults(),
	}
)
