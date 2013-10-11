 
local oil_drum_max_load = 55

-- oil drum
-- gas can
-- lpg bottle (steel bottle + regulator)
-- large storage containers
-- very large storage container, possibly arbitrarily constructable like nuke reactor



--[[ NEED:
textures:
	steel drum
	medium lpg bottle
	pipes

inv textures:
	plastic gas can
	small lpg bottle
	lpg regulator
	pipes

craft items:
	^ lpg regulator
	small lpg bottle
	gas can
	pipes

register tool:
	gas can
	small lpg bottle

register node:
	oil drum
	medium lpg bottle
	large lpg bottle sections
	pipes

box models:
	medium lpg bottle
	large lpg bottle sections
	oil drum
	pipes

]]

minetest.register_craft({
	output = 'bitumen:oil_drum 2',
	recipe = {
		{'default:steel_ingot', 'technic:rubber','default:steel_ingot'},
		{'default:steel_ingot', '', 'default:steel_ingot'},
		{'default:steel_ingot', 'default:steel_ingot', 'default:steel_ingot'},
	}
})

minetest.register_craft({
	output = 'bitumen:lpg_regulator 4',
	recipe = {
		{'default:brass_ingot', '',                 'default:brass_ingot'},
		{'',                    'bitumen:lpg_pipe', 'bitumen:lpg_pipe'},
		{'',                    'technic:rubber',   ''},
	}
})


minetest.register_craft({
	type = 'shapeless',
	output = 'bitumen:small_lpg_bottle 1',
	recipe = { 'bitumen:lpg_regulator','vessels:steel_bottle' },
	}
})
--[[
minetest.register_node("technic:water_can", {
	description = "Water Can",
	inventory_image = "technic_water_can.png",
	stack_max = 1,
	liquids_pointable = true,
	on_use = function(itemstack, user, pointed_thing)
		
		if pointed_thing.type ~= "node" then
					return end
		n = minetest.env:get_node(pointed_thing.under)
		
		item=itemstack:to_table()
		local load=nil
		if item["metadata"]=="" then load=0 
		else load=tonumber(item["metadata"]) 
		end
		
		if n.name == "default:water_source" then
			if load+1<17 then
			minetest.env:add_node(pointed_thing.under, {name="air"})
			 load=load+1;	
			item["metadata"]=tostring(load)
			technic.set_RE_wear(item,load,water_can_max_load)
			itemstack:replace(item)
			end
			return itemstack
		end
		item=itemstack:to_table()
		if load==0 then return end
			
		if n.name == "default:water_flowing" then
			minetest.env:add_node(pointed_thing.under, {name="default:water_source"})
			load=load-1;	
			item["metadata"]=tostring(load)
			technic.set_RE_wear(item,load,water_can_max_load)
			itemstack:replace(item)
			return itemstack
			end

		n = minetest.env:get_node(pointed_thing.above)
		if n.name == "air" then
			minetest.env:add_node(pointed_thing.above, {name="default:water_source"})
			load=load-1;	
			item["metadata"]=tostring(load)
			technic.set_RE_wear(item,load,water_can_max_load)
			itemstack:replace(item)
			return itemstack
			end		
	end,
})]]

minetest.register_node(":bitumen:oil_drum", {
	description = "Oil Drum",
	tiles = {"technic_copper_chest_top.png", "technic_copper_chest_top.png", "technic_copper_chest_side.png",
		"technic_copper_chest_side.png", "technic_copper_chest_side.png", "technic_copper_chest_front.png"},
	paramtype2 = "facedir",
	inventory_image = "technic_water_can.png",
	--groups = chest_groups1,
	stack_max = 1,
	-- tube = tubes_properties,legacy_facedir_simple = true,
	sounds = default.node_sound_wood_defaults(),
	on_construct = function(pos)
		local meta = minetest.env:get_meta(pos)
		meta:set_string("formspec",
				"invsize[10,10;]"..
				"label[0,0;Copper Chest]"..
				"list[current_name;main;0,1;10,4;]"..
				"list[current_player;main;0,6;8,4;]"..
				"background[-0.19,-0.25;10.4,10.75;ui_form_bg.png]"..
				"background[0,1;10,4;ui_copper_chest_inventory.png]"..
				"background[0,6;8,4;ui_main_inventory.png]")
		meta:set_string("infotext", "Copper Chest")
		local inv = meta:get_inventory()
		inv:set_size("main", 10*4)
	end,

	can_dig = chest_can_dig,
	on_metadata_inventory_move = def_on_metadata_inventory_move,
	on_metadata_inventory_put = def_on_metadata_inventory_put,
	on_metadata_inventory_take = def_on_metadata_inventory_take 
})

minetest.register_tool("bitumen:oil_drum", {
	description = "55 Gallon Oil Drum",
	inventory_image = "technic_battery.png",
	tool_capabilities = {
		charge = 0,
		max_drop_level = 0,
		groupcaps = {
			fleshy = {times={}, uses=10000, maxlevel=0}
		}
	}
})
