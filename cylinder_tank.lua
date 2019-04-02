


local function check_tank_foundation(bpos)
	local meta = minetest.get_meta(bpos)
	local height = meta:get_int("height")
	
	if height < 1 then
		return
	end
	
	local d = math.ceil(height / 5)
	
	local ret = bitumen.check_foundation(
		{x = bpos.x - 2, y = bpos.y - 1 - d, z = bpos.z - 2},
		{x = bpos.x + 2, y = bpos.y - 2    , z = bpos.z + 2},
		{
			["default:stone"] = 1,
			["default:desert_stone"] = 1,
			["default:steelblock"] = 1,
			["bitumen:concrete"] = 1,
		}
	)
	
	if ret == true then 
		return true 
	end
	
	-- try for the steel foundation
	ret = bitumen.check_foundation(
		{x = bpos.x - 1, y = bpos.y - 1 - d, z = bpos.z - 1},
		{x = bpos.x + 1, y = bpos.y - 1    , z = bpos.z + 1},
		{ ["default:steelblock"] = 1 }
	)
	
	if not ret then
		return false
	end
	-- todo: check steel legs
	
	
	return true
end


-- check poor foundation
minetest.register_abm({
	nodenames = {"bitumen:cylinder_tank_bottom"},
	interval = 30,
	chance   = 10,
	action = function(pos)
		if not check_tank_foundation(pos) then
			--print("tank failure")
			
			local meta = minetest.get_meta(pos)
			local fill = meta:get_int("fill")
			local height = meta:get_int("height")
			
			if height < 2 then
				-- no middle segments
				return
			end
			
			local fillh = math.ceil(fill / (9 * 60)) 
			
			local y = math.random(1, fillh)
			minetest.set_node({x=pos.x, y=pos.y+y, z=pos.z}, {name="bitumen:cylinder_tank_cracked"})
			
		end
	end
})


local function try_add_fluid(tpos)

	-- find the bottom node
	local tmeta = minetest.get_meta(tpos)
	local rbpos = tmeta:get_string("bpos")
	if not rbpos then
		return
	end
	
	
	-- grab the input network
	local npos = {x=tpos.x, y=tpos.y+1, z=tpos.z}
	local tnet = bitumen.pipes.get_net(npos)
	if not tnet or not tnet.fluid or tnet.fluid == "air" then
		return
	end
	
	-- all the data is in the bottom node
	local bpos = minetest.deserialize(rbpos)
	local bmeta = minetest.get_meta(bpos)
	local fill = bmeta:get_int("fill")
	local capacity = bmeta:get_int("capacity")
	local fluid = bmeta:get_string("fluid")
	
	-- check for full
	if fill >= capacity then
		return
	end
	
	if fill > 0 and fluid ~= tnet.fluid then
		return
	end
	
	local remcap = capacity - fill
	
	
	local taken, tfluid = bitumen.pipes.take_fluid(npos, remcap)
	if taken == 0 then
		return
	end
	
	-- set or change fluids
	if fluid == "air" or fill == 0 then
		bmeta:set_string("fluid", tfluid)
		tmeta:set_string("fluid", tfluid)
	end
	
	fill = fill + taken
	
	bmeta:set_int("fill", fill)
end


local function try_give_fluid(bpos)
	
	-- grab the output network
	local npos = {x=bpos.x, y=bpos.y-1, z=bpos.z}
	local tnet = bitumen.pipes.get_net(npos)
	if not tnet then
		return
	end
	
	-- grab the data
	local bmeta = minetest.get_meta(bpos)
	local fill = bmeta:get_int("fill")
	local capacity = bmeta:get_int("capacity")
	local fluid = bmeta:get_string("fluid")
	
	-- check for empty
	if fill <= 0 or fluid == "air" then
		return
	end
	
	local lift = capacity / (9 * 60)
	
	local pushed = bitumen.pipes.push_fluid(npos, fluid, math.min(fill, 64), lift)
	if pushed == 0 then
		return
	end
	
	fill = math.max(fill - pushed, 0)
	
	bmeta:set_int("fill", fill)
end




