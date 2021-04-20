local function find_index(table, value)
	for i, v in pairs(table) do
		if v == value then
			return i
		end
	end
end

local function handcuff(player, victim)
	local player_meta = player:get_meta()
	local victim_meta = victim:get_meta()

	local privs = minetest.get_player_privs(victim:get_player_name())
	privs.interact = nil
	minetest.set_player_privs(victim:get_player_name(), privs)

	local victim_armor_groups = victim:get_armor_groups()
	victim_armor_groups.immortal = 1
	victim:set_armor_groups(victim_armor_groups)

	victim:set_attach(player, "", {x = 0, y = 6, z = -10}, {x = 0, y = 0, z = 0}, true)
	victim:set_eye_offset({x = 0, y = 6, z = -10}, {x = 0, y = 6, z = -15})

	victim_meta:set_string("handcuffed_by", player:get_player_name())
	local player_victims = minetest.deserialize(player_meta:get_string("handcuffed_players"))
	if player_victims == nil then
		player_victims = {}
	end
	table.insert(player_victims, victim:get_player_name())
	player_meta:set_string("handcuffed_players", minetest.serialize(player_victims))

	minetest.sound_play("hightech_handcuffs_close", {pos = victim:get_pos()}, true)
end

local function un_handcuff(player, victim)
	local player_meta = player:get_meta()
	local victim_meta = victim:get_meta()

	local privs = minetest.get_player_privs(victim:get_player_name())
	privs.interact = true
	minetest.set_player_privs(victim:get_player_name(), privs)

	local victim_armor_groups = victim:get_armor_groups()
	victim_armor_groups.immortal = 0
	victim:set_armor_groups(victim_armor_groups)

	victim:set_detach()
	victim:set_eye_offset({x = 0, y = 0, z = 0}, {x = 0, y = 0, z = 0})

	victim_meta:set_string("handcuffed_by", "")
	local player_victims = minetest.deserialize(player_meta:get_string("handcuffed_players"))
	table.remove(player_victims, find_index(player_victims, victim:get_player_name()))
	player_meta:set_string("handcuffed_players", minetest.serialize(player_victims))

	minetest.sound_play("hightech_handcuffs_open", {pos = victim:get_pos()}, true)
end

minetest.register_privilege("handcuff", "Allows to use Hightech Handcuffs")

minetest.register_craftitem(
	"hightech:handcuffs",
	{
		description = "Hightech Handcuffs",
		inventory_image = "hightech_handcuffs.png",
		stack_max = 1,
		on_use = function(itemstack, player, pointed_thing)
			if pointed_thing.type == "object" and pointed_thing.ref:is_player() then
				local victim = pointed_thing.ref
				local victim_meta = victim:get_meta()
				if victim_meta:get_string("handcuffed_by") == "" then
					if not minetest.check_player_privs(player:get_player_name(), "handcuff") then
						minetest.chat_send_player(
							player:get_player_name(),
							'You are not allowed to use Hightech Handcuffs (missing "handcuff" privilege).'
						)
						return
					end
					handcuff(player, victim)
					minetest.chat_send_player(
						victim:get_player_name(),
						player:get_player_name() .. " has handcuffed you."
					)
				else
					minetest.chat_send_player(
						player:get_player_name(),
						victim:get_player_name() ..
							" is already handcuffed by " .. victim_meta:get_string("handcuffed_by") .. "."
					)
				end
			else
				local player_meta = player:get_meta()
				local player_victims = minetest.deserialize(player_meta:get_string("handcuffed_players"))
				if player_victims == nil then
					player_victims = {}
				end
				for _, victim_name in pairs(player_victims) do
					local victim = minetest.get_player_by_name(victim_name)
					un_handcuff(player, victim)
					minetest.chat_send_player(
						victim:get_player_name(),
						player:get_player_name() .. " has opened your handcuffs."
					)
				end
			end
		end
	}
)

minetest.register_on_leaveplayer(
	function(player, timed_out)
		local player_meta = player:get_meta()

		if player_meta:get_string("handcuffed_by") ~= "" then
			local handcuffer = minetest.get_player_by_name(player_meta:get_string("handcuffed_by"))
			un_handcuff(handcuffer, player)
			minetest.chat_send_player(
				handcuffer:get_player_name(),
				player:get_player_name() .. " is free again because he left the game."
			)
		end

		local player_victims = minetest.deserialize(player_meta:get_string("handcuffed_players"))
		if player_victims == nil then
			player_victims = {}
		end
		for _, victim_name in pairs(player_victims) do
			local victim = minetest.get_player_by_name(victim_name)
			un_handcuff(player, victim)
			minetest.chat_send_player(
				victim:get_player_name(),
				player:get_player_name() .. " left the game, so you are now free again."
			)
		end
	end
)

minetest.register_craft({
	recipe = {
		{"hightech:glass", "hightech:glass", ""},
		{"hightech:glass", "hightech:glass", "hightech:glass"},
		{"", "hightech:glass", "hightech:glass"},
	},
	output = "hightech:handcuffs",
})
