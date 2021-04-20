local _contexts = {}
local function get_context(name)
		local context = _contexts[name] or {}
		_contexts[name] = context
		return context
end
minetest.register_on_leaveplayer(function(player)
		_contexts[player:get_player_name()] = nil
end)

local function tech_card_get_formspec(context)
	return
		"formspec_version[4]" ..
		"size[3.62,3.3]" ..
		"label[0.375,0.5;" .. minetest.colorize("#00fffb", "TechCard") .. "]" ..
		"label[0.375,1.125;ID:               " .. minetest.formspec_escape(context.tech_card_id) .. "]" ..
		"label[0.375,1.5;Balance:    " .. tech_card.get_balance(context.tech_card_id) .. " Techies]" ..
		"button[0.375,2.125;2.87,0.8;transfer;Transfer]"
end

local function tech_card_get_transfer_formspec(context)
	return
		"formspec_version[4]" ..
		"size[3.62,4.755]" ..
		"label[0.375,0.5;" .. minetest.colorize("#00fffb", "Transfer") .. "]" ..
		"field[0.375,1.25;2.87,0.8;receiver_id;Receiver ID;]" ..
		"field[0.375,2.55;2.87,0.8;amount;Amount                  \\[Techies\\];]" ..
		"button[0.375,3.58;2.87,0.8;transfer;Transfer]"
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
		if formname == "hightech:tech_card_gui" then
			if fields.transfer then
				local context = get_context(player:get_player_name())
				minetest.show_formspec(player:get_player_name(), "hightech:tech_card_transfer_gui", tech_card_get_transfer_formspec(context))
			end
		elseif formname == "hightech:tech_card_transfer_gui" then
			local context = get_context(player:get_player_name())
			if fields.transfer then
				if fields.receiver_id == "" or fields.amount == "" then
					return
				end
				if not tech_card.exists(fields.receiver_id) then
					minetest.chat_send_player(player:get_player_name(), "There is no TechCard with the ID " .. fields.receiver_id .. ".")
					return
				end
				if fields.receiver_id == context.tech_card_id then
					minetest.chat_send_player(player:get_player_name(), "You can't tranfer Techies from a TechCard to itself.")
					return
				end
				local amount = tonumber(fields.amount)
				if amount == nil then
					minetest.chat_send_player(player:get_player_name(), "\"" .. fields.amount .. "\" isn't a number.")
					return
				end
				if amount <= 0 then
					minetest.chat_send_player(player:get_player_name(), "The amount of Techies to transfer must be greater than 0.")
					return
				end
				if not tech_card.can_subtract(context.tech_card_id, amount) then
					minetest.chat_send_player(player:get_player_name(), "You can't transfer more Techies than you have.")
					return
				end
				tech_card.subtract(context.tech_card_id, amount)
				tech_card.add(fields.receiver_id, amount)
				tech_card.save()
				minetest.chat_send_player(player:get_player_name(), amount .. " Techies were transfered from the TechCard with the ID " .. context.tech_card_id .. " to the TechCard with the ID " .. fields.receiver_id .. ".")
				minetest.show_formspec(player:get_player_name(), "hightech:tech_card_gui", tech_card_get_formspec(context))
			end
		end
end)

local function update_tech_card_description(meta)
	meta:set_string("description", minetest.colorize("#00fffb", "TechCard") .. "\n" .. meta:get_string("id"))
end

minetest.register_craftitem("hightech:tech_card", {
	description = minetest.colorize("#00fffb", "TechCard") .. "\nUnconfigured",
	inventory_image = "hightech_tech_card.png",
	stack_max = 1,
	on_use = function(itemstack, user, pointed_thing)
		local meta = itemstack:get_meta()
		if meta:get_string("id") == "" then
			meta:set_string("id", tech_card.new())
			tech_card.save()
			update_tech_card_description(meta)
			minetest.chat_send_player(user:get_player_name(), "The TechCard is now configured. It has the ID " .. meta:get_string("id") .. ".")
			return itemstack
		else
			local context = get_context(user:get_player_name())
			context.tech_card_id = meta:get_string("id")
			minetest.show_formspec(user:get_player_name(), "hightech:tech_card_gui", tech_card_get_formspec(context))
		end
	end,
})

minetest.register_craft({
	recipe = {
		{"hightech:dark", "hightech:dark", "hightech:dark"},
		{"hightech:dark", "hightech:dark", "hightech:dark"},
		{"hightech:glass", "hightech:glass", "hightech:glass"},
	},
	output = "hightech:tech_card",
})

minetest.register_on_newplayer(function(player)
	local itemstack = ItemStack("hightech:tech_card")
	local meta = itemstack:get_meta()
	meta:set_string("id", tech_card.new())
	tech_card.add(meta:get_string("id"), 300)
	tech_card.save()
	update_tech_card_description(meta)
	player:get_inventory():add_item("main", itemstack)
end)
