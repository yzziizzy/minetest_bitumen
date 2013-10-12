 
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

sounds:
	metal sounds
	filling sounds

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



bitumen.containers = {}

bitumen.containers.max_fill = {
	{oil_drum = 200},
	{gas_can = 20},
}

-- gas can is a tool
minetest.register_tool("bitumen:gas_can", {
	description = "Gas Can",
	inventory_image = "bitumen_gas_can.png",
	stack_max = 1,
	-- liquids_pointable = true,
	on_use = function(itemstack, user, pointed_thing)
		
		if pointed_thing.type ~= "node" then
					return end
		n = minetest.env:get_node(pointed_thing)
		
		-- only operate on oil givers
		if n.group.oilpipe_give ~= 1 then
			return end
		
		item=itemstack:to_table()
		local fill=nil
		if item["metadata"]=="" then fill=0 
		else fill=tonumber(item["metadata"]) 
		end
		
		-- can is empty
		if fill <= 0 then return end
		
-- 		if n.name == "default:water_source" then
-- 			if load+1<17 then
-- 			minetest.env:add_node(pointed_thing.under, {name="air"})
-- 			 load=load+1;	
-- 			item["metadata"]=tostring(load)
-- 			technic.set_RE_wear(item,load,water_can_max_load)
-- 			itemstack:replace(item)
-- 			end
-- 			return itemstack
-- 		end
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
})

minetest.register_node(":bitumen:oil_drum", {
	description = "Oil Drum",
	tiles = {"technic_copper_chest_top.png", "technic_copper_chest_top.png", "technic_copper_chest_side.png",
		"technic_copper_chest_side.png", "technic_copper_chest_side.png", "technic_copper_chest_front.png"},
	paramtype2 = "facedir",
	-- inventory_image = "bitumen_oil_drum.png",
	groups = {
		cracky=2,
		oddly_breakable_by_hand=2,
		oilpipe=1, 
		oilpipe_receive=1,
		oil_container = 1
	},
	-- stack_max = 99,
	-- tube = tubes_properties,legacy_facedir_simple = true,
	sounds = default.node_sound_wood_defaults(),
	
	on_construct = function(pos)
		local meta = minetest.env:get_meta(pos)
		meta:set_string("infotext", "Oil Drum (Empty)")
		meta:set_string("oiltype", "Empty")
		meta:set_int("filllevel", "0")
		-- meta:set_string("fillmax", "200") -- 55 US Gal, 44 Imp. Gal, 200 L
		local inv = meta:get_inventory()
		inv:set_size("main", 10*4)
	end,

	can_dig = function(pos, player) 
		local meta = minetest.env:get_meta(pos)
		if meta:get_int('filllevel') > 0 then
			return false
		end
		return true
	end,
})

-- minetest.register_tool("bitumen:oil_drum", {
-- 	description = "55 Gallon Oil Drum",
-- 	inventory_image = "technic_battery.png",
-- 	tool_capabilities = {
-- 		charge = 0,
-- 		max_drop_level = 0,
-- 		groupcaps = {
-- 			fleshy = {times={}, uses=10000, maxlevel=0}
-- 		}
-- 	}
-- })