-- tank data is stored based on the bottom position
local function init_tank(tpos, bpos) 
	
	
	local fluid = "air"
	local tnet = bitumen.pipes.get_net({x=tpos.x, y=tpos.y+1, z=tpos.z})
	if tnet and tnet.fluid then
		fluid = tnet.fluid
	end
	
	local tmetad = { fields = {
		bpos = minetest.serialize(bpos),
		fluid = fluid,
	}}
	local tmeta = minetest.get_meta(tpos)
	tmeta:from_table(tmetad)
	
	local height = tpos.y - bpos.y
	local cap = height * 60 * 9
	
	local bmeta = minetest.get_meta(bpos)
	local bmetad = {fields = {
		capacity = cap,
		fill = 0,
		fluid = fluid,
		height = height,
		tpos = minetest.serialize(tpos),
	}}
	bmeta:from_table(bmetad)
	
	
end


local function find_bottom(pos)
	
	local p = {x=pos.x, y=pos.y, z=pos.z}
	
	while 1==1 do
		-- find the bottom and check the fill
		
		local n = minetest.get_node(p)
		if n.name == "bitumen:cylinder_tank_bottom" then
			return p
		elseif n.name ~= "bitumen:cylinder_tank" 
		   and n.name ~= "bitumen:cylinder_tank_cracked" 
		   and n.name ~= "bitumen:cylinder_tank_top" 
		   
		   then
			return nil
		end

		p.y = p.y - 1
	end

end


local function can_dig_tank(pos, player) 
	--if 1==1 then return true end
	-- check owner
	
	-- TODO: fix ownership
--	local nmeta = minetest.get_meta(pos);
--	local owner = nmeta:get_string("owner")
--	if player:get_player_name() ~= owner then
--		return false
--	end
	
	local n = find_bottom(pos)
	if n == nil then
		return true
	else
		local meta = minetest.get_meta(pos)
		local fill = meta:get_int("fill")
		return fill <= 0 
	end
	
end




minetest.register_node("bitumen:cylinder_tank", {
	paramtype = "light",
	drawtype = "nodebox",
	description = "Cylinder Tank Segment",
	tiles = {
		"default_steel_block.png",
	},
 	node_box = {
		type = "fixed",
		fixed = {
			{ -1.3, -.5, -1.3, 1.3, .5, 1.3 },
			{ -1.5, -.5, -1.1, 1.5, .5, 1.1 },
			{ -1.1, -.5, -1.5, 1.1, .5, 1.5 },
-- 			{ -8.2, -.5, -.2, -7.8, 10, .2 },
-- 			{ -.2, -.5, -8.2, .2, 10, -7.8 },
-- 			{ 8.2, -.5, -.2, 7.8, 10, .2 },
-- 			{ -.2, -.5, 8.2, .2, 10, 7.8 },
		},
 	},
 	collision_box = {
		type = "fixed",
		fixed = {
			{ -1.5, -.5, -1.5, 1.5, .5, 1.5 },
		}
 	},
 	selection_box = {
		type = "fixed",
		fixed = {
			{ -1.5, -.5, -1.5, 1.5, .5, 1.5 },
		}
 	},
	paramtype2 = "facedir",
	groups = {cracky=1, level =2},
	sounds = default.node_sound_wood_defaults(),
	
	on_construct = function(pos)
-- 		local meta = minetest.get_meta(pos)
-- 		if placer then
-- 			local owner = placer:get_player_name()
-- 			meta:set_string("owner", owner)
-- 		end
-- 		meta:set_float("fluid_level", 0)
-- 		meta:set_float("capacity", math.floor(3.14159 * .75 * 9 * 9 * 9 * 64))
-- 		meta:set_string("infotext", "0%")
		
		--bitumen.pipes.on_construct(pos)
	end,
	
-- 	on_destruct = bitumen.magic.on_destruct,
	
	can_dig = can_dig_tank,
})



