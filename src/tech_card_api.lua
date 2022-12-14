local storage = minetest.get_mod_storage()
local tech_cards = minetest.deserialize(storage:get_string("tech_cards"))
if tech_cards == nil then
	tech_cards = {}
end
local current_index = storage:get_int("tech_cards_current_index")
if current_index == 0 then
	current_index = 1
end

hightech.tech_card = {}

-- hightech.tech_card.save persists the TechCard data.
function hightech.tech_card.save()
	storage:set_string("tech_cards", minetest.serialize(tech_cards))
	storage:set_int("tech_cards_current_index", current_index)
end

-- hightech.tech_card.new creates a new TechCard and returns its ID.
-- Note: You must call hightech.tech_card.save afterwards!
function hightech.tech_card.new()
	local id = string.format("%012x", current_index)
	tech_cards[id] = {
		balance = 0,
	}
	current_index = current_index + 1
	return id
end

-- hightech.tech_card.exists checks if there is a TechCard with the specified ID.
function hightech.tech_card.exists(id)
	return tech_cards[id] ~= nil
end

-- hightech.tech_card.get_balance returns the balance of the TechCard with the specified ID.
function hightech.tech_card.get_balance(id)
	return tech_cards[id].balance
end

-- hightech.tech_card.add adds the specified amount of Techies to the TechCard with the specified ID.
-- Note: You must call hightech.tech_card.save afterwards!
function hightech.tech_card.add(id, amount)
	tech_cards[id].balance = tech_cards[id].balance + amount
end

-- hightech.tech_card.subtract subtracts the specified amount of Techies from the TechCard with the specified ID.
-- Note: You must call hightech.tech_card.save afterwards!
function hightech.tech_card.subtract(id, amount)
	tech_cards[id].balance = tech_cards[id].balance - amount
end

-- hightech.tech_card.can_subtract checks if the specified amount of Techies can be subtracted from the TechCard with the specified ID.
function hightech.tech_card.can_subtract(id, amount)
	if tech_cards[id].balance >= amount then
		return true
	else
		return false
	end
end

-- hightech.internal.is_int checks whether the given number is an integer.
function hightech.internal.is_int(n)
	return n == math.floor(n)
end
