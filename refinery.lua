-- need:
-- bottler?

local function mul(t, x)
	local o = {}
	
	for n,i in ipairs(t) do
		o[n] = i * x
	end
	
	o[2] = o[2] / x
	o[5] = o[5] / x
	
	return o
end



 
-- 
-- usage: alternate distillation columns and dist. col. outlets
-- put boiler on the bottom
-- pipe various distillates out
--
--
minetest.register_node("bitumen:distillation_column", {
	paramtype = "light",
	description = "Distillation Column Segment",
	tiles = {"bitumen_cracking_column.png",  "bitumen_cracking_column.png", "bitumen_cracking_column.png",
	         "bitumen_cracking_column.png", "bitumen_cracking_column.png",   "bitumen_cracking_column.png"},
	node_box = {
		type = "fixed",
		fixed = {
			--11.25
			mul({-0.49, -0.5, -0.10, 0.49, 0.5, 0.10}, 1.5),
			mul({-0.10, -0.5, -0.49, 0.10, 0.5, 0.49}, 1.5),
			--22.5
			mul({-0.46, -0.5, -0.19, 0.46, 0.5, 0.19}, 1.5),
			mul({-0.19, -0.5, -0.46, 0.19, 0.5, 0.46}, 1.5),
			-- 33.75
			mul({-0.416, -0.5, -0.28, 0.416, 0.5, 0.28}, 1.5),
			mul({-0.28, -0.5, -0.416, 0.28, 0.5, 0.416}, 1.5),
			--45
			mul({-0.35, -0.5, -0.35, 0.35, 0.5, 0.35}, 1.5),
		},
	},
	selection_box = {
		type = "fixed",
		fixed = {
			mul({-0.5, -0.5, -0.5, 0.5, 0.5, 0.5}, 1.5),
		},
	},
	drawtype = "nodebox",
	groups = {cracky=3,oddly_breakable_by_hand=3 },
	legacy_facedir_simple = true,
	sounds = default.node_sound_wood_defaults(),
	on_construct = function(pos)
		
	end,
})

minetest.register_node("bitumen:distillation_column_outlet", {
	paramtype = "light",
	description = "Distillation Column Outlet",
	tiles = {"bitumen_cracking_column.png",  "bitumen_cracking_column_outlet.png", "bitumen_cracking_column_outlet.png",
	         "bitumen_cracking_column_outlet.png", "bitumen_cracking_column_outlet.png",   "bitumen_cracking_column.png"},
	node_box = {
		type = "fixed",
		fixed = {
			--11.25
			mul({-0.49, -0.5, -0.10, 0.49, 0.5, 0.10}, 1.5),
			mul({-0.10, -0.5, -0.49, 0.10, 0.5, 0.49}, 1.5),
			--22.5
			mul({-0.46, -0.5, -0.19, 0.46, 0.5, 0.19}, 1.5),
			mul({-0.19, -0.5, -0.46, 0.19, 0.5, 0.46}, 1.5),
			-- 33.75
			mul({-0.416, -0.5, -0.28, 0.416, 0.5, 0.28}, 1.5),
			mul({-0.28, -0.5, -0.416, 0.28, 0.5, 0.416}, 1.5),
			--45
			mul({-0.35, -0.5, -0.35, 0.35, 0.5, 0.35}, 1.5),
		},
	},
	selection_box = {
		type = "fixed",
		fixed = {
			mul({-0.5, -0.5, -0.5, 0.5, 0.5, 0.5}, 1.0)
		},
	},
	drawtype = "nodebox",
	groups = {cracky=3,oddly_breakable_by_hand=3, petroleum_fixture=1},
	legacy_facedir_simple = true,
	sounds = default.node_sound_wood_defaults(),
	on_construct = function(pos)
		-- connect to the pipe network
		bitumen.pipes.on_construct(pos)
	end,
})

bitumen.distillation_stack = {
	"tar",
	"heavy_oil",
	"light_oil",
	"diesel",
	"kerosene",
	"gasoline",
	"mineral_spirits",
-- 	"lpg",
}
	
local function check_stack(opos) 
	local ret = { }
	local oh = opos.y
	local pos = {x=opos.x, y=opos.y+1, z=opos.z}
	local height = 0
	local n
	
	while height < 7 do
		local n = minetest.get_node(pos)
		if n.name == "bitumen:distillation_column" then
			-- noop
			--print("col")
		elseif n.name == "bitumen:distillation_column_outlet" then
			height = height+1
			local t = bitumen.distillation_stack[height]
			
			ret[t] = {x=pos.x, y=pos.y, z=pos.z}
			
			--print(t.." at ".. (pos.y).. " - " .. height)
		else
			--print("n "..n.name)
			-- end of the stack
			break
		end
		
		pos.y = pos.y+1
	end
	--print("returning")
	return ret
