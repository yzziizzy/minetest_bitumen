

minetest.register_craftitem("bitumen:oil_drum_filled", {
	description = "Filled Oil Drum",
	inventory_image = "bitumen_drum_side.png",
	stack_max = 1,
	on_place = function(itemstack, placer, pointed_thing)
		local imeta = itemstack:get_meta()
		local fluid = imeta:get_string("fluid")
		local fill = imeta:get_int("fill")
		local max_fill = imeta:get_int("maxfill")
		
		local pos = minetest.get_pointed_thing_position(pointed_thing, true)
		
		-- todo: check if buildable/ protected/ etc
		minetest.set_node(pos, {name="bitumen:oil_drum"})
		
		local bmeta = minetest.get_meta(pos)
		bmeta:set_string("fluid", fluid)
		bmeta:set_float("fill", fill)
		bmeta:set_float("maxfill", max_fill)
		bmeta:set_string("infotext", fluid .." (".. math.floor(((fill*100)/max_fill)+0.5) .."%)")
	
		itemstack:take_item()
		return itemstack
	end,
})


local function user_name(user)
	return user and user:get_player_name() or ""
end

-- Returns a logging function. For empty names, does not log.
local function make_log(name)
	return name ~= "" and core.log or function() end
end


minetest.register_node("bitumen:oil_drum", {
	description = "Oil Drum",
	tiles = {"bitumen_drum_top.png", "bitumen_drum_bottom.png", "bitumen_drum_side.png",
		"bitumen_drum_side.png", "bitumen_drum_side.png", "bitumen_drum_side.png"},
	paramtype2 = "facedir",
	-- inventory_image = "bitumen_oil_drum.png",
	groups = {
		cracky=2,
		oddly_breakable_by_hand=2,
		oil_container = 1
	},
	paramtype = "light",
	drawtype = "nodebox",
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
	
	stack_max = 99,
	-- tube = tubes_properties,legacy_facedir_simple = true,
-- 	sounds = default.node_sound_wood_defaults(),
	
	on_construct = function(pos)
		local meta = minetest.env:get_meta(pos)
		meta:set_string("infotext", "Oil Drum (Empty)")
		meta:set_string("fluid", "air")
		meta:set_float("fill", "0")
		meta:set_float("maxfill", "48")
		meta:set_string("infotext", "Empty drum")
			-- meta:set_string("fillmax", "200") -- 55 US Gal, 44 Imp. Gal, 200 L
	end,

-- 	can_dig = function(pos, player) 
-- 		local meta = minetest.env:get_meta(pos)
-- 		if meta:get_int('filllevel') > 0 then
-- 			return false
-- 		end
-- 		return true
-- 	end,
	on_dig = function(pos, node, digger)
		local diggername = user_name(digger)
		local log = make_log(diggername)
		local def = minetest.registered_nodes[node.name]
		if def and (not def.diggable or
				(def.can_dig and not def.can_dig(pos, digger))) then
			minetest.log("info", diggername .. " tried to dig "
				.. node.name .. " which is not diggable "
				.. minetest.pos_to_string(pos))
			return
		end

		if minetest.is_protected(pos, diggername) then
			log("action", diggername
					.. " tried to dig " .. node.name
					.. " at protected position "
					.. minetest.pos_to_string(pos))
			minetest.record_protection_violation(pos, diggername)
			return
		end
		
		-- create an item and propagate meta
		local item
		
		local bmeta = minetest.get_meta(pos)
		local fluid = bmeta:get_string("fluid")
		local fill = bmeta:get_int("fill")
		local max_fill = bmeta:get_int("maxfill")
		print("fill: "..fill.." fluid:"..fluid)
		if fill == 0 or fluid == "air" then
			item = ItemStack("bitumen:oil_drum 1")
		else
			item = ItemStack("bitumen:oil_drum_filled 1")
			local imeta = item:get_meta()
			imeta:set_string("fluid", fluid)
			imeta:set_string("infotext", fluid .. " drum")
			imeta:set_float("fill", fill)
			imeta:set_float("maxfill", max_fill)
		end
		
		
		-- check if the digger has enough inventory
		local inv = digger and digger:get_inventory()
		if inv and inv:room_for_item("main", item) then
			inv:add_item("main", item)
		else
			-- can't dig item
			return
		end
		
		minetest.remove_node(pos)
		
		
		-- Run callback
		if def and def.after_dig_node then
			-- Copy pos and node because callback can modify them
			local pos_copy = {x=pos.x, y=pos.y, z=pos.z}
			local node_copy = {name=node.name, param1=node.param1, param2=node.param2}
			def.after_dig_node(pos_copy, node_copy, oldmetadata, digger)
		end

		-- Run script hook
		local _, callback
		for _, callback in ipairs(core.registered_on_dignodes) do
			local origin = minetest.callback_origins[callback]
			if origin then
				minetest.set_last_run_mod(origin.mod)
				--print("Running " .. tostring(callback) ..
				--	" (a " .. origin.name .. " callback in " .. origin.mod .. ")")
			else
				--print("No data associated with callback")
			end

			-- Copy pos and node because callback can modify them
			local pos_copy = {x=pos.x, y=pos.y, z=pos.z}
			local node_copy = {name=node.name, param1=node.param1, param2=node.param2}
			callback(pos_copy, node_copy, digger)
		end
			
	end
})






