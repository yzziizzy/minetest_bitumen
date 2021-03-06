
local pump_formspec =
	"size[10,8;]" ..
	default.gui_bg ..
	default.gui_bg_img ..
	default.gui_slots ..
	"button[5,1;1,4;start;Start]" ..
	"list[current_player;main;0,3.85;8,1;]" ..
	"list[current_player;main;0,5.08;8,3;8]" ..
	"listring[context;main]" ..
	"listring[current_player;main]" ..
	default.get_hotbar_bg(0, 3.85)

local pump_formspec_on =
	"size[10,8;]" ..
	default.gui_bg ..
	default.gui_bg_img ..
	default.gui_slots ..
	"button[5,1;1,4;stop;Stop]" ..
	"list[current_player;main;0,3.85;8,1;]" ..
	"list[current_player;main;0,5.08;8,3;8]" ..
	"listring[context;main]" ..
	"listring[current_player;main]" ..
	default.get_hotbar_bg(0, 3.85)




local function swap_node(pos, name)
	local node = minetest.get_node(pos)
	if node.name == name then
		return
	end
	node.name = name
	minetest.swap_node(pos, node)
end

minetest.register_node("bitumen:pump", {
	description = "Pump",
	drawtype = "normal",
	tiles = {
		"default_steel_block.png^bitumen_arrow.png^[transformR90", "default_steel_block.png^bitumen_arrow.png^[transformR270",
		"default_steel_block.png^bitumen_arrow.png", "default_steel_block.png^bitumen_arrow.png^[transformR180",
		"default_copper_block.png", "default_tin_block.png",
	},
	is_ground_content = false,
	paramtype2 = "facedir",
	groups = {cracky = 1, petroleum_fixture=1, oddly_breakable_by_hand = 3},
	sounds = default.node_sound_glass_defaults(),
	on_place = minetest.rotate_node,
	
	on_construct = function(pos) 
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", pump_formspec)
		
		--bitumen.pipes.on_construct(pos)
	end,
	
	--[[ not working, apparently due to an "undocumented feature" in the engine ;)
	on_receive_fields = function(pos, form, fields, player)
		local meta = minetest:get_meta(pos)
		local mf = meta:get_string("formspec")
		print(dump(mf).."\n")
		
		if fields.start then
			print("start")
			swap_node(pos, "bitumen:pump_on")
			
			-- refetch the meta after the node swap just to be sure
			local meta = minetest:get_meta(pos)
			meta:set_string("formspec", "") 
			meta:set_string("formspec", pump_formspec_on) 
			local mf = meta:get_string("formspec")
			print(dump(mf))
			
			minetest.show_formspec(player:get_player_name(), "", pump_formspec_on)
		end
	end,
	]]
	
	on_punch = function(pos)
		swap_node(pos, "bitumen:pump_on")
	end,
})




minetest.register_node("bitumen:pump_on", {
	description = "Pump (Active)",
	drawtype = "normal",
	tiles = {
		"default_steel_block.png^bitumen_arrow_yellow.png^[transformR90", "default_steel_block.png^bitumen_arrow_yellow.png^[transformR270",
		"default_steel_block.png^bitumen_arrow_yellow.png", "default_steel_block.png^bitumen_arrow_yellow.png^[transformR180",
		"default_copper_block.png", "default_tin_block.png",
	},
	is_ground_content = false,
	paramtype2 = "facedir",
	groups = {cracky = 1, petroleum_fixture=1, oddly_breakable_by_hand = 3, --[[not_in_creaetive_inventory=1]]},
	sounds = default.node_sound_glass_defaults(),
	on_place = minetest.rotate_node,
	drop = "bitumen:pump",
	
	on_construct = function(pos) 
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", pump_formspec_on)
		
		--bitumen.pipes.on_construct(pos)
	end,
	
	--[[ not working, apparently due to an "undocumented feature" in the engine ;)
	on_receive_fields = function(pos, form, fields, player)
		if fields.stop then
			print("stop")
			swap_node(pos, {name="bitumen:pump"})
			
			local meta = minetest:get_meta(pos)
			meta:set_string("formspec", pump_formspec)
			minetest.show_formspec(player:get_player_name(), "", pump_formspec)
		end
	end,
	]]
	
	on_punch = function(pos)
		swap_node(pos, "bitumen:pump")
	end,
})



