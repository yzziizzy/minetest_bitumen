local modpath = minetest.get_modpath("bitumen")

bitumen ={}

-- first, to initialize the pipe API
dofile(modpath.."/pipes.lua")

dofile(modpath.."/fluids.lua")

--dofile(modpath.."/craftitems.lua")
--dofile(modpath.."/containers.lua")

--dofile(modpath.."/pumping.lua")

dofile(modpath.."/pump.lua")
dofile(modpath.."/oilshale.lua")
dofile(modpath.."/wells.lua")
dofile(modpath.."/sphere_tank.lua")

dofile(modpath.."/refinery.lua")



minetest.register_node("bitumen:glass", {
	description = "Glass",
	drawtype = "glasslike_framed_optional",
	tiles = {"default_glass.png", "default_glass_detail.png"},
	special_tiles = {"default_stone.png"},
	paramtype = "light",
	paramtype2 = "glasslikeliquidlevel",
	--param2 = 30;
	sunlight_propagates = true,
	use_texture_alpha = true,
	is_ground_content = false,
	groups = {cracky = 3, oddly_breakable_by_hand = 3},
	sounds = default.node_sound_glass_defaults(),
	on_construct = function(pos) 
		--local n = minetest.get_node(pos)
		--n.param2 = 32
		--minetest.set_node_level(pos, 32)
		--minetest.swap_node(pos, {name = "bitumen:glass", param2 = 120})
	end,
})

local support = {}

minetest.register_abm({
	nodenames = {"bitumen:glass"},
	interval = 1,
	chance = 1,
	action = function(pos)
-- 		minetest.set_node_level(pos, 30)
		local sides = {}
		local on = minetest.get_node(pos)
		
		local npos = {
			{x=pos.x+1, y=pos.y, z=pos.z},
			{x=pos.x-1, y=pos.y, z=pos.z},
			{x=pos.x, y=pos.y, z=pos.z+1},
			{x=pos.x, y=pos.y, z=pos.z-1},
		}

		pos.y = pos.y - 1
		local ym = minetest.get_node(pos)
		local sb = support[minetest.hash_node_position(pos)]
		pos.y = pos.y + 1
		
		
		local hash = minetest.hash_node_position(pos)
		
		if ym.name == "air" then
			local nb = {}
			print("air below")
			
			for _,p in ipairs(npos) do
				local n = minetest.get_node(p)
				nb[n.name] = (nb[n.name] or 0) + 1
			end
			
			if (nb["air"] or 0) == 4 then
				support[hash] = nil
				minetest.spawn_falling_node(pos, on)
				return
			end
			
			if (nb["bitumen:glass"] or 0) > 0 then
				for _,p in ipairs(npos) do
					local s = support[minetest.hash_node_position(p)]
					if s ~= nil then
						print("found support: " .. s)
						support[hash] = math.min(support[hash] or 999, s + 1)
					end
				end
			end
			
			if support[hash] == nil or support[hash] > 4 then
				support[hash] = nil
				minetest.spawn_falling_node(pos, on)
				return
			end
			
		else 
			--print("setting support to 0")
			support[hash] = sb or 0
		end
		
		--minetest.swap_node(pos, {name = "bitumen:glass", param2 = math.random(255)})
	end
})



