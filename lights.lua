
local function swap_node(pos, name)
	local node = minetest.get_node(pos)
	if node.name == name then
		return
	end
	node.name = name
	minetest.swap_node(pos, node)
end


local loffs = {
	{x=0, y=4, z=4},
	{x=0, y=4, z=-4},
	{x=4, y=4, z=0},
	{x=-4, y=4, z=0},
	
	{x=7, y=8, z=7},
	{x=7, y=8, z=-7},
	{x=-7, y=8, z=7},
	{x=-7, y=8, z=-7},
	
	{x=9, y=8, z=0},
	{x=-9, y=8, z=0},
	{x=0, y=8, z=-9},
	{x=0, y=8, z=-9},
	
	
	{x=0, y=16, z=0},
}


local function destruct_light(pos) 

	for _,v in ipairs(loffs) do
		local p = vector.add(pos, v)
		local n = minetest.get_node(p)
		if n.name == "bitumen:magic_light" then
			minetest.set_node(p, {name="air"})
		end
	end
end

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



minetest.register_node("bitumen:kerosene_light", {
	description = "Kerosene Light",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{ -.1, -.4, -.1,  .1, .5,  .1},
			{ -.4, -.5, -.4,  .4,  -.3,  .4},
			{ -.4, .5, -.4,  .41,  .51,  .41},
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
	groups = { cracky = 3, petroleum_fixture = 1 },
	light_source = 1,
	
	on_punch = function(pos)
		swap_node(pos, "bitumen:kerosene_light_on")
		try_turn_on(pos)
	end,
	
	on_destruct = destruct_light,
})


minetest.register_node("bitumen:kerosene_light_on", {
	description = "Kerosene Light",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{ -.1, -.4, -.1,  .1, .5,  .1},
			{ -.4, -.5, -.4,  .4,  -.3,  .4},
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
	light_source = default.LIGHT_MAX,

	on_punch = function(pos)
		swap_node(pos, "bitumen:kerosene_light")
		destruct_light(pos)
	end,
	
	on_destruct = destruct_light,
})

minetest.register_node("bitumen:magic_light", {
	description = "Hidden Magic Light",
	drawtype = "airlike",
--	tiles = {"default_mese.png"},
	paramtype = "light",
	sunlight_propagates = true,
	is_ground_content = false,
	light_source = default.LIGHT_MAX,
})





minetest.register_abm({
	nodenames = {"bitumen:kerosene_light_on"},
--	neighbors = {"bitumen:oil_drum"},
	interval = 60,
	chance   = 1,
	action = function(pos, node)
		try_turn_on(pos)
	end,
})


--[[ cleanup failsafe
minetest.register_abm({
	nodenames = {"bitumen:magic_light"},
	interval = 30,
	chance   = 1,
	action = function(pos, node)
		minetest.set_node(pos, {name="air"})
	end,
})

]]
