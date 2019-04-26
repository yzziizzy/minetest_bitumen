





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
			if level > 42 then
				minetest.set_node(bpos, {name="bitumen:concrete"})
				minetest.set_node(pos, {name="bitumen:concrete_slab"})
			elseif level > 10 then
				minetest.set_node(bpos, {name="bitumen:concrete"})
				minetest.set_node(pos, {name="air"})
			else
				minetest.set_node(pos, {name="air"})
			end
		else
			if level > 42 then
				minetest.set_node(pos, {name="bitumen:concrete"})
			elseif level > 10 then
				minetest.set_node(pos, {name="bitumen:concrete_slab"})
			else
				minetest.set_node(pos, {name="air"})
			end
		end
	end,
})



minetest.register_abm({
	nodenames = {"bitumen:wet_concrete", "bitumen:wet_concrete_full", "bitumen:curing_concrete"},
	interval = 2,
	chance   = 5,
	catch_up = true,
	action = function(pos)
		local t = minetest.get_node_timer(pos)
		if not t:is_started() then
			t:start(15*60) -- concrete takes 30 minutes to cure at best
	-- 		minetest.get_node_timer(pos):start(5) -- fast cure for debugging
		end
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


local cement_mixer_formspec =
	"size[10,9;]" ..
	default.gui_bg ..
	default.gui_bg_img ..
	default.gui_slots ..
	"list[context;main;0,0.3;5,4;]" ..
	"list[current_player;main;0,4.85;8,1;]" ..
	"list[current_player;main;0,6.08;8,3;8]" ..
	"listring[context;main]" ..
	"listring[current_player;main]" ..
	default.get_hotbar_bg(0, 4.85)


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
	groups = {cracky=1, petroleum_fixture=1},
	sounds = default.node_sound_wood_defaults(),
	
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		inv:set_size("main", 20)
		
		meta:set_string("formspec", cement_mixer_formspec);
	end,
	
	on_timer = function(pos, elapsed)
		
		local meta = minetest.get_meta(pos)
		
		local cache = meta:get_int("cache") or 0
		
		if cache < 32 then
			local inv = meta:get_inventory();
			
			if not inv:contains_item("main", "bitumen:lime 1") then 
				print("not enough lime")
				return false 
			end
			
			if not inv:contains_item("main", "default:gravel 3") then 
				print("not enough gravel")
				return false 
			end

			if not inv:contains_item("main", "bucket:bucket_water 2") then 
				print("not enough water")
				return false 
			end
			
			if not (
				inv:contains_item("main", "default:sand 3") 
			) then
				print("not enough sand")
				return false
			end
			
			inv:remove_item("main", "default:sand 1")
			inv:remove_item("main", "default:sand 1")
			inv:remove_item("main", "default:sand 1")
			inv:remove_item("main", "bitumen:lime 1")
			inv:remove_item("main", "default:gravel 1")
			inv:remove_item("main", "default:gravel 1")
			inv:remove_item("main", "default:gravel 1")
			
			cache = cache + (9 * 64)
		end
		
		
		local pushed = bitumen.pipes.push_fluid({x=pos.x, y=pos.y-1, z=pos.z}, "bitumen:wet_concrete", 32, 1)
		
		meta:set_int("cache", cache - pushed)
		
		return true
	end,
	
	
	can_dig = function(pos, player)
		local meta = minetest.get_meta(pos);
		local inv = meta:get_inventory();
		
		return inv:is_empty("main")
	end,
	
	
	-- spit out some concrete
	on_punch = function(pos)
		local timer = minetest.get_node_timer(pos)
		if timer:is_started() then
			timer:stop()
		else 
			timer:start(3.0)
		end
	end,
})

bitumen.register_blueprint({
	name="bitumen:cement_mixer",
	no_constructor_craft = true,
})




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


