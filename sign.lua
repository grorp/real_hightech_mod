signs_lib.register_sign(
	"hightech:sign",
	{
		description = "Hightech Sign",
		inventory_image = "hightech_sign_inv.png",
		tiles = {
			"hightech_sign.png",
			"hightech_sign_edges.png",
			"",
			"",
			"hightech_dark.png"
		},
		entity_info = "standard",
		allow_yard = true,
		y_offset = 3,
		x_offset = 3,
		default_color = "f",
		allow_widefont = true,
		groups = {cracky = 3},
		sounds = default.node_sound_stone_defaults(),
	}
)

minetest.register_craft({
	recipe = {
		{"hightech:dark", "hightech:dark", "hightech:dark"},
		{"hightech:dark", "hightech:dark", "hightech:dark"},
	},
	output = "hightech:sign 3",
})
