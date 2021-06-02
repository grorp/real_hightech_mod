local S = minetest.get_translator("hightech")
local F = minetest.formspec_escape

local particle_spawner_ids = {}
local function get_particle_spawner_id(pos)
	return particle_spawner_ids[minetest.pos_to_string(pos)]
end
local function set_particle_spawner_id(pos, id)
	particle_spawner_ids[minetest.pos_to_string(pos)] = id
end

local function create_particle_spawner(pos)
	if get_particle_spawner_id(pos) ~= nil then
		return
	end

	local id = minetest.add_particlespawner({
		texture = "hightech_glass.png",
		glow = minetest.LIGHT_MAX,
		amount = 10,
		time = 0,
		minpos = vector.add(pos, {x = -0.4, y = -0.4, z = -0.4}),
		maxpos = vector.add(pos, {x = 0.4, y = -0.4, z = 0.4}),
		minvel = {x = 0, y = 0.25, z = 0},
		maxvel = {x = 0, y = 0.5, z = 0},
		minsize = 0.5,
		maxsize = 0.75,
		minexptime = 3.5,
		maxexptime = 3.5,
	})
	set_particle_spawner_id(pos, id)
end

local function delete_particle_spawner(pos)
	if get_particle_spawner_id(pos) == nil then
		return
	end

	minetest.delete_particlespawner(get_particle_spawner_id(pos))
	set_particle_spawner_id(pos, nil)
end

local function is_configured(pos)
	local meta = minetest.get_meta(pos)
	return meta:get_string("name") ~= ""
end

local function set_infotext(pos)
	local meta = minetest.get_meta(pos)

	if not is_configured(pos) then
		meta:set_string("infotext", S("Hightech Elevator") .. "\n" .. S("Not yet configured"))
		return
	end

	meta:set_string("infotext", S("Hightech Elevator") .. "\n" .. meta:get_string("name"))
end

local function configure(pos, player)
	if is_configured(pos) then
		return
	end

	local ctx = hightech.internal.get_context(player)
	ctx.elevator_pos = pos

	local meta = minetest.get_meta(pos)
	local formspec =
		"formspec_version[4]" ..
		"size[6,3.475]" ..
		"label[0.375,0.5;" .. minetest.colorize("#00fffb", F(S("Hightech Elevator"))) .. "]" ..
		"field[0.375,1.25;5.25,0.8;name;" .. F(S("Name")) .. ";" .. F(meta:get_string("name")) .. "]" ..
		"button_exit[0.375,2.3;5.25,0.8;save;" .. F(S("Save")) .. "]"
	minetest.show_formspec(player:get_player_name(), "hightech:elevator_configure", formspec)
end

minetest.register_on_player_receive_fields(function(player, formspec_name, fields)
	if formspec_name == "hightech:elevator_configure" then
		local ctx = hightech.internal.get_context(player)
		if not ctx.elevator_pos then
			return
		end

		if is_configured(ctx.elevator_pos) then
			ctx.elevator_pos = nil
			return
		end

		local meta = minetest.get_meta(ctx.elevator_pos)
		meta:set_string("name", fields.name)
		set_infotext(ctx.elevator_pos)
	end
end)

local function get_connected_elevators_in_dir(pos, dir)
	local elevators = {}

	while true do
		pos = vector.add(pos, dir)
		local node_name = hightech.internal.get_node_force(pos).name

		if node_name == "hightech:elevator" then
			if is_configured(pos) then
				local meta = minetest.get_meta(pos)
				elevators[#elevators + 1] = {
					pos = pos,
					name = meta:get_string("name"),
				}
			end
		end

		if
			node_name ~= "hightech:elevator" and
			node_name ~= "hightech:elevator_top_invisible" and
			node_name ~= "hightech:elevator_shaft"
		then
			break
		end
	end

	return elevators
end

local function get_connected_elevators(pos)
	local elevators_above = get_connected_elevators_in_dir(pos, {x = 0, y = 1, z = 0})
	elevators_above = hightech.internal.table.reverse(elevators_above)

	local meta = minetest.get_meta(pos)
	elevators_above[#elevators_above + 1] = {
		pos = pos,
		name = meta:get_string("name"),
		self = true,
	}

	local elevators_below = get_connected_elevators_in_dir(pos, {x = 0, y = -1, z = 0})

	return hightech.internal.table.concat(elevators_above, elevators_below)
end

