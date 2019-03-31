

local function try_add_fluid(tpos)

	-- find the bottom node
	local tmeta = minetest.get_meta(tpos)
	local rbpos = tmeta:get_string("bpos")
	if not rbpos then
	--print("no bpos")
		return
	end
	
	
	-- grab the input network
	local npos = {x=tpos.x, y=tpos.y+1, z=tpos.z}
	local tnet = bitumen.pipes.get_net(npos)
	if not tnet or not tnet.fluid or tnet.fluid == "air" then
	--print("no tnet")
	--print(dump(tnet.fluid))
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
		--print("empty")
		return
	end
	
	if fill > 0 and fluid ~= tnet.fluid then
		--print("wrong fluid to take")
		return
	end
	
	local remcap = capacity - fill
	
	
	local taken, tfluid = bitumen.pipes.take_fluid(npos, remcap)
	if taken == 0 then
		--print("none taken")
		return
	end
	
	-- set or change fluids
	if fluid == "air" or fill == 0 then
		bmeta:set_string("fluid", tfluid)
		tmeta:set_string("fluid", tfluid)
	end
	
	fill = fill + taken
	--print("cyl tank fill: " .. fill .. " ("..tfluid..")")
	
	bmeta:set_int("fill", fill)
end


local function try_give_fluid(bpos)
	
	-- grab the output network
	local npos = {x=bpos.x, y=bpos.y-1, z=bpos.z}
	local tnet = bitumen.pipes.get_net(npos)
	if not tnet then
		--print("no bnet")
		return
	end
	
	-- grab the data
	local bmeta = minetest.get_meta(bpos)
	local fill = bmeta:get_int("fill")
	local capacity = bmeta:get_int("capacity")
	local fluid = bmeta:get_string("fluid")
	
	-- check for empty
	if fill <= 0 or fluid == "air" then
		--print("tank empty " .. fluid .. " " ..fill)
		return
	end
	
	local lift = capacity / (9 * 60)
	
	local pushed = bitumen.pipes.push_fluid(npos, fluid, math.min(fill, 64), lift)
	if pushed == 0 then
		--print("none pushed")
		return
	end
	
	fill = math.max(fill - pushed, 0)
	--print("cyl tank fill: " .. fill .. " ("..fluid..") [push]")
	
	bmeta:set_int("fill", fill)
end




-- tank data is stored based on the bottom position
local function init_tank(tpos, bpos) 
	
	--print(dump(tpos))
	--print(dump(bpos))
	
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
	--print(dump2(tmeta:to_table()))
	
	local cap = (tpos.y - bpos.y) * 60 * 9
	--print("capacity: ".. cap)
	
	local bmeta = minetest.get_meta(bpos)
	local bmetad = {fields = {
		capacity = cap,
		fill = 0,
		fluid = fluid,
		tpos = minetest.serialize(tpos),
	}}
	bmeta:from_table(bmetad)
	
	
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

	local p = {x=pos.x, y=pos.y, z=pos.z}
	
	while 1==1 do
		-- find the bottom and check the fill
		local n = minetest.get_node(p)
		if n.name == "bitumen:cylinder_tank_bottom" then
			local meta = minetest.get_meta(p)
			local fill = meta:get_int("fill")
			return fill <= 0 
		elseif n.name ~= "bitumen:cylinder_tank" and n.name ~= "bitumen:cylinder_tank_top" then
			return true
		end
		
		p.y = p.y - 1
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
			{ -1.5, -.5, -1.5, 1.5, .5, 1.5 },
			{ -1.7, -.5, -1.2, 1.7, .5, 1.2 },
			{ -1.2, -.5, -1.7, 1.2, .5, 1.7 },
-- 			{ -8.2, -.5, -.2, -7.8, 10, .2 },
-- 			{ -.2, -.5, -8.2, .2, 10, -7.8 },
-- 			{ 8.2, -.5, -.2, 7.8, 10, .2 },
-- 			{ -.2, -.5, 8.2, .2, 10, 7.8 },
		},
 	},
 	collision_box = {
		type = "fixed",
		fixed = {
			{ -1.7, -.5, -1.7, 1.7, .5, 1.7 },
		}
 	},
 	selection_box = {
		type = "fixed",
		fixed = {
			{ -1.7, -.5, -1.7, 1.7, .5, 1.7 },
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
			{ -1.5, -.5, -1.5, 1.5, .0, 1.5 },
			{ -1.7, -.5, -1.2, 1.7, .0, 1.2 },
			{ -1.2, -.5, -1.7, 1.2, .0, 1.7 },
			{ -1.2, -.1, -1.2, 1.2, .2, 1.2 },
			{ -.7, -.1, -.7, .7, .4, .7 },
			{ -.1, .1, -.1, .1, .5, .1 },
		},
 	},
 	collision_box = {
		type = "fixed",
		fixed = {
			{ -1.7, -.5, -1.7, 1.7, .5, 1.7 },
		}
 	},
 	selection_box = {
		type = "fixed",
		fixed = {
			{ -1.7, -.5, -1.7, 1.7, .5, 1.7 },
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
			{ -1.5, .0, -1.5, 1.5, .5, 1.5 },
			{ -1.7, .0, -1.2, 1.7, .5, 1.2 },
			{ -1.2, .0, -1.7, 1.2, .5, 1.7 },
			{ -1.2, -.2, -1.2, 1.2, .1, 1.2 },
			{ -.7, -.4, -.7, .7, .1, .7 },
			{ -.1, -.5, -.1, .1, .1, .1 },
			
			-- legs
			{ -1.4, -1.55, -1.4, -1.3, 0, -1.3 },
			{  1.3, -1.55, -1.4,  1.4, 0, -1.3 },
			{ -1.4, -1.55,  1.3, -1.3, 0,  1.4 },
			{  1.3, -1.55,  1.3,  1.4, 0,  1.4 },
			
		},
 	},
 	collision_box = {
		type = "fixed",
		fixed = {
			{ -1.7, -.5, -1.7, 1.7, .5, 1.7 },
		}
 	},
 	selection_box = {
		type = "fixed",
		fixed = {
			{ -1.7, -.5, -1.7, 1.7, .5, 1.7 },
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




--[[
minetest.register_craft({
	output = 'bitumen:sphere_tank_constructor',
	recipe = {
		{'default:steelblock', 'default:steelblock', 'default:steelblock'},
		{'default:steelblock', 'vessels:steel_bottle', 'default:steelblock'},
		{'default:steelblock', 'default:steelblock', 'default:steelblock'},
	}
})
]]
