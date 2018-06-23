

local function vmin(a, b)
	return {
		x = math.min(a.x, b.x), 
		y = math.min(a.y, b.y), 
		z = math.min(a.z, b.z), 
	}
end
local function vmax(a, b)
	return {
		x = math.max(a.x, b.x), 
		y = math.max(a.y, b.y), 
		z = math.max(a.z, b.z), 
	}
end

local function check_foundation(p1, p2, accept)
	local low = vmin(p1, p2)
	local high = vmax(p1, p2)
	print(dump(low) .. "\n" .. dump(high))
	for x = low.x, high.x do 
	for y = low.y, high.y do 
	for z = low.z, high.z do 
		local n = minetest.get_node({x=x, y=y, z=z})
		if accept[n.name] == nil then
			return false
		end
	end
	end
	end
	
	return true
end



local tank_builder_formspec =
	"size[10,8;]" ..
	default.gui_bg ..
	default.gui_bg_img ..
	default.gui_slots ..
	"list[context;main;0,0.3;4,3;]" ..
	"button[5,1;1,4;build;Build]" ..
	"list[current_player;main;0,3.85;8,1;]" ..
	"list[current_player;main;0,5.08;8,3;8]" ..
	"listring[context;main]" ..
	"listring[current_player;main]" ..
	default.get_hotbar_bg(0, 3.85)


minetest.register_node("bitumen:sphere_tank_constructor", {
	description = "Spherical Tank Constructor",
	drawtype = "normal",
	paramtype2 = "facedir",
	on_rotate = screwdriver.rotate_simple,
	groups = {cracky=1},
	tiles = {
		"default_copper_block.png","default_tin_block.png",
	},
	
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		inv:set_size("main", 12)
		
		meta:set_string("formspec", tank_builder_formspec);
	end,
	

	on_receive_fields = function(pos, form, fields, player)
		
		local meta = minetest.get_meta(pos)
		
		if fields.build then
			-- tanks can only be built on thick foundations
			local ret = check_foundation(
				{x = pos.x - 9, y = pos.y - 3, z = pos.z - 9},
				{x = pos.x + 9, y = pos.y - 1, z = pos.z + 9},
				{
					["default:stone"] = 1,
					["bitumen:concrete"] = 1,
				}
			)
			
			if ret == false then
				minetest.chat_send_player(player:get_player_name(), "Foundation is incomplete: 10x10x3")
				return
			else
				minetest.chat_send_player(player:get_player_name(), "Foundation is complete.")
			end
			
			local inv = meta:get_inventory();
			
			if inv:contains_item("main", "default:steelblock 15") and 
				inv:contains_item("main", "default:coal 20") then
				
				inv:remove_item("main", "default:steelblock 15")
				inv:remove_item("main", "default:coal_lump 20")
			else
				minetest.chat_send_player(player:get_player_name(), "Not enough materials: 15x SteelBlock, 20x Coal Lump")
				return
			end
			
			-- ready to go
			minetest.chat_send_player(player:get_player_name(), "Clear area, construction starting...")
			
			minetest.after(5, function()
				minetest.set_node(pos, {name="bitumen:sphere_tank"})
			end)
		end
	end,
})

minetest.register_craft({
	output = 'bitumen:sphere_tank_constructor',
	recipe = {
		{'default:steelblock', 'default:steelblock', 'default:steelblock'},
		{'default:steelblock', 'vessels:steel_bottle', 'default:steelblock'},
		{'default:steelblock', 'default:steelblock', 'default:steelblock'},
	}
})


