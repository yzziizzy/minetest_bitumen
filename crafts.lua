

-- pipes

minetest.register_craft({
	output = "bitumen:pipe 12",
	recipe = {
		{"default:steel_ingot", "default:tin_ingot", "default:steel_ingot"},
		{"", "", ""},
		{"default:steel_ingot", "default:tin_ingot", "default:steel_ingot"},
	}
})

minetest.register_craft({
	output = "bitumen:intake 1",
	type = "shapeless",
	recipe = {"bitumen:pipe", "default:tin_ingot"},
})

minetest.register_craft({
	output = "bitumen:spout 1",
	type = "shapeless",
	recipe = {"bitumen:pipe", "default:copper_ingot"},
})



-- drilling

minetest.register_craft({
	output = 'bitumen:drill_pipe 12',
	recipe = {
		{'', 'default:steel_ingot', ''},
		{'', 'default:steel_ingot', ''},
		{'', 'default:steel_ingot', ''},
	}
})



-- refining

minetest.register_craft({
	output = 'bitumen:distillation_column',
	recipe = {
		{'', 'bitumen:galv_steel_sheet', ''},
		{'', 'bitumen:galv_steel_sheet', ''},
		{'', 'bitumen:galv_steel_sheet', ''},
	}
})

minetest.register_craft({
	output = 'bitumen:distillation_column_outlet',
	recipe = {
		{'',             'bitumen:galv_steel_sheet', ''},
		{'bitumen:pipe', 'bitumen:galv_steel_sheet', 'bitumen:pipe'},
		{'',             'bitumen:galv_steel_sheet', ''},
	}
})


minetest.register_craft({
	output = 'bitumen:distillation_column_boiler',
	type = "shapeless",
	recipe = {
		'bitumen:distillation_column',
		'default:furnace',
	},
})

minetest.register_craft({
	output = 'bitumen:cracking_boiler',
	type = "shapeless",
	recipe = {
		'bitumen:distillation_column',
		'default:furnace',
		'default:silver_sand',
		'default:silver_sand',
	},
})



-- concrete

minetest.register_craft({
	type = 'cooking',
	output = 'bitumen:lime',
	recipe = 'bitumen:chalk',
	cooktime = 5,
})
minetest.register_craft({
	type = 'cooking',
	output = 'bitumen:lime',
	recipe = 'default:coral_brown',
	cooktime = 5,
})
minetest.register_craft({
	type = 'cooking',
	output = 'bitumen:lime',
	recipe = 'default:coral_orange',
	cooktime = 5,
})
minetest.register_craft({
	type = 'cooking',
	output = 'bitumen:lime',
	recipe = 'default:coral_skeleton',
	cooktime = 5,
})


minetest.register_craft({
	output = 'bitumen:mineral_oil_furnace 1',
	recipe = {
		{'default:steel_ingot', 'default:steel_ingot',                   'default:steel_ingot'},
		{'default:steel_ingot', 'bitumen:mineral_oil_furnace_blueprint', 'default:steel_ingot'},
		{'default:steel_ingot', 'default:steel_ingot',                   'default:steel_ingot'},
	}
})




-- concrete's recipe is:
-- ---------------------
-- 1 part cement
-- 2 parts water
-- 3 parts sand
-- 3 parts gravel



