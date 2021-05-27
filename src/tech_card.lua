local S = minetest.get_translator("hightech")
local F = minetest.formspec_escape

local function tech_card_get_formspec(context)
	return
		"formspec_version[4]" ..
		"size[3.62,3.3]" ..
		"label[0.375,0.5;" .. minetest.colorize("#00fffb", F(S("TechCard"))) .. "]" ..
		"label[0.375,1.125;" .. F(S("ID: @1", context.tech_card_id)) .. "]" ..
		"label[0.375,1.5;" .. F(S("Balance: @1 Techies", hightech.tech_card.get_balance(context.tech_card_id))) .. "]" ..
		"button[0.375,2.125;2.87,0.8;transfer;" .. F(S("Transfer")) .. "]"
end

local function tech_card_get_transfer_formspec(context)
	return
		"formspec_version[4]" ..
		"size[3.62,4.755]" ..
		"label[0.375,0.5;" .. minetest.colorize("#00fffb", F(S("Transfer"))) .. "]" ..
		"field[0.375,1.25;2.87,0.8;receiver_id;" .. F(S("Receiver ID")) .. ";]" ..
		"field[0.375,2.55;2.87,0.8;amount;" .. F(S("Amount [Techies]")) .. ";]" ..
		"button[0.375,3.58;2.87,0.8;transfer;" .. F(S("Transfer")) .. "]"
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
		if formname == "hightech:tech_card_gui" then
			if fields.transfer then
				local context = hightech.internal.get_context(player)
				minetest.show_formspec(player:get_player_name(), "hightech:tech_card_transfer_gui", tech_card_get_transfer_formspec(context))
			end
		elseif formname == "hightech:tech_card_transfer_gui" then
			local context = hightech.internal.get_context(player)
			if fields.transfer then
				if fields.receiver_id == "" or fields.amount == "" then
					return
				end
				if not hightech.tech_card.exists(fields.receiver_id) then
					minetest.chat_send_player(player:get_player_name(), S("There is no TechCard with the ID \"@1\".", fields.receiver_id))
					return
				end
				if fields.receiver_id == context.tech_card_id then
					minetest.chat_send_player(player:get_player_name(), S("You can't tranfer Techies from a TechCard to itself."))
					return
				end
				local amount = tonumber(fields.amount)
				if amount == nil then
					minetest.chat_send_player(player:get_player_name(), S("\"@1\" isn't a number.", fields.amount))
					return
				end
				if not hightech.internal.is_int(amount) then
					minetest.chat_send_player(player:get_player_name(), S("The amount of Techies to transfer must be a whole number."))
					return
				end
				if amount <= 0 then
					minetest.chat_send_player(player:get_player_name(), S("The amount of Techies to transfer must be greater than 0."))
					return
				end
				if not hightech.tech_card.can_subtract(context.tech_card_id, amount) then
					minetest.chat_send_player(player:get_player_name(), S("You can't transfer more Techies than you have."))
					return
				end
				hightech.tech_card.subtract(context.tech_card_id, amount)
				hightech.tech_card.add(fields.receiver_id, amount)
				hightech.tech_card.save()
				minetest.chat_send_player(player:get_player_name(), S("@1 Techies were transfered from the TechCard with the ID \"@2\" to the TechCard with the ID \"@3\".", amount, context.tech_card_id, fields.receiver_id))
				minetest.show_formspec(player:get_player_name(), "hightech:tech_card_gui", tech_card_get_formspec(context))
			end
		end
end)

local function tech_card_update_description(meta)
	meta:set_string("description", minetest.colorize("#00fffb", S("TechCard")) .. "\n" .. meta:get_string("id"))
end

local function tech_card_on_place(itemstack, user)
	local meta = itemstack:get_meta()
	if meta:get_string("id") == "" then
		meta:set_string("id", hightech.tech_card.new())
		hightech.tech_card.save()
		tech_card_update_description(meta)
		minetest.chat_send_player(user:get_player_name(), S("The TechCard is now configured. It has the ID \"@1\".", meta:get_string("id")))
		return itemstack
	else
		local context = hightech.internal.get_context(user)
		context.tech_card_id = meta:get_string("id")
		minetest.show_formspec(user:get_player_name(), "hightech:tech_card_gui", tech_card_get_formspec(context))
	end
end

minetest.register_craftitem("hightech:tech_card", {
	description = minetest.colorize("#00fffb", S("TechCard")) .. "\n" .. S("Not yet configured"),
	inventory_image = "hightech_tech_card.png",
	stack_max = 1,
	on_place = tech_card_on_place,
	on_secondary_use = tech_card_on_place,
})

minetest.register_craft({
	recipe = {
		{"hightech:dark", "hightech:dark", "hightech:dark"},
		{"hightech:dark", "hightech:glass", "hightech:dark"},
		{"hightech:glass", "hightech:glass", "hightech:glass"},
	},
	output = "hightech:tech_card",
})

minetest.register_on_newplayer(function(player)
	local itemstack = ItemStack("hightech:tech_card")
	local meta = itemstack:get_meta()
	meta:set_string("id", hightech.tech_card.new())
	hightech.tech_card.add(meta:get_string("id"), 300)
	hightech.tech_card.save()
	tech_card_update_description(meta)
	player:get_inventory():add_item("main", itemstack)
end)
