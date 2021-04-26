doors.register(
	"hightech:door",
	{
		description = "Hightech Door",
		tiles = {"hightech_door.png"},
		inventory_image = "hightech_door_inv.png",
		use_texture_alpha = "blend",
		paramtype = "light",
		light_source = minetest.LIGHT_MAX,
		groups = {cracky = 3},
		sounds = default.node_sound_stone_defaults(),
	}
)
minetest.register_craft({
	recipe = {
		{"hightech:glass", "hightech:glass"},
		{"hightech:dark", "hightech:dark"},
		{"hightech:dark", "hightech:dark"},
	},
	output = "hightech:door",
})

doors.register(
	"hightech:door_locked",
	{
		description = "Hightech Door\n(locked)",
		tiles = {"hightech_door.png"},
		inventory_image = "hightech_door_inv.png",
		use_texture_alpha = "blend",
		paramtype = "light",
		light_source = minetest.LIGHT_MAX,
		protected = true,
		groups = {cracky = 3},
		sounds = default.node_sound_stone_defaults(),
	}
)
minetest.register_craft({
	type = "shapeless",
	recipe = {
		"hightech:door",
		"basic_materials:padlock",
	},
	output = "hightech:door_locked",
})

doors.register(
	"hightech:door_no_window",
	{
		description = "Hightech Door\n(no window)",
		tiles = {"hightech_door_no_window.png"},
		inventory_image = "hightech_door_no_window_inv.png",
		groups = {cracky = 3},
		sounds = default.node_sound_stone_defaults(),
	}
)
minetest.register_craft({
	recipe = {
		{"hightech:dark", "hightech:dark"},
		{"hightech:dark", "hightech:dark"},
		{"hightech:dark", "hightech:dark"},
	},
	output = "hightech:door_no_window",
})

doors.register(
	"hightech:door_no_window_locked",
	{
		description = "Hightech Door\n(no window, locked)",
		tiles = {"hightech_door_no_window.png"},
		inventory_image = "hightech_door_no_window_inv.png",
		protected = true,
		groups = {cracky = 3},
		sounds = default.node_sound_stone_defaults(),
	}
)
minetest.register_craft({
	type = "shapeless",
	recipe = {
		"hightech:door_no_window",
		"basic_materials:padlock",
	},
	output = "hightech:door_no_window_locked",
})
