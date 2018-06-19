
--[[ NEED:

textures: 
	oil shale
	crushed oil shale

node defs:
	(tweak) oil shale

craftitem:
	crushed oil shale

ore reg:
	(tweak) oil shale

grinder recipe:
	oil shale -> crushed oil shale

extractor recipe:
	crushed oil shale -> bitumen

]]


 -- need to get the info for stone-type things
minetest.register_node( "bitumen:tar_sand", {
	description = "Tar Sand",
	tiles = { "default_sand.png^[colorize:black:180" },
	is_ground_content = true,
	groups = {crumbly=2, falling_node=1},
	sounds = default.node_sound_sand_defaults(),
}) 
minetest.register_node( "bitumen:oil_shale", {
	description = "Oil Shale",
	tiles = { "default_stone.png^[colorize:black:180" },
	is_ground_content = true,
	groups = {cracky=2, },
	sounds = default.node_sound_stone_defaults(),
}) 
	


minetest.register_ore({
	ore_type        = "blob",
	ore             = "bitumen:tar_sand",
	wherein         = {"default:desert_stone", "default:sandstone", "default:stone"},
	clust_scarcity  = 64 * 64 * 64,
	clust_size      = 20,
	y_min           = -15,
	y_max           = 500,
	noise_threshold = 0.4,
	noise_params    = {
		offset = 0.5,
		scale = 0.7,
		spread = {x = 40, y = 40, z = 40},
		seed = 2316,
		octaves = 4,
		persist = 0.7
	},
	biomes = {
			"taiga", "snowy_grassland", 
			"grassland", "desert", "sandstone_desert", "cold_desert",
			}
})

	
minetest.register_ore({
	ore_type        = "blob",
	ore             = "bitumen:oil_shale",
	wherein         = {"default:sandstone"},
	clust_scarcity  = 96 * 96 * 96,
	clust_size      = 30,
	y_min           = -15,
	y_max           = 500,
	noise_threshold = 0.4,
	noise_params    = {
		offset = 0.5,
		scale = 0.7,
		spread = {x = 40, y = 40, z = 40},
		seed = 23136,
		octaves = 4,
		persist = 0.7
	},
	biomes = { "sandstone_desert"},
})






local function swap_node(pos, name)
	local node = minetest.get_node(pos)
	if node.name == name then
		return
	end
	node.name = name
	minetest.swap_node(pos, node)
end



local function get_melter_active_formspec(fuel_percent, item_percent)
	fuel_percent = fuel_percent or 0
	item_percent = item_percent or 0
	return "size[8,8.5]"..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
		"list[context;fuel;.75,.5;2,4;]"..
		"image[2.75,1.5;1,1;default_furnace_fire_bg.png^[lowpart:"..
		(100-fuel_percent)..":default_furnace_fire_fg.png]"..
		"image[3.75,1.5;1,1;gui_furnace_arrow_bg.png^[lowpart:"..
		(item_percent)..":gui_furnace_arrow_fg.png^[transformR270]"..
		"list[current_player;main;0,4.25;8,1;]"..
		"list[current_player;main;0,5.5;8,3;8]"..
		default.get_hotbar_bg(0, 4.25)
end


bitumen.get_melter_active_formspec = get_melter_active_formspec


local function grab_fuel(inv)
	
	local list = inv:get_list("fuel")
	for i,st in ipairs(list) do
	print(st:get_name())
		local fuel, remains
		fuel, remains = minetest.get_craft_result({
			method = "fuel", 
			width = 1, 
			items = {
				ItemStack(st:get_name())
			},
		})

		if fuel.time > 0 then
			-- Take fuel from fuel list
			st:take_item()
			inv:set_stack("fuel", i, st)
			
			return fuel.time
		end
	end
	
	return 0 -- no fuel found
end








bitumen.burners = {}

bitumen.register_burner = function(nodes, callbacks) 
	local default_callbacks = {
		grab_fuel = grab_fuel, -- needs to return the fuel time
		start_cook = function() end, -- needs to return the cook time
		finish_cook = function() end,
		abort_cook = function() end,
		get_formspec_on = get_melter_active_formspec,
		turn_on = function() end,
		turn_off = function() end,
	}
	
	for k,v in pairs(callbacks) do
		default_callbacks[k] = v
	end
	
	for _,n in ipairs(nodes) do
		print("setting burner: "..n)
		bitumen.burners[n] = default_callbacks
	end
end



bitumen.burner_on_timer = function(pos, elapsed)

	local posnode = minetest.get_node(pos)
	local fns = bitumen.burners[posnode.name]
	if fns == nil then
		return false
	end
	
	
	local meta = minetest.get_meta(pos)
	local fuel_time = meta:get_float("fuel_time") or 0
	local fuel_burned = meta:get_float("fuel_burned") or 0
	local cook_time = meta:get_float("cook_time") or 0
	local cook_burned = meta:get_float("cook_burned") or 0
	
	local inv = meta:get_inventory()
	
	local burned = elapsed
	local turn_off = false
	
	
