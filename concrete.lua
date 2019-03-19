





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

minetest.register_node("bitumen:curing_concrete", {
	description = "Foundation Concrete Slab",
	drawtype = "nodebox",
	tiles = {"default_silver_sand.png^[colorize:black:160"},
	paramtype = "light",
	groups = {cracky=1},
	leveled = 64,
	node_box = {
		type = "leveled",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, 0.5, 0.5}, 
		}
	},
	drop = "",
	
	on_timer = function(pos)
		local bpos = {x=pos.x, y=pos.y-1, z=pos.z}
		local bnode = minetest.get_node(bpos)
		
		local level = minetest.get_node_level(pos)
		if bnode and bnode.name == "bitumen:concrete_slab" then
			if level > 48 then
				minetest.set_node(bpos, {name="bitumen:concrete"})
				minetest.set_node(pos, {name="bitumen:concrete_slab"})
			elseif level > 16 then
				minetest.set_node(bpos, {name="bitumen:concrete"})
				minetest.set_node(pos, {name="air"})
			else
				minetest.set_node(pos, {name="air"})
			end
		else
			if level > 48 then
				minetest.set_node(pos, {name="bitumen:concrete"})
			elseif level > 16 then
				minetest.set_node(pos, {name="bitumen:concrete_slab"})
			else
				minetest.set_node(pos, {name="air"})
			end
		end
	end,
})



minetest.register_abm({
	nodenames = {"bitumen:wet_concrete", "bitumen:wet_concrete_full", "bitumen:curing_concrete"},
	interval = 5,
	chance   = 5,
	action = function(pos)
		minetest.get_node_timer(pos):start(15*60) -- concrete takes half an hour to cure at best
-- 		minetest.get_node_timer(pos):start(5) -- fast cure for debugging
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
			minetest.set_node(pos, {name="bitumen:curing_concrete"})
			minetest.set_node_level(pos, level)
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






-- 1 part cement
-- 2 parts water
-- 3 parts sand
-- 3 parts gravel


