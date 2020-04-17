
local function splitname(name)
	local c = string.find(name, ":", 1)
	return string.sub(name, 1, c - 1), string.sub(name, c + 1, string.len(name))
end


function deepclone(t)
	if type(t) ~= "table" then 
		return t 
	end
	
	local meta = getmetatable(t)
	local target = {}
	
	for k, v in pairs(t) do
		if type(v) == "table" then
			target[k] = deepclone(v)
		else
			target[k] = v
		end
	end
	
	setmetatable(target, meta)
	
	return target
end




local spill_nodes = {
	"default:cobble",
	"default:mossycobble",
	"default:desert_cobble",
	"default:sand",
	"default:silver_sand",
	"default:desert_sand",
	"default:gravel",
	"default:snow",
	"default:snowblock",
	"default:dirt",
	"default:dirt_with_grass",
	"default:dirt_with_grass_footsteps",
	"default:dirt_with_dry_grass",
	"default:dirt_with_snow",
	"default:dirt_with_rainforest_litter",
	"default:dirt_with_coniferous_litter",
-- 	"default:water_source",
}

local soil_more = {}
local soil_less = {}
local soil_abm_nodes = {}
local soil_abm_neighbors = {}
local burnable_soiled_nodes = {}


local function spill_name(orig, lvl) 
	local mod, node = splitname(orig)
	return "bitumen:oily_"..mod.."_"..node.."_"..lvl
end



local function reg_level(old, modname, nodename, level)
	local def = deepclone(minetest.registered_nodes[old])
	if not def then
		return nil
	end
	
	--def.groups.not_in_creative_inventory = 1
	def.groups.bitumen_oily = level
	def.description = "Oily " .. def.description
	
	local name1 = "bitumen:oily_"..modname.."_"..nodename.."_"..level
--	table.insert(abm_list_1, old)
--	downgrades[old] = name1
	

	for k, v in pairs(def.tiles) do
		local o = def.tiles[k]
		if type(o) == 'string' then
			def.tiles[k] = def.tiles[k].."^bitumen_oil_splat_"..level..".png"
		elseif type(o) == 'table' then
			o.name = o.name .. "^bitumen_oil_splat_"..level..".png"
		end
	end

	
	def.drops = name1
	
	minetest.register_node(name1, def)
	
	return name1
end



local register_spill_node = function(old) 
	local modname, nodename = splitname(old)
	
	local n1 = reg_level(old, modname, nodename, 1)
	local n2 = reg_level(old, modname, nodename, 2)
	local n3 = reg_level(old, modname, nodename, 3)
	
	if n1 and n2 and n3 then
		soil_more[old] = n1
		soil_more[n1] = n2
		soil_more[n2] = n3
		
		soil_less[n3] = n2
		soil_less[n2] = n1
		soil_less[n1] = old
		
		table.insert(soil_abm_nodes, n3)
		table.insert(soil_abm_nodes, n2)
		table.insert(soil_abm_neighbors, n2)
		table.insert(soil_abm_neighbors, n1)
		table.insert(soil_abm_neighbors, old)
		
		table.insert(burnable_soiled_nodes, n3)
		table.insert(burnable_soiled_nodes, n2)
	end
end


-- TODO: wool, stairs, walls, seasons

for _,n in ipairs(spill_nodes) do
	register_spill_node(n)
end



