-- need:
-- boiler
-- distillation column
-- bottler?

--[[ NEED:


machine defs:
	synth crude upgrader

]]





-- technic.register_extractor_recipe("technic:coal_dust",        1,          "dye:black",      2)
-- technic.register_extractor_recipe("default:cactus",           1,          "dye:green",      2)





local extractor_formspec =
   "invsize[8,9;]"..
   "label[0,0;Extractor]"..
   "list[current_name;src;3,1;1,1;]"..
   "list[current_name;dst;5,1;2,2;]"..
   "list[current_player;main;0,5;8,4;]"


 
--need pipeworks integration
minetest.register_node("bitumen:distillation_column", {
	paramtype = "light",
	description = "Distillation Column Segment",
	tiles = {"bitumen_cracking_column.png",  "bitumen_cracking_column.png", "bitumen_cracking_column.png",
	         "bitumen_cracking_column.png", "bitumen_cracking_column.png",   "bitumen_cracking_column.png"},
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

minetest.register_node("bitumen:distillation_column_outlet", {
	paramtype = "light",
	description = "Distillation Column Outlet",
	tiles = {"bitumen_cracking_column.png",  "bitumen_cracking_column_outlet.png", "bitumen_cracking_column_outlet.png",
	         "bitumen_cracking_column_outlet.png", "bitumen_cracking_column_outlet.png",   "bitumen_cracking_column.png"},
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
	
local function check_stack(pos) 
	local ret = { }
	local oh = pos.y
	pos.y = pos.y + 1
	local height = 0
	local n
	
	while height < 8*2 do
		if minetest.get_node(pos).name == "bitumen:distillation_column" then
			-- noop
		elseif minetest.get_node(pos).name == "bitumen:distillation_column_outlet" then
			height = height+1
			local t = bitumen.distillation_stack[height]
			
			ret[t] = {x=pos.x, y=pos.y, z=pos.z}
			
			print(t.." at ".. (pos.y).. " - " .. height)
		else
			-- end of the stack
			break
		end
		pos.y = pos.y+1
	end
	
	return ret
end


local function dcb_node_timer(pos, elapsed) 
	
	
	
end


minetest.register_node("bitumen:distillation_column_boiler", {
	description = "Distillation Column Boiler",
	tiles = {"default_steel_block.png",  "default_steel_block.png", "default_steel_block.png",
	         "default_steel_block.png", "default_steel_block.png",   "default_steel_block.png"},
	paramtype2 = "facedir",
	groups = {cracky=2, petroleum_fixture=1},
	sounds = default.node_sound_wood_defaults(),
	can_dig = function(pos,player)
		return true
	end,
	
	on_timer = dcb_node_timer,
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", "Boiler")
		meta:set_string("formspec", "")
		local inv = meta:get_inventory()
		inv:set_size('fuel', 6)
		
		-- connect to the pipe network
		bitumen.pipes.on_construct(pos)
		
		print("constructed")
		minetest.get_node_timer(pos):start(1.0)
		
	end,
	
})

--temp hack for dev
minetest.register_abm({
	nodenames = {"bitumen:distillation_column_boiler"},
	interval = 3,
	chance   = 1,
	action = function(pos, node, active_object_count, active_object_count_wider)
		local stack = check_stack(pos)
		
		for fluid,p in pairs(stack) do
			print("pushing "..fluid.." at "..p.y)
			bitumen.pipes.push_fluid(p, "bitumen:"..fluid, 10, 10)
		end
		
		
	end
})
--[[
minetest.register_node("bitumen:cracking_boiler_active", {
	description = "Cracking Column Boiler",
	tiles = {"technic_lv_grinder_top.png",  "technic_lv_grinder_bottom.png",
	         "technic_lv_grinder_side.png", "technic_lv_grinder_side.png",
	         "technic_lv_grinder_side.png", "technic_lv_grinder_front_active.png"},
	paramtype2 = "facedir",
	groups = {cracky=2, not_in_creative_inventory=1},
	legacy_facedir_simple = true,
	sounds = default.node_sound_wood_defaults(),
	can_dig = function(pos,player)
		local meta = minetest.get_meta(pos);
		local inv = meta:get_inventory()
		if not inv:is_empty("src") or not inv:is_empty("dst") then
			minetest.chat_send_player(player:get_player_name(),
				"Machine cannot be removed because it is not empty");
			return false
		else
			return true
		end
	end,
})
]]
	
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






bitumen.cracking_yield_rate = {
	lpg = 5 ,
	jet_fuel = 1 ,
	gasoline = 4 ,
	diesel = 5,
	fuel_oil = 10,
	lube_oil = 9,
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


--temp hack for dev
minetest.register_abm({
	nodenames = {"bitumen:cracking_boiler", "bitumen:cracking_boiler_active"},
	interval = 3,
	chance   = 1,
	action = function(pos, node, active_object_count, active_object_count_wider)
		local meta     = minetest.get_meta(pos)
		local inv      = meta:get_inventory()
		local srcstack = inv:get_stack("src", 1)
		
		local avail = srcstack:get_count()
		
		local columns = check_cracking_stack(pos)
		for otype,colpos in pairs(columns) do
			local cmeta    = minetest.get_meta(colpos)
			local cinv     = cmeta:get_inventory()
			local dststack = cinv:get_stack("dst", 1)
			
			local yield = bitumen.cracking_yield_rate[otype] 
			
		--	cinv:add_item("dst", )
			
			
		end
		
		-- srcstack:take_item(recipe.src_count)
		-- inv:set_stack("src", 1, srcstack)
		-- inv:add_item("dst", result)
		
	end,
})
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



