-- str_starts_with checks if the specified string starts with the specified prefix.
local function str_starts_with(str, prefix)
	return str:sub(1, #prefix) == prefix
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

local function conn_dirs_table_to_autoconnect_stripe_nodename(node_basename, conn_dirs)
	return node_basename .. "_" .. conn_dirs_table_to_string(conn_dirs)
end

local function is_autoconnect_stripe_node(node_basename, pos)
	return str_starts_with(get_node_force(pos).name, node_basename)
end

local function get_autoconnect_stripe_node_conn_dirs(node_basename, pos)
	local conn_dirs = {false, false, false, false}
	if is_autoconnect_stripe_node(node_basename, { x = pos.x+1, y = pos.y, z = pos.z }) then
		conn_dirs[1] = true
	end
	if is_autoconnect_stripe_node(node_basename, { x = pos.x-1, y = pos.y, z = pos.z }) then
		conn_dirs[2] = true
	end
	if is_autoconnect_stripe_node(node_basename, { x = pos.x, y = pos.y, z = pos.z+1 }) then
		conn_dirs[3] = true
	end
	if is_autoconnect_stripe_node(node_basename, { x = pos.x, y = pos.y, z = pos.z-1 }) then
		conn_dirs[4] = true
	end
	return conn_dirs
end

local function update_autoconnect_stripe_node(node_basename, pos)
	minetest.set_node(pos, {name = conn_dirs_table_to_autoconnect_stripe_nodename(node_basename, get_autoconnect_stripe_node_conn_dirs(node_basename, pos))})
end

local function update_surrounding_autoconnect_stripe_nodes(node_basename, pos)
	if is_autoconnect_stripe_node(node_basename, { x = pos.x+1, y = pos.y, z = pos.z }) then
		update_autoconnect_stripe_node(node_basename, { x = pos.x+1, y = pos.y, z = pos.z })
	end
	if is_autoconnect_stripe_node(node_basename, { x = pos.x-1, y = pos.y, z = pos.z }) then
		update_autoconnect_stripe_node(node_basename, { x = pos.x-1, y = pos.y, z = pos.z })
	end
	if is_autoconnect_stripe_node(node_basename, { x = pos.x, y = pos.y, z = pos.z+1 }) then
		update_autoconnect_stripe_node(node_basename, { x = pos.x, y = pos.y, z = pos.z+1 })
	end
	if is_autoconnect_stripe_node(node_basename, { x = pos.x, y = pos.y, z = pos.z-1 }) then
		update_autoconnect_stripe_node(node_basename, { x = pos.x, y = pos.y, z = pos.z-1 })
	end
end

local autoconnect_stripe_top_node_basename = "hightech:dark_stripe_top_autoconnect"
local autoconnect_stripe_top_nodenames = {}
local autoconnect_stripe_bottom_node_basename = "hightech:dark_stripe_bottom_autoconnect"
local autoconnect_stripe_bottom_nodenames = {}

for xp = 0, 1 do
	for xn = 0, 1 do
		for zp = 0, 1 do
			for zn = 0, 1 do
				local conn_dirs = conn_dirs_string_to_table(xp .. xn .. zp .. zn)
				local autoconnect_stripe_top_nodename = conn_dirs_table_to_autoconnect_stripe_nodename(autoconnect_stripe_top_node_basename, conn_dirs)
				local autoconnect_stripe_bottom_nodename = conn_dirs_table_to_autoconnect_stripe_nodename(autoconnect_stripe_bottom_node_basename, conn_dirs)
				local is_in_inv = conn_dirs[1] and conn_dirs[2] and not conn_dirs[3] and not conn_dirs[4]

				minetest.register_node(
					autoconnect_stripe_top_nodename,
					{
						description = is_in_inv and "Dark Hightech Block\n(automatically connecting stripe on the top)" or "",
						not_in_creative_inventory = not is_in_inv,
						tiles = {
							hightech.get_stripe_texture(conn_dirs),
							"hightech_dark.png",
						},
						paramtype = "light",
						light_source = minetest.LIGHT_MAX,
						groups = {cracky = 3},
						sounds = default.node_sound_stone_defaults(),
						after_place_node = function(pos)
							update_autoconnect_stripe_node(autoconnect_stripe_top_node_basename, pos)
							update_surrounding_autoconnect_stripe_nodes(autoconnect_stripe_top_node_basename, pos)
						end,
						after_dig_node = function(pos)
							update_surrounding_autoconnect_stripe_nodes(autoconnect_stripe_top_node_basename, pos)
						end,
						drop = conn_dirs_table_to_autoconnect_stripe_nodename(autoconnect_stripe_top_node_basename, {true, true, false, false}),
					}
				)

				minetest.register_node(
					autoconnect_stripe_bottom_nodename,
					{
						description = is_in_inv and "Dark Hightech Block\n(automatically connecting stripe on the bottom)" or "",
						not_in_creative_inventory = not is_in_inv,
						tiles = {
							"hightech_dark.png",
							hightech.get_stripe_texture(conn_dirs) .. "^[transformFY",
							"hightech_dark.png",
						},
						paramtype = "light",
						light_source = minetest.LIGHT_MAX,
						groups = {cracky = 3},
						sounds = default.node_sound_stone_defaults(),
						after_place_node = function(pos)
							update_autoconnect_stripe_node(autoconnect_stripe_bottom_node_basename, pos)
							update_surrounding_autoconnect_stripe_nodes(autoconnect_stripe_bottom_node_basename, pos)
						end,
						after_dig_node = function(pos)
							update_surrounding_autoconnect_stripe_nodes(autoconnect_stripe_bottom_node_basename, pos)
						end,
						drop = conn_dirs_table_to_autoconnect_stripe_nodename(autoconnect_stripe_bottom_node_basename, {true, true, false, false}),
					}
				)

				table.insert(autoconnect_stripe_top_nodenames, autoconnect_stripe_top_nodename)
				table.insert(autoconnect_stripe_bottom_nodenames, autoconnect_stripe_bottom_nodename)
			end
		end
	end
end

minetest.register_lbm({
	name = "hightech:update_dark_stripe_top_autoconnect",
	nodenames = autoconnect_stripe_top_nodenames,
	run_at_every_load = true,
	action = function (pos)
		update_autoconnect_stripe_node(autoconnect_stripe_top_node_basename, pos)
	end,
})

minetest.register_lbm({
	name = "hightech:update_dark_stripe_bottom_autoconnect",
	nodenames = autoconnect_stripe_bottom_nodenames,
	run_at_every_load = true,
	action = function (pos)
		update_autoconnect_stripe_node(autoconnect_stripe_bottom_node_basename, pos)
	end,
})
