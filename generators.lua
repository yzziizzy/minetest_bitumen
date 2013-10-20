

--[[
	LV, MV, HV.
	different fuels for different outputs/etc.

	need nice craft sequences to make them. 
		engine blocks, pistons, crankshafts, ecu, control panel
	
	need transmission 
		gears for crafting


	generator section
		electric motor


	need enough air blocks nearby to work

	need motor sounds
	
	animated crankshafts
	
]]



minetest.register_craftitem(":bitumen:engine_piston", {
	description = "Engine Piston",
	inventory_image = "bitumen_engine_piston.png",
	on_place_on_ground = minetest.craftitem_place_item,
})


minetest.register_craftitem(":bitumen:engine_crankshaft", {
	description = "Engine Piston",
	inventory_image = "bitumen_engine_crankshaft.png",
	on_place_on_ground = minetest.craftitem_place_item,
})



minetest.register_node("bitumen:gasoline_engine", {
	description = "Engine Piston",
	tiles = { "bitumen_gasoline_engine.png" },
	paramtype = "light",
	groups = {cracky=3},
	sounds = default.node_sound_leaves_defaults(),
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.3, -0.5, -0.5, 0.3, 0.3, 0.5},
			{-0.5, -0.5, -0.3, 0.5, 0.3, 0.3},
			{-0.3, -0.5, -0.3, 0.3, 0.5, 0.3},
		},
	},
	selection_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
		},
	},
	
})


minetest.register_node("bitumen:driveshaft", {
	description = "Driveshaft",
	tiles = { "bitumen_generator_lv.png" },
	paramtype = "light",
	groups = {cracky=3},
	sounds = default.node_sound_leaves_defaults(),
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.3, -0.5, -0.5, 0.3, 0.3, 0.5},
			{-0.5, -0.5, -0.3, 0.5, 0.3, 0.3},
			{-0.3, -0.5, -0.3, 0.3, 0.5, 0.3},
		},
	},
	selection_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
		},
	},
	
})






minetest.register_node("bitumen:electric_generator_lv", {
	description = "LV Electric Generator",
	tiles = { "bitumen_generator_lv.png" },
	paramtype = "light",
	groups = {cracky=3},
	sounds = default.node_sound_leaves_defaults(),
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.3, -0.5, -0.5, 0.3, 0.3, 0.5},
			{-0.5, -0.5, -0.3, 0.5, 0.3, 0.3},
			{-0.3, -0.5, -0.3, 0.3, 0.5, 0.3},
		},
	},
	selection_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
		},
	},
	
})