minetest.register_node("bitumen:cylinder_tank_cracked", {
	paramtype = "light",
	drawtype = "nodebox",
	description = "Cracked Cylinder Tank Segment",
	tiles = {
		"default_tin_block.png",
	},
 	node_box = {
		type = "fixed",
		fixed = {
			{ -1.3, -.5, -1.3, 1.3, .5, 1.3 },
			{ -1.5, -.5, -1.1, 1.5, .5, 1.1 },
			{ -1.1, -.5, -1.5, 1.1, .5, 1.5 },
-- 			{ -8.2, -.5, -.2, -7.8, 10, .2 },
-- 			{ -.2, -.5, -8.2, .2, 10, -7.8 },
-- 			{ 8.2, -.5, -.2, 7.8, 10, .2 },
-- 			{ -.2, -.5, 8.2, .2, 10, 7.8 },
		},
 	},
 	collision_box = {
		type = "fixed",
		fixed = {
			{ -1.5, -.5, -1.5, 1.5, .5, 1.5 },
		}
 	},
 	selection_box = {
		type = "fixed",
		fixed = {
			{ -1.5, -.5, -1.5, 1.5, .5, 1.5 },
		}
 	},
	paramtype2 = "facedir",
	groups = {cracky=1, level =2},
	sounds = default.node_sound_wood_defaults(),
	
	on_construct = function(pos)
-- 		local meta = minetest.get_meta(pos)
-- 		if placer then
-- 			local owner = placer:get_player_name()
-- 			meta:set_string("owner", owner)
-- 		end
-- 		meta:set_float("fluid_level", 0)
-- 		meta:set_float("capacity", math.floor(3.14159 * .75 * 9 * 9 * 9 * 64))
-- 		meta:set_string("infotext", "0%")
		
		--bitumen.pipes.on_construct(pos)
	end,
	
-- 	on_destruct = bitumen.magic.on_destruct,
	
	can_dig = can_dig_tank,
})



minetest.register_node("bitumen:cylinder_tank_top", {
	paramtype = "light",
	drawtype = "nodebox",
	description = "Cylinder Tank Top",
	tiles = {
		"default_steel_block.png",
	},
 	node_box = {
		type = "fixed",
		fixed = {
			{ -1.3, -.5, -1.3, 1.3, .0, 1.3 },
			{ -1.5, -.5, -1.1, 1.5, .0, 1.1 },
			{ -1.1, -.5, -1.5, 1.1, .0, 1.5 },
			{ -1.2, -.1, -1.2, 1.2, .2, 1.2 },
			{ -.7, -.1, -.7, .7, .4, .7 },
			{ -.1, .1, -.1, .1, .5, .1 },
		},
 	},
 	collision_box = {
		type = "fixed",
		fixed = {
			{ -1.5, -.5, -1.5, 1.5, .5, 1.5 },
		}
 	},
 	selection_box = {
		type = "fixed",
		fixed = {
			{ -1.5, -.5, -1.5, 1.5, .5, 1.5 },
		}
 	},
	paramtype2 = "facedir",
	groups = {cracky=1, level =2, petroleum_fixture=1},
	sounds = default.node_sound_wood_defaults(),
	
	on_construct = function(pos)
		
		local p = {x=pos.x, y=pos.y, z=pos.z}
		local segs = 1
		
		while 1==1 do
			p.y = p.y - 1
			local n = minetest.get_node(p)
			if n.name == "bitumen:cylinder_tank_bottom" then
				-- done
				
				break
			elseif n.name == "bitumen:cylinder_tank" then
				segs = segs + 1
			else
				print("invalid top segment placement")
				return
			end
			
		end
		
		print("tank segments: " .. segs .. ", capacity: ".. (segs*9*60))
		
		
		init_tank(pos, p)
		
		
		local meta = minetest.get_meta(pos)
		if placer then
			local owner = placer:get_player_name()
			meta:set_string("owner", owner)
		end

-- 		meta:set_string("infotext", "0%")
		
	end,
	
-- 	on_destruct = bitumen.magic.on_destruct,
	
	can_dig = can_dig_tank,
})


