local S = minetest.get_translator("hightech")
local F = minetest.formspec_escape

local function shop_is_configured(pos)
	local meta = minetest.get_meta(pos)
	if meta:get_string("seller_tech_card_id") == "" then
		return false
	end
	if meta:get_string("price") == "" then
		return false
	end

	local inv = meta:get_inventory()
	local for_sale_is_not_empty = false
	for _, item in pairs(inv:get_list("for_sale")) do
		if not item:is_empty() then
			for_sale_is_not_empty = true
			break
		end
	end
	return for_sale_is_not_empty
end

local function shop_has_infinite_stock(pos)
	local meta = minetest.get_meta(pos)
	return minetest.is_creative_enabled(meta:get_string("owner")) and meta:get_int("infinite_stock") == 1
end

local function shop_is_sold_out(pos)
	if shop_has_infinite_stock(pos) then
		return false
	end

	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local temp_inv = minetest.create_detached_inventory("hightech:shop_temp_sold_out_check:(" .. pos.x .. "," .. pos.y .. "," .. pos.z .. "):" .. os.time())
	temp_inv:set_size("for_sale", inv:get_size("for_sale"))
	temp_inv:set_list("for_sale", inv:get_list("for_sale"))
	temp_inv:set_size("stock", inv:get_size("stock"))
	temp_inv:set_list("stock", inv:get_list("stock"))
	for _, item in pairs(temp_inv:get_list("for_sale")) do
		if not temp_inv:contains_item("stock", item) then
			minetest.remove_detached_inventory(temp_inv:get_location().name)
			return true
		end
		temp_inv:remove_item("stock", item)
	end
	minetest.remove_detached_inventory(temp_inv:get_location().name)
	return false
end

local function shop_update_infotext(pos)
	local meta = minetest.get_meta(pos)

	if not shop_is_configured(pos) then
		meta:set_string("infotext",
			S("Hightech Shop") .. "\n" ..
			minetest.translate("doors", "Owned by @1", meta:get_string("owner")) .. "\n" ..
			S("Not yet configured")
		)
		return
	end

	if shop_is_sold_out(pos) then
		meta:set_string("infotext",
			S("Hightech Shop") .. "\n" ..
			minetest.translate("doors", "Owned by @1", meta:get_string("owner")) .. "\n" ..
			S("Sold out")
		)
		return
	end

	local inv = meta:get_inventory()
	local for_sale_str_parts = {}
	for _, item in pairs(inv:get_list("for_sale")) do
		if not item:is_empty() then
			if item:get_count() == 1 then
				table.insert(for_sale_str_parts, item:get_short_description())
			else
				table.insert(for_sale_str_parts, S("@1x @2", item:get_count(), item:get_short_description()))
			end
		end
	end
	local for_sale_str = ""
	for i, part in pairs(for_sale_str_parts) do
		if i == #for_sale_str_parts-1 then
			for_sale_str = for_sale_str .. S("@1 and ", part)
		elseif i == #for_sale_str_parts then
			for_sale_str = for_sale_str .. part
		else
			for_sale_str = for_sale_str .. S("@1, ", part)
		end
	end

	meta:set_string("infotext",
		S("Hightech Shop") .. "\n" ..
		minetest.translate("doors", "Owned by @1", meta:get_string("owner")) .. "\n" ..
		S("@1 for @2 Techies", for_sale_str, meta:get_int("price")) .. "\n" ..
		S("PUNCH the shop with your TechCard to buy something.")
	)
end

local function shop_get_entity(pos)
	for _, obj in pairs(minetest.get_objects_inside_radius(pos, 0)) do
		if obj:get_luaentity().name == "hightech:shop_item" then
			return obj
		end
	end
	return minetest.add_entity(pos, "hightech:shop_item")
end

local function shop_on_place(pos, player)
	local meta = minetest.get_meta(pos)
	meta:set_string("owner", player:get_player_name())
	shop_update_infotext(pos)

	local inv = meta:get_inventory()
	inv:set_size("for_sale", 8)
	inv:set_size("stock", 32)

	local ent = shop_get_entity(pos)
	ent:set_rotation(vector.dir_to_rotation(minetest.facedir_to_dir(minetest.get_node(pos).param2)))
end

local function shop_on_dig(pos)
	local ent = shop_get_entity(pos)
	ent:remove()
end