end


local function dcb_node_timer(pos, elapsed) 
	
	
	
end



local function swap_node(pos, name)
	local node = minetest.get_node(pos)
	if node.name == name then
		return
	end
	node.name = name
	minetest.swap_node(pos, node)
end


bitumen.register_burner({"bitumen:distillation_column_boiler_on"}, {
	start_cook = function() 
		--print("starting") 
		
		return 2  
	end,
	finish_cook = function(pos) 
		--print("y1 ".. pos.y)
		local input = bitumen.pipes.take_fluid(pos, 64)
		---print("crude taken: ".. input)
		if input <= 0 then
			return
		end
		--print("y2 ".. pos.y)
		local stack = check_stack(pos)
		--print("y3 ".. pos.y)
		for fluid,p in pairs(stack) do
			print("pushing "..fluid.." at "..p.y)
			local yield = bitumen.distillation_yield[fluid] * (input / 100) -- convert to levels
			bitumen.pipes.push_fluid(p, "bitumen:"..fluid, yield, 20)
		end
	end,
	get_formspec_on = get_melter_active_formspec,
})

minetest.register_node("bitumen:distillation_column_boiler", {
	description = "Distillation Column Boiler",
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
		meta:set_string("formspec", bitumen.get_melter_active_formspec())
		local inv = meta:get_inventory()
		inv:set_size('fuel', 4)
		
		bitumen.pipes.on_construct(pos)
		
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
		swap_node(pos, "bitumen:distillation_column_boiler_on")
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

	
minetest.register_node("bitumen:distillation_column_boiler_on", {
	description = "Distillation Column Boiler",
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
		meta:set_string("formspec", bitumen.get_melter_active_formspec())
		local inv = meta:get_inventory()
		inv:set_size('fuel', 4)
		
		bitumen.pipes.on_construct(pos)
		
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
		swap_node(pos, "bitumen:distillation_column_boiler")
	end,

	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
})

-- must add up to 100
bitumen.distillation_yield = {
	tar = 20,
	heavy_oil = 20,
	light_oil = 10,
	diesel = 20,
	kerosene = 15,
	gasoline = 10,
	mineral_spirits = 5,
}




bitumen.energy_density = {
	lpg = { 33 },
	jet_fuel = { 40 },
	gasoline = { 30 },
	diesel = { 25 },
	fuel_oil = { 18 },
	lube_oil = { 12 },
	synth_crude = { 10 }
}



--[[
minetest.register_abm({
	nodenames = {"bitumen:cracking_boiler_active"},
	interval = 10,
	chance   = 1,
	action = function(pos, node, active_object_count, active_object_count_wider)
		-- The machine will automatically shut down if disconnected from power in some fashion.
		local meta     = minetest.get_meta(pos)
		local inv      = meta:get_inventory()
		local srcstack = inv:get_stack("src", 1)
		local eu_input = meta:get_int("LV_EU_input")

		-- Machine information
		local machine_name = "Cracking Boiler"
		local machine_node = "bitumen:cracking_boiler"
		local demand       = 1000

		-- Setup meta data if it does not exist.
		if not eu_input then
			meta:set_int("LV_EU_demand", demand)
			meta:set_int("LV_EU_input", 0)
			return
		end

		-- Power off automatically if no longer connected to a switching station
		technic.switching_station_timeout_count(pos, "LV")

		if srcstack then
			src_item = srcstack:to_table()
		end
		if src_item then
			recipe = technic.get_extractor_recipe(src_item)
		end
		if recipe then
			result = {name=recipe.dst_name, count=recipe.dst_count}
		end 
		if inv:is_empty("src") or (not recipe) or (not result) or
		   (not inv:room_for_item("dst", result)) then
			hacky_swap_node(pos, machine_node)
			meta:set_string("infotext", machine_name.." Idle")
			meta:set_int("LV_EU_demand", 0)
			return
		end

		if eu_input < demand then
			-- unpowered - go idle
			hacky_swap_node(pos, machine_node)
			meta:set_string("infotext", machine_name.." Unpowered")
		elseif eu_input >= demand then
			-- Powered
			hacky_swap_node(pos, machine_node.."_active")
			meta:set_string("infotext", machine_name.." Active")

			meta:set_int("src_time", meta:get_int("src_time") + 1)
			if meta:get_int("src_time") >= 4 then -- 4 ticks per output
				meta:set_int("src_time", 0)
				srcstack:take_item(recipe.src_count)
				inv:set_stack("src", 1, srcstack)
				inv:add_item("dst", result)
			end
		end
		meta:set_int("LV_EU_demand", demand)
	end
})

technic.register_machine("LV", "bitumen:cracking_boiler",        technic.receiver)
technic.register_machine("LV", "bitumen:cracking_boiler_active", technic.receiver)]]