minetest.register_node("bitumen:cylinder_tank_bottom", {
	paramtype = "light",
	drawtype = "nodebox",
	description = "Cylinder Tank Bottom",
	tiles = {
		"default_steel_block.png",
	},
 	node_box = {
		type = "fixed",
		fixed = {
			{ -1.3, .0, -1.3, 1.3, .5, 1.3 },
			{ -1.5, .0, -1.1, 1.5, .5, 1.1 },
			{ -1.1, .0, -1.5, 1.1, .5, 1.5 },
			{ -1.0, -.2, -1.0, 1.0, .1, 1.0 },
			{ -.7, -.4, -.7, .7, .1, .7 },
			{ -.1, -.5, -.1, .1, .1, .1 },
			
			-- legs
			{ -1.25, -1.55, -1.25, -1.15, 0, -1.15 },
			{  1.15, -1.55, -1.15,  1.25, 0, -1.25 },
			{ -1.25, -1.55,  1.15, -1.15, 0,  1.25 },
			{  1.15, -1.55,  1.15,  1.25, 0,  1.25 },
			
		},
 	},
 	collision_box = {
		type = "fixed",
		fixed = {
			{ -1.5, -.5, -1.5, 1.5, .5, 1.5 },
		}
 	},
 	selection_box = {
		type = "fixed",
		fixed = {
			{ -1.5, -.5, -1.5, 1.5, .5, 1.5 },
		}
 	},
	paramtype2 = "facedir",
	groups = {cracky=1, level =2, petroleum_fixture=1},
	sounds = default.node_sound_wood_defaults(),
	
	on_construct = function(pos)
		
		local p = {x=pos.x, y=pos.y, z=pos.z}
		local segs = 1
		
		while 1==1 do
			p.y = p.y + 1
			local n = minetest.get_node(p)
			if n.name == "bitumen:cylinder_tank_top" then
				-- done
				
				break
			elseif n.name == "bitumen:cylinder_tank" then
				segs = segs + 1
			else
				print("invalid bottom segment placement")
				return
			end
			
		end
		
		init_tank(p, pos)
		
		
		local meta = minetest.get_meta(pos)
		if placer then
			local owner = placer:get_player_name()
			meta:set_string("owner", owner)
		end
-- 		meta:set_float("fluid_level", 0)
-- 		meta:set_float("capacity", math.floor(3.14159 * .75 * 9 * 9 * 9 * 64))
-- 		meta:set_string("infotext", "0%")
	end,
	
-- 	on_destruct = bitumen.magic.on_destruct,
	
	can_dig = can_dig_tank,
})



minetest.register_abm({
	nodenames = {"bitumen:cylinder_tank_top"},
	interval = 2,
	chance   = 1,
	action = function(pos, node, active_object_count, active_object_count_wider)
		try_add_fluid(pos)
	end,
})

minetest.register_abm({
	nodenames = {"bitumen:cylinder_tank_bottom"},
	interval = 2,
	chance   = 1,
	action = function(pos, node, active_object_count, active_object_count_wider)
		try_give_fluid(pos)
	end,
})





-- leaking
minetest.register_abm({
	nodenames = {"bitumen:cylinder_tank_cracked"},
	interval = 10,
	chance   = 5,
	action = function(pos, node, active_object_count, active_object_count_wider)
		
		local p = find_bottom(pos)
		if p == nil then
			return
		end
		
		local meta = minetest.get_meta(p)
		local fill = meta:get_int("fill")
		
		local fillh = math.ceil(fill / (9 * 60))
		local dh = pos.y - p.y
		-- fill level is below the crack
		if fillh < dh then
			return
		end
		
		-- choose a random place to leak
		local airs = minetest.find_nodes_in_area({x=pos.x-2, y=pos.y-1, z=pos.z-2}, {x=pos.x+2, y=pos.y, z=pos.z+2}, {"air"})
		if not airs then
			return
		end
		
		local ap = airs[math.random(#airs)]
		local l = math.min(fill, math.min(64, math.random(5, 30)))
		
		local fluid = meta:get_string("fluid")
		minetest.set_node(ap, {name=fluid})
		minetest.set_node_level(ap, l)
		
		meta:set_int("fill", fill - l)
		
	end,
})




