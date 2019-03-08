

local function combine_table(a, b)
	a = a or {}
	for k,v in pairs(a) do
		b[k] = v
	end
	
	return b
end



local function register_fluid(modname, name, info)
	local fname = modname..":"..name
	local full_fname = modname..":"..name.."_full"
	
	local gname = modname.."_"..name.."_fluid"
	
	local groups = { liquid = 3, [gname]=1}
	for n,l in pairs(info.groups) do
		groups[n] = l
	end
	
	local full_groups = {not_in_creative_inventory = 1}
	for n,l in pairs(groups) do
		full_groups[n] = l
	end
	
	
	minetest.register_node(fname, combine_table(info.def, {
		description = info.desc,
		drawtype = "nodebox",
		paramtype = "light",  
		tiles = {
			{
				name = "default_river_water_source_animated.png"..info.colorize,
				animation = {
					type = "vertical_frames",
					aspect_w = 16,
					aspect_h = 16,
					length = 2.0,
				},
			},
		},
		special_tiles = {
			{
				name = "default_river_water_source_animated.png"..info.colorize,
				animation = {
					type = "vertical_frames",
					aspect_w = 16,
					aspect_h = 16,
					length = 2.0,
				},
				backface_culling = false,
			},
		},
		leveled = 64,
		alpha = 160,
		drop = "",
		drowning = 1,
		walkable = false, -- because viscosity doesn't work for regular nodes, and the liquid hack can't be leveled
		climbable = true, -- because viscosity doesn't work for regular nodes, and the liquid hack can't be leveled
		pointable = false,
		diggable = false,
		buildable_to = true,
		post_effect_color = info.post_effect_color,
		groups = groups,
		nonfull_name = fname,
		sounds = default.node_sound_water_defaults(),
		node_box = {
			type = "leveled",
			fixed = {
				{-0.5, -0.5, -0.5, 0.5, 0.5, 0.5}, -- NodeBox1
			}
		}
	}))




	-- this is a special node used to optimize large pools of water
	-- its flowing abm runs much less frequently
	minetest.register_node(full_fname, combine_table(info.def, {
		description = info.desc,
		drawtype = "nodebox",
		paramtype = "light",  
		tiles = {
			{
				name = "default_river_water_source_animated.png"..info.colorize,
				animation = {
					type = "vertical_frames",
					aspect_w = 16,
					aspect_h = 16,
					length = 2.0,
				},
			},
		},
		special_tiles = {
			{
				name = "default_river_water_source_animated.png"..info.colorize,
				animation = {
					type = "vertical_frames",
					aspect_w = 16,
					aspect_h = 16,
					length = 2.0,
				},
				backface_culling = false,
			},
		},
		leveled = 64,
		alpha = 160,
		drop = "",
		drowning = 1,
		walkable = false, -- because viscosity doesn't work for regular nodes, and the liquid hack can't be leveled
		climbable = true, -- because viscosity doesn't work for regular nodes, and the liquid hack can't be leveled
		pointable = false,
		diggable = false,
		buildable_to = true,
		post_effect_color = info.post_effect_color,
		groups = full_groups,
		nonfull_name = fname,
		sounds = default.node_sound_water_defaults(),
		node_box = {
			type = "leveled",
			fixed = {
				{-0.5, -0.5, -0.5, 0.5, 0.5, 0.5}, -- NodeBox1
			}
		}
	}))
	
	
		
	local soak = {
		["default:cobble"] = 10,
		["default:desert_cobble"] = 10,
		["default:mossycobble"] = 9,
		["default:dirt"] = 2,
		["default:dirt_with_grass"] = 2,
		["default:dirt_with_grass_footsteps"] = 2,
		["default:dirt_with_dry_grass"] = 2,
		["default:dirt_with_coniferous_litter"] = 2,
		["default:dirt_with_rainforest_litter"] = 1,
		["default:gravel"] = 8,
		["default:coral_orange"] = 6,
		["default:coral_brown"] = 6,
		["default:coral_skeleton"] = 6,
		["default:sand"] = 6,
		["default:sand_with_kelp"] = 6,
		["default:desert_sand"] = 7,
		["default:silver_sand"] = 7,
		["default:snow"] = 4,
		["default:snowblock"] = 4,
		["default:leaves"] = 60,
		["default:bush_leaves"] = 60,
		["default:jungleleaves"] = 60,
		["default:pine_needles"] = 60,
		["default:acacia_leaves"] = 60,
		["default:acacia_bush_leaves"] = 60,
		["default:aspen_leaves"] = 60,
		
		-- dilution
		["default:water_source"] = 65,
		["default:water_flowing"] = 65,
		["default:river_water_source"] = 65,
		["default:river_water_flowing"] = 65,
		
		-- boiling -- TODO: steam effect
		["default:lava_source"] = 65,
		["default:lava_flowing"] = 65,
		
		-- no ladder hacks
		["default:ladder_wood"] = 65,
	--	["default:ladder_steel"] = 65, -- need to figure out a way for water to flow through ladders
		["default:sign_wall_wood"] = 65,
		["default:sign_wall_steel"] = 65,

		["default:fence_wood"] = 65,
		["default:fence_acacia_wood"] = 65,
		["default:fence_junglewood"] = 65,
		["default:fence_pine_wood"] = 65,
		["default:fence_aspen_wood"] = 65,
		
		["default:torch"] = 65,
		["carts:rail"] = 65,
		["carts:brakerail"] = 65,
		["carts:powerrail"] = 65,


	}

	local soak_names = {}
	
	if info.no_default_soak ~= true then
		for n,_ in pairs(soak) do
			table.insert(soak_names, n)
		end
	end
	
	-- todo: superflammability
	--       boil-off for water near fire
	--       vapors or explosions

	
	
	
	if info.evap_chance > 0 then

		-- evaporation
		minetest.register_abm({
			nodenames = {"group:"..gname},
			neighbors = {"group:"..gname, "air"},
			interval = info.evap_interval,
			chance = info.evap_chance,
			action = function(pos)
				local mylevel = minetest.get_node_level(pos)
				if math.random(16 - minetest.get_node_light(pos)) == 1 then
					if mylevel > info.evap_rate then
						minetest.set_node_level(pos, mylevel - info.evap_rate)
					else
						minetest.set_node(pos, {name = "air"})
					end
				end
			end
		})

	end

	-- de-stagnation (faster flowing)
	minetest.register_abm({
		nodenames = {full_fname},
		neighbors = {"air"},
		interval = info.reflow_interval or 5,
		chance = info.flow_chance or 1,
		action = function(pos)
			-- if it's near air it might flow
			minetest.set_node(pos, {name = fname})
		end
	})



	-- flowing
	minetest.register_abm({
		nodenames = {fname},
		neighbors = {"group:"..gname, "air"},
		interval = info.flow_interval or 1,
		chance = info.flow_chance or 1,
		action = function(pos)
			local mylevel = minetest.get_node_level(pos)
	-- 		print("\n mylevel ".. mylevel)
		
			-- falling
			local below = {x=pos.x, y=pos.y - 1, z=pos.z}
			local nbelow = minetest.get_node(below).name
			if nbelow == "air" then
				minetest.set_node(below, {name=fname})
				minetest.set_node_level(below, mylevel)
				minetest.set_node(pos, {name="air"})
				return
			elseif nbelow == fname then
				local blevel = minetest.get_node_level(below)
				if blevel < 64 then
					local sum = mylevel + blevel
					minetest.set_node_level(below, math.min(64, sum))
					
					if sum > 64 then
						mylevel = sum - 64
						minetest.set_node_level(pos, mylevel)
						-- keep flowing the liquid. this speeds up cascades
					else
						minetest.set_node(pos, {name="air"})
						return
					end
				end
			else -- check soaking
				local rate = soak[nbelow]
				if rate ~= nil then
					local remains = mylevel - rate
					if remains > 0 then
						minetest.set_node_level(pos, remains)
					else
						minetest.set_node(pos, {name="air"})
					end
					
				if 1 == math.random(120 / mylevel) then
					minetest.set_node(below, {name = "air"})
				end
					
					mylevel = remains 
					--return -- keep the fluid mechanics
				end
			end
		
			local air_nodes = minetest.find_nodes_in_area(
				{x=pos.x - 1, y=pos.y - 1, z=pos.z - 1},
				{x=pos.x + 1, y=pos.y, z=pos.z + 1},
				"air"
			)
			
			
			
			
	-- 		print("x: "..pos.x.." y: "..pos.y.." z: "..pos.z)
	-- 		print("air list len ".. #air_nodes)
			local off = math.random(#air_nodes)
			
			for i = 1,#air_nodes do
				--local theirlevel = minetest.get_node_level(fp)
				local fp = air_nodes[((i + off) % #air_nodes) + 1]
				if mylevel >= 2 then
					local half = math.ceil(mylevel / 2)
					
					minetest.set_node_level(pos, mylevel - half)
					minetest.set_node(fp, {name= fname})
					minetest.set_node_level(fp, half)
	-- 				minetest.check_for_falling(fp)
					return
				end
			end
			
			local flow_nodes = minetest.find_nodes_in_area(
				{x=pos.x - 1, y=pos.y , z=pos.z - 1},
				{x=pos.x + 1, y=pos.y, z=pos.z + 1},
				"group:"..gname
			)
			
	-- 		print("x: "..pos.x.." y: "..pos.y.." z: "..pos.z)
	-- 		print("list len ".. #flow_nodes)
			local off = math.random(#flow_nodes)
			
			for i = 1,#flow_nodes do
				local fp = flow_nodes[((i + off) % #flow_nodes) + 1]
				local theirlevel = minetest.get_node_level(fp)
	-- 			print("theirlevel "..theirlevel)
				if mylevel - theirlevel >= 2 then
					local diff = (mylevel - theirlevel)
					local half = math.ceil(diff / 2)
					
					minetest.set_node_level(pos, mylevel - half)
					minetest.set_node_level(fp, theirlevel + (diff - half))
					return
				end
			end
				
	-- 			local n = minetest.get_node(fp);
	-- 			-- check above to make sure it can get here
	-- 			local na = minetest.get_node({x=fp.x, y=fp.y+1, z=fp.z})
	-- 			
	-- 	--		print("name: " .. na.name .. " l: " ..g)
	-- 			if na.name == "default:river_water_flowing" or na.name == "default:river_water_flowing" then
	-- 				minetest.set_node(fp, {name=node.name})
	-- 				minetest.set_node(pos, {name=n.name})
	-- 				return
	-- 			end
	-- 		end
			
			
			-- stagnation: this may not work
			if mylevel == 64 then
				--print("stagnating ".. pos.x .. ","..pos.y..","..pos.z)
				minetest.set_node(pos, {name = full_fname})
			end
		end
	})

end


bitumen.register_fluid = register_fluid


-- distillation products


register_fluid("bitumen", "mineral_spirits", {
	desc = "Mineral Spirits",
	groups = {flammable=1, petroleum=1},
	
	colorize = "^[colorize:white:160",
	post_effect_color = {a = 103, r = 30, g = 76, b = 90},
	
	evap_interval = 5,
	evap_chance = 5,
	evap_rate = 5,
})

register_fluid("bitumen", "gasoline", {
	desc = "Gasoline",
	groups = {flammable=1, petroleum=1},
	
	colorize = "^[colorize:yellow:160",
	post_effect_color = {a = 103, r = 30, g = 76, b = 90},
	
	evap_interval = 5,
	evap_chance = 5,
	evap_rate = 5,
})

register_fluid("bitumen", "diesel", {
	desc = "Diesel",
	groups = {flammable=1, petroleum=1},
	
	colorize = "^[colorize:red:160",
	post_effect_color = {a = 103, r = 230, g = 76, b = 90},
	
	evap_interval = 5,
	evap_chance = 10,
	evap_rate = 2,
})

register_fluid("bitumen", "kerosene", {
	desc = "Kerosene",
	groups = {flammable=1, petroleum=1},
	
	colorize = "^[colorize:white:100",
	post_effect_color = {a = 103, r = 80, g = 76, b = 190},
	
	evap_interval = 5,
	evap_chance = 10,
	evap_rate = 8,
})

register_fluid("bitumen", "light_oil", {
	desc = "Light Oil",
	groups = {flammable=1, petroleum=1},
	
	colorize = "^[colorize:brown:220",
	post_effect_color = {a = 103, r = 80, g = 76, b = 90},
	
	evap_chance = 0,
})

register_fluid("bitumen", "heavy_oil", {
	desc = "Heavy Oil",
	groups = {flammable=1, petroleum=1},
	
	colorize = "^[colorize:brown:240",
	post_effect_color = {a = 103, r = 80, g = 76, b = 90},
	
	evap_chance = 0,
})

register_fluid("bitumen", "tar", {
	desc = "Tar",
	groups = {flammable=1, petroleum=1},
	
	colorize = "^[colorize:black:210",
	post_effect_color = {a = 103, r = 80, g = 76, b = 90},
	
	evap_chance = 0,
})


-- oil itself

register_fluid("bitumen", "crude_oil", {
	desc = "Crude Oil",
	groups = {flammable=1, petroleum=1},
	
	reflow_interval = 10,
	reflow_chance = 2,
	flow_interval = 3,
	flow_chance = 3,
	
	colorize = "^[colorize:black:240",
	post_effect_color = {a = 103, r = 80, g = 76, b = 90},
	
	evap_chance = 0,
})



-- other

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










--temp hack for dev
minetest.register_node("bitumen:crudesource", {
	description = "thing",
	tiles = { "default_copper_block.png" },
	groups = { cracky = 3 },
})


minetest.register_abm({
	nodenames = {"bitumen:crudesource"},
	interval = 1,
	chance   = 1,
	action = function(pos, node, active_object_count, active_object_count_wider)
		
		pos.y = pos.y - 1
		minetest.set_node(pos, {name = "bitumen:crude_oil"})
		minetest.set_node_level(pos, 64)
		
	end
})
	

