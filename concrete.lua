




minetest.register_node("bitumen:concrete", {
	description = "Foundation Concrete",
	drawtype = "normal",
	tiles = {"default_silver_sand.png^[colorize:black:120"},
	groups = {cracky = 1},
})



minetest.register_node("bitumen:concrete_slab", {
	description = "Foundation Concrete Slab",
	drawtype = "nodebox",
	tiles = {"default_silver_sand.png^[colorize:black:120"},
	paramtype = "light",
	paramtype2 = "facedir",
	groups = {cracky = 1},
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, 0.0, 0.5},
		},
	},
})



minetest.register_abm({
	nodenames = {"bitumen:wet_concrete", "bitumen:wet_concrete_full"},
	interval = 5,
	chance   = 5,
	action = function(pos)
		minetest.get_node_timer(pos):start(30*60) -- concrete takes half an hour to cure at best
	end
})

bitumen.register_fluid("bitumen", "wet_concrete", {
	desc = "Wet Concrete",
	groups = {flammable=1, petroleum=1},
	
	colorize = "^[colorize:gray:230",
	post_effect_color = {a = 10, r = 30, g = 20, b = 10},
	
	no_default_soak = true,
	evap_chance = 0,
	
	def = {
		on_timer = function(pos)
			local level = minetest.get_node_level(pos)
			if level > 48 then
				minetest.set_node(pos, {name="bitumen:concrete"})
			elseif level > 16 then
				minetest.set_node(pos, {name="bitumen:concrete_slab"})
			else
				minetest.set_node(pos, {name="air"})
			end
		end
	},
})



minetest.register_node("bitumen:cement_mixer", {
	paramtype = "light",
	drawtype = "mesh",
	mesh = "cement_mixer.obj",
	description = "Cement Mixer",
	inventory_image = "bitumen_cement_mixer_invimg.png",
	tiles = {
		"default_snow.png",
	},
 	selection_box = {
		type = "fixed",
		fixed = {
			{ -.5, -.5, -.5, .5, 1.5, .5 },
			{ 1.5, 1.5, 1.5, -1.5, 4.5, -1.5 },
		},
 	},
 	collision_box = {
		type = "fixed",
		fixed = {
			{ -.5, -.5, -.5, .5, 1.5, .5 },
			{ -1.5, -1.5, -1.5, -1.4, 3, -1.4 },
			{ 1.5, -1.5, -1.5, 1.4, 3, -1.4 },
			{ -1.5, -1.5, 1.5, -1.4, 3, 1.4 },
			{ 1.5, -1.5, 1.5, 1.4, 3, 1.4 },
			{ 1.5, 1.5, 1.5, -1.5, 4.5, -1.5 },
		}
 	},
	paramtype2 = "facedir",
	groups = {choppy=1, petroleum_fixture=1},
	sounds = default.node_sound_wood_defaults(),
	
	on_timer = function(pos, elapsed)
		
		
		
		
	end,
	
	-- spit out some concrete
	on_punch = function(pos)
		print("concrete mixer punched")
		local take = bitumen.pipes.push_fluid({x=pos.x, y=pos.y-1, z=pos.z}, "bitumen:wet_concrete", 20, 5)
		print("take ".. take)
	end,
})

bitumen.register_blueprint({name="bitumen:cement_mixer"})




minetest.register_abm({
	nodenames = {"bitumen:concrete_mixer"},
	interval = 2,
	chance   = 1,
	action = function(pos)
		minetest.get_node_timer(pos):start(30*60) -- concrete takes half an hour to cure at best
	end
})




minetest.register_node("bitumen:chalk", {
	description = "Chalk",
	drawtype = "normal",
	tiles = {"default_clay.png^[colorize:white:80"},
	groups = {crumbly = 3, cracky = 3},
})

minetest.register_node("bitumen:lime", {
	description = "Lime",
	drawtype = "normal",
	tiles = {"default_clay.png^[colorize:white:160"},
	groups = {crumbly = 3},
})


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


minetest.register_ore({
	ore_type        = "blob",
	ore             = "bitumen:chalk",
	wherein         = {"default:stone"},
	clust_scarcity  = 32 * 32 * 32,
	clust_size      = 6,
	y_min           = 2,
	y_max           = 30,
	noise_threshold = 0.0,
	noise_params    = {
		offset = 0.5,
		scale = 0.2,
		spread = {x = 5, y = 5, z = 5},
		seed = -343,
		octaves = 1,
		persist = 0.0
	},		
	biomes = {"savanna", "savanna_shore", "savanna_ocean",
		"rainforest", "rainforest_swamp", "rainforest_ocean", "underground",
		"floatland_coniferous_forest", "floatland_coniferous_forest_ocean"}
})



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
		{ "bucket:bucket_water", "bucket:bucket_empty" }
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
		{ "bucket:bucket_water", "bucket:bucket_empty" }
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
		{ "bucket:bucket_water", "bucket:bucket_empty" }
	}
})








