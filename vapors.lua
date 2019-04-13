

-- more concentrated
minetest.register_node("bitumen:vapor_2", {
	description = "Vapor",
	drawtype = "airlike",
	pointable = false,
	diggable = false,
	walkable = false,
	buildable_to = true,
	paramtype = "light",  
	sunlight_propagates = true, 
-- 	post_effect_color = info.post_effect_color,

-- 	tiles = { "default_copper_block.png" },
	groups = { not_in_creative_inventory = 1, bitumen_vapor = 1 },
})


-- less concentrated
minetest.register_node("bitumen:vapor_1", {
	description = "Vapor",
	drawtype = "airlike",
	pointable = false,
	diggable = false,
	walkable = false,
	buildable_to = true,
	paramtype = "light",  
	sunlight_propagates = true,
-- 	tiles = { "default_steel_block.png" },
	groups = { not_in_creative_inventory = 1, bitumen_vapor = 1 },
})


--[[ for testing
minetest.register_node("bitumen:vapor_gen", {
	description = "Vapor Generator",
	tiles = { "default_steel_block.png" },
	groups = { cracky = 1 },
})




minetest.register_abm({
	nodenames = {"bitumen:vapor_gen"},
	neighbors = {"air"},
	interval = 3,
	chance   = 1,
	action = function(pos, node, active_object_count, active_object_count_wider)
		pos.y = pos.y + 1
		
		minetest.set_node(pos, {name="bitumen:vapor_2"})
	end
})

]]



-- move around randomly
minetest.register_abm({
	nodenames = {"bitumen:vapor_2", "bitumen:vapor_1"},
	neighbors = {"air"},
	interval = 4,
	chance   = 8,
	action = function(pos, node, active_object_count, active_object_count_wider)
		
		local name = node.name
		
		local air_nodes = minetest.find_nodes_in_area(
			{x=pos.x - 1, y=pos.y - 1, z=pos.z - 1},
			{x=pos.x + 1, y=pos.y, z=pos.z + 1},
			"air"
		)
		
		--  try to go down first
		if #air_nodes > 0 and math.random(6) > 1 then
			local off = math.random(#air_nodes)
			--print("off "..dump(off).. " - " .. dump(#air_nodes))
			minetest.set_node(pos, {name="air"})
			minetest.set_node(air_nodes[off], {name=name})
			
			return
		end
		
		-- go up if there's no down
		air_nodes = minetest.find_nodes_in_area(
			{x=pos.x - 1, y=pos.y + 1, z=pos.z - 1},
			{x=pos.x + 1, y=pos.y + 1, z=pos.z + 1},
			"air"
		)
		
		if #air_nodes > 0 then
			local off = math.random(#air_nodes)
			
			minetest.set_node(pos, {name="air"})
			minetest.set_node(air_nodes[off], {name=name})
		end
	end
})

-- diffuse away completely
minetest.register_abm({
	nodenames = {"bitumen:vapor_1"},
	neighbors = {"air"},
	interval = 8,
	chance   = 16,
	action = function(pos, node)
		local air_nodes = minetest.find_nodes_in_area(
			{x=pos.x - 1, y=pos.y - 1, z=pos.z - 1},
			{x=pos.x + 1, y=pos.y + 1, z=pos.z + 1},
			"air"
		)
		
		if #air_nodes > 12 then
			minetest.set_node(pos, {name="air"})
		end
	end
})

-- diffuse
minetest.register_abm({
	nodenames = {"bitumen:vapor_2"},
	neighbors = {"air"},
	interval = 4,
	chance   = 4,
	action = function(pos, node, active_object_count, active_object_count_wider)
		
		
		local air_nodes = minetest.find_nodes_in_area(
			{x=pos.x - 1, y=pos.y - 1, z=pos.z - 1},
			{x=pos.x + 1, y=pos.y + 1, z=pos.z + 1},
			"air"
		)
		
		if #air_nodes > 0 then
			local off = math.random(#air_nodes)
			--print("off "..dump(off).. " - " .. dump(#air_nodes))
			minetest.set_node(pos, {name="bitumen:vapor_1"})
			minetest.set_node(air_nodes[off], {name="bitumen:vapor_1"})
		end
		
	end
})



-- go up in flames
minetest.register_abm({
	nodenames = {"bitumen:vapor_1", "bitumen:vapor_2"},
	neighbors = {"group:igniter", "default:torch", "default:furnace_active"},
	interval = 1,
	chance   = 3,
	action = function(pos, node, active_object_count, active_object_count_wider)
		
		local air_nodes = minetest.find_nodes_in_area(
			{x=pos.x - 1, y=pos.y - 1, z=pos.z - 1},
			{x=pos.x + 1, y=pos.y + 1, z=pos.z + 1},
			{"air", "group:flammable"}
		)
		
		if #air_nodes > 0 then
			
			local off = math.random(#air_nodes)
			local num = math.random(#air_nodes / 2)
			
			for i = 1,num do
				--local theirlevel = minetest.get_node_level(fp)
				local fp = air_nodes[((i + off) % #air_nodes) + 1]
				
				minetest.set_node(fp, {name="fire:basic_flame"})
			end
		end
		
		minetest.set_node(pos, {name="fire:basic_flame"})
	
	end
})



