local S = minetest.get_translator("hightech")

local function hightech_grid_after_place(pos, player)
	local meta = minetest.get_meta(pos)
	meta:set_string("owner", player:get_player_name())
	meta:set_string("infotext", S("Hightech Grid") .. "\n" .. minetest.translate("doors", "Owned by @1", player:get_player_name()))
	minetest.get_node_timer(pos):start(0.1)
end

local function hightech_grid_should_be_open(pos)
	local objs = minetest.get_objects_inside_radius(pos, 3)
	for _, obj in pairs(objs) do
		if hightech.internal.is_allowed(pos, obj:get_player_name()) then
			return true
		end
	end
	return false
end

xpanes.register_pane("hightech_grid", {
	description = S("Hightech Grid"),
	textures = {"hightech_grid.png"},
	inventory_image = "hightech_grid.png",
	groups = {cracky = 2},
	sounds = default.node_sound_metal_defaults(),
	recipe = {
		{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
		{"default:steel_ingot", "hightech:glass", "default:steel_ingot"},
		{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
	},
})

minetest.override_item("xpanes:hightech_grid", {
	after_place_node = hightech_grid_after_place,
	on_timer = function(pos)
		if hightech_grid_should_be_open(pos) then
			local n = minetest.get_node(pos)
			n.name = "xpanes:hightech_grid_open"
			minetest.swap_node(pos, n)
		end
		return true
	end,
	damage_per_second = 2,
	paramtype = "light",
	light_source = minetest.LIGHT_MAX,
	connects_to = {
		"xpanes:hightech_grid",
		"xpanes:hightech_grid_flat",
		"xpanes:hightech_grid_open",
		"xpanes:hightech_grid_open_flat",
	},
})

minetest.override_item("xpanes:hightech_grid_flat", {
	after_place_node = hightech_grid_after_place,
	on_timer = function(pos)
		if hightech_grid_should_be_open(pos) then
			local n = minetest.get_node(pos)
			n.name = "xpanes:hightech_grid_open_flat"
			minetest.swap_node(pos, n)
		end
		return true
	end,
	damage_per_second = 2,
	paramtype = "light",
	light_source = minetest.LIGHT_MAX,
})

xpanes.register_pane("hightech_grid_open", {
	textures = {"hightech_grid.png"},
	groups = {cracky = 2, not_in_creative_inventory = 1},
	sounds = default.node_sound_metal_defaults(),
	recipe = {{""}},
})

minetest.override_item("xpanes:hightech_grid_open", {
	walkable = false,
	after_place_node = hightech_grid_after_place,
	on_timer = function(pos)
		if not hightech_grid_should_be_open(pos) then
			local n = minetest.get_node(pos)
			n.name = "xpanes:hightech_grid"
			minetest.swap_node(pos, n)
		end
		return true
	end,
	paramtype = "light",
	light_source = minetest.LIGHT_MAX,
	connects_to = {
		"xpanes:hightech_grid",
		"xpanes:hightech_grid_flat",
		"xpanes:hightech_grid_open",
		"xpanes:hightech_grid_open_flat",
	},
	drop = "xpanes:hightech_grid_flat",
})

minetest.override_item("xpanes:hightech_grid_open_flat", {
	walkable = false,
	after_place_node = hightech_grid_after_place,
	on_timer = function(pos)
		if not hightech_grid_should_be_open(pos) then
			local n = minetest.get_node(pos)
			n.name = "xpanes:hightech_grid_flat"
			minetest.swap_node(pos, n)
		end
		return true
	end,
	paramtype = "light",
	light_source = minetest.LIGHT_MAX,
	drop = "xpanes:hightech_grid_flat",
})
