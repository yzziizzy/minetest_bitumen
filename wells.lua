










local function check_drill_stack(opos) 
	local pos = vector.new(opos)
	pos.y = pos.y - 1
	
	while 1 == 1 do  
		local name = minetest.get_node(pos).name
		if name == "bitumen:drill_pipe" then
		elseif name == "bitumen:drill_mud_extractor" then
		elseif name == "bitumen:drill_mud_injector" then
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





local function pushpos(t, v, p)
	local h = minetest.hash_node_position(p)
	if v[h] == nil then
		table.insert(t, p)
	end
end


local function find_blob_extent(startpos)
	
	local blob = {}
	local stack = {}
	local visited = {}
	local future = {}
--	local shell = {}
	
	
	local node = minetest.get_node(startpos)
	if node.name == "air" then
		return nil
	end
	
	local bname = node.name
	
	table.insert(stack, startpos)
	
	while #stack > 0 do
		
		local p = table.remove(stack)
		local ph = minetest.hash_node_position(p)
		
		--print("visiting "..minetest.pos_to_string(p))
		if p.x < startpos.x - 50
			or p.x > startpos.x + 50
			or p.y < startpos.y - 50
			or p.y > startpos.y + 50
			or p.z < startpos.z - 50
			or p.z > startpos.z + 50
		then
			print("got to extent")
			visited[ph] = 1
		end
		
		if visited[ph] == nil then
			
			print("visiting "..minetest.pos_to_string(p))
			
			local pn = minetest.get_node(p)
			if pn then
				if pn.name == "bitumen:crude_oil" or pn.name == "bitumen:crude_oil_full" then
					blob[ph] = {x=p.x, y=p.y, z=p.z}
					
					pushpos(stack, visited, {x=p.x+1, y=p.y, z=p.z})
					pushpos(stack, visited, {x=p.x-1, y=p.y, z=p.z})
					pushpos(stack, visited, {x=p.x, y=p.y+1, z=p.z})
					pushpos(stack, visited, {x=p.x, y=p.y-1, z=p.z})
					pushpos(stack, visited, {x=p.x, y=p.y, z=p.z+1})
					pushpos(stack, visited, {x=p.x, y=p.y, z=p.z-1})
					
					visited[ph] = 1
				elseif pn.name == "ignore" then
					if minetest.forceload_block(p, false) then
						print("forceload successful: ".. minetest.pos_to_string(p))
					else
						print("forceload failed: ".. minetest.pos_to_string(p))
					end
					
					table.insert(future, p)
				end
			else
				print("failed to get node")
			end
		end
	end
	
	
	for _,p in pairs(blob) do
		print("blob "..minetest.pos_to_string(p))
	end
	
--	for n,v in pairs(shell) do
--		print("shell "..n.." - ".. v)
--	end
	
	
	return blob--, shell
end




local function forceload_deposit(pos) 
-- 	minetest.emerge_area(dp, {x=dp.x, y=dp.y - 20, z=dp.z})
	find_blob_extent(pos)
end


local function drill(pos)
	
	local meta = minetest.get_meta(pos)
	local dp = meta:get_string("drilldepth") or ""
	print("dp" .. dump(dp))
	if dp == "" then
		dp = check_drill_stack(pos)
		meta:set_string("drilldepth", minetest.serialize(dp))
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
	
	local hit_oil = false
	if n.name == "ignore" then
		minetest.emerge_area(dp, {x=dp.x, y=dp.y - 20, z=dp.z})
		print("emerging " .. minetest.pos_to_string(dp))
		
		return
	elseif n.name == "bitumen:drill_pipe" or n.name == "bitumen:drill_mud_injector" or n.name == "bitumen:drill_mud_extractor"then
		dp = check_drill_stack(dp)
	elseif n.name == "bitumen:crude_oil" or n.name == "bitumen:crude_oil_full" then
		pos.y = pos.y + 2
		minetest.set_node(pos, {name = "bitumen:crude_oil"})
		minetest.set_node_level(pos, 64)
		hit_oil = true
	else
		print("drilling at "..dp.y.." of "..n.name )
		minetest.set_node(dp, {name = "bitumen:drill_pipe"})
	end
	
	meta:set_string("drilldepth", minetest.serialize(dp))
	
	local desc = minetest.registered_nodes[n.name].description
	if n.name == "air" then
		desc = "Air" -- because of a cheeky description in the default game
	end
	
	return desc, dp.y, hit_oil