local function ride(pos, player)
	local ctx = hightech.internal.get_context(player)
	ctx.elevator_pos = pos

	local elevators = get_connected_elevators(pos)
	local formspec =
		"formspec_version[4]" ..
		"size[6,6.25]" ..
		"label[0.375,0.5;" .. minetest.colorize("#00fffb", F(S("Hightech Elevator"))) .. "]" ..
		"scroll_container[0.375,0.875;4.7,5;scrollbar;vertical]"
	local next_y = 0
	for _, elevator in pairs(elevators) do
		if not elevator.self then
			formspec = formspec .. "button_exit[0," .. tostring(next_y) .. ";4.7,0.8;target_" .. F(minetest.pos_to_string(elevator.pos)) .. ";" .. F(elevator.name) .. "]"
		else
			formspec = formspec .. "label[0," .. tostring(next_y + (0.8 / 2)) .. ";" .. F(S("@1 (current position)", elevator.name)) .. "]"
		end
		next_y = next_y + 0.8 + 0.25
	end
	formspec = formspec ..
		"scroll_container_end[]" ..
		"scrollbaroptions[max=" .. tostring((next_y - 0.25 - 4.95) / 0.1) .. "]" ..
		"scrollbar[5.325,0.875;0.3,5;vertical;scrollbar;0]"

	minetest.show_formspec(player:get_player_name(), "hightech:elevator_ride", formspec)
end

minetest.register_on_player_receive_fields(function(player, formspec_name, fields)
	if formspec_name == "hightech:elevator_ride" then
		local ctx = hightech.internal.get_context(player)
		if not ctx.elevator_pos then
			return
		end

		local target_elevator_pos = nil
		for field in pairs(fields) do
			if hightech.internal.str.has_prefix(field, "target_") then
				local pos_str = hightech.internal.str.strip_prefix(field, "target_")
				pos_str = string.gsub(pos_str, "\\,", ",")
				target_elevator_pos = minetest.string_to_pos(pos_str)

				if target_elevator_pos then
					break
				end
			end
		end

		if not target_elevator_pos then
			return
		end

		local available_targets = get_connected_elevators(ctx.elevator_pos)
		local is_available = false
		for _, elevator in pairs(available_targets) do
			if vector.equals(elevator.pos, target_elevator_pos) then
				is_available = true
				break
			end
		end

		if not is_available then
			ctx.elevator_pos = nil
			return
		end

		player:set_pos(vector.subtract(target_elevator_pos, {x = 0, y = 0.45, z = 0}))
		local target_elevator_dir = vector.subtract({x = 0, y = 0, z = 0}, minetest.facedir_to_dir(minetest.get_node(target_elevator_pos).param2))
		player:set_look_horizontal(minetest.dir_to_yaw(target_elevator_dir))
		player:set_look_vertical(0)

		minetest.sound_play("hightech_elevator_ride", {pos = target_elevator_pos}, true)

		ctx.elevator_pos = nil
	end
end)

minetest.register_node("hightech:elevator", {
	description = S("Hightech Elevator"),
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, -0.45, 0.5},
			{-0.5, 1.5, -0.5, 0.5, 1.45, 0.5},
			{-0.5, 1.5, -0.5, -0.45, -0.5, 0.5},
			{0.5, 1.5, -0.5, 0.45, -0.5, 0.5},
			{-0.5, 1.5, 0.5, 0.5, -0.5, 0.45},
		},
	},
	tiles = {"hightech_dark.png"},

	paramtype = "light",
	paramtype2 = "facedir",
	selection_box = {
		type = "fixed",
		fixed = {-0.5, 1.5, -0.5, 0.5, -0.5, 0.5},
	},
	groups = {cracky = 3},
	sounds = default.node_sound_stone_defaults(),

	after_place_node = function(pos, player)
		minetest.set_node({x = pos.x, y = pos.y + 1, z = pos.z}, {name = "hightech:elevator_top_invisible"})
		create_particle_spawner(pos)
		set_infotext(pos)
		configure(pos, player)
	end,
	on_rightclick = function(pos, _, player)
		ride(pos, player)
	end,
	after_dig_node = function(pos)
		minetest.remove_node({x = pos.x, y = pos.y + 1, z = pos.z})
		delete_particle_spawner(pos)
	end,
})

minetest.register_lbm({
	name = "hightech:elevator_create_particle_spawners",
	nodenames = {"hightech:elevator"},
	action = function(pos)
		create_particle_spawner(pos)
	end,
	run_at_every_load = true,
})

minetest.register_node("hightech:elevator_top_invisible", {
	drawtype = "airlike",
	collision_box = {
		type = "fixed",
		fixed = {-0.5, 0.45, -0.5, 0.5, 0.5, 0.5},
	},
	pointable = false,
	groups = {not_in_creative_inventory = 1},
})

minetest.register_node("hightech:elevator_shaft", {
	description = S("Hightech Elevator Shaft"),
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, 0.5, -0.45},
			{-0.5, -0.5, -0.5, -0.45, 0.5, 0.5},
			{-0.5, -0.5, 0.5, 0.5, 0.5, 0.45},
			{0.5, -0.5, -0.5, 0.45, 0.5, 0.5},
		},
	},
	tiles = {"hightech_dark.png"},

	climbable = true,
	paramtype = "light",
	sunlight_propagates = true,
	selection_box = {type = "regular"},
	groups = {cracky = 3},
	sounds = default.node_sound_stone_defaults(),
})
