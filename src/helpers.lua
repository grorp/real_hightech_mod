local contexts = {}

-- hightech.internal.get_context returns a table where you can store temporary data belonging to the specified player.
-- The table is not preserved across server restarts.
function hightech.internal.get_context(player)
	local context = contexts[player:get_player_name()] or {}
	contexts[player:get_player_name()] = context
	return context
end

minetest.register_on_leaveplayer(function(player)
	contexts[player:get_player_name()] = nil
end)

-- hightech.internal.get_node_force returns the node at the specified position.
-- If necessary, the node is loaded from disk beforehand.
function hightech.internal.get_node_force(pos)
	local node = minetest.get_node_or_nil(pos)
	if node == nil then
		minetest.load_area(pos)
		node = minetest.get_node_or_nil(pos)
	end
	return node
end

-- hightech.internal.is_allowed checks whether the specified player is allowed to interact with the node at the specified position.
function hightech.internal.is_allowed(pos, player_name)
	if minetest.check_player_privs(player_name, { protection_bypass = true }) then
		return true
	end
	local meta = minetest.get_meta(pos)
	if meta:get_string("owner") == player_name then
		return true
	end
	return false
end

hightech.internal.str = {}

-- hightech.internal.str.has_prefix checks whether the string starts with the specified prefix.
function hightech.internal.str.has_prefix(str, prefix)
	return str:sub(1, #prefix) == prefix
end

-- hightech.internal.str.strip_prefix removes the specified prefix from the string.
function hightech.internal.str.strip_prefix(str, prefix)
	return string.sub(str, #prefix + 1)
end

hightech.internal.table = {}

-- hightech.internal.table.find_index returns the position where the value occurs in the table for the first time.
function hightech.internal.table.find_index(table, value)
	for i, v in pairs(table) do
		if v == value then
			return i
		end
	end
end

-- hightech.internal.table.concat appends the second table to the end of the first table and returns the result.
function hightech.internal.table.concat(t1, t2)
  for i = 1, #t2 do
    t1[#t1 + 1] = t2[i]
  end
  return t1
end

-- hightech.internal.table.reverse returns the table in reverse order.
function hightech.internal.table.reverse(t)
	local r = {}
	for i = #t, 1, -1 do
		r[#r + 1] = t[i]
	end
	return r
end