minetest.register_node("bitumen:sphere_tank", {
	paramtype = "light",
	drawtype = "mesh",
	mesh = "sphere.obj",
	description = "Spherical Tank",
	tiles = {
		"default_snow.png",
	},
 	inventory_image = "default_snow.png",
 	selection_box = {
		type = "fixed",
		fixed = {
			{ -.5, -.5, -.5, .5, 1.5, .5 },
-- 			{ -8.2, -.5, -.2, -7.8, 10, .2 },
-- 			{ -.2, -.5, -8.2, .2, 10, -7.8 },
-- 			{ 8.2, -.5, -.2, 7.8, 10, .2 },
-- 			{ -.2, -.5, 8.2, .2, 10, 7.8 },
		},
 	},
 	collision_box = {
		type = "fixed",
		fixed = {
			{ -.5, -.5, -.5, .5, 1.5, .5 },
		}
 	},
	paramtype2 = "facedir",
	groups = {choppy=1, petroleum_fixture=1},
	sounds = default.node_sound_wood_defaults(),
	
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		if placer then
			local owner = placer:get_player_name()
			meta:set_string("owner", owner)
		end
		meta:set_float("fluid_level", 0)
		meta:set_float("capacity", math.floor(3.14159 * .75 * 9 * 9 * 9 * 64))
		meta:set_string("infotext", "0%")
	
		bitumen.magic.set_collision_nodes(pos, gensphere({0, 11, 0}, 9.99)) 
		
		bitumen.magic.set_collision_nodes(pos, gencube({8, 0, 0}, {8, 8, 0})) 
		bitumen.magic.set_collision_nodes(pos, gencube({0, 0, 8}, {0, 8, 8})) 
		bitumen.magic.set_collision_nodes(pos, gencube({-8, 0, 0}, {-8, 8, 0})) 
		bitumen.magic.set_collision_nodes(pos, gencube({0, 0, -8}, {0, 8, -8})) 
		
		bitumen.magic.set_collision_nodes(pos, gencube({-6, 0, -6}, {-6, 8, -6})) 
		bitumen.magic.set_collision_nodes(pos, gencube({6, 0, -6}, {6, 8, -6})) 
		bitumen.magic.set_collision_nodes(pos, gencube({-6, 0, 6}, {-6, 8, 6})) 
		bitumen.magic.set_collision_nodes(pos, gencube({6, 0, 6}, {6, 8, 6})) 
		--]]
		
		bitumen.pipes.on_construct(pos)
	end,
	
	on_destruct = bitumen.magic.on_destruct,
	
	can_dig = function(pos, player)
		local meta = minetest.get_meta(pos);
		local owner = meta:get_string("owner")
		local fluid_level = meta:get_float("fluid_level") or 0
		return player:get_player_name() ~= owner and fluid_level <= 0.01 
	end,
})


minetest.register_abm({
	nodenames = {"bitumen:sphere_tank"},
	interval = 1,
	chance   = 1,
	action = function(pos)
		
		local meta = minetest.get_meta(pos)
		local fluid = meta:get_string("fluid") or "air"
		local capacity = meta:get_float("capacity") or 109000
		local fill = meta:get_float("fill_level") or 0
		
 	--	print("tank fill: ".. fill .. " " ..capacity )
		local rem_capacity = capacity - fill
		local can_change = fill <= 0.01
		local pres = (fill / capacity) * 20  -- the tank is roughly 20 nodes tall, nevermind the sphere part
		local cap_take = math.min(rem_capacity, 60)
		
		local delta, new_fluid = bitumen.pipes.buffer(pos, fluid, pres, fill, cap_take, can_change)
-- 		print("delta ".. delta .. " " .. new_fluid)
		if delta > 0.01 or delta < -0.01 then
		
			meta:set_float("fill_level", math.max(math.min(capacity, delta + fill), 0))
			meta:set_string("fluid", new_fluid)
		end
		
-- 		print("")
		
	end
})





-- used to create a large collision box because minetest doesn't allow ones bigger than 3x3x3
minetest.register_node("bitumen:collision_node", {
	paramtype = "light",
	drawtype = "airlike",
	--tiles = {"default_mese.png"},
	walkable = true,
	sunlight_propagates = true,
})