-- water is handled differently
local function reg_oily_water(level)
	local color = 120 + (level * 3)
	local aff = (level + 2)
	minetest.register_node("bitumen:oily_default_water_source_"..level, {
		description = "Oily Water Source",
		drawtype = "liquid",
		tiles = {
			{
				name = "default_water_source_animated.png^[colorize:black:"..color,
				animation = {
					type = "vertical_frames",
					aspect_w = 16,
					aspect_h = 16,
					length = 2.0,
				},
			},
		},
		special_tiles = {
			-- New-style water source material (mostly unused)
			{
				name = "default_water_source_animated.png^[colorize:black:"..color,
				animation = {
					type = "vertical_frames",
					aspect_w = 16,
					aspect_h = 16,
					length = 2.0,
				},
				backface_culling = false,
			},
		},
		alpha = 160,
		paramtype = "light",
		walkable = false,
		pointable = false,
		diggable = false,
		buildable_to = true,
		is_ground_content = false,
		drop = "",
		drowning = 1,
		liquidtype = "source",
		liquid_alternative_flowing = "bitumen:oily_default_water_flowing_"..level,
		liquid_alternative_source = "bitumen:oily_default_water_source_"..level,
		liquid_viscosity = 1,
		post_effect_color = {a = 103 + (level * 50), r = 30 / aff, g = 60 / aff, b = 90 / aff},
		groups = {water = 3, liquid = 3, puts_out_fire = 1, cools_lava = 1, bitumen_oily = level},
		sounds = default.node_sound_water_defaults(),
	})

	minetest.register_node("bitumen:oily_default_water_flowing_"..level, {
		description = "Oily Flowing Water",
		drawtype = "flowingliquid",
		tiles = {"default_water.png^[colorize:black:"..color},
		special_tiles = {
			{
				name = "default_water_flowing_animated.png^[colorize:black:"..color,
				backface_culling = false,
				animation = {
					type = "vertical_frames",
					aspect_w = 16,
					aspect_h = 16,
					length = 0.8,
				},
			},
			{
				name = "default_water_flowing_animated.png^[colorize:black:"..color,
				backface_culling = true,
				animation = {
					type = "vertical_frames",
					aspect_w = 16,
					aspect_h = 16,
					length = 0.8,
				},
			},
		},
		alpha = 160,
		paramtype = "light",
		paramtype2 = "flowingliquid",
		walkable = false,
		pointable = false,
		diggable = false,
		buildable_to = true,
		is_ground_content = false,
		drop = "",
		drowning = 1,
		liquidtype = "flowing",
		liquid_alternative_flowing = "bitumen:oily_default_water_flowing_"..level,
		liquid_alternative_source = "bitumen:oily_default_water_source_"..level,
		liquid_viscosity = 1,
		post_effect_color = {a = 103 + (level * 50), r = 30 / aff, g = 60 / aff, b = 90 / aff},
		groups = {water = 3, liquid = 3, puts_out_fire = 1,
			not_in_creative_inventory = 1, cools_lava = 1, bitumen_oily = level},
		sounds = default.node_sound_water_defaults(),
	})


	minetest.register_node("bitumen:oily_default_river_water_source_"..level, {
		description = "Oily River Water Source",
		drawtype = "liquid",
		tiles = {
			{
				name = "default_river_water_source_animated.png^[colorize:black:"..color,
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
				name = "default_river_water_source_animated.png^[colorize:black:"..color,
				animation = {
					type = "vertical_frames",
					aspect_w = 16,
					aspect_h = 16,
					length = 2.0,
				},
				backface_culling = false,
			},
		},
		alpha = 160,
		paramtype = "light",
		walkable = false,
		pointable = false,
		diggable = false,
		buildable_to = true,
		is_ground_content = false,
		drop = "",
		drowning = 1,
		liquidtype = "source",
		liquid_alternative_flowing = "bitumen:oily_default_river_water_flowing_"..level,
		liquid_alternative_source = "bitumen:oily_default_river_water_source_"..level,
		liquid_viscosity = 1,
		-- Not renewable to avoid horizontal spread of water sources in sloping
		-- rivers that can cause water to overflow riverbanks and cause floods.
		-- River water source is instead made renewable by the 'force renew'
		-- option used in the 'bucket' mod by the river water bucket.
		liquid_renewable = false,
		liquid_range = 2,
		post_effect_color = {a = 103 + (level * 50), r = 30 / aff, g = 76 / aff, b = 90 / aff},
		groups = {water = 3, liquid = 3, puts_out_fire = 1, cools_lava = 1, bitumen_oily = level},
		sounds = default.node_sound_water_defaults(),
	})

	minetest.register_node("bitumen:oily_default_river_water_flowing_"..level, {
		description = "Oily Flowing River Water",
		drawtype = "flowingliquid",
		tiles = {"default_river_water.png^[colorize:black:"..color},
		special_tiles = {
			{
				name = "default_river_water_flowing_animated.png^[colorize:black:"..color,
				backface_culling = false,
				animation = {
					type = "vertical_frames",
					aspect_w = 16,
					aspect_h = 16,
					length = 0.8,
				},
			},
			{
				name = "default_river_water_flowing_animated.png^[colorize:black:"..color,
				backface_culling = true,
				animation = {
					type = "vertical_frames",
					aspect_w = 16,
					aspect_h = 16,
					length = 0.8,
				},
			},
		},
		alpha = 160,
		paramtype = "light",
		paramtype2 = "flowingliquid",
		walkable = false,
		pointable = false,
		diggable = false,
		buildable_to = true,
		is_ground_content = false,
		drop = "",
		drowning = 1,
		liquidtype = "flowing",
		liquid_alternative_flowing = "bitumen:oily_default_river_water_flowing_"..level,
		liquid_alternative_source = "bitumen:oily_default_river_water_source_"..level,
		liquid_viscosity = 1,
		liquid_renewable = false,
		liquid_range = 2,
		post_effect_color = {a = 103 + (level * 50), r = 30 / aff, g = 76 / aff, b = 90 / aff},
		groups = {water = 3, liquid = 3, puts_out_fire = 1,
			not_in_creative_inventory = 1, cools_lava = 1, bitumen_oily = level},
		sounds = default.node_sound_water_defaults(),
	})

