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
			--local t = bitumen.distillation_stack[height]
			
			ret[height] = {x=pos.x, y=pos.y, z=pos.z}
			
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
		for i,p in ipairs(stack) do
			local fluid = bitumen.distillation_stack[i]
			local yield = bitumen.distillation_yield[fluid] * (input / 100) -- convert to levels
			--print("pushing "..yield.. " " ..fluid.." at "..p.y)
			bitumen.pipes.push_fluid(p, "bitumen:"..fluid, yield, 20)
		end
	end,
	get_formspec_on = get_melter_active_formspec,
}, 5.0)

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


-- TODO: more
bitumen.cracking_yield = {
	["bitumen:tar"] = {
		{"tar", 40},
		{"heavy_oil", 30},
		{"light_oil", 20},
		{"diesel", 10},
	},
	
	["bitumen:heavy_oil"] = {
		{"heavy_oil", 30},
		{"light_oil", 30},
		{"diesel", 30},
		{"kerosene", 10},
	},
	
	["bitumen:light_oil"] = {
		{"light_oil", 30},
		{"diesel", 30},
		{"kerosene", 20},
		{"gasoline", 20},
	},
	
	["bitumen:diesel"] = {
		{"diesel", 20},
		{"kerosene", 30},
		{"gasoline", 25},
		{"mineral_spirits", 25},
	},

	["bitumen:kerosene"] = {
		{"kerosene", 10},
		{"gasoline", 30},
		{"mineral_spirits", 30},
		--lpg = 30,
	},
	
	["bitumen:gasoline"] = {
		{"gasoline", 5},
		{"mineral_spirits", 40},
-- 		lpg = 40,
-- 		ethane = 15,
	},
	
	["bitumen:mineral_spirits"] = {
		{"mineral_spirits", 10},
-- 		lpg = 60,
-- 		ethane = 30,
	},
	
}









-- cracking columns



bitumen.register_burner({"bitumen:cracking_boiler_on"}, {
	start_cook = function() 
		return 2  
	end,
	finish_cook = function(pos) 
		local input, influid = bitumen.pipes.take_fluid(pos, 64)
		if input <= 0 then
			return
		end
		
		local ytable = bitumen.cracking_yield[influid]
		if not ytable then
			return
		end

		local stack = check_stack(pos)
		for i,p in ipairs(stack) do
			local def = ytable[i]
			if not def then
				break
			end
			
			local yield = def[2] * (input / 100) -- convert to levels
			bitumen.pipes.push_fluid(p, "bitumen:"..def[1], yield, 20)
		end
	end,
	get_formspec_on = get_melter_active_formspec,
}, 5.0)

minetest.register_node("bitumen:cracking_boiler", {
	description = "Cracking Column Boiler",
	tiles = {
		"default_bronze_block.png", "default_bronze_block.png",
		"default_bronze_block.png", "default_bronze_block.png",
		"default_bronze_block.png", "default_furnace_front.png",
	},
	paramtype2 = "facedir",
	groups = {cracky=2, petroleum_fixture=1},
	is_ground_content = false,
	sounds = default.node_sound_stone_defaults(),

	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", bitumen.get_melter_active_formspec())
		local inv = meta:get_inventory()
		inv:set_size('fuel', 4)
		
		bitumen.pipes.on_construct(pos)
		
		minetest.get_node_timer(pos):start(1.0)
		
	end,
	
	on_punch = function(pos)
		swap_node(pos, "bitumen:cracking_boiler_on")
		minetest.get_node_timer(pos):start(1.0)
	end,

	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
})


minetest.register_node("bitumen:cracking_boiler_on", {
	description = "Cracking Column Boiler",
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
		swap_node(pos, "bitumen:cracking_boiler")
	end,

	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
})






