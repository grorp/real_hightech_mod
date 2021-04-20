minetest.register_node(
	"hightech:dark_stripe_horizontal",
	{
		description = "Dark Hightech Block\n(horizontal stripe)",
		tiles = {
			"hightech_dark.png",
			"hightech_dark.png",
			"hightech_dark_stripe.png",
		},
		paramtype = "light",
		light_source = minetest.LIGHT_MAX,
		groups = {cracky = 3},
		sounds = default.node_sound_stone_defaults(),
	}
)
minetest.register_craft({
	recipe = {
		{"hightech:dark", "hightech:dark", "hightech:dark"},
		{"hightech:glass", "hightech:glass", "hightech:glass"},
		{"hightech:dark", "hightech:dark", "hightech:dark"},
	},
	output = "hightech:dark_stripe_horizontal 9",
})

minetest.register_node(
	"hightech:dark_stripe_vertical",
	{
		description = "Dark Hightech Block\n(vertical stripe)",
		tiles = {
			"hightech_dark.png",
			"hightech_dark.png",
			"hightech_dark_stripe.png^[transformR90"
		},
		paramtype = "light",
		light_source = minetest.LIGHT_MAX,
		groups = {cracky = 3},
		sounds = default.node_sound_stone_defaults(),
	}
)
minetest.register_craft({
	recipe = {
		{"hightech:dark", "hightech:glass", "hightech:dark"},
		{"hightech:dark", "hightech:glass", "hightech:dark"},
		{"hightech:dark", "hightech:glass", "hightech:dark"},
	},
	output = "hightech:dark_stripe_vertical 9",
})