local function shop_on_use(pos, _, player)
	local meta = minetest.get_meta(pos)
	if hightech.internal.is_allowed(pos, player:get_player_name()) then
		local context = hightech.internal.get_context(player:get_player_name())
		context.shop_pos = pos

		local pos_str = pos.x .. "," .. pos.y .. "," .. pos.z
		minetest.show_formspec(player:get_player_name(), "hightech:shop_owner_gui",
			"formspec_version[4]" ..
			"size[10.5,17.625]" ..
			"label[0.375,0.5;" .. minetest.colorize("#00fffb", F(S("Hightech Shop"))) .. "]" ..
			"field[0.375,1.25;9.75,0.8;seller_tech_card_id;" .. F(S("TechCard ID of the seller")) .. ";" .. F(meta:get_string("seller_tech_card_id")) .. "]" ..
			"field[0.375,2.55;9.75,0.8;price;" .. F(S("Price [Techies]")) .. ";" .. F(meta:get_string("price")) .. "]" ..
			"label[0.375,3.725;" .. F(S("Items for sale")) .. "]" ..
			"label[0.375,4.025;" .. F(S("(these items are taken from the stock for each sale)")) .. "]" ..
			"list[nodemeta:" .. pos_str .. ";for_sale;0.375,4.275;8,1;]" ..
			"label[0.375,5.65;" .. F(S("Stock")) .. "]" ..
			"checkbox[0.375,6.025;infinite_stock;" .. F(S("Infinite")) ..";" .. (meta:get_int("infinite_stock") == 1 and "true" or "false") .. "]" ..
			"list[nodemeta:" .. pos_str .. ";stock;0.375,6.325;8,4;]" ..
			"button_exit[0.375,11.325;9.75,0.8;save;" .. F(S("Save")) .."]" ..
			"list[current_player;main;0.375,12.5;8,4;]" ..
			"listring[nodemeta:" .. pos_str .. ";for_sale]" ..
			"listring[current_player;main]" ..
			"listring[nodemeta:" .. pos_str .. ";stock]" ..
			"listring[current_player;main]"
		)
	else
		minetest.chat_send_player(player:get_player_name(), S("PUNCH the shop with your TechCard to buy something."))
	end
end

minetest.register_on_player_receive_fields(function(player, gui_name, fields)
	if gui_name == "hightech:shop_owner_gui" then
		local context = hightech.internal.get_context(player:get_player_name())
		shop_update_infotext(context.shop_pos)
	end
end)

minetest.register_on_player_receive_fields(function(player, gui_name, fields)
	if gui_name == "hightech:shop_owner_gui" and fields.infinite_stock ~= nil then
		local context = hightech.internal.get_context(player:get_player_name())
		if not minetest.is_creative_enabled(player:get_player_name()) then
			minetest.chat_send_player(player:get_player_name(), S("The infinite stock is only available in creative mode."))
			return
		end
		
		local meta = minetest.get_meta(context.shop_pos)
		meta:set_int("infinite_stock", fields.infinite_stock == "true" and 1 or 0)
	end
end)

minetest.register_on_player_receive_fields(function(player, gui_name, fields)
	if gui_name == "hightech:shop_owner_gui" and fields.save then
		local context = hightech.internal.get_context(player:get_player_name())
		local meta = minetest.get_meta(context.shop_pos)

		if fields.price then
			if fields.price == "" then
				meta:set_string("price", "")
				return
			end

			local price = tonumber(fields.price)
			if price == nil then
				minetest.chat_send_player(player:get_player_name(), S("\"@1\" isn't a number.", fields.price))
				return
			end
			if not hightech.internal.is_int(price) then
				minetest.chat_send_player(player:get_player_name(), S("The price must be whole number."))
				return
			end
			meta:set_int("price", price)
		end
	end
end)

minetest.register_on_player_receive_fields(function(player, gui_name, fields)
	if gui_name == "hightech:shop_owner_gui" and fields.save then
		local context = hightech.internal.get_context(player:get_player_name())
		local meta = minetest.get_meta(context.shop_pos)

		if fields.seller_tech_card_id then
			if fields.seller_tech_card_id == "" then
				meta:set_string("seller_tech_card_id", "")
				return
			end
			if not hightech.tech_card.exists(fields.seller_tech_card_id) then
				minetest.chat_send_player(player:get_player_name(), S("There is no TechCard with the ID \"@1\".", fields.seller_tech_card_id))
				return
			end
			meta:set_string("seller_tech_card_id", fields.seller_tech_card_id)
		end
	end
end)

local function shop_on_inv_change(pos)
	local meta = minetest.get_meta(pos)

	local inv = meta:get_inventory()
	local for_sale_item = inv:get_stack("for_sale", 1)
	local ent = shop_get_entity(pos)
	ent:get_luaentity():set_item(for_sale_item:get_name())

	shop_update_infotext(pos)
end

