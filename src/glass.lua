local S = minetest.get_translator("hightech")

minetest.register_node(
	"hightech:glass",
	{
		description = S("Hightech Glass"),
		tiles = {"hightech_glass.png"},
		drawtype = "glasslike",
		use_texture_alpha = "blend",
		paramtype = "light",
		light_source = minetest.LIGHT_MAX,
		groups = {cracky = 3, oddly_breakable_by_hand = 3},
		sounds = default.node_sound_glass_defaults(),
	}
)

stairs.register_stair_and_slab(
	"hightech_glass",
	"hightech:glass",
	{cracky = 3, oddly_breakable_by_hand = 3},
	{"hightech_glass.png"},
	S("Hightech Glass Stair"),
	S("Hightech Glass Slab"),
	default.node_sound_glass_defaults(),
	false,
	S("Inner Hightech Glass Stair"),
	S("Outer Hightech Glass Stair")
)
minetest.override_item("stairs:stair_hightech_glass", {
	paramtype = "light",
	light_source = minetest.LIGHT_MAX,
})
minetest.override_item("stairs:stair_inner_hightech_glass", {
	paramtype = "light",
	light_source = minetest.LIGHT_MAX,
})
minetest.override_item("stairs:stair_outer_hightech_glass", {
	paramtype = "light",
	light_source = minetest.LIGHT_MAX,
})
minetest.override_item("stairs:slab_hightech_glass", {
	paramtype = "light",
	light_source = minetest.LIGHT_MAX,
})

minetest.register_node(
	"hightech:glass_ore",
	{
		description = S("Hightech Glass Ore"),
		tiles = {"default_stone.png^hightech_glass_ore.png"},
		paramtype = light,
		light_source = minetest.LIGHT_MAX / 4 * 3,
		groups = {cracky = 3},
		sounds = default.node_sound_stone_defaults(),
		drop = "hightech:glass_dust 2",
	}
)
minetest.register_ore({
	ore_type       = "scatter",
	ore            = "hightech:glass_ore",
	wherein        = "default:stone",
	clust_scarcity = 8 * 8 * 8,
	clust_size     = 3,
	clust_num_ores = 9,
})

minetest.register_craftitem(
	"hightech:glass_dust",
	{
		description = S("Hightech Glass Dust"),
		inventory_image = "hightech_glass_dust.png",
	}
)
minetest.register_craft({
	type = "cooking",
	recipe = "hightech:glass_dust",
	output = "hightech:glass",
})
minetest.register_craft({
	recipe = {
		{"hightech:glass"},
	},
	output = "hightech:glass_dust",
})
