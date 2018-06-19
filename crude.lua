


local function check_drill_stack(opos) 
	local pos = vector.new(opos)
	pos.y = pos.y - 1
	
	while 1 == 1 do  
		if minetest.get_node(pos).name == "bitumen:drill_pipe" then
			-- noop
		else
			-- end of the stack
			break
		end
		pos.y = pos.y - 1
	end
	
	
	print("well depth: "..pos.y)
	
	return {x=pos.x, y=pos.y, z=pos.z}
	
end






minetest.register_node("bitumen:drill_pipe", {
	paramtype = "light",
	description = "Drill Pipe",
	tiles = {"default_copper_block.png",  "default_copper_block.png", "default_copper_block.png",
	         "default_copper_block.png", "default_copper_block.png",   "default_copper_block.png"},
	node_box = {
		type = "fixed",
		fixed = {
			--11.25
			{-0.49, -0.5, -0.10, 0.49, 0.5, 0.10},
			{-0.10, -0.5, -0.49, 0.10, 0.5, 0.49},
			--22.5
			{-0.46, -0.5, -0.19, 0.46, 0.5, 0.19},
			{-0.19, -0.5, -0.46, 0.19, 0.5, 0.46},
			-- 33.75
			{-0.416, -0.5, -0.28, 0.416, 0.5, 0.28},
			{-0.28, -0.5, -0.416, 0.28, 0.5, 0.416},
			--45
			{-0.35, -0.5, -0.35, 0.35, 0.5, 0.35},
		},
	},
	selection_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
		},
	},
	drawtype = "nodebox",
	groups = {cracky=3,oddly_breakable_by_hand=3 },
	legacy_facedir_simple = true,
	sounds = default.node_sound_wood_defaults(),
	on_punch = function(pos)
		check_drill_stack(pos)
	end,
})


minetest.register_node("bitumen:well_siphon", {
	paramtype = "light",
	description = "Well Siphon",
	tiles = {"default_bronze_block.png",  "default_bronze_block.png", "default_bronze_block.png",
	         "default_bronze_block.png", "default_bronze_block.png",   "default_bronze_block.png"},
	node_box = {
		type = "fixed",
		fixed = {
			--11.25
			{-0.49, -0.5, -0.10, 0.49, 0.5, 0.10},
			{-0.10, -0.5, -0.49, 0.10, 0.5, 0.49},
			--22.5
			{-0.46, -0.5, -0.19, 0.46, 0.5, 0.19},
			{-0.19, -0.5, -0.46, 0.19, 0.5, 0.46},
			-- 33.75
			{-0.416, -0.5, -0.28, 0.416, 0.5, 0.28},
			{-0.28, -0.5, -0.416, 0.28, 0.5, 0.416},
			--45
			{-0.35, -0.5, -0.35, 0.35, 0.5, 0.35},
		},
	},
	selection_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
		},
	},
	drawtype = "nodebox",
	groups = {cracky=3,oddly_breakable_by_hand=3 },
	legacy_facedir_simple = true,
	sounds = default.node_sound_wood_defaults(),
	on_construct = function(pos)
		
	end,
})


local function drill(pos)

	local dp = check_drill_stack(pos)
	
	local n = minetest.get_node(dp)
	
	if n.name == "ignore" then
		if minetest.forceload_block(pos, true) then
			print("forceload successful")
			minetest.emerge_area(pos, pos)
			local n = minetest.get_node(dp)
		else 
			print("forceload failed")
			return
		end
--		minetest.emerge_area(pos, pos)
	end
	
	
	if n.name == "bitumen:crude_oil" then
		pos.y = pos.y + 2
		minetest.set_node(pos, {name = "bitumen:crude_oil"})
		minetest.set_node_level(pos, 64)
	else
		print("drilling "..n.name)
		minetest.set_node(dp, {name = "bitumen:drill_pipe"})
	end
end


minetest.register_node("bitumen:drill_rig", {
	description = "Drill Rig",
	tiles = {"default_tin_block.png",  "default_steel_block.png", "default_steel_block.png",
	         "default_tin_block.png", "default_tin_block.png",   "default_steel_block.png"},
	paramtype2 = "facedir",
	groups = {cracky=2, petroleum_fixture=1},
	sounds = default.node_sound_wood_defaults(),
	can_dig = function(pos,player)
		return true
	end,
	
	on_timer = dcb_node_timer,
	on_punch = function(pos)
		drill(pos)
		
	end,
	
})


minetest.register_abm({
	nodenames = {"bitumen:drill_rig"},
	interval = 1,
	chance   = 1,
	action = function(pos, node, active_object_count, active_object_count_wider)
	print("trydrill")
		drill(pos)
		
	end
})


local function pump_oil(pos)
	
	local dp = check_drill_stack(pos)
	
	local n = minetest.get_node(dp)
	
	if n.name == "bitumen:crude_oil" then
		minetest.set_node(dp, {name="air"})
		
		pos.x = pos.x + 1
		minetest.set_node(pos, {name="bitumen:crude_oil"})
		minetest.set_node_level(pos, 64)
	end
end



minetest.register_node("bitumen:well_pump", {
	description = "Drill Rig",
	tiles = {"default_gold_block.png",  "default_steel_block.png", "default_copper_block.png",
	         "default_tin_block.png", "default_gold_block.png",   "default_steel_block.png"},
	paramtype2 = "facedir",
	groups = {cracky=2, petroleum_fixture=1},
	sounds = default.node_sound_wood_defaults(),
	can_dig = function(pos,player)
		return true
	end,
	
	on_timer = dcb_node_timer,
	on_punch = function(pos)
		pump_oil(pos)
		
	end,
	
})

