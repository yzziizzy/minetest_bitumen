
local function swap_node(pos, name)
	local node = minetest.get_node(pos)
	if node.name == name then
		return
	end
	node.name = name
	minetest.swap_node(pos, node)
end

--[[
local function try_turn_on(pos)

	local bpos = {x=pos.x, y=pos.y - 1, z=pos.z}
	local bnode = minetest.get_node(bpos)
	local bmeta = minetest.env:get_meta(bpos)
	
	if not bmeta or bnode.name ~= "bitumen:oil_drum" then
		swap_node(pos, "bitumen:kerosene_light")
		destruct_light(pos)
		return
	end
	
	local fluid = bmeta:get_string("fluid")
	local fill = bmeta:get_int("fill")
	local max_fill = bmeta:get_int("maxfill")
	
	
	if not fill or fill == 0 then
		swap_node(pos, "bitumen:kerosene_light")
		destruct_light(pos)
		return
	end
	
	local taken = 1

	-- turn on
	for _,v in ipairs(loffs) do
		local p = vector.add(pos, v)
		local n = minetest.get_node(p)
		if n.name == "air" then
			minetest.set_node(p, {name="bitumen:magic_light"})
-- 			else
		
		end
	end
	
	
	bmeta:set_float("fill", math.max(fill - taken, 0))
	bmeta:set_string("infotext", fluid .." (".. math.floor(((fill-taken)*100/max_fill)+0.5) .."%)")
end
]]



local rock_crusher_formspec =
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


local function take_gas(itemstack, amount) 
	
	if st:get_name() ~= "bitumen:oil_drum_filled" end
		return false
	end
	
	local smeta = st:get_meta()
	if smeta:get_float("fluid") ~= "bitumen:gasoline" then
		return false
	end

	local fill = smeta:get_float("fill")
	if fill < amount then
		return false
	end
	
	smeta:set_float("fill", fill - amount)
	
	return true
end


minetest.register_node("bitumen:rock_crusher", {
	description = "Small Gas Rock Crusher",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{ -.5, -.5, -.5,  .5, .5,  .5},
			{ -.7, -.3, -.7,  .7,  .3,  .7},
		},
	},
	selection_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, 0.0, 0.5},
		},
	},
	paramtype = "light",
	is_ground_content = false,
	tiles = { "default_wood.png" },
	walkable = true,
	groups = { cracky = 3, },
	
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		inv:set_size("main", 1)
		
		meta:set_string("formspec", rock_crusher_formspec);
	end,
	
	on_punch = function(pos)
		swap_node(pos, "bitumen:rock_crusher_on")
		try_turn_on(pos)
	end,
		
	on_timer = function(pos, elapsed)
		
		local meta = minetest.get_meta(pos)
		
		local fuel = meta:get_float("fuel") or 0.0
		
		if fuel <= 0 then
			-- try to get some fuel
			local inv = meta:get_inventory()
			
			local st = inv:get_stack("main", 1)
			
			if take_gas(st, 1) then
				inv:set_stack("main", 1, st);
				fuel = fuel + 1
			else
				-- out of fuel, turn off
				return false
			end
			
		end
		
		fuel = fuel - .1
		meta:set_float("fuel", fuel)
		
		-- try to grind some rocks
		
		
		
		
	end
	
})


minetest.register_node("bitumen:rock_crusher_on", {
	description = "Small Gas Rock Crusher",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{ -.5, -.5, -.5,  .5, .5,  .5},
			{ -.7, -.3, -.7,  .7,  .3,  .7},
		},
	},
	selection_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, 0.0, 0.5},
		},
	},
	paramtype = "light",
	is_ground_content = false,
	tiles = { "default_meselamp.png" },
	walkable = true,
	groups = { cracky = 3, petroleum_fixture = 1 },
	
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		inv:set_size("main", 1)
		
		meta:set_string("formspec", rock_crusher_formspec);
	end,
	
	on_punch = function(pos)
		swap_node(pos, "bitumen:rock_crusher")
		destruct_light(pos)
	end,
	

})