end



local function insert_soiling(mod, node) 
	local old = mod .. ":" .. node
	local n1 = "bitumen:oily_"..mod.."_"..node.."_1"
	local n2 = "bitumen:oily_"..mod.."_"..node.."_2"
	local n3 = "bitumen:oily_"..mod.."_"..node.."_3"
	
	soil_more[old] = n1
	soil_more[n1] = n2
	soil_more[n2] = n3
	
	soil_less[n3] = n2
	soil_less[n2] = n1
	soil_less[n1] = old
	
	table.insert(soil_abm_nodes, n3)
	table.insert(soil_abm_nodes, n2)
	table.insert(soil_abm_neighbors, n2)
	table.insert(soil_abm_neighbors, n1)
	table.insert(soil_abm_neighbors, old)
end

reg_oily_water(1)
reg_oily_water(2)
reg_oily_water(3)
insert_soiling("default", "water_source")
insert_soiling("default", "river_water_source")



-- abms


minetest.register_abm({
	nodenames = soil_abm_nodes,
	neighbors = soil_abm_neighbors,
	interval = 5,
	chance   = 20,
	action = function(pos, node, active_object_count, active_object_count_wider)
		
		local alvl = minetest.registered_nodes[node.name].groups.bitumen_oily or 0
		
		local unsoiled = minetest.find_nodes_in_area(
			{x=pos.x-1, y=pos.y-1, z=pos.z-1}, 
			{x=pos.x+1, y=pos.y  , z=pos.z+1}, 
			soil_abm_neighbors
		)
		if not unsoiled then
			return
		end
		
		local off = math.random(#unsoiled)
		for i = 1, #unsoiled do
			local bp = unsoiled[((i + off) % #unsoiled) + 1]
			
			local bnode = minetest.get_node(bp)
			local blvl = minetest.registered_nodes[bnode.name].groups.bitumen_oily or 0
			
			if alvl > blvl then 
				minetest.set_node(pos, {name = soil_less[node.name]})
				minetest.set_node(bp, {name = soil_more[bnode.name]})
				return
			end
		end
		
	end
})
	



-- crude oil spreads into certain tiles
minetest.register_abm({
	nodenames = {"bitumen:crude_oil", "bitumen:crude_oil_full"},
	neighbors = soil_abm_neighbors,
	interval = 3,
	chance   = 10,
	action = function(pos, node, active_object_count, active_object_count_wider)
		
		local unsoiled = minetest.find_nodes_in_area(
			{x=pos.x-1, y=pos.y-1, z=pos.z-1}, 
			{x=pos.x+1, y=pos.y  , z=pos.z+1}, 
			soil_abm_neighbors
		)
		if not unsoiled then
			return
		end
		
		local off = math.random(#unsoiled)
		for i = 1, #unsoiled do
			local bp = unsoiled[((i + off) % #unsoiled) + 1]
			local bnode = minetest.get_node(bp)
			

			local x = soil_more[bnode.name]
			if x == nil then
			--	print(dump2(x).. " -> " ..dump2(bnode.name))
			else
				local lvl = minetest.get_node_level(pos)
				local nl = math.max(0, lvl - 10)
				
				if nl == 0 then
					minetest.set_node(pos, {name="air"})
				else
					minetest.set_node_level(pos, nl)
				end
				
				minetest.set_node(bp, {name=x})
				
				return
			end
		end
		
	end
})
	




minetest.register_abm({
	label = "Spilled nodes burn slowly",
	nodenames = burnable_soiled_nodes,
	neighbors = {"fire:basic_flame"},
	interval = 4,
	chance = 20,
	catch_up = true,
	action = function(pos, node, active_object_count, active_object_count_wider)
		local n = minetest.get_node(pos)
		if n then
			local less = soil_less[n.name]
			if less then
				minetest.set_node(pos, {name = less})
			end
		end
	end,
})


minetest.register_abm({
	label = "Spilled nodes catch fire",
	nodenames = burnable_soiled_nodes,
	neighbors = {"fire:basic_flame"},
	interval = 3,
	chance = 5,
	catch_up = true,
	action = function(pos, node, active_object_count, active_object_count_wider)
		local n = minetest.find_node_near(pos, 1, {"air"})
		if n then
			minetest.set_node(n, {name = "fire:basic_flame"})
		end
	end,
})










