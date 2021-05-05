local S = minetest.get_translator("hightech")

-- str_starts_with checks if the specified string starts with the specified prefix.
local function str_starts_with(str, prefix)
	return str:sub(1, #prefix) == prefix
end

-- bool_to_number converts the specified boolean value to a number (either 0 or 1).
local function bool_to_number(value)
  return value and 1 or 0
end

-- get_node_force returns the node at the specified position.
-- If necessary, the node is loaded from disk beforehand.
local function get_node_force(pos)
	local node = minetest.get_node_or_nil(pos)
	if node == nil then
		minetest.load_area(pos)
		node = minetest.get_node_or_nil(pos)
	end
	return node
end

-- conn_dirs_table_to_string converts a connection directions table (a list of four boolean values, e.g. {true, true, false, false})
-- to a connection directions string (a list of four numbers between 0 and 1, e.g. "1100").
local function conn_dirs_table_to_string(conn_dirs)
	return (conn_dirs[1] and 1 or 0) .. (conn_dirs[2] and 1 or 0) .. (conn_dirs[3] and 1 or 0) .. (conn_dirs[4] and 1 or 0)
end
-- conn_dirs_string_to_table does the opposite of conn_dirs_table_to_string.
-- Who would have thought it?
local function conn_dirs_string_to_table(conn_dirs)
	return {string.sub(conn_dirs, 1, 1) == "1", string.sub(conn_dirs, 2, 2) == "1", string.sub(conn_dirs, 3, 3) == "1", string.sub(conn_dirs, 4, 4) == "1"}
end

local function conn_dirs_table_to_autoconnect_stripe_nodename(base_nodename, conn_dirs)
	return base_nodename .. "_" .. conn_dirs_table_to_string(conn_dirs)
end

local function is_autoconnect_stripe_node(base_nodename, pos)
	return str_starts_with(get_node_force(pos).name, base_nodename)
end

local function get_autoconnect_stripe_node_conn_dirs(base_nodename, pos)
	local conn_dirs = {false, false, false, false}
	if is_autoconnect_stripe_node(base_nodename, { x = pos.x+1, y = pos.y, z = pos.z }) then
		conn_dirs[1] = true
	end
	if is_autoconnect_stripe_node(base_nodename, { x = pos.x-1, y = pos.y, z = pos.z }) then
		conn_dirs[2] = true
	end
	if is_autoconnect_stripe_node(base_nodename, { x = pos.x, y = pos.y, z = pos.z+1 }) then
		conn_dirs[3] = true
	end
	if is_autoconnect_stripe_node(base_nodename, { x = pos.x, y = pos.y, z = pos.z-1 }) then
		conn_dirs[4] = true
	end
	return conn_dirs
end

local function update_autoconnect_stripe_node(base_nodename, pos)
	minetest.set_node(pos, {name = conn_dirs_table_to_autoconnect_stripe_nodename(base_nodename, get_autoconnect_stripe_node_conn_dirs(base_nodename, pos))})
end

local function update_surrounding_autoconnect_stripe_nodes(base_nodename, pos)
	if is_autoconnect_stripe_node(base_nodename, { x = pos.x+1, y = pos.y, z = pos.z }) then
		update_autoconnect_stripe_node(base_nodename, { x = pos.x+1, y = pos.y, z = pos.z })
	end
	if is_autoconnect_stripe_node(base_nodename, { x = pos.x-1, y = pos.y, z = pos.z }) then
		update_autoconnect_stripe_node(base_nodename, { x = pos.x-1, y = pos.y, z = pos.z })
	end
	if is_autoconnect_stripe_node(base_nodename, { x = pos.x, y = pos.y, z = pos.z+1 }) then
		update_autoconnect_stripe_node(base_nodename, { x = pos.x, y = pos.y, z = pos.z+1 })
	end
	if is_autoconnect_stripe_node(base_nodename, { x = pos.x, y = pos.y, z = pos.z-1 }) then
		update_autoconnect_stripe_node(base_nodename, { x = pos.x, y = pos.y, z = pos.z-1 })
	end
end

local autoconnect_stripe_top_base_nodename = "hightech:dark_stripe_top_autoconnect"
local autoconnect_stripe_top_inv_nodename = conn_dirs_table_to_autoconnect_stripe_nodename(autoconnect_stripe_top_base_nodename, {true, true, false, false})
local autoconnect_stripe_top_nodenames = {}

local autoconnect_stripe_bottom_base_nodename = "hightech:dark_stripe_bottom_autoconnect"
local autoconnect_stripe_bottom_inv_nodename = conn_dirs_table_to_autoconnect_stripe_nodename(autoconnect_stripe_bottom_base_nodename, {true, true, false, false})
local autoconnect_stripe_bottom_nodenames = {}

for xp = 0, 1 do
	for xn = 0, 1 do
		for zp = 0, 1 do
			for zn = 0, 1 do
				local conn_dirs = conn_dirs_string_to_table(xp .. xn .. zp .. zn)
				local autoconnect_stripe_top_nodename = conn_dirs_table_to_autoconnect_stripe_nodename(autoconnect_stripe_top_base_nodename, conn_dirs)
				local autoconnect_stripe_bottom_nodename = conn_dirs_table_to_autoconnect_stripe_nodename(autoconnect_stripe_bottom_base_nodename, conn_dirs)

				minetest.register_node(
					autoconnect_stripe_top_nodename,
					{
						description = S("Dark Hightech Block\n(automatically connecting stripe on the top)"),
						tiles = {
							hightech.internal.get_stripe_texture(conn_dirs),
							"hightech_dark.png",
						},
						paramtype = "light",
						light_source = minetest.LIGHT_MAX,
						groups = {
							cracky = 3,
							not_in_creative_inventory = bool_to_number(autoconnect_stripe_top_nodename ~= autoconnect_stripe_top_inv_nodename),
						},
						sounds = default.node_sound_stone_defaults(),
						after_place_node = function(pos)
							update_autoconnect_stripe_node(autoconnect_stripe_top_base_nodename, pos)
							update_surrounding_autoconnect_stripe_nodes(autoconnect_stripe_top_base_nodename, pos)
						end,
						after_dig_node = function(pos)
							update_surrounding_autoconnect_stripe_nodes(autoconnect_stripe_top_base_nodename, pos)
						end,
						drop = autoconnect_stripe_top_inv_nodename,
					}
				)

				minetest.register_node(
					autoconnect_stripe_bottom_nodename,
					{
						description = S("Dark Hightech Block\n(automatically connecting stripe on the bottom)"),
						tiles = {
							"hightech_dark.png",
							hightech.internal.get_stripe_texture(conn_dirs) .. "^[transformFY",
							"hightech_dark.png",
						},
						paramtype = "light",
						light_source = minetest.LIGHT_MAX,
						groups = {
							cracky = 3,
							not_in_creative_inventory = bool_to_number(autoconnect_stripe_bottom_nodename ~= autoconnect_stripe_bottom_inv_nodename),
						},
						sounds = default.node_sound_stone_defaults(),
						after_place_node = function(pos)
							update_autoconnect_stripe_node(autoconnect_stripe_bottom_base_nodename, pos)
							update_surrounding_autoconnect_stripe_nodes(autoconnect_stripe_bottom_base_nodename, pos)
						end,
						after_dig_node = function(pos)
							update_surrounding_autoconnect_stripe_nodes(autoconnect_stripe_bottom_base_nodename, pos)
						end,
						drop = autoconnect_stripe_bottom_inv_nodename,
					}
				)

				table.insert(autoconnect_stripe_top_nodenames, autoconnect_stripe_top_nodename)
				table.insert(autoconnect_stripe_bottom_nodenames, autoconnect_stripe_bottom_nodename)
			end
		end
	end
end

minetest.register_craft({
	recipe = {
		{"hightech:glass", "hightech:glass", "hightech:glass"},
		{"hightech:dark", "hightech:dark", "hightech:dark"},
		{"hightech:dark", "hightech:dark", "hightech:dark"},
	},
	output = autoconnect_stripe_top_inv_nodename .. " 9",
})

minetest.register_craft({
	recipe = {
		{"hightech:dark", "hightech:dark", "hightech:dark"},
		{"hightech:dark", "hightech:dark", "hightech:dark"},
		{"hightech:glass", "hightech:glass", "hightech:glass"},
	},
	output = autoconnect_stripe_bottom_inv_nodename .. " 9",
})

minetest.register_lbm({
	name = "hightech:update_dark_stripe_top_autoconnect",
	nodenames = autoconnect_stripe_top_nodenames,
	run_at_every_load = true,
	action = function (pos)
		update_autoconnect_stripe_node(autoconnect_stripe_top_base_nodename, pos)
	end,
})

minetest.register_lbm({
	name = "hightech:update_dark_stripe_bottom_autoconnect",
	nodenames = autoconnect_stripe_bottom_nodenames,
	run_at_every_load = true,
	action = function (pos)
		update_autoconnect_stripe_node(autoconnect_stripe_bottom_base_nodename, pos)
	end,
})