--	print("\n\naf timer")
--/	print("fuel_burned: " .. fuel_burned)
--	print("fuel_time: " .. fuel_time)
	
	
	if fuel_time > 0 and fuel_burned + elapsed < fuel_time then
		-- still good on fuel
		fuel_burned = fuel_burned + elapsed
		meta:set_float("fuel_burned", fuel_burned + elapsed)
	else
		local t = fns.grab_fuel(inv)
		if t <= 0 then -- out of fuel
			--print("out of fuel")
			meta:set_float("fuel_time", 0)
			meta:set_float("fuel_burned", 0)
			
			burned = fuel_time - fuel_burned
			
			turn_off = true
		else
			-- check if the machine is turning on
			if fuel_time == 0 then
				fns.turn_on(pos, meta, inv)
			end
			
			-- roll into the next period
			fuel_burned =  elapsed - (fuel_time - fuel_burned)
			fuel_time = t
			
			meta:set_float("fuel_time", fuel_time)
			meta:set_float("fuel_burned", fuel_burned)
		end
	end
	
	
	--print("cooktime " .. cook_time)
	--print("cookburned " .. cook_burned)
	if cook_time == 0 then -- nothing cooking atm
		--print("fueltime " .. fuel_time)
		--print("turnoff " .. dump(turn_off))
		if fuel_time ~= 0 and turn_off == false then -- should we start to cook?
			cook_time = fns.start_cook(pos, meta, inv)
			meta:set_float("cook_time", cook_time)
			meta:set_float("cook_burned", 0)
		else
			-- no fuel
		end
	else -- continue cooking
		cook_burned = cook_burned + burned
		if cook_burned >= cook_time then -- cooking finished
			fns.finish_cook(pos, met, inv)
			
			local new_cook_time = fns.start_cook(pos, meta, inv)
			meta:set_float("cook_time", new_cook_time)
			cook_burned = cook_burned - cook_time 
		end
		meta:set_float("cook_burned", cook_burned)
	end
	
	
	
	if turn_off then
		fns.turn_off(pos)
		return false
	end
	
	fuel_pct = math.floor((fuel_burned * 100) / fuel_time)
	meta:set_string("formspec", fns.get_formspec_on(fuel_pct, 0))
	meta:set_string("infotext", "Fuel: " ..  fuel_pct)
	
	return true
end








bitumen.register_burner({"bitumen:engine_on"}, {
	start_cook = function() 
		print("starting-") 
		return 8 
	end,
	finish_cook = function() 
		print("ending-") 
	end,
	get_formspec_on = get_melter_active_formspec,
})

minetest.register_node("bitumen:engine", {
	description = "Engine",
	tiles = {
		"default_bronze_block.png", "default_bronze_block.png",
		"default_bronze_block.png", "default_bronze_block.png",
		"default_bronze_block.png", "default_furnace_front.png",
	},
	paramtype2 = "facedir",
	groups = {cracky=2, petroleum_fixture=1},
	is_ground_content = false,
	sounds = default.node_sound_stone_defaults(),
	--can_dig = can_dig,
	
	--on_timer = burner_on_timer,

	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", get_melter_active_formspec())
		local inv = meta:get_inventory()
		inv:set_size('fuel', 4)
		
		minetest.get_node_timer(pos):start(1.0)
		
	end,

-- 	on_metadata_inventory_move = function(pos)
-- 		minetest.get_node_timer(pos):start(1.0)
-- 	end,
-- 	on_metadata_inventory_put = function(pos)
-- 		-- start timer function, it will sort out whether furnace can burn or not.
-- 		minetest.get_node_timer(pos):start(1.0)
-- 	end,
-- 	
	
	on_punch = function(pos)
		swap_node(pos, "bitumen:engine_on")
		minetest.get_node_timer(pos):start(1.0)
	end,
	
	
-- 	on_blast = function(pos)
-- 		local drops = {}
-- 		default.get_inventory_drops(pos, "src", drops)
-- 		default.get_inventory_drops(pos, "fuel", drops)
-- 		default.get_inventory_drops(pos, "dst", drops)
-- 		drops[#drops+1] = "machines:machine"
-- 		minetest.remove_node(pos)
-- 		return drops
-- 	end,

	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
})

	
minetest.register_node("bitumen:engine_on", {
	description = "Engine",
	tiles = {
		"default_tin_block.png", "default_bronze_block.png",
		"default_bronze_block.png", "default_tin_block.png",
		"default_tin_block.png",
		{
			image = "default_furnace_front_active.png",
			backface_culling = false,
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 1.5
			},
		}
	},
	paramtype2 = "facedir",
	groups = {cracky=2, petroleum_fixture=1, not_in_creative_inventory=1},
	is_ground_content = false,
	sounds = default.node_sound_stone_defaults(),
	--can_dig = can_dig,
	
	on_timer = bitumen.burner_on_timer,

	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", get_melter_active_formspec())
		local inv = meta:get_inventory()
		inv:set_size('fuel', 4)
		
		minetest.get_node_timer(pos):start(1.0)
		
	end,

-- 	on_metadata_inventory_move = function(pos)
-- 		minetest.get_node_timer(pos):start(1.0)
-- 	end,
-- 	on_metadata_inventory_put = function(pos)
-- 		-- start timer function, it will sort out whether furnace can burn or not.
-- 		minetest.get_node_timer(pos):start(1.0)
-- 	end,
-- 	
	
	on_punch = function(pos)
		swap_node(pos, "bitumen:engine")
	end,

	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
})




















--[[	
minetest.register_ore({
      ore_type        = "stratum",
      ore             = "default:meselamp",
      wherein         = {"default:stone"},
      clust_scarcity  = 1,
      y_min           = -8,
      y_max           = 72,
      noise_params    = {
         offset = 32,
         scale = 16,
         spread = {x = 256, y = 256, z = 256},
         seed = 90122,
         octaves = 3,
         persist = 0.5
      },
      np_stratum_thickness = {
         offset = 8,
         scale = 4,
         spread = {x = 128, y = 128, z = 128},
         seed = -316,
         octaves = 1,
         persist = 0.0
      },
   })
]]
