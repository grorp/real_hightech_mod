-- hightech.internal.find_index returns the position where the value occurs in the table for the first time.
function hightech.internal.find_index(table, value)
	for i, v in pairs(table) do
		if v == value then
			return i
		end
	end
end

-- hightech.internal.starts_with checks whether the string starts with the specified prefix.
function hightech.internal.starts_with(str, prefix)
	return str:sub(1, #prefix) == prefix
end

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
