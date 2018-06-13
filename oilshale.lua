
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









local function make_burning_fn(begin_cook, finish_cook)


	local function af_on_timer(pos, elapsed)

		local meta = minetest.get_meta(pos)
		local fuel_time = meta:get_float("fuel_time") or 0
		local fuel_burned = meta:get_float("fuel_burned") or 0
		local cook_time_remaining = meta:get_float("cook_time_remaining") or 0
		local cook_item = meta:get_int("is_cooking") or 0
		
		local inv = meta:get_inventory()
		
		local can_cook = false
		
		local burned = elapsed
		local turn_off = false
		
		print("\n\naf timer")
		print("fuel_burned: " .. fuel_burned)
		print("fuel_time: " .. fuel_time)
		
	-- 	if fuel_burned <= fuel_time or fuel_time == 0 then
	-- 		-- use fuel
	-- 		print("af fuel")
			
		if fuel_time > 0 and fuel_burned + elapsed < fuel_time then

			fuel_burned = fuel_burned + elapsed
			meta:set_float("fuel_burned", fuel_burned + elapsed)
		else
			local t = grab_fuel(inv)
			if t <= 0 then -- out of fuel
				--print("out of fuel")
				meta:set_float("fuel_time", 0)
				meta:set_float("fuel_burned", 0)
				
				burned = fuel_time - fuel_burned
				
				turn_off = true
			else
				-- roll into the next period
				fuel_burned =  elapsed - (fuel_time - fuel_burned)
				fuel_time = t
				
				--print("fuel remaining: " .. (fuel_time - fuel_burned))
			
				meta:set_float("fuel_time", fuel_time)
				meta:set_float("fuel_burned", fuel_burned)
			end
		end
			
	-- 	end
		
		
			
		if cook_item == "" then
			
			
			local cooked = grab_raw_item({x=pos.x, y=pos.y+1, z=pos.z})
			if cooked ~= nil then
				cook_item = cooked.item:to_table()
				cook_time_remaining = cooked.time
				print(cook_item)
				meta:set_string("cook_item", minetest.serialize(cook_item))
				meta:set_float("cook_time_remaining", cooked.time)
			else
				-- nothing to cook, carry on
				print("nothing to cook")
				cook_item = nil
				meta:set_string("cook_item", "")
			end
			
			
		else
			print(cook_item)
			cook_item = minetest.deserialize(cook_item)
		end
		
		
		
		
		if cook_item ~= nil and burned > 0 then
			
			
			local remain = cook_time_remaining - burned
			print("remain: ".. remain);
			if remain > 0 then
				meta:set_float("cook_time_remaining", remain)
			else
				print("finished")
				
				finished_fn(pos, meta)
				
				-- cooking is finished
				
				--meta:set_string("cook_item", "")
				meta:set_float("cook_time_remaining", 0)
			end
			
			
		end
		
		
		
		if turn_off then
			swap_node(pos, "machines:autofurnace_off")
			return
		end
		
		fuel_pct = math.floor((fuel_burned * 100) / fuel_time)
	--	item_pct = math.floor((fuel_burned * 100) / fuel_time)
		meta:set_string("formspec", get_boiler_active_formspec(fuel_pct, 0))
		meta:set_string("infotext", "Fuel: " ..  fuel_pct)
		
		return true
	end


end













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
