


local function swap_node(pos, name)
	local node = minetest.get_node(pos)
	if node.name == name then
		return
	end
	node.name = name
	minetest.swap_node(pos, node)
end



minetest.register_craftitem("bitumen:heat", {
	description = "Heat",
	stack_max = 100,
	inventory_image = "bitumen_heat.png",
	groups = {flammable = 3},
})

minetest.register_craft({
	type = "fuel",
	recipe = "bitumen:heat",
	burntime = 10,
})


minetest.register_node("bitumen:heater", {
	description = "Heater",
	tiles = {
		"default_bronze_block.png", "default_bronze_block.png",
		"default_bronze_block.png", "default_bronze_block.png",
		"default_bronze_block.png", "default_furnace_front.png",
	},
	paramtype2 = "facedir",
	groups = {cracky=2, petroleum_fixture=1},
	is_ground_content = false,
	sounds = default.node_sound_stone_defaults(),

	on_punch = function(pos)
		swap_node(pos, "bitumen:heater_on")
	end,
})


minetest.register_node("bitumen:heater_on", {
	description = "Heater (Active)",
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
	
	on_punch = function(pos)
		swap_node(pos, "bitumen:heater")
	end,
})





minetest.register_abm({
	nodenames = {"bitumen:heater_on"},
	interval = 1,
	chance = 1,
	action = function(pos)
		
		local apos = {x=pos.x, y=pos.y + 1, z=pos.z}
		local anode = minetest.get_node(apos)
		if anode.name == "air" then
	--		print("air above")
			return
		end
		
		local ameta = minetest.get_meta(apos)
		local ainv = ameta:get_inventory()
		if ainv:get_size("fuel") <= 0 then
	--		print("no fuel inv")
			return
		end
		
		if ainv:contains_item("fuel", "bitumen:heat 2") then
		--	print("fuel full")
			return -- still full
		end
		
		local node = minetest.get_node(pos)
		local back_dir = minetest.facedir_to_dir(node.param2)
		local backpos = vector.add(pos, back_dir) 
		local backnet = bitumen.pipes.get_net(backpos)
		if backnet == nil then
	--		print("no network")
			return
		end
		
		local max_amount = 1
		
		local taken, fluid = bitumen.pipes.take_fluid(backpos, max_amount)
	--	print("taken " .. fluid .. " " .. taken)
		local heat = bitumen.fluid_to_heat(fluid, taken)
		ainv:add_item("fuel", "bitumen:heat ".. math.floor(heat+.5))
-- 		print("")
		
	--	print("added heat ".. heat)
	end
})




minetest.register_craft({
	output = "bitumen:heater",
	recipe = {
		{"default:tin_ingot", "default:furnace", "default:tin_ingot"},
		{"default:tin_ingot", "default:tin_ingot", "default:tin_ingot"},
		{"default:tin_ingot", "default:tin_ingot", "default:tin_ingot"},
	}
})