minetest.register_abm({
	nodenames = {"bitumen:pump_on"},
	interval = 1,
	chance   = 1,
	action = function(pos, node, active_object_count, active_object_count_wider)
		local node   = minetest.get_node(pos)
		
		local back_dir = minetest.facedir_to_dir(node.param2)
		local backpos = vector.add(pos, back_dir) 
		local backnet = bitumen.pipes.get_net(backpos)
		if backnet == nil then
			print("bpump no backnet at "..minetest.pos_to_string(backpos))
			return
		end
		
		local front_dir = vector.multiply(back_dir, -1)
		local frontpos = vector.add(pos, front_dir)
		local frontnet = bitumen.pipes.get_net(frontpos)
		if frontnet == nil then
			print("bpump no frontnet at "..minetest.pos_to_string(frontpos))
			return
		end
		
		if backnet.fluid ~= frontnet.fluid and backnet.fluid ~= "air" then
			print("bpump: bad_fluid")
			return -- incompatible fluids
		end
		
		local lift = 25
		--print("fpos ".. minetest.pos_to_string(frontpos) .. " | bpos "..minetest.pos_to_string(backpos))
		--print("fp ".. frontnet.in_pressure .. " | bp "..backnet.in_pressure)
		-- HACK: hardcoded buffer amount
		local to_take = math.min(20, 64 - backnet.buffer)
		if to_take == 0 then
		--	print("pump: output pipe full")
			return
		end
		
		local taken, fluid = bitumen.pipes.take_fluid(frontpos, to_take)
		local pushed = bitumen.pipes.push_fluid(backpos, fluid, taken, lift)
-- 		print("bitumen pumped " ..taken .. " > "..pushed)
		
		if pushed < taken then
			print("bitumen pump leaked ".. (taken - pushed) .. " at " ..pos.x..","..pos.y..","..pos.z)
		end
		
		--print("")
	end
})






-- gas-powered pump

minetest.register_node("bitumen:pump_gas", {
	description = "Gas-powered Pump",
	drawtype = "normal",
	tiles = {
		"default_steel_block.png^default_obsidian_glass.png^bitumen_arrow.png^[transformR90", "default_steel_block.png^default_obsidian_glass.png^bitumen_arrow.png^[transformR270",
		"default_steel_block.png^default_obsidian_glass.png^bitumen_arrow.png", "default_steel_block.png^default_obsidian_glass.png^bitumen_arrow.png^[transformR180",
		"default_copper_block.png^default_obsidian_glass.png", "default_tin_block.png^default_obsidian_glass.png",
	},
	is_ground_content = false,
	paramtype2 = "facedir",
	groups = {cracky = 1, petroleum_fixture=1, oddly_breakable_by_hand = 3},
	sounds = default.node_sound_glass_defaults(),
	on_place = minetest.rotate_node,
	
	on_construct = function(pos) 
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", pump_formspec)
		
		--bitumen.pipes.on_construct(pos)
	end,
	
	--[[ not working, apparently due to an "undocumented feature" in the engine ;)
	on_receive_fields = function(pos, form, fields, player)
		local meta = minetest:get_meta(pos)
		local mf = meta:get_string("formspec")
		print(dump(mf).."\n")
		
		if fields.start then
			print("start")
			swap_node(pos, "bitumen:pump_on")
			
			-- refetch the meta after the node swap just to be sure
			local meta = minetest:get_meta(pos)
			meta:set_string("formspec", "") 
			meta:set_string("formspec", pump_formspec_on) 
			local mf = meta:get_string("formspec")
			print(dump(mf))
			
			minetest.show_formspec(player:get_player_name(), "", pump_formspec_on)
		end
	end,
	]]
	
	on_punch = function(pos)
		swap_node(pos, "bitumen:pump_gas_on")
	end,
})