end


minetest.register_node("bitumen:drill_controls", {
	description = "Drilling Controls",
	tiles = {"default_bronze_block.png",  "default_bronze_block.png", "default_bronze_block.png",
	         "default_bronze_block.png", "default_bronze_block.png",   "default_bronze_block.png"},
	drawtype = "normal",
	paramtype = "light",
	paramtype2 = "facedir",
	groups = { }, -- undiggable: part of the drill rig
	sounds = default.node_sound_wood_defaults(),
	
	on_receive_fields = function(pos, form, fields, player)
		
		local cmd = "none"
		if fields.drill then
			cmd = "drill"
		elseif fields.retract then
			cmd = "retract"
		elseif fields.stop then
			cmd = "stop"
		elseif fields.pump then
			cmd = "pump"
		elseif fields.up then
			cmd = "up"
		elseif fields.down then
			cmd = "down"
		elseif fields.explore then
			cmd = "explore"
		elseif fields.forceload then
			cmd = "forceload"
		elseif fields.un_forceload then
			cmd = "un_forceload"
		end
		
		if cmd ~= "none" then
			local meta = minetest.get_meta(pos)
			local dpos = minetest.deserialize(meta:get_string("magic_parent"))
			local dmeta = minetest.get_meta(dpos)
			--print(dump(dpos))
			
			--if 1==1 then return end
			local state = minetest.deserialize(dmeta:get_string("state")) 
			
			state.command = cmd
			dmeta:set_string("state", minetest.serialize(state))
		end
	end,
	
-- 	on_rick_click = function(pos, node, player, itemstack, pointed_thing)
-- 		minetest.show_formspec(player:get_player_name(), fs)]]
-- 		return itemstack -- don't take anything
-- 	end,
})

minetest.register_node("bitumen:drill_pipe_chest", {
	description = "Drilling Controls",
	tiles = {"default_bronze_block.png",  "default_bronze_block.png", "default_bronze_block.png",
	         "default_bronze_block.png", "default_bronze_block.png",   "default_bronze_block.png"},
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "facedir",
	node_box = {
		type = "fixed",
		fixed = {
			{ -.5, -1.5, -.5, .5, 1.5, .5 },
		},
 	},
	selection_box = {
		type = "fixed",
		fixed = {
			{ -.5, -1.5, -.5, .5, 1.5, .5 },
		},
 	},
	collision_box = {
		type = "fixed",
		fixed = {
			{ -.5, -1.5, -.5, .5, 1.5, .5 },
		},
 	},
	groups = { }, -- undiggable: part of the drill rig
	sounds = default.node_sound_wood_defaults(),
	
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		
		inv:set_size("main", 4*8)
	end,
	
})


