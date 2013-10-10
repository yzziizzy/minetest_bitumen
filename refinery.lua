-- need:
-- boiler
-- distillation column
-- bottler?



minetest.register_craft({
	output = 'bitumen:cracking_boiler',
	recipe = {
		{'default:steel_ingot', '',     'default:steel_ingot'},
		{'pipeworks:steel_pipe', 'technic:lv_electric_furnace', 'pipeworks:steel_pipe'},
		{'',                'technic:lv_cable0',               ''},
	}
})
minetest.register_craft({
	output = 'bitumen:cracking_column',
	recipe = {
		{'default:steel_ingot',            '',     'default:steel_ingot'},
		{'default:steel_ingot',            '',    'pipeworks:steel_pipe'},
		{'default:steel_ingot',            '',   'default:steel_ingot'},
	}
})

-- technic.extractor_recipes ={}
--[[
technic.register_extractor_recipe = function(src, src_count, dst, dst_count)
	technic.extractor_recipes[src] = {src_count = src_count, dst_name = dst, dst_count = dst_count}
	if unified_inventory then
		unified_inventory.register_craft({
			type = "extracting",
			output = dst.." "..dst_count,
			items = {src.." "..src_count},
			width = 0,
		})
	end
end

-- Receive an ItemStack of result by an ItemStack input
technic.get_extractor_recipe = function(item)
	if technic.extractor_recipes[item.name] and
	   item.count >= technic.extractor_recipes[item.name].src_count then
		return technic.extractor_recipes[item.name]
	else
		return nil
	end
end]]

-- technic.register_extractor_recipe("technic:coal_dust",        1,          "dye:black",      2)
-- technic.register_extractor_recipe("default:cactus",           1,          "dye:green",      2)


local extractor_formspec =
   "invsize[8,9;]"..
   "label[0,0;Extractor]"..
   "list[current_name;src;3,1;1,1;]"..
   "list[current_name;dst;5,1;2,2;]"..
   "list[current_player;main;0,5;8,4;]"

   
--need pipeworks integration
minetest.register_node("bitumen:cracking_column", {
	description = "Cracking Column Segment",
	tiles = {"technic_lv_grinder_top.png",  "technic_lv_grinder_bottom.png", "technic_lv_grinder_side.png",
	         "technic_lv_grinder_side.png", "technic_lv_grinder_side.png",   "technic_lv_grinder_front.png"},
	paramtype2 = "facedir",
	groups = {cracky=2},
	legacy_facedir_simple = true,
	sounds = default.node_sound_wood_defaults(),
})
   
   
minetest.register_node("bitumen:cracking_boiler", {
	description = "Cracking Column Boiler",
	tiles = {"technic_lv_grinder_top.png",  "technic_lv_grinder_bottom.png", "technic_lv_grinder_side.png",
	         "technic_lv_grinder_side.png", "technic_lv_grinder_side.png",   "technic_lv_grinder_front.png"},
	paramtype2 = "facedir",
	groups = {cracky=2},
	legacy_facedir_simple = true,
	sounds = default.node_sound_wood_defaults(),
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", "Extractor")
		meta:set_string("formspec", extractor_formspec)
		local inv = meta:get_inventory()
		inv:set_size("src", 1)
		inv:set_size("dst", 4)
	end,
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

minetest.register_abm({
	nodenames = {"bitumen:cracking_boiler", "bitumen:cracking_boiler_active"},
	interval = 1,
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
technic.register_machine("LV", "bitumen:cracking_boiler_active", technic.receiver)

energy_density = {
	lpg = { 26 },
	jet_fuel = { 31 },
	gasoline = { 34 },
	diesel = { 37 },
	fuel_oil = { 40 },
	lube_oil = { 43 },
	synth_crude = { 50 }
}

