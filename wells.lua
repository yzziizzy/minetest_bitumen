



bitumen.register_fluid("bitumen", "drill_mud", {
	desc = "Drilling Mud",
	groups = {petroleum=1},
	
	reflow_interval = 5,
	reflow_chance = 1,
	flow_interval = 1,
	flow_chance = 1,
	
	colorize = "^[colorize:brown:40",
	post_effect_color = {a = 103, r = 80, g = 76, b = 90},
	
	evap_chance = 0,
})

bitumen.register_fluid("bitumen", "drill_mud_dirty", {
	desc = "Dirty Drilling Mud",
	groups = {petroleum=1},
	
	reflow_interval = 5,
	reflow_chance = 1,
	flow_interval = 1,
	flow_chance = 1,
	
	colorize = "^[colorize:brown:140",
	post_effect_color = {a = 103, r = 80, g = 76, b = 90},
	
	evap_chance = 0,
})











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
	
	
	print("check stack well depth: "..pos.y)
	
	return {x=pos.x, y=pos.y, z=pos.z}
	
end




local function mul(t, x)
	local o = {}
	
	for n,i in ipairs(t) do
		o[n] = i * x
	end
	
	o[2] = o[2] / x
	o[5] = o[5] / x
	
	return o
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
			mul({-0.49, -0.5, -0.10, 0.49, 0.5, 0.10}, .3),
			mul({-0.10, -0.5, -0.49, 0.10, 0.5, 0.49}, .3),
			--22.5
			mul({-0.46, -0.5, -0.19, 0.46, 0.5, 0.19}, .3),
			mul({-0.19, -0.5, -0.46, 0.19, 0.5, 0.46}, .3),
			-- 33.75
			mul({-0.416, -0.5, -0.28, 0.416, 0.5, 0.28}, .3),
			mul({-0.28, -0.5, -0.416, 0.28, 0.5, 0.416}, .3),
			--45
			mul({-0.35, -0.5, -0.35, 0.35, 0.5, 0.35}, .3),
		},
	},
	selection_box = {
		type = "fixed",
		fixed = {
			mul({-0.5, -0.5, -0.5, 0.5, 0.5, 0.5}, .3),
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



minetest.register_craft({
	output = 'bitumen:drill_pipe 12',
	recipe = {
		{'default:steel_ingot', '', 'default:steel_ingot'},
		{'default:steel_ingot', '', 'default:steel_ingot'},
		{'default:steel_ingot', '', 'default:steel_ingot'},
	}
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
	
	local meta = minetest.get_meta(pos)
	local dp = meta:get_string("drilldepth") or ""
	--print("dp" .. dump(dp))
	if dp == "" then
		dp = check_drill_stack(pos)
	else
		dp = minetest.deserialize(dp)
		--print("deserialized " .. dump(pos))
		dp.y = dp.y - 1
	end
	
	local n = minetest.get_node(dp)
	
	
	if n.name == "ignore" then
		if minetest.forceload_block(dp, true) then
			print("forceload successful: ".. minetest.pos_to_string(dp))
			
			local n = minetest.get_node(dp)
		else 
			--minetest.emerge_area(dp, {x=dp.x, y=dp.y - 20, z=dp.z})
		--	print("forceload failed, emerging " .. minetest.pos_to_string(dp))
		--	return
		end
--		minetest.emerge_area(pos, pos)
	end
	
	
	if n.name == "ignore" then
		minetest.emerge_area(dp, {x=dp.x, y=dp.y - 20, z=dp.z})
		print("emerging " .. minetest.pos_to_string(dp))
		
		return
	elseif n.name == "bitumen:drill_pipe" then
		dp = check_drill_stack(pos)
	elseif n.name == "bitumen:crude_oil" or n.name == "bitumen:crude_oil_full" then
		pos.y = pos.y + 2
		minetest.set_node(pos, {name = "bitumen:crude_oil"})
		minetest.set_node_level(pos, 64)
	else
		print("drilling at "..dp.y.." of "..n.name )
		minetest.set_node(dp, {name = "bitumen:drill_pipe"})
	end
	
	meta:set_string("drilldepth", minetest.serialize(dp))
	
	
	
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
	--print("trydrill")
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