minetest.register_node("bitumen:pump_gas_on", {
	description = "Gas-powered Pump (Active)",
	drawtype = "normal",
	tiles = {
		"default_steel_block.png^default_obsidian_glass.png^bitumen_arrow_yellow.png^[transformR90", "default_steel_block.png^default_obsidian_glass.png^bitumen_arrow_yellow.png^[transformR270",
		"default_steel_block.png^default_obsidian_glass.png^bitumen_arrow_yellow.png", "default_steel_block.png^default_obsidian_glass.png^bitumen_arrow_yellow.png^[transformR180",
		"default_copper_block.png^default_obsidian_glass.png", "default_tin_block.png^default_obsidian_glass.png",
	},
	is_ground_content = false,
	paramtype2 = "facedir",
	groups = {cracky = 1, petroleum_fixture=1, oddly_breakable_by_hand = 3, --[[not_in_creaetive_inventory=1]]},
	sounds = default.node_sound_glass_defaults(),
	on_place = minetest.rotate_node,
	drop = "bitumen:pump_gas",
	
	on_construct = function(pos) 
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", pump_formspec_on)
		
		--bitumen.pipes.on_construct(pos)
	end,
	
	--[[ not working, apparently due to an "undocumented feature" in the engine ;)
	on_receive_fields = function(pos, form, fields, player)
		if fields.stop then
			print("stop")
			swap_node(pos, {name="bitumen:pump"})
			
			local meta = minetest:get_meta(pos)
			meta:set_string("formspec", pump_formspec)
			minetest.show_formspec(player:get_player_name(), "", pump_formspec)
		end
	end,
	]]
	
	on_punch = function(pos)
		swap_node(pos, "bitumen:pump_gas")
	end,
})



minetest.register_abm({
	nodenames = {"bitumen:pump_gas_on"},
	interval = 1,
	chance   = 1,
	action = function(pos)
		local node = minetest.get_node(pos)
		
		local meta = minetest.get_meta(pos)
		local fuel = meta:get_int("fuel")
-- 		print("pump fuel "..fuel)
		if fuel <= 0 then
			local below = {x=pos.x, y=pos.y-1, z=pos.z}
			local bnode = minetest.get_node(below)
			if bnode.name == "bitumen:oil_drum" then
				local bmeta = minetest.get_meta(below)
				local fluid = bmeta:get_string("fluid")
				if fluid == "bitumen:gasoline" then
					local fill = bmeta:get_int("fill")
					print("pump fill "..fill)
					if fill >= 1 then
						fill = fill - 1
						bmeta:set_int("fill", fill)
						
						local max_fill = bmeta:get_int("maxfill")
						bmeta:set_string("infotext", fluid .." (".. math.floor(((fill*100)/max_fill)+0.5) .."%)")
						
						fuel = 60
					end
				end
			end
		end
		
		if fuel <= 0 then
-- 			minetest.set_node(pos, {name="bitumen:pump_gas"})
			print("pump out of gas " .. fuel)
			swap_node(pos, "bitumen:pump_gas")
			return
		else
			
			fuel = fuel - 1
			meta:set_int("fuel", fuel)
		end
		
		
		local back_dir = minetest.facedir_to_dir(node.param2)
		local backpos = vector.add(pos, back_dir) 
		local backnet = bitumen.pipes.get_net(backpos)
		if backnet == nil then
			print("bpump no backnet at "..minetest.pos_to_string(backpos))
			return
		end
		
		local front_dir = vector.multiply(back_dir, -1)
		local frontpos = vector.add(pos, front_dir)
		local frontnet = bitumen.pipes.get_net(frontpos)
		if frontnet == nil then
			print("bpump no frontnet at "..minetest.pos_to_string(frontpos))
			return
		end
		
		if backnet.fluid ~= frontnet.fluid and backnet.fluid ~= "air" then
			print("bpump: bad_fluid")
			return -- incompatible fluids
		end
		
		local lift = 50
		--print("fpos ".. minetest.pos_to_string(frontpos) .. " | bpos "..minetest.pos_to_string(backpos))
		--print("fp ".. frontnet.in_pressure .. " | bp "..backnet.in_pressure)
		-- HACK: hardcoded buffer amount
		local to_take = 64 - backnet.buffer
		if to_take <= 0 then
		--	print("pump: output pipe full")
			return
		end
		
		local taken, fluid = bitumen.pipes.take_fluid(frontpos, to_take)
		local pushed = bitumen.pipes.push_fluid(backpos, fluid, taken, lift)
-- 		print("bitumen pumped " ..taken .. " > "..pushed)
		
		if pushed < taken then
			print("bitumen pump leaked ".. (taken - pushed) .. " at " ..pos.x..","..pos.y..","..pos.z)
		end
		
		--print("")
	end
})