-- 3 crafts for combinations of water and river water 
minetest.register_craft( {
	type = "shapeless",
	output = "bitumen:wet_concrete 9",
	recipe = {
		"bitumen:lime",
		"bucket:bucket_water",
		"bucket:bucket_water",
		"group:sand",
		"group:sand",
		"group:sand",
		"default:gravel",
		"default:gravel",
		"default:gravel",
	},
	replacements = {
		{ "bucket:bucket_water", "bucket:bucket_empty" },
		{ "bucket:bucket_water", "bucket:bucket_empty" },
	}
})
minetest.register_craft( {
	type = "shapeless",
	output = "bitumen:wet_concrete 9",
	recipe = {
		"bitumen:lime",
		"bucket:bucket_river_water",
		"bucket:bucket_river_water",
		"group:sand",
		"group:sand",
		"group:sand",
		"default:gravel",
		"default:gravel",
		"default:gravel",
	},
	replacements = {
		{ "bucket:bucket_river_water", "bucket:bucket_empty" },
		{ "bucket:bucket_river_water", "bucket:bucket_empty" },
	}
})
minetest.register_craft( {
	type = "shapeless",
	output = "bitumen:wet_concrete 9",
	recipe = {
		"bitumen:lime",
		"bucket:bucket_water",
		"bucket:bucket_river_water",
		"group:sand",
		"group:sand",
		"group:sand",
		"default:gravel",
		"default:gravel",
		"default:gravel",
	},
	replacements = {
		{ "bucket:bucket_water", "bucket:bucket_empty" },
		{ "bucket:bucket_river_water", "bucket:bucket_empty" },
	}
})



-- blueprints

minetest.register_craft( {
	type = "shapeless",
	output = "bitumen:blueprint_paper",
	recipe = {"default:paper", "dye:blue"},
})

minetest.register_craft({
	output = 'bitumen:blueprint_book',
	recipe = {
		{'bitumen:blueprint_paper'},
		{'bitumen:blueprint_paper'},
		{'bitumen:blueprint_paper'},
	}
})


minetest.register_craft({
	output = 'bitumen:blueprint_bookshelf',
	recipe = {
		{'group:wood', 'group:wood', 'group:wood'},
		{'bitumen:blueprint_book', 'bitumen:blueprint_book', 'bitumen:blueprint_book'},
		{'group:wood', 'group:wood', 'group:wood'},
	}
})


-- barrels 

minetest.register_craft({
	output = "bitumen:drum_filler",
	type = "shapeless",
	recipe = { "bitumen:oil_drum", "bitumen:spout" },
})

minetest.register_craft({
	output = "bitumen:drum_extractor",
	type = "shapeless",
	recipe = { "bitumen:oil_drum", "bitumen:intake" },
})

minetest.register_craft({
	output = "bitumen:oil_drum 3",
	recipe = {
		{"default:tin_ingot",   "default:tin_ingot",   "default:tin_ingot"},
		{"default:steel_ingot", "",                    "default:steel_ingot"},
		{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
	}
})


-- tanks
minetest.register_craft({
	output = "bitumen:galv_steel_sheet 3",
	recipe = {
		{"", "", ""},
		{"", "", ""},
		{"default:steel_ingot", "default:tin_ingot", "default:steel_ingot"},
	}
})

minetest.register_craft({
	output = "bitumen:cylinder_tank 1",
	recipe = {
		{"bitumen:galv_steel_sheet", "bitumen:galv_steel_sheet", "bitumen:galv_steel_sheet"},
		{"bitumen:galv_steel_sheet", "",                         "bitumen:galv_steel_sheet"},
		{"bitumen:galv_steel_sheet", "bitumen:galv_steel_sheet", "bitumen:galv_steel_sheet"},
	}
})


minetest.register_craft({
	output = "bitumen:cylinder_tank_top 1",
	recipe = {
		{"", "bitumen:intake",        ""},
		{"", "bitumen:cylinder_tank", ""},
		{"", "",                      ""},
	}
})

minetest.register_craft({
	output = "bitumen:cylinder_tank_bottom 1",
	recipe = {
		{"", "",                      ""},
		{"", "bitumen:cylinder_tank", ""},
		{"", "bitumen:spout",         ""},
	}
})

minetest.register_craft({
	output = "bitumen:galv_steel_sheet 4",
	type = "shapeless",
	recipe = {"bitumen:cylinder_tank_cracked"},
})


--

minetest.register_craft({
	output = "bitumen:kerosene_light",
	recipe = {
		{"", "",                      ""},
		{"", "default:meselamp", ""},
		{"", "bitumen:drum_extractor",         ""},
	}
})