minetest.register_node("bitumen:drill_mud_injector", {
	description = "Drilling Mud Injector",
	tiles = {"default_bronze_block.png",  "default_bronze_block.png", "default_bronze_block.png",
	         "default_bronze_block.png", "default_bronze_block.png",   "default_bronze_block.png"},
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "facedir",
	node_box = {
		type = "fixed",
		fixed = {
			{ -.5, -.5, -.5, .5, .5, .5 },
		},
 	},
	selection_box = {
		type = "fixed",
		fixed = {
			{ -.5, -.5, -.5, .5, .5, .5 },
		},
 	},
	collision_box = {
		type = "fixed",
		fixed = {
			{ -.5, -.5, -.5, .5, .5, .5 },
		},
 	},
	groups = { petroleum_fixture=1 }, -- undiggable: part of the drill rig
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_node("bitumen:drill_mud_extractor", {
	description = "Drilling Mud Extractor",
	tiles = {"default_bronze_block.png",  "default_bronze_block.png", "default_bronze_block.png",
	         "default_bronze_block.png", "default_bronze_block.png",   "default_bronze_block.png"},
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "facedir",
	node_box = {
		type = "fixed",
		fixed = {
			{ -.5, -.5, -.5, .5, .5, .5 },
		},
 	},
	selection_box = {
		type = "fixed",
		fixed = {
			{ -.5, -.5, -.5, .5, .5, .5 },
		},
 	},
	collision_box = {
		type = "fixed",
		fixed = {
			{ -.5, -.5, -.5, .5, .5, .5 },
		},
 	},
	groups = { petroleum_fixture=1 }, -- undiggable: part of the drill rig
	sounds = default.node_sound_wood_defaults(),
})



minetest.register_node("bitumen:drill_rig", {
	description = "Drill Rig",
	paramtype = "light",
	drawtype = "mesh",
	mesh = "oil_derrick.obj",
	description = "Drilling Derrick",
	inventory_image = "bitumen_cement_mixer_invimg.png",
	tiles = {
		"default_obsidian_block.png",
	},
 	selection_box = {
		type = "fixed",
		fixed = {
			{ -.5, -.5, -.5, .5, 1.5, .5 },
		},
 	},
 	collision_box = {
		type = "fixed",
		fixed = {
			{ -.5, -.5, -.5, .5, 1.5, .5 },
-- 			{ -1.5, -1.5, -1.5, -1.4, 3, -1.4 },
-- 			{ 1.5, -1.5, -1.5, 1.4, 3, -1.4 },
-- 			{ -1.5, -1.5, 1.5, -1.4, 3, 1.4 },
-- 			{ 1.5, -1.5, 1.5, 1.4, 3, 1.4 },
-- 			{ 1.5, 1.5, 1.5, -1.5, 4.5, -1.5 },
		}
 	},
	paramtype2 = "facedir",
	groups = {choppy=1 },
	sounds = default.node_sound_wood_defaults(),
	
	on_timer = dcb_node_timer,
	
	on_construct = function(pos)
		bitumen.magic.set_collision_nodes(pos, {
			{3, -2, 3}, {3, -1, 3},
			{3, -2, -3}, {3, -1, -3},
			{-3, -2, 3}, {-3, -1, 3},
			{-3, -2, -3}, {-3, -1, -3},
			
			{-2, 0, -2}, {-2, 0, -1}, {-2, 0, 0}, {-2, 0, 1}, {-2, 0, 2},
			{2, 0, -2}, {2, 0, -1}, {2, 0, 0}, {2, 0, 1}, {2, 0, 2},
			{-1, 0, -2}, {0, 0, -2}, {1, 0, -2},
			{-1, 0, 2}, {0, 0, 2}, {1, 0, 2},
			
			{0, 9, 0},
			{0, 8, 0},
		})
		
		bitumen.magic.set_collision_nodes(pos, bitumen.magic.gencube({1, 1, 1}, {1, 7, 1})) 
		bitumen.magic.set_collision_nodes(pos, bitumen.magic.gencube({1, 1, -1}, {1, 7, -1})) 
		bitumen.magic.set_collision_nodes(pos, bitumen.magic.gencube({-1, 1, 1}, {-1, 7, 1})) 
		bitumen.magic.set_collision_nodes(pos, bitumen.magic.gencube({-1, 1, -1}, {-1, 7, -1})) 
		
		
		local controls_delta = {1, 2, 0}
		local pipe_chest_delta = {0, 2, 1}
		local mud_injector_delta = {0, -1, 0}
		local mud_extractor_delta = {0, -2, 0}
		
		bitumen.magic.set_nodes(pos, "bitumen:drill_controls", {controls_delta})
		bitumen.magic.set_nodes(pos, "bitumen:drill_pipe_chest", {pipe_chest_delta})
		bitumen.magic.set_nodes(pos, "bitumen:drill_mud_injector", {mud_injector_delta})
		bitumen.magic.set_nodes(pos, "bitumen:drill_mud_extractor", {mud_extractor_delta})
		
		local function add(p, d)
			return {x=p.x + d[1], y=p.y + d[2], z=p.z + d[3]}
		end
		
		local altnodes = {
			controls = add(pos, controls_delta),
			pipe_chest = add(pos, pipe_chest_delta),
			mud_injector = add(pos, mud_injector_delta),
			mud_extractor = add(pos, mud_extractor_delta),
		}
		
		
		local pcmeta = minetest.get_meta(altnodes.pipe_chest)
		local pcinv = pcmeta:get_inventory()
		pcinv:set_size("main", 8*32)
		
		
		local pipe_chest_formspec =
			"size[8,9;]" ..
			default.gui_bg ..
			default.gui_bg_img ..
			default.gui_slots ..
			"list[context;main;0,0.3;8,4;]" ..
			"list[current_player;main;0,4.85;8,1;]" ..
			"list[current_player;main;0,6.08;8,3;8]" ..
			"listring[context;main]" ..
			"listring[current_player;main]" ..
			default.get_hotbar_bg(0, 4.85)
		
		pcmeta:set_string("formspec", pipe_chest_formspec)
		
		
		local state = {
			state = "idle",
			command = "none",
			depth = pos.y - 3, -- depth of the next non-pipe node
			max_depth = pos.y - 3,
			forceload_oil = false, -- forceload the oil field to make the fluids flow
			last_drilled_node = "none"
		}
		
		local meta = minetest.get_meta(pos)
		meta:set_string("altnodes", minetest.serialize(altnodes))
		meta:set_string("state", minetest.serialize(state))
		meta:set_string("drilldepth", minetest.serialize(add(pos, {0, -3, 0})))
	end,
	
	on_destruct = bitumen.magic.on_destruct,
	
-- 	on_punch = function(pos)
-- 		drill(pos)
-- 	end,
	
})

local function get_controls_formspec(state)
	
	local up_down = ""
	if state.state == "idle" then
		up_down = "button[5,3;4,1;up;Up One]" ..
			"button[5,4;4,1;down;Down One]"
	end
	
	local stop = ""
	if state.state ~= "idle" then
		stop = "button[5,0;4,1;stop;Stop]"
	end

	local drill = ""
	if state.state ~= "drilling" then
		drill = "button[5,1;4,1;drill;Drill]"
	end
	
	local retract= ""
	if state.state ~= "retracting" then
		retract = "button[5,2;4,1;retract;Retract Pipe]"
	end
	
	local forceload= ""
	if state.state ~= "forceload" then
		forceload = "button[5,3;4,1;forceload;Forceload]"
	end

	local pump= ""
	if state.state ~= "pump" then
		pump = "button[5,4;4,1;pump;Pump]"
	end
	
	local state_strings = {
		drilling = "Drilling",
		retracting = "Retracting",
		idle = "Idle",
		pump = "Pumping",
	}
	
	local state_str = state_strings[state.state] or "None"
	
	
	return "" ..
		"size[10,8;]" ..
		default.gui_bg ..
		default.gui_bg_img ..
		default.gui_slots ..
		"label[1,1;"..state_str.."]" ..
		"label[1,2;Last Node: "..(state.last_drilled_node or "none").."]" ..
		"label[1,3;Depth: "..state.depth.."]" ..
		stop ..
		drill ..
		retract ..
		up_down ..
		forceload ..
		pump ..
		""
end


local function retract(pos)
	
	local meta = minetest.get_meta(pos)
	local dp = meta:get_string("drilldepth") or ""
	
	if dp == "" then
		dp = check_drill_stack(pos)
		meta:set_string("drilldepth", minetest.serialize(dp))
	else
		dp = minetest.deserialize(dp)
		--print("deserialized " .. dump(pos))
		--dp.y = dp.y - 1
	end
	
	
	local n = minetest.get_node(dp)
	
	
	if n.name == "ignore" then
		if minetest.forceload_block(dp, true) then
			print("forceload successful: ".. minetest.pos_to_string(dp))
			
			local n = minetest.get_node(dp)
		end
--		minetest.emerge_area(pos, pos)
	end
	
	local removed = false
	if n.name == "ignore" then
		minetest.emerge_area(dp, {x=dp.x, y=dp.y - 20, z=dp.z})
		print("emerging " .. minetest.pos_to_string(dp))
		return dp.y, false, false
	elseif n.name == "bitumen:drill_pipe" then
		minetest.set_node(dp, {name = "air"})
		removed = true
	elseif n.name == "bitumen:drill_mud_injector" or n.name == "bitumen:drill_mud_extractor"then
		return dp.y, false, true
	else
		print("retract at "..dp.y.." of "..n.name )
	end
	
	
	dp.y = dp.y + 1
	meta:set_string("drilldepth", minetest.serialize(dp))
	
	return dp.y, removed, false
end


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

minetest.register_abm({
	nodenames = {"bitumen:drill_rig"},
	interval = 2,
	chance   = 1,
	action = function(pos, node, active_object_count, active_object_count_wider)
	--print("trydrill")
		
		--if 1==1 then return end
		
		local meta = minetest.get_meta(pos)
		local state = minetest.deserialize(meta:get_string("state"))
		local alts = minetest.deserialize(meta:get_string("altnodes"))
-- 		print(dump(alts))
		
		if alts == nil then
			--print("\n\nnull alts: "..dump(pos).."\n\n")
			return 
		end
		
		
		local inch = 0
		if state.command ~= "none" then
			if state.command == "drill" then
				state.state = "drilling"
			elseif state.command == "retract" then
				state.state = "retracting"
			elseif state.command == "stop" then
				state.state = "idle"
			elseif state.command == "pump" then
				print("set to pump")
				state.state = "pump"
			elseif state.command == "explore" then
				state.state = "idle"
				
				-- explore extent of oil deposit
			elseif state.command == "forceload" then
				state.state = "idle"
				
				forceload_deposit({x=pos.x, y = state.depth - 1, z=pos.z})
				-- do forceload
			elseif state.command == "un_forceload" then
				state.state = "idle"
				
				-- undo forceload
			elseif state.command == "up" then
				state.state = "idle"
				inch = 1
			elseif state.command == "down" then
				state.state = "idle"
				inch = -1
			end
			
			state.command = "none"
		end
		
		
		local pcmeta, pcinv 
		if state.state == "drilling" or state.state == "retracting" then
			pcmeta = minetest.get_meta(alts.pipe_chest)
			pcinv = pcmeta:get_inventory()
		end
		
		
		if state.state == "drilling" or inch == -1 then
			local pcmeta = minetest.get_meta(alts.pipe_chest)
			local pcinv = pcmeta:get_inventory()
			
			if pcinv:contains_item("main", "bitumen:drill_pipe 1") then
			
				local n, y, hit_oil = drill(pos)
				if n then
					state.last_drilled_node = n
					state.depth = y
					state.max_depth = math.min(y, state.max_depth or y)
					
					pcinv:remove_item("main", "bitumen:drill_pipe 1")
					
					if hit_oil and inch == 0 then
						state.state = "idle"
					end
				end
			else
				-- out of pipe
				state.state = "idle"
			end
		elseif state.state == "retracting" or inch == 1 then
			local y, removed, ended
			
			for i = 1,3 do
				y, removed, ended = retract(pos)
				if removed then
					pcinv:add_item("main", "bitumen:drill_pipe")
				end
				
				state.depth = y
				
				if ended or inch == 1 then
					break
				end
			end
			
		elseif state.state == "pump" then
			local expos = alts.mud_extractor
			expos.x = expos.x + 1
			local exnet = bitumen.pipes.get_net(expos)
			if exnet and (exnet.fluid == "bitumen:crude_oil" or exnet.fluid == "air") then
				-- pump oil
				local dp = {x=pos.x, y = state.depth - 1, z=pos.z}
				local n = minetest.get_node(dp)
				
				if n.name == "bitumen:crude_oil" or n.name == "bitumen:crude_oil_full" then
-- 					minetest.set_node(dp, {name="air"})
					
-- 					local expos = alts.mud_extractor
-- 					expos.x = expos.x + 1
					local p = bitumen.pipes.push_fluid(expos, "bitumen:crude_oil", 15, 20)
					--print("pushed " .. p)
				end
				
				
			else
				-- must empty the mud out of the pipe first
				
				print("well not connected " .. dump(exnet))
			end
			
		end
		
		-- update the control box formspec
		local control_meta = minetest.get_meta(alts.controls)
		control_meta:set_string("formspec", get_controls_formspec(state))
		
		meta:set_string("state", minetest.serialize(state))
	end
})






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















local rig_builder_formspec =
	"size[10,8;]" ..
	default.gui_bg ..
	default.gui_bg_img ..
	default.gui_slots ..
	"list[context;main;0,0.3;4,3;]" ..
	"button[5,1;1,4;build;Build]" ..
	"list[current_player;main;0,3.85;8,1;]" ..
	"list[current_player;main;0,5.08;8,3;8]" ..
	"listring[context;main]" ..
	"listring[current_player;main]" ..
	default.get_hotbar_bg(0, 3.85)




minetest.register_node("bitumen:oil_rig_constructor", {
	description = "Oil Rig Constructor",
	drawtype = "normal",
	paramtype2 = "facedir",
	on_rotate = screwdriver.rotate_simple,
	groups = {cracky=1},
	tiles = {
		"default_copper_block.png","default_tin_block.png",
	},
	
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		inv:set_size("main", 12)
		
		meta:set_string("formspec", rig_builder_formspec);
	end,
	

	on_receive_fields = function(pos, form, fields, player)
		
		local meta = minetest.get_meta(pos)
		
		if fields.build then
			-- tanks can only be built on thick foundations
--[[
			local ret = check_foundation(
				{x = pos.x - 9, y = pos.y - 3, z = pos.z - 9},
				{x = pos.x + 9, y = pos.y - 1, z = pos.z + 9},
				{
					["default:stone"] = 1,
					["bitumen:concrete"] = 1,
				}
			)
			
			if ret == false then
				minetest.chat_send_player(player:get_player_name(), "Foundation is incomplete: 10x10x3")
				return
			else
				minetest.chat_send_player(player:get_player_name(), "Foundation is complete.")
			end
			]]
-- 			local inv = meta:get_inventory();
-- 			
-- 			if inv:contains_item("main", "default:steelblock 8") then
-- 				
-- 				inv:remove_item("main", "default:steelblock 8")
-- 			else
-- 				minetest.chat_send_player(player:get_player_name(), "Not enough materials: 8x SteelBlock")
-- 				return
-- 			end
			
			-- ready to go
			minetest.chat_send_player(player:get_player_name(), "Clear area, construction starting...")
			
			minetest.after(5, function()
				minetest.set_node({x=pos.x, y=pos.y + 2, z=pos.z}, {name="bitumen:drill_rig"})
			end)
		end
	end,
})


bitumen.register_blueprint({name="bitumen:drill_rig"})


minetest.register_craft({
	output = 'bitumen:oil_rig_constructor',
	recipe = {
		{'default:steelblock', 'default:steelblock', 'default:steelblock'},
		{'default:steelblock', 'bitumen:drill_rig_blueprint', 'default:steelblock'},
		{'default:steelblock', 'default:steelblock', 'default:steelblock'},
	}
})