local function shop_on_punch(pos, _, player)
	local wield_item = player:get_wielded_item()
	if wield_item:get_name() ~= "hightech:tech_card" then
		minetest.chat_send_player(player:get_player_name(), S("PUNCH the shop with your TechCard to buy something."))
		return
	end
	local tech_card_id = wield_item:get_meta():get_string("id")
	if tech_card_id == "" then
		minetest.chat_send_player(player:get_player_name(), S("This TechCard is not yet configured."))
		return
	end

	if not shop_is_configured(pos) then
		minetest.chat_send_player(player:get_player_name(), S("This shop is not yet configured."))
		return
	end
	if shop_is_sold_out(pos) then
		minetest.chat_send_player(player:get_player_name(), S("This shop is sold out."))
		return
	end
	local meta = minetest.get_meta(pos)
	local price = meta:get_int("price")
	if not hightech.tech_card.can_subtract(tech_card_id, price) then
		minetest.chat_send_player(player:get_player_name(), S("You don't have enough Techies to buy this."))
		return
	end

	local shop_inv = meta:get_inventory()
	local player_inv = player:get_inventory()
	local temp_inv = minetest.create_detached_inventory("hightech:shop_temp_enough_space_check:(" .. pos.x .. "," .. pos.y .. "," .. pos.z .. "):" .. player:get_player_name() .. ":" .. os.time())
	temp_inv:set_size("main", player_inv:get_size("main"))
	temp_inv:set_list("main", player_inv:get_list("main"))
	for _, item in pairs(shop_inv:get_list("for_sale")) do
		if not temp_inv:room_for_item("main", item) then
			minetest.chat_send_player(player:get_player_name(), S("You don't have enough space in your inventory to buy this."))
			minetest.remove_detached_inventory(temp_inv:get_location().name)
			return
		end
		temp_inv:add_item("main", item)
	end
	minetest.remove_detached_inventory(temp_inv:get_location().name)

	for _, item in pairs(shop_inv:get_list("for_sale")) do
		if not shop_has_infinite_stock(pos) then
			shop_inv:remove_item("stock", item)
		end
		player_inv:add_item("main", item)
	end
	hightech.tech_card.subtract(tech_card_id, price)
	hightech.tech_card.add(meta:get_string("seller_tech_card_id"), price)
	hightech.tech_card.save()
	minetest.chat_send_player(player:get_player_name(), S("@1 Techies were subtracted from your TechCard.", price))
	minetest.chat_send_player(player:get_player_name(), S("The items you have bought were put into your inventory."))
	shop_update_infotext(pos)
end

minetest.register_node(
	"hightech:shop",
	{
		description = S("Hightech Shop"),
		drawtype = "nodebox",
		node_box = {type = "fixed", fixed = {-0.5, -0.5, -0.0, 0.5, 0.5, 0.5}},
		tiles = {
			"hightech_shop_sides.png",
			"hightech_shop_sides.png",
			"hightech_shop_sides.png^[transformR90",
			"hightech_shop_sides.png^[transformR90",
			"hightech_shop_front.png",
			"hightech_shop_front.png",
		},
		paramtype2 = "facedir",
		paramtype = "light",
		groups = {cracky = 3, tubedevice = 1, tubedevice_receiver = 1},
		sounds = default.node_sound_stone_defaults(),
		after_place_node = shop_on_place,
		after_dig_node = shop_on_dig,
		on_rightclick = shop_on_use,
		on_punch = shop_on_punch,
		on_metadata_inventory_put = shop_on_inv_change,
		on_metadata_inventory_take = shop_on_inv_change,
		on_metadata_inventory_move = shop_on_inv_change,

		tube = {
			insert_object = function(pos, _, item)
				local meta = minetest.get_meta(pos)
				local inv = meta:get_inventory()
				return inv:add_item("stock", item)
			end,
			can_insert = function(pos, _, item, _, player_name)
				local meta = minetest.get_meta(pos)
				if not hightech.internal.is_allowed(pos, player_name) then
					return false
				end
				local inv = meta:get_inventory()
				return inv:room_for_item("stock", item)
			end,
			input_inventory = "stock",
			connect_sides = {left = 1, right = 1, back = 1, bottom = 1, top = 1},
		},
		allow_metadata_inventory_take = function(pos, _, _, item, player)
			if not hightech.internal.is_allowed(pos, player:get_player_name()) then
				return 0
			end
			return item:get_count()
		end,
	}
)

local ShopItemEntity = {
	initial_properties = {
		visual = "wielditem",
		visual_size = {x = 0.2, y = 0.2, z = 0.2},
		physical = false,
		pointable = false,
	},
}

function ShopItemEntity:set_item(item)
	self.object:set_properties({
		wield_item = item,
	})
	if item == "" then
		self.object:set_properties({
			visual_size = {x = 0, y = 0, z = 0},
		})
	else
		self.object:set_properties({
			visual_size = ShopItemEntity.initial_properties.visual_size,
		})
	end
end

function ShopItemEntity:get_staticdata()
  return minetest.serialize({item = self.object:get_properties().wield_item})
end

function ShopItemEntity:on_activate(staticdata)
  local data = minetest.deserialize(staticdata) or {}
  self:set_item(data.item or "")
end

minetest.register_entity("hightech:shop_item", ShopItemEntity)