-- filler

minetest.register_node("bitumen:drum_filler", {
	description = "Petroleum Drum Filler",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{ -.1, -.1, -.1,  .1, .5,  .1},
			{ -.4, -.5, -.4,  .4,  0,  .4},
		},
	},
	selection_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, 0.0, 0.5},
		},
	},
	paramtype = "light",
	is_ground_content = false,
	tiles = { "default_bronze_block.png" },
	walkable = true,
	groups = { cracky = 3, petroleum_fixture = 1 },

})


minetest.register_abm({
	nodenames = {"bitumen:drum_filler"},
	neighbors = {"bitumen:oil_drum"},
	interval = 2,
	chance   = 1,
	action = function(pos, node)
		local npos = {x=pos.x, y=pos.y + 1, z=pos.z}
		local pnet = bitumen.pipes.get_net(npos)
		
		local bpos = {x=pos.x, y=pos.y - 1, z=pos.z}
		local bmeta = minetest.env:get_meta(bpos)
		
		local fluid = bmeta:get_string("fluid")
		local fill = bmeta:get_int("fill")
		local max_fill = bmeta:get_int("maxfill")
		
		if pnet.buffer <= 0 then
			print("barrel filler: no oil in pipe")
			return -- no water in the pipe
		end
		
		if pnet.fluid ~= fluid and fluid ~= "air" then
			print("barrel filler: bad_fluid")
			return -- incompatible fluids
		end
		
		local cap = math.max(max_fill - fill, 0)
		print("cap: "..cap)
		local to_take = math.min(10, math.min(cap, pnet.buffer))
		if to_take == 0 then
			print("barrel full")
			return
		end
		
		local taken, fluid = bitumen.pipes.take_fluid(npos, to_take)
		if fluid == "air" or fill == 0 then
			bmeta:set_string("fluid", pnet.fluid)
		end
		bmeta:set_float("fill", math.min(taken + fill, max_fill))
		
		bmeta:set_string("infotext", fluid .." (".. math.floor(((taken+fill)*100/max_fill)+0.5) .."%)")
		print("barrel took ".. taken)
	end,
})











-- extractor

minetest.register_node("bitumen:drum_extractor", {
	description = "Petroleum Drum Extractor",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{ -.1, -.4, -.1,  .1, .5,  .1},
			{ -.4, -.5, -.4,  .4,  -.3,  .4},
		},
	},
	selection_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, 0.0, 0.5},
		},
	},
	paramtype = "light",
	is_ground_content = false,
	tiles = { "default_tin_block.png" },
	walkable = true,
	groups = { cracky = 3, petroleum_fixture = 1 },

})



minetest.register_abm({
	nodenames = {"bitumen:drum_extractor"},
	neighbors = {"bitumen:oil_drum"},
	interval = 2,
	chance   = 1,
	action = function(pos, node)
		local npos = {x=pos.x, y=pos.y + 1, z=pos.z}
		local pnet = bitumen.pipes.get_net(npos)
		
		local bpos = {x=pos.x, y=pos.y - 1, z=pos.z}
		local bmeta = minetest.env:get_meta(bpos)
		
		local fluid = bmeta:get_string("fluid")
		local fill = bmeta:get_int("fill")
		local max_fill = bmeta:get_int("maxfill")
		
		local lift = 4 
		local max_push = 3
		
		if pnet.buffer >= 64 then
			return
		end
		
		local to_push = math.min(max_push, math.min(64 - pnet.buffer, fill))
		if to_push <= 0 then
			--print("barrel extractor: barrel empty")
			return
		end
		print("to_push: "..to_push)
		
		if pnet.fluid ~= fluid and pnet.fluid ~= "air" then
			--print("barrel extractor: bad fluid")
			return -- incompatible fluids
		end
		
		
		local pushed = bitumen.pipes.push_fluid(npos, fluid, to_push, lift)
		
		bmeta:set_float("fill", math.max(fill - pushed, 0))
		
		bmeta:set_string("infotext", fluid .." (".. math.floor(((fill-pushed)*100/max_fill)+0.5) .."%)")
		--print("barrel pushed ".. pushed)
	end,
})







