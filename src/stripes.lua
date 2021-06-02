local S = minetest.get_translator("hightech")

function hightech.internal.get_stripe_texture(conn_dirs)
	local texture = "hightech_dark.png^(hightech_stripe_middle.png"
	if conn_dirs[1] then
		texture = texture .. "^(hightech_stripe_part.png^[transformFYR90)"
	end
	if conn_dirs[2] then
		texture = texture .. "^(hightech_stripe_part.png^[transformR90)"
	end
	if conn_dirs[3] then
		texture = texture .. "^hightech_stripe_part.png"
	end
	if conn_dirs[4] then
		texture = texture .. "^(hightech_stripe_part.png^[transformFY)"
	end
	texture = texture .. ")"
	return texture
end

minetest.register_node(
	"hightech:dark_stripe_horizontal",
	{
		description = S("Dark Hightech\n(horizontal stripe)"),
		tiles = {
			"hightech_dark.png",
			"hightech_dark.png",
			hightech.internal.get_stripe_texture({true, true, false, false}),
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
		description = S("Dark Hightech\n(vertical stripe)"),
		tiles = {
			"hightech_dark.png",
			"hightech_dark.png",
			hightech.internal.get_stripe_texture({false, false, true, true}),
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
