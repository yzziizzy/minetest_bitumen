--[[

Due to engine limitations with non-trivial technical hurdles, minetest
collision boxes can only occupy a 3x3x3 node space at most. To work 
around this limitation, magic invisible undiggable nodes are added to
fill in the shape of a mesh. The nodes are tracked in meta and removed
on destruction.

]]



bitumen.magic = {}



-- used to create a large collision box because minetest doesn't allow ones bigger than 3x3x3
minetest.register_node("bitumen:collision_node", {
	paramtype = "light",
	drawtype = "airlike",
-- 	drawtype = "node",
-- 	tiles = {"default_leaves.png"},
	walkable = true,
	sunlight_propagates = true,
-- 	groups = {choppy = 1},
})





local function add(a, b)
	return {
		x = a.x + b[1],
		y = a.y + b[2], -- wtf?
		z = a.z + b[3]
	}
end

bitumen.magic.set_nodes = function(pos, nodename, def)
	local set = {}
	
	for _,delta in ipairs(def) do
		
		local p = add(pos, delta)
		local n = minetest.get_node(p)
		local g = minetest.registered_nodes[n.name].groups
		if g and not g.bitumen_magic_proof then
		--	print("magic node at ".. minetest.pos_to_string(p))
			minetest.set_node(p, {name= nodename})
-- 			minetest.set_node(p, {name= "default:glass"})
			
			-- save the parent node
			local meta = minetest.get_meta(p)
			meta:set_string("magic_parent", minetest.serialize(pos))
			
			table.insert(set, p)
		end
	end
	
	-- save positions for all the magic nodes
	local meta = minetest.get_meta(pos)
	local oldset = meta:get_string("magic_children") or ""
	if oldset == "" then
		oldset = {}
	else
		oldset = minetest.deserialize(oldset)
	end
	
	for _,p in ipairs(set) do
		table.insert(oldset, p)
	end
	
	meta:set_string("magic_children", minetest.serialize(oldset))
end

bitumen.magic.set_collision_nodes = function(pos, def) 
	bitumen.magic.set_nodes(pos, "bitumen:collision_node", def)
end

bitumen.magic.gensphere = function(center, radius) 
	local out = {}
	
	for x = -radius, radius do 
	for y = -radius, radius do 
	for z = -radius, radius do 
		if math.sqrt(x * x + y * y + z * z) <= radius then 
			
			table.insert(out, {center[1]+x, center[2]+y, center[3]+z})
		end
	end
	end
	end
	
	return out
end

-- center is the base
bitumen.magic.gencylinder = function(center, radius, height) 
	local out = {}
	
	for x = -radius, radius do 
	for z = -radius, radius do 
		if math.sqrt(x * x + z * z) <= radius then 
			for y = 0, height do 
				table.insert(out, {center[1]+x, center[2]+y, center[3]+z})
			end
		end
	end
	end
	
	return out
end

bitumen.magic.gencube = function(low, high) 
	local out = {}
	
	for x = low[1], high[1] do 
	for y = low[2], high[2] do 
	for z = low[3], high[3] do 
		table.insert(out, {x, y, z})
	end
	end
	end
	
	return out
end


bitumen.magic.on_destruct = function(pos)
	local meta = minetest.get_meta(pos)
	local magic = meta:get_string("magic_children")
	if magic == nil then
		return
	end
	
	magic = minetest.deserialize(magic)
	if magic == nil then
		return
	end
	
	-- clean up all the magic
	for _,p in ipairs(magic) do
		minetest.set_node(p, {name = "air"})
	end
end
