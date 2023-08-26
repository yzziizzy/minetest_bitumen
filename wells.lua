





local node_oil_yield = {
	["geology:shale"] = 1,
	["bitumen:oil_shale"] = 3,
}

--[[
The new general plan:        
                             
drill hoist -->  [H] [T]  <-- rig track
steel cable -->   |  [T]  (not crafted, part of the hoist)
drill motor -->  [M] [T]     (moves up and down)
drill pipe -->    |  [T][C]   (pushed into ground)
well head  --> XX[W]XXXXX   (on the ground, check for anchoring)
                  |
drill pipe -->    |
                  |

[C] control boxes, must be connected to the rig track


---- top view ----

   [ ][s][ ][C]
   [ ][W][T][e]
   [ ][d][ ][C]


[s] drill mud supply
[d] drill mud drain
[e] engine

]]

local function find_bottom_of_stack(opos, name)
	local pos = vector.new(opos)
	while 1 == 1 do
		pos.y = pos.y - 1
		
		local n = minetest.get_node(pos)
		if n.name ~= name then
			pos.y = pos.y + 1
			return pos
		end
	end

	return nil
end

local function find_top_of_stack(opos, name)
	local pos = vector.new(opos)
	while 1 == 1 do
		pos.y = pos.y + 1
		
		local n = minetest.get_node(pos)
		if n.name ~= name then
			pos.y = pos.y - 1
			return pos
		end
	end

	return nil
end


local function find_horizontal(pos, name)
	if pos == nil then
		return nil
	end

	local tracks = minetest.find_nodes_in_area(
		{x=pos.x-1, y=pos.y, z=pos.z-1}, 
		{x=pos.x+1, y=pos.y, z=pos.z+1}, 
		{name}
	)
	
	if not tracks or #tracks ~= 1 then
		return nil
	end
	
	return tracks[1]
end



local function find_wellhead_from_track(trackpos)
	if trackpos == nil then return nil end
	
	local pos = find_bottom_of_stack(trackpos, "bitumen:drill_track")
	local head = find_horizontal(pos, "bitumen:well_head")
	
	if head then print("found wellhead ".. dump(head)) end
	
	return head
end


local function find_wellhead(pos)
	local t = find_horizontal(pos, "bitumen:drill_track")
	return find_wellhead_from_track(t), t
end



local function find_well_parts(pos)
	local wh, tr = find_wellhead(pos)
	if wh == nil then return nil end
	
	local dir = {x = wh.x - tr.x, y = 0, z = wh.z - tr.z}
	
	local ttop = find_top_of_stack(tr, "bitumen:drill_track")
	print(dump(ttop))
	
	local parts = minetest.find_nodes_in_area(
		{x=wh.x, y=wh.y + 1, z=wh.z}, 
		{x=wh.x, y=ttop.y, z=wh.z}, 
		{"bitumen:drill_hoist", "bitumen:drill_motor"},
		true
	)
	
	local ret = {
		wh = wh,
		tr_b = tr,
		tr_t = ttop,
		controls = {},
		cur_dir = ""
	}
	
	print(dump(parts))
	
	if parts["bitumen:drill_motor"] then
		ret.motor = parts["bitumen:drill_motor"][1]
	end
	if parts["bitumen:drill_hoist"] then
		ret.hoist = parts["bitumen:drill_hoist"][1]
	end
	
	
	local controls = minetest.find_nodes_in_area(
		{x=tr.x-1, y=tr.y, z=tr.z-1}, 
		{x=tr.x+1, y=ttop.y, z=tr.z+1}, 
		{"group:bitumen_drill_control"},
		true
	)
	
	
	if controls["bitumen:drill_direction_control_down"] then
		ret.controls.dir = controls["bitumen:drill_direction_control_down"][1]
		ret.cur_dir = "down"
	end
	if controls["bitumen:drill_direction_control_up"] then
		ret.controls.dir = controls["bitumen:drill_direction_control_up"][1]
		ret.cur_dir = "up"
	end
	if controls["bitumen:drill_control_on"] then
		ret.controls.power = controls["bitumen:drill_control_on"][1]
	end
	if controls["bitumen:drill_control_off"] then
		ret.controls.power = controls["bitumen:drill_control_off"][1]
	end
	if controls["bitumen:drill_control_mode_drill"] then
		ret.controls.mode = controls["bitumen:drill_control_mode_drill"][1]
		ret.cur_mode = "drill"
	end
	if controls["bitumen:drill_control_mode_retract"] then
		ret.controls.mode = controls["bitumen:drill_control_mode_retract"][1]
		ret.cur_mode = "retract"
	end
	
	if controls["bitumen:drill_oil_pressure_0"] then
		ret.controls.pressure = controls["bitumen:drill_oil_pressure_0"][1]
	end
	if controls["bitumen:drill_oil_pressure_1"] then
		ret.controls.pressure = controls["bitumen:drill_oil_pressure_1"][1]
	end
	if controls["bitumen:drill_oil_pressure_2"] then
		ret.controls.pressure = controls["bitumen:drill_oil_pressure_2"][1]
	end
	if controls["bitumen:drill_oil_pressure_3"] then
		ret.controls.pressure = controls["bitumen:drill_oil_pressure_3"][1]
	end
	if controls["bitumen:drill_oil_pressure_4"] then
		ret.controls.pressure = controls["bitumen:drill_oil_pressure_4"][1]
	end
	

	return ret
end


local function verify_drill_parts(parts)
	if not parts then return false end
	if not parts.wh then return false end
	if not parts.motor then return false end
	if not parts.hoist then return false end
	if not parts.controls.dir then return false end
	if not parts.controls.power then return false end
	if not parts.controls.mode then return false end
	return true
end

local function hoist_motor_up(mpos, replacement)
	local above = {x=mpos.x, y=mpos.y+1, z=mpos.z}
	
	local an = minetest.get_node(above)
	if an.name ~= "bitumen:steel_cable" then
		return false -- todo: error vs reached the top
	end
	
	minetest.set_node(above, {name = "bitumen:drill_motor"})
	minetest.set_node(mpos, {name = replacement})
	
	return true
end
local function hoist_motor_down(mpos)
	local below = {x=mpos.x, y=mpos.y-1, z=mpos.z}
	
	local bn = minetest.get_node(below)
	if bn.name ~= "air" and bn.name ~= "bitumen:drill_pipe" then
		return false -- todo: error vs reached the bottom
	end
	
	minetest.set_node(below, {name = "bitumen:drill_motor"})
	minetest.set_node(mpos, {name = "bitumen:steel_cable"})
	
	return bn.name
end


local stone_oil_content = {
	["default:stone"] = .01,
	["default:desert_stone"] = .01,
	["default:silver_sandstone"] = .02,
	["default:desert_sandstone"] = .02,
	["default:sandstone"] = .02,
	["default:gravel"] = .03,
	["default:sand"] = .01,
	["default:desert_sand"] = .01,
	["default:silver_sand"] = .01,
	["bitumen:oil_shale"] = .1,
	["bitumen:tar_sand"] = .1,
	["geology:shale"] = .05,
	["geology:granite"] = .01,
	["geology:marble"] = .01,
	["technic:granite"] = .01,
	["technic:marble"] = .01,
	["geology:basalt"] = .01,
	["geology:chalk"] = .02,
	["geology:gneiss"] = .01,
	["geology:ors"] = .02,
	["geology:serpentine"] = .005,
	["geology:jade"] = .005,
	["geology:schist"] = .01,
	["geology:slate"] = .02,
	["geology:anthracite"] = .1,
	["default:coalblock"] = .1,

}


local function scan_oil_slice(pos, depth)
	local depth_min = 50;
	local depth_ratio = 5;
	local depth_max = 500;

	local depth_range = depth_max - depth_min

	local d = depth - depth_min;
	if d < 0 then
		d = 0
	elseif d > depth_max then
		d = depth_max
	end
	
	d = depth_ratio * (d / depth_range) 
	
	minetest.forceload_block({x=pos.x-8, y=pos.y, z=pos.z-8}, true)
	minetest.forceload_block({x=pos.x-8, y=pos.y, z=pos.z+8}, true)
	minetest.forceload_block({x=pos.x+8, y=pos.y, z=pos.z-8}, true)
	minetest.forceload_block({x=pos.x+8, y=pos.y, z=pos.z+8}, true)

	local nodes = minetest.find_nodes_in_area(
		{x=pos.x-8, y=pos.y, z=pos.z-8}, 
		{x=pos.x+8, y=pos.y, z=pos.z+8}, 
		{"group:stone", "group:bitumen_mineral", "default:coalblock", "geology:chalk", "geology:anthracite" },
		true
	)
	
	local sum = d
	
	for k,v in pairs(nodes) do
		if stone_oil_content[k] then
			
			for _,v2 in ipairs(v) do
				local x = v2.x - pos.x
				local y = v2.y - pos.y
				
				
				
				sum = sum + stone_oil_content[k] * (((1.4*8) - math.sqrt(x*x + y*y)) / (1.4*8))
			end
		end
	end
	
	return sum
end






local function check_drill_stack(opos) 
	local pos = vector.new(opos)
	pos.y = pos.y - 1
	
	while 1 == 1 do  
		local name = minetest.get_node(pos).name
		if name == "bitumen:drill_pipe" then
		elseif name == "bitumen:drill_mud_extractor" then
		elseif name == "bitumen:drill_mud_injector" then
			-- noop
		else
			-- end of the stack
			break
		end
		pos.y = pos.y - 1
	end
	
	
	print("check stack well depth: "..pos.y)
	
	return {x=pos.x, y=pos.y, z=pos.z}
	
end


-- returns the next node to be drilled
local function get_drill_depth(parts)
	local meta = minetest.get_meta(parts.wh)
	local dp = meta:get_string("drilldepth") or ""
	
	print("dp" .. dump(dp))
	
	if dp == "" then
		--dp = check_drill_stack(pos)
		dp = {x=parts.wh.x, y=parts.wh.y, z=parts.wh.z}
		meta:set_string("drilldepth", minetest.serialize(dp))
	else
		dp = minetest.deserialize(dp)
		--print("deserialized " .. dump(pos))
	end
	
	dp.y = dp.y - 1

	return dp
end

-- saves the deepest node with a drill pipe
local function set_drill_depth(parts, dp)
	local meta = minetest.get_meta(parts.wh)

	meta:set_string("drilldepth", minetest.serialize(dp))
end


local function get_oil_pressure(parts)
	local meta = minetest.get_meta(parts.wh)
	return meta:get_int("oil_pressure") or 0
end


local function add_oil_pressure(parts, amt)
	local meta = minetest.get_meta(parts.wh)
	local dp = meta:get_int("oil_pressure")
	
	if dp == nil then
		dp = 0
	end
	
	dp = dp + amt
	
	meta:set_int("oil_pressure", dp)
	
	return dp
end


local function update_oil_pressure_gauge(parts, oil)
	if not parts.controls.pressure then return end
	
	local nn = minetest.get_node(parts.controls.pressure)
	
	if oil < 100 then
		minetest.set_node(parts.controls.pressure, {param2 = nn.param2, name = "bitumen:drill_oil_pressure_0"})
	elseif oil < 200 then
		minetest.set_node(parts.controls.pressure, {param2 = nn.param2, name = "bitumen:drill_oil_pressure_1"})
	elseif oil < 500 then
		minetest.set_node(parts.controls.pressure, {param2 = nn.param2, name = "bitumen:drill_oil_pressure_2"})
	elseif oil < 700 then
		minetest.set_node(parts.controls.pressure, {param2 = nn.param2, name = "bitumen:drill_oil_pressure_3"})
	else
		minetest.set_node(parts.controls.pressure, {param2 = nn.param2, name = "bitumen:drill_oil_pressure_4"})
	end

	local pmeta = minetest.get_meta(parts.controls.pressure)
	pmeta:set_string("infotext", math.floor(oil + .5))

end


local function mul(t, x)
	local o = {}
	
	for n,i in ipairs(t) do
		o[n] = i * x
	end
	
	o[2] = o[2] / x
	o[5] = o[5] / x
	
	return o
end



minetest.register_node("bitumen:drill_pipe", {
	paramtype = "light",
	description = "Drill Pipe",
	tiles = {"default_copper_block.png",  "default_copper_block.png", "default_copper_block.png",
	         "default_copper_block.png", "default_copper_block.png",   "default_copper_block.png"},
	node_box = {
		type = "fixed",
		fixed = {
			--11.25
			mul({-0.49, -0.5, -0.10, 0.49, 0.5, 0.10}, .3),
			mul({-0.10, -0.5, -0.49, 0.10, 0.5, 0.49}, .3),
			--22.5
			mul({-0.46, -0.5, -0.19, 0.46, 0.5, 0.19}, .3),
			mul({-0.19, -0.5, -0.46, 0.19, 0.5, 0.46}, .3),
			-- 33.75
			mul({-0.416, -0.5, -0.28, 0.416, 0.5, 0.28}, .3),
			mul({-0.28, -0.5, -0.416, 0.28, 0.5, 0.416}, .3),
			--45
			mul({-0.35, -0.5, -0.35, 0.35, 0.5, 0.35}, .3),
		},
	},
	selection_box = {
		type = "fixed",
		fixed = {
			mul({-0.5, -0.5, -0.5, 0.5, 0.5, 0.5}, .3),
		},
	},
	drawtype = "nodebox",
	groups = {cracky=3,oddly_breakable_by_hand=3 },
	legacy_facedir_simple = true,
	sounds = default.node_sound_wood_defaults(),
	on_punch = function(pos)
		check_drill_stack(pos)
	end,
})





minetest.register_node("bitumen:drill_track", {
	description = "Drilling Track",
	tiles = {"bitumen_x_frame.png", "bitumen_x_frame.png", "bitumen_x_frame.png",
	         "bitumen_x_frame.png", "bitumen_x_frame.png", "bitumen_x_frame.png"},
	use_texture_alpha = "clip",
	drawtype = "allfaces",
	paramtype = "light",
	paramtype2 = "facedir",
	groups = { cracky=3, oddly_breakable_by_hand=3 }, -- undiggable: part of the drill rig
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_node("bitumen:drill_hoist", {
	description = "Drilling Hoist",
	tiles = {"bitumen_dark_metal.png", "bitumen_dark_metal.png", "bitumen_dark_metal.png",
	         "bitumen_dark_metal.png", "bitumen_dark_metal.png", "bitumen_dark_metal.png"},
	use_texture_alpha = "clip",
	drawtype = "normal",
	paramtype = "light",
	paramtype2 = "facedir",
	groups = { cracky=3, oddly_breakable_by_hand=3 }, -- undiggable: part of the drill rig
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_node("bitumen:drill_motor", {
	description = "Drilling Motor",
	tiles = {"bitumen_dark_metal.png", "bitumen_dark_metal.png", "bitumen_dark_metal.png",
	         "bitumen_dark_metal.png", "bitumen_dark_metal.png",  "bitumen_dark_metal.png"},
	use_texture_alpha = "clip",
	drawtype = "normal",
	paramtype = "light",
	paramtype2 = "facedir",
	groups = { cracky=3, oddly_breakable_by_hand=3 }, -- undiggable: part of the drill rig
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_node("bitumen:well_head", {
	description = "Well Head",
	tiles = {"bitumen_well_top.png",  "bitumen_dark_metal.png", "bitumen_dark_metal.png",
	         "bitumen_dark_metal.png", "bitumen_dark_metal.png",   "bitumen_dark_metal.png"},
	drawtype = "normal",
	paramtype = "light",
	paramtype2 = "facedir",
	groups = { cracky=3, oddly_breakable_by_hand=3 }, -- undiggable: part of the drill rig
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_node("bitumen:steel_cable", {
	paramtype = "light",
	description = "Steel Cable",
	tiles = {"default_steel_block.png", "default_steel_block.png", "default_steel_block.png",
	         "default_steel_block.png", "default_steel_block.png", "default_steel_block.png"},
	node_box = {
		type = "fixed",
		fixed = {
			{-0.02, -0.5, -0.02, 0.02, 0.5, 0.02},
		},
	},
	selection_box = {
		type = "fixed",
		fixed = {
			{-0.02, -0.5, -0.02, 0.02, 0.5, 0.02},
		},
	},
	drawtype = "nodebox",
	groups = {cracky=3, oddly_breakable_by_hand=3, },
	sounds = default.node_sound_wood_defaults(),
})




minetest.register_node("bitumen:drill_direction_control_up", {
	description = "Drilling Controls (Up)",
	tiles = {"default_steel_block.png", "default_steel_block.png", "default_steel_block.png",
	         "default_steel_block.png", "default_steel_block.png", "default_steel_block.png^bitumen_arrow_up.png"},
	drawtype = "normal",
	paramtype = "light",
	paramtype2 = "facedir",
	groups = { cracky=3, oddly_breakable_by_hand=3, bitumen_drill_control=1 }, -- undiggable: part of the drill rig
	sounds = default.node_sound_wood_defaults(),
	
	on_punch = function(pos)
		local nn = minetest.get_node(pos)
		minetest.set_node(pos, {param2 = nn.param2, name="bitumen:drill_direction_control_down"})
	end,
})

minetest.register_node("bitumen:drill_direction_control_down", {
	description = "Drilling Controls (Down)",
	tiles = {"default_steel_block.png", "default_steel_block.png", "default_steel_block.png",
	         "default_steel_block.png", "default_steel_block.png", "default_steel_block.png^bitumen_arrow_down.png"},
	drawtype = "normal",
	paramtype = "light",
	paramtype2 = "facedir",
	groups = { cracky=3, oddly_breakable_by_hand=3, bitumen_drill_control=1 }, -- undiggable: part of the drill rig
	sounds = default.node_sound_wood_defaults(),
	
	on_punch = function(pos)
		local nn = minetest.get_node(pos)
		minetest.set_node(pos, {param2 = nn.param2, name="bitumen:drill_direction_control_up"})
	end,
	
})


local function siphon_pump_oil(parts)

end



minetest.register_node("bitumen:drill_control_on", {
	description = "Drilling Controls (On)",
	tiles = {"default_steel_block.png", "default_steel_block.png", "default_steel_block.png",
	         "default_steel_block.png", "default_steel_block.png", "default_steel_block.png^bitumen_green_button.png"},
	drawtype = "normal",
	paramtype = "light",
	paramtype2 = "facedir",
	groups = { cracky=3, oddly_breakable_by_hand=3, bitumen_drill_control=1 }, -- undiggable: part of the drill rig
	sounds = default.node_sound_wood_defaults(),

	on_punch = function(pos)
		local nn = minetest.get_node(pos)
		minetest.swap_node(pos, {param2 = nn.param2, name="bitumen:drill_control_off"})
		
	end,
	
	on_timer = function(pos, elapsed) 
		local parts = find_well_parts(pos)
		local nn = minetest.get_node(pos)
		--print(dump(parts))
		
		-- incomplete drill rig
		if not parts or not parts.motor then
			minetest.swap_node(pos, {param2 = nn.param2, name="bitumen:drill_control_off"})
			return
		end
		
		
		if parts.cur_dir == "down" then
			local pipe = hoist_motor_down(parts.motor)
			
			if parts.cur_mode == "drill" then
				if pipe == "bitumen:drill_pipe" then -- dig a node
					local dp = get_drill_depth(parts)
					minetest.forceload_block(dp, true)
					minetest.set_node(dp, {name = "bitumen:drill_pipe"})
					
					local oil = scan_oil_slice(dp, parts.wh.y - dp.y)
					oil = add_oil_pressure(parts, oil)
					
					print(dump(oil))
					
					update_oil_pressure_gauge(parts, oil)
					
					set_drill_depth(parts, dp)
					minetest.get_node_timer(pos):start(2.0)
				else 
					minetest.swap_node(pos, {param2 = nn.param2, name="bitumen:drill_control_off"})
					
					local dn = minetest.get_node(parts.controls.dir)
					minetest.swap_node(parts.controls.dir, {param2 = dn.param2, name="bitumen:drill_direction_control_up"})
				end
			else
				if pipe then
					minetest.get_node_timer(pos):start(1.0)
					
				else 
					minetest.swap_node(pos, {param2 = nn.param2, name="bitumen:drill_control_off"})
					
					local dn = minetest.get_node(parts.controls.dir)
					minetest.swap_node(parts.controls.dir, {param2 = dn.param2, name="bitumen:drill_direction_control_up"})
				end
			end	
			
		else -- up
			-- todo: check the "grab" option
			local replacement
			local dp
			
			if parts.cur_mode == "drill" then -- raise the drill motor, unconnected to the pipe string
				replacement = "air"
				
			elseif parts.cur_mode == "retract" then
				
				dp = get_drill_depth(parts)
				dp.y = dp.y + 1
				
				minetest.forceload_block(dp, true)
				local dn = minetest.get_node(dp)
				print(dump(dn))
				if dn.name == "bitumen:drill_pipe" then
					replacement = "bitumen:drill_pipe"
				else
					replacement = "air"
				end
				
			else
				return
			end
			
			if hoist_motor_up(parts.motor, replacement) then
				minetest.get_node_timer(pos):start(1.0)
				
				if replacement == "bitumen:drill_pipe" then
					minetest.forceload_block(dp, true)
					minetest.set_node(dp, {name="air"})
					dp.y = dp.y + 1
					set_drill_depth(parts, dp)
				end
				
			else
				minetest.swap_node(pos, {param2 = nn.param2, name="bitumen:drill_control_off"})
				
				local dn = minetest.get_node(parts.controls.dir)
				minetest.swap_node(parts.controls.dir, {param2 = dn.param2, name="bitumen:drill_direction_control_down"})
			end
		end
		
	end
})

minetest.register_node("bitumen:drill_control_off", {
	description = "Drilling Controls (Off)",
	tiles = {"default_steel_block.png", "default_steel_block.png", "default_steel_block.png",
	         "default_steel_block.png", "default_steel_block.png", "default_steel_block.png^bitumen_red_button.png"},
	drawtype = "normal",
	paramtype = "light",
	paramtype2 = "facedir",
	groups = { cracky=3, oddly_breakable_by_hand=3, bitumen_drill_control=1 }, -- undiggable: part of the drill rig
	sounds = default.node_sound_wood_defaults(),
	
	on_punch = function(pos)
		local nn = minetest.get_node(pos)
		minetest.swap_node(pos, {param2 = nn.param2, name="bitumen:drill_control_on"})
		minetest.get_node_timer(pos):start(2.0)
	end,
	
})

minetest.register_node("bitumen:drill_control_mode_drill", {
	description = "Drilling Controls (Drill)",
	tiles = {"default_steel_block.png", "default_steel_block.png", "default_steel_block.png",
	         "default_steel_block.png", "default_steel_block.png", "default_steel_block.png^bitumen_drill_icon.png"},
	drawtype = "normal",
	paramtype = "light",
	paramtype2 = "facedir",
	groups = { cracky=3, oddly_breakable_by_hand=3, bitumen_drill_control=1 },
	sounds = default.node_sound_wood_defaults(),
	
	on_punch = function(pos)
		local nn = minetest.get_node(pos)
		minetest.swap_node(pos, {param2 = nn.param2, name="bitumen:drill_control_mode_retract"})
	end,
})

minetest.register_node("bitumen:drill_control_mode_retract", {
	description = "Drilling Controls (Retract)",
	tiles = {"default_steel_block.png", "default_steel_block.png", "default_steel_block.png",
	         "default_steel_block.png", "default_steel_block.png", "default_steel_block.png^bitumen_retract_icon.png"},
	drawtype = "normal",
	paramtype = "light",
	paramtype2 = "facedir",
	groups = { cracky=3, oddly_breakable_by_hand=3, bitumen_drill_control=1 },
	sounds = default.node_sound_wood_defaults(),
	
	on_punch = function(pos)
		local nn = minetest.get_node(pos)
		minetest.swap_node(pos, {param2 = nn.param2, name="bitumen:drill_control_mode_drill"})
	end,
})

minetest.register_node("bitumen:drill_oil_pressure_0", {
	description = "Oil Pressure Guage",
	tiles = {"default_steel_block.png", "default_steel_block.png", "default_steel_block.png",
	         "default_steel_block.png", "default_steel_block.png", "default_steel_block.png^bitumen_bar_background.png"},
	drawtype = "normal",
	paramtype = "light",
	paramtype2 = "facedir",
	groups = { cracky=3, oddly_breakable_by_hand=3, bitumen_drill_control=1 },
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_node("bitumen:drill_oil_pressure_1", {
	description = "Oil Pressure Guage",
	tiles = {"default_steel_block.png", "default_steel_block.png", "default_steel_block.png",
	         "default_steel_block.png", "default_steel_block.png", "default_steel_block.png^bitumen_bar_background.png^bitumen_red_bar.png"},
	drawtype = "normal",
	paramtype = "light",
	paramtype2 = "facedir",
	groups = { cracky=3, oddly_breakable_by_hand=3, bitumen_drill_control=1, not_in_creative_inventory=1 },
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_node("bitumen:drill_oil_pressure_2", {
	description = "Oil Pressure Guage",
	tiles = {"default_steel_block.png", "default_steel_block.png", "default_steel_block.png",
	         "default_steel_block.png", "default_steel_block.png", "default_steel_block.png^bitumen_bar_background.png^bitumen_red_bar.png^bitumen_orange_bar.png"},
	drawtype = "normal",
	paramtype = "light",
	paramtype2 = "facedir",
	groups = { cracky=3, oddly_breakable_by_hand=3, bitumen_drill_control=1, not_in_creative_inventory=1 },
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_node("bitumen:drill_oil_pressure_3", {
	description = "Oil Pressure Guage",
	tiles = {"default_steel_block.png", "default_steel_block.png", "default_steel_block.png",
	         "default_steel_block.png", "default_steel_block.png", "default_steel_block.png^bitumen_bar_background.png^bitumen_red_bar.png^bitumen_orange_bar.png^bitumen_yellow_bar.png"},
	drawtype = "normal",
	paramtype = "light",
	paramtype2 = "facedir",
	groups = { cracky=3, oddly_breakable_by_hand=3, bitumen_drill_control=1, not_in_creative_inventory=1 },
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_node("bitumen:drill_oil_pressure_4", {
	description = "Oil Pressure Guage",
	tiles = {"default_steel_block.png", "default_steel_block.png", "default_steel_block.png",
	         "default_steel_block.png", "default_steel_block.png", "default_steel_block.png^bitumen_bar_background.png^bitumen_red_bar.png^bitumen_orange_bar.png^bitumen_yellow_bar.png^bitumen_green_bar.png"},
	drawtype = "normal",
	paramtype = "light",
	paramtype2 = "facedir",
	groups = { cracky=3, oddly_breakable_by_hand=3, bitumen_drill_control=1, not_in_creative_inventory=1 },
	sounds = default.node_sound_wood_defaults(),
})







minetest.register_node("bitumen:drill_pump_on", {
	description = "Drilling Pump (On)",
	tiles = {"default_bronze_block.png",  "default_bronze_block.png", "default_bronze_block.png",
	         "default_bronze_block.png", "default_bronze_block.png",   "default_bronze_block.png"},
	drawtype = "normal",
	paramtype = "light",
	paramtype2 = "facedir",
	groups = { cracky=3, oddly_breakable_by_hand=3, bitumen_drill_control=1 }, -- undiggable: part of the drill rig
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_node("bitumen:drill_pump_off", {
	description = "Drilling Pump (Off)",
	tiles = {"default_bronze_block.png",  "default_bronze_block.png", "default_bronze_block.png",
	         "default_bronze_block.png", "default_bronze_block.png",   "default_bronze_block.png"},
	drawtype = "normal",
	paramtype = "light",
	paramtype2 = "facedir",
	groups = { cracky=3, oddly_breakable_by_hand=3, bitumen_drill_control=1 }, -- undiggable: part of the drill rig
	sounds = default.node_sound_wood_defaults(),
})





minetest.register_node("bitumen:well_siphon", {
	paramtype = "light",
	description = "Well Siphon",
	tiles = {"default_bronze_block.png",  "default_bronze_block.png", "default_bronze_block.png",
	         "default_bronze_block.png", "default_bronze_block.png",   "default_bronze_block.png"},
	node_box = {
		type = "connected",
		fixed = {
			--11.25
			{-0.49, -0.5, -0.10, 0.49, 0.4, 0.10},
			{-0.10, -0.5, -0.49, 0.10, 0.4, 0.49},
			--22.5
			{-0.46, -0.5, -0.19, 0.46, 0.4, 0.19},
			{-0.19, -0.5, -0.46, 0.19, 0.4, 0.46},
			-- 33.75
			{-0.416, -0.5, -0.28, 0.416, 0.4, 0.28},
			{-0.28, -0.5, -0.416, 0.28, 0.4, 0.416},
			--45
			{-0.35, -0.5, -0.35, 0.35, 0.4, 0.35},
		},
		connect_top = {{ -.1, .3, -.1,  .1, .5,  .1}},
	},
	selection_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
		},
	},
	connects_to = { "group:petroleum_pipe"--[[, "group:petroleum_fixture"]]},
	drawtype = "nodebox",
	groups = {cracky=3,oddly_breakable_by_hand=3, petroleum_fixture=1 },
	legacy_facedir_simple = true,
	sounds = default.node_sound_wood_defaults(),
	on_construct = bitumen.pipes.on_construct,
	after_destruct = bitumen.pipes.after_destruct,
})


minetest.register_abm({
	nodenames = {"bitumen:well_siphon"},
	neighbors = {"bitumen:well_head"},
	interval = 5,
	chance = 1,
	action = function(pos)
		
		local exnet = bitumen.pipes.get_net(pos)
		if exnet and (exnet.fluid == "bitumen:crude_oil" or exnet.fluid == "air") then
			-- pump oil
			local dp = {x=pos.x, y=pos.y-1, z=pos.z}
			local oil = get_oil_pressure({wh = dp})
			
			local p = bitumen.pipes.push_fluid(pos, "bitumen:crude_oil", oil / 10, 20)
			
		else
			-- must empty the mud out of the pipe first
			
			print("well not connected " .. dump(exnet))
		end
	end
})







bitumen.register_blueprint({
	name="bitumen:drill_track",
	no_constructor_craft = true,
})
bitumen.register_blueprint({
	name="bitumen:well_head",
	no_constructor_craft = true,
})
bitumen.register_blueprint({
	name="bitumen:well_siphon",
	no_constructor_craft = true,
})
bitumen.register_blueprint({
	name="bitumen:drill_motor",
	no_constructor_craft = true,
})
bitumen.register_blueprint({
	name="bitumen:drill_hoist",
	no_constructor_craft = true,
})

bitumen.register_blueprint({
	name="bitumen:drill_control_mode_retract",
	no_constructor_craft = true,
})

bitumen.register_blueprint({
	name="bitumen:drill_oil_pressure_0",
	no_constructor_craft = true,
})

bitumen.register_blueprint({
	name="bitumen:drill_control_off",
	no_constructor_craft = true,
})

bitumen.register_blueprint({
	name="bitumen:drill_direction_control_down",
	no_constructor_craft = true,
})




minetest.register_craft({
	output = 'bitumen:drill_track',
	type = "shapeless",
	recipe = {
		'bitumen:drill_track_blueprint',
		'default:steel_ingot',
		'default:steel_ingot'
	},
	replacements = {
		{ 'bitumen:drill_track_blueprint', 'bitumen:drill_track_blueprint' },
	}
})

minetest.register_craft({
	output = 'bitumen:well_head',
	type = "shapeless",
	recipe = {
		'bitumen:well_head_blueprint',
		'default:steelblock',
	},
	replacements = {
		{ 'bitumen:well_head_blueprint', 'bitumen:well_head_blueprint' },
	}
})

minetest.register_craft({
	output = 'bitumen:well_siphon',
	type = "shapeless",
	recipe = {
		'bitumen:well_siphon_blueprint',
		'default:steelblock',
	},
	replacements = {
		{ 'bitumen:well_siphon_blueprint', 'bitumen:well_siphon_blueprint' },
	}
})

minetest.register_craft({
	output = 'bitumen:drill_motor',
	type = "shapeless",
	recipe = {
		'bitumen:drill_motor_blueprint',
		'default:steelblock',
	},
	replacements = {
		{ 'bitumen:drill_motor_blueprint', 'bitumen:drill_motor_blueprint' },
	}
})

minetest.register_craft({
	output = 'bitumen:drill_hoist',
	type = "shapeless",
	recipe = {
		'bitumen:drill_hoist_blueprint',
		'default:steelblock',
	},
	replacements = {
		{ 'bitumen:drill_hoist_blueprint', 'bitumen:drill_hoist_blueprint' },
	}
})

minetest.register_craft({
	output = 'bitumen:drill_control_mode_retract',
	type = "shapeless",
	recipe = {
		'bitumen:drill_control_mode_retract_blueprint',
		'default:steelblock'
	},
	replacements = {
		{ 'bitumen:drill_control_mode_retract_blueprint', 'bitumen:drill_control_mode_retract_blueprint' },
	}
})

minetest.register_craft({
	output = 'bitumen:drill_oil_pressure_0',
	type = "shapeless",
	recipe = {
		'bitumen:drill_oil_pressure_0_blueprint',
		'default:steelblock'
	},
	replacements = {
		{ 'bitumen:drill_oil_pressure_0_blueprint', 'bitumen:drill_oil_pressure_0_blueprint' },
	}
})

minetest.register_craft({
	output = 'bitumen:drill_control_off',
	type = "shapeless",
	recipe = {
		'bitumen:drill_control_off_blueprint',
		'default:steelblock'
	},
	replacements = {
		{ 'bitumen:drill_control_off_blueprint', 'bitumen:drill_control_off_blueprint' },
	}
})

minetest.register_craft({
	output = 'bitumen:drill_direction_control_down',
	type = "shapeless",
	recipe = {
		'bitumen:drill_direction_control_down_blueprint',
		'default:steelblock'
	},
	replacements = {
		{ 'bitumen:drill_direction_control_down_blueprint', 'bitumen:drill_direction_control_down_blueprint' },
	}
})










































-- old stuff


local function pushpos(t, v, p)
	local h = minetest.hash_node_position(p)
	if v[h] == nil then
		table.insert(t, p)
	end
end


local function find_blob_extent(startpos)
	
	local blob = {}
	local stack = {}
	local visited = {}
	local future = {}
--	local shell = {}
	
	
	local node = minetest.get_node(startpos)
	if node.name == "air" then
		return nil
	end
	
	local bname = node.name
	
	table.insert(stack, startpos)
	
	while #stack > 0 do
		
		local p = table.remove(stack)
		local ph = minetest.hash_node_position(p)
		
		--print("visiting "..minetest.pos_to_string(p))
		if p.x < startpos.x - 50
			or p.x > startpos.x + 50
			or p.y < startpos.y - 50
			or p.y > startpos.y + 50
			or p.z < startpos.z - 50
			or p.z > startpos.z + 50
		then
			print("got to extent")
			visited[ph] = 1
		end
		
		if visited[ph] == nil then
			
			print("visiting "..minetest.pos_to_string(p))
			
			local pn = minetest.get_node(p)
			if pn then
				if pn.name == "bitumen:crude_oil" or pn.name == "bitumen:crude_oil_full" then
					blob[ph] = {x=p.x, y=p.y, z=p.z}
					
					pushpos(stack, visited, {x=p.x+1, y=p.y, z=p.z})
					pushpos(stack, visited, {x=p.x-1, y=p.y, z=p.z})
					pushpos(stack, visited, {x=p.x, y=p.y+1, z=p.z})
					pushpos(stack, visited, {x=p.x, y=p.y-1, z=p.z})
					pushpos(stack, visited, {x=p.x, y=p.y, z=p.z+1})
					pushpos(stack, visited, {x=p.x, y=p.y, z=p.z-1})
					
					visited[ph] = 1
				elseif pn.name == "ignore" then
					if minetest.forceload_block(p, false) then
						print("forceload successful: ".. minetest.pos_to_string(p))
					else
						print("forceload failed: ".. minetest.pos_to_string(p))
					end
					
					table.insert(future, p)
				end
			else
				print("failed to get node")
			end
		end
	end
	
	
	for _,p in pairs(blob) do
		print("blob "..minetest.pos_to_string(p))
	end
	
--	for n,v in pairs(shell) do
--		print("shell "..n.." - ".. v)
--	end
	
	
	return blob--, shell
end




local function forceload_deposit(pos) 
-- 	minetest.emerge_area(dp, {x=dp.x, y=dp.y - 20, z=dp.z})
	find_blob_extent(pos)
end


local function drill(pos)
	
	local meta = minetest.get_meta(pos)
	local dp = meta:get_string("drilldepth") or ""
	print("dp" .. dump(dp))
	if dp == "" then
		dp = check_drill_stack(pos)
		meta:set_string("drilldepth", minetest.serialize(dp))
	else
		dp = minetest.deserialize(dp)
		--print("deserialized " .. dump(pos))
		dp.y = dp.y - 1
	end
	
	
	local n = minetest.get_node(dp)
	
	
	if n.name == "ignore" then
		if minetest.forceload_block(dp, true) then
			print("forceload successful: ".. minetest.pos_to_string(dp))
			
			local n = minetest.get_node(dp)
		else 
			--minetest.emerge_area(dp, {x=dp.x, y=dp.y - 20, z=dp.z})
		--	print("forceload failed, emerging " .. minetest.pos_to_string(dp))
		--	return
		end
--		minetest.emerge_area(pos, pos)
	end
	
	local hit_oil = false
	if n.name == "ignore" then
		minetest.emerge_area(dp, {x=dp.x, y=dp.y - 20, z=dp.z})
		print("emerging " .. minetest.pos_to_string(dp))
		
		return
	elseif n.name == "bitumen:drill_pipe" or n.name == "bitumen:drill_mud_injector" or n.name == "bitumen:drill_mud_extractor"then
		dp = check_drill_stack(dp)
	elseif n.name == "bitumen:crude_oil" or n.name == "bitumen:crude_oil_full" then
		pos.y = pos.y + 2
		minetest.set_node(pos, {name = "bitumen:crude_oil"})
		minetest.set_node_level(pos, 64)
		hit_oil = true
	else
		print("drilling at "..dp.y.." of "..n.name )
		minetest.set_node(dp, {name = "bitumen:drill_pipe"})
	end
	
	meta:set_string("drilldepth", minetest.serialize(dp))
	
	local desc = minetest.registered_nodes[n.name].description
	if n.name == "air" then
		desc = "Air" -- because of a cheeky description in the default game
	end
	
	return desc, dp.y, hit_oil
end


minetest.register_node("bitumen:drill_controls", {
	description = "Drilling Controls",
	tiles = {"default_bronze_block.png",  "default_bronze_block.png", "default_bronze_block.png",
	         "default_bronze_block.png", "default_bronze_block.png",   "default_bronze_block.png"},
	drawtype = "normal",
	paramtype = "light",
	paramtype2 = "facedir",
	groups = { }, -- undiggable: part of the drill rig
	sounds = default.node_sound_wood_defaults(),
	
	on_receive_fields = function(pos, form, fields, player)
		
		local cmd = "none"
		if fields.drill then
			cmd = "drill"
		elseif fields.retract then
			cmd = "retract"
		elseif fields.stop then
			cmd = "stop"
		elseif fields.pump then
			cmd = "pump"
		elseif fields.up then
			cmd = "up"
		elseif fields.down then
			cmd = "down"
		elseif fields.explore then
			cmd = "explore"
		elseif fields.forceload then
			cmd = "forceload"
		elseif fields.un_forceload then
			cmd = "un_forceload"
		end
		
		if cmd ~= "none" then
			local meta = minetest.get_meta(pos)
			local dpos = minetest.deserialize(meta:get_string("magic_parent"))
			local dmeta = minetest.get_meta(dpos)
			--print(dump(dpos))
			
			--if 1==1 then return end
			local state = minetest.deserialize(dmeta:get_string("state")) 
			
			state.command = cmd
			dmeta:set_string("state", minetest.serialize(state))
		end
	end,
	
-- 	on_rick_click = function(pos, node, player, itemstack, pointed_thing)
-- 		minetest.show_formspec(player:get_player_name(), fs)]]
-- 		return itemstack -- don't take anything
-- 	end,
})

minetest.register_node("bitumen:drill_pipe_chest", {
	description = "Drilling Controls",
	tiles = {"default_bronze_block.png",  "default_bronze_block.png", "default_bronze_block.png",
	         "default_bronze_block.png", "default_bronze_block.png",   "default_bronze_block.png"},
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "facedir",
	node_box = {
		type = "fixed",
		fixed = {
			{ -.5, -1.5, -.5, .5, 1.5, .5 },
		},
 	},
	selection_box = {
		type = "fixed",
		fixed = {
			{ -.5, -1.5, -.5, .5, 1.5, .5 },
		},
 	},
	collision_box = {
		type = "fixed",
		fixed = {
			{ -.5, -1.5, -.5, .5, 1.5, .5 },
		},
 	},
	groups = { }, -- undiggable: part of the drill rig
	sounds = default.node_sound_wood_defaults(),
	
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		
		inv:set_size("main", 4*8)
	end,
	
})


minetest.register_node("bitumen:drill_mud_injector", {
	description = "Drilling Mud Injector",
	tiles = {"default_bronze_block.png",  "default_bronze_block.png", "default_bronze_block.png",
	         "default_bronze_block.png", "default_bronze_block.png",   "default_bronze_block.png"},
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "facedir",
	node_box = {
		type = "fixed",
		fixed = {
			{ -.5, -.5, -.5, .5, .5, .5 },
		},
 	},
	selection_box = {
		type = "fixed",
		fixed = {
			{ -.5, -.5, -.5, .5, .5, .5 },
		},
 	},
	collision_box = {
		type = "fixed",
		fixed = {
			{ -.5, -.5, -.5, .5, .5, .5 },
		},
 	},
	groups = { petroleum_fixture=1 }, -- undiggable: part of the drill rig
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_node("bitumen:drill_mud_extractor", {
	description = "Drilling Mud Extractor",
	tiles = {"default_bronze_block.png",  "default_bronze_block.png", "default_bronze_block.png",
	         "default_bronze_block.png", "default_bronze_block.png",   "default_bronze_block.png"},
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "facedir",
	node_box = {
		type = "fixed",
		fixed = {
			{ -.5, -.5, -.5, .5, .5, .5 },
		},
 	},
	selection_box = {
		type = "fixed",
		fixed = {
			{ -.5, -.5, -.5, .5, .5, .5 },
		},
 	},
	collision_box = {
		type = "fixed",
		fixed = {
			{ -.5, -.5, -.5, .5, .5, .5 },
		},
 	},
	groups = { petroleum_fixture=1 }, -- undiggable: part of the drill rig
	sounds = default.node_sound_wood_defaults(),
})



minetest.register_node("bitumen:drill_rig", {
	description = "Drill Rig",
	paramtype = "light",
	drawtype = "mesh",
	mesh = "oil_derrick.obj",
	description = "Drilling Derrick",
	inventory_image = "bitumen_cement_mixer_invimg.png",
	tiles = {
		"default_obsidian_block.png",
	},
 	selection_box = {
		type = "fixed",
		fixed = {
			{ -.5, -.5, -.5, .5, 1.5, .5 },
		},
 	},
 	collision_box = {
		type = "fixed",
		fixed = {
			{ -.5, -.5, -.5, .5, 1.5, .5 },
-- 			{ -1.5, -1.5, -1.5, -1.4, 3, -1.4 },
-- 			{ 1.5, -1.5, -1.5, 1.4, 3, -1.4 },
-- 			{ -1.5, -1.5, 1.5, -1.4, 3, 1.4 },
-- 			{ 1.5, -1.5, 1.5, 1.4, 3, 1.4 },
-- 			{ 1.5, 1.5, 1.5, -1.5, 4.5, -1.5 },
		}
 	},
	paramtype2 = "facedir",
	groups = {choppy=1 },
	sounds = default.node_sound_wood_defaults(),
	
	on_timer = dcb_node_timer,
	
	on_construct = function(pos)
		bitumen.magic.set_collision_nodes(pos, {
			{3, -2, 3}, {3, -1, 3},
			{3, -2, -3}, {3, -1, -3},
			{-3, -2, 3}, {-3, -1, 3},
			{-3, -2, -3}, {-3, -1, -3},
			
			{-2, 0, -2}, {-2, 0, -1}, {-2, 0, 0}, {-2, 0, 1}, {-2, 0, 2},
			{2, 0, -2}, {2, 0, -1}, {2, 0, 0}, {2, 0, 1}, {2, 0, 2},
			{-1, 0, -2}, {0, 0, -2}, {1, 0, -2},
			{-1, 0, 2}, {0, 0, 2}, {1, 0, 2},
			
			{0, 9, 0},
			{0, 8, 0},
		})
		
		bitumen.magic.set_collision_nodes(pos, bitumen.magic.gencube({1, 1, 1}, {1, 7, 1})) 
		bitumen.magic.set_collision_nodes(pos, bitumen.magic.gencube({1, 1, -1}, {1, 7, -1})) 
		bitumen.magic.set_collision_nodes(pos, bitumen.magic.gencube({-1, 1, 1}, {-1, 7, 1})) 
		bitumen.magic.set_collision_nodes(pos, bitumen.magic.gencube({-1, 1, -1}, {-1, 7, -1})) 
		
		
		local controls_delta = {1, 2, 0}
		local pipe_chest_delta = {0, 2, 1}
		local mud_injector_delta = {0, -1, 0}
		local mud_extractor_delta = {0, -2, 0}
		
		bitumen.magic.set_nodes(pos, "bitumen:drill_controls", {controls_delta})
		bitumen.magic.set_nodes(pos, "bitumen:drill_pipe_chest", {pipe_chest_delta})
		bitumen.magic.set_nodes(pos, "bitumen:drill_mud_injector", {mud_injector_delta})
		bitumen.magic.set_nodes(pos, "bitumen:drill_mud_extractor", {mud_extractor_delta})
		
		local function add(p, d)
			return {x=p.x + d[1], y=p.y + d[2], z=p.z + d[3]}
		end
		
		local altnodes = {
			controls = add(pos, controls_delta),
			pipe_chest = add(pos, pipe_chest_delta),
			mud_injector = add(pos, mud_injector_delta),
			mud_extractor = add(pos, mud_extractor_delta),
		}
		
		
		local pcmeta = minetest.get_meta(altnodes.pipe_chest)
		local pcinv = pcmeta:get_inventory()
		pcinv:set_size("main", 8*32)
		
		
		local pipe_chest_formspec =
			"size[8,9;]" ..
			default.gui_bg ..
			default.gui_bg_img ..
			default.gui_slots ..
			"list[context;main;0,0.3;8,4;]" ..
			"list[current_player;main;0,4.85;8,1;]" ..
			"list[current_player;main;0,6.08;8,3;8]" ..
			"listring[context;main]" ..
			"listring[current_player;main]" ..
			default.get_hotbar_bg(0, 4.85)
		
		pcmeta:set_string("formspec", pipe_chest_formspec)
		
		
		local state = {
			state = "idle",
			command = "none",
			depth = pos.y - 3, -- depth of the next non-pipe node
			max_depth = pos.y - 3,
			forceload_oil = false, -- forceload the oil field to make the fluids flow
			last_drilled_node = "none"
		}
		
		local meta = minetest.get_meta(pos)
		meta:set_string("altnodes", minetest.serialize(altnodes))
		meta:set_string("state", minetest.serialize(state))
		meta:set_string("drilldepth", minetest.serialize(add(pos, {0, -3, 0})))
	end,
	
	on_destruct = bitumen.magic.on_destruct,
	
-- 	on_punch = function(pos)
-- 		drill(pos)
-- 	end,
	
})

local function get_controls_formspec(state)
	
	local up_down = ""
	if state.state == "idle" then
		up_down = "button[5,3;4,1;up;Up One]" ..
			"button[5,4;4,1;down;Down One]"
	end
	
	local stop = ""
	if state.state ~= "idle" then
		stop = "button[5,0;4,1;stop;Stop]"
	end

	local drill = ""
	if state.state ~= "drilling" then
		drill = "button[5,1;4,1;drill;Drill]"
	end
	
	local retract= ""
	if state.state ~= "retracting" then
		retract = "button[5,2;4,1;retract;Retract Pipe]"
	end
	
	local forceload= ""
	if state.state ~= "forceload" then
		forceload = "button[5,3;4,1;forceload;Forceload]"
	end

	local pump= ""
	if state.state ~= "pump" then
		pump = "button[5,4;4,1;pump;Pump]"
	end
	
	local state_strings = {
		drilling = "Drilling",
		retracting = "Retracting",
		idle = "Idle",
		pump = "Pumping",
	}
	
	local state_str = state_strings[state.state] or "None"
	
	
	return "" ..
		"size[10,8;]" ..
		default.gui_bg ..
		default.gui_bg_img ..
		default.gui_slots ..
		"label[1,1;"..state_str.."]" ..
		"label[1,2;Last Node: "..(state.last_drilled_node or "none").."]" ..
		"label[1,3;Depth: "..state.depth.."]" ..
		stop ..
		drill ..
		retract ..
		up_down ..
		forceload ..
		pump ..
		""
end


local function retract(pos)
	
	local meta = minetest.get_meta(pos)
	local dp = meta:get_string("drilldepth") or ""
	
	if dp == "" then
		dp = check_drill_stack(pos)
		meta:set_string("drilldepth", minetest.serialize(dp))
	else
		dp = minetest.deserialize(dp)
		--print("deserialized " .. dump(pos))
		--dp.y = dp.y - 1
	end
	
	
	local n = minetest.get_node(dp)
	
	
	if n.name == "ignore" then
		if minetest.forceload_block(dp, true) then
			print("forceload successful: ".. minetest.pos_to_string(dp))
			
			local n = minetest.get_node(dp)
		end
--		minetest.emerge_area(pos, pos)
	end
	
	local removed = false
	if n.name == "ignore" then
		minetest.emerge_area(dp, {x=dp.x, y=dp.y - 20, z=dp.z})
		print("emerging " .. minetest.pos_to_string(dp))
		return dp.y, false, false
	elseif n.name == "bitumen:drill_pipe" then
		minetest.set_node(dp, {name = "air"})
		removed = true
	elseif n.name == "bitumen:drill_mud_injector" or n.name == "bitumen:drill_mud_extractor"then
		return dp.y, false, true
	else
		print("retract at "..dp.y.." of "..n.name )
	end
	
	
	dp.y = dp.y + 1
	meta:set_string("drilldepth", minetest.serialize(dp))
	
	return dp.y, removed, false
end


local function pump_oil(pos)
	
	local dp = check_drill_stack(pos)
	
	local n = minetest.get_node(dp)
	
	if n.name == "bitumen:crude_oil" then
		minetest.set_node(dp, {name="air"})
		
		pos.x = pos.x + 1
		minetest.set_node(pos, {name="bitumen:crude_oil"})
		minetest.set_node_level(pos, 64)
	end
end

minetest.register_abm({
	nodenames = {"bitumen:drill_rig"},
	interval = 2,
	chance   = 1,
	action = function(pos, node, active_object_count, active_object_count_wider)
	--print("trydrill")
		
		--if 1==1 then return end
		
		local meta = minetest.get_meta(pos)
		local state = minetest.deserialize(meta:get_string("state"))
		local alts = minetest.deserialize(meta:get_string("altnodes"))
-- 		print(dump(alts))
		
		if alts == nil then
			--print("\n\nnull alts: "..dump(pos).."\n\n")
			return 
		end
		
		
		local inch = 0
		if state.command ~= "none" then
			if state.command == "drill" then
				state.state = "drilling"
			elseif state.command == "retract" then
				state.state = "retracting"
			elseif state.command == "stop" then
				state.state = "idle"
			elseif state.command == "pump" then
				print("set to pump")
				state.state = "pump"
			elseif state.command == "explore" then
				state.state = "idle"
				
				-- explore extent of oil deposit
			elseif state.command == "forceload" then
				state.state = "idle"
				
				forceload_deposit({x=pos.x, y = state.depth - 1, z=pos.z})
				-- do forceload
			elseif state.command == "un_forceload" then
				state.state = "idle"
				
				-- undo forceload
			elseif state.command == "up" then
				state.state = "idle"
				inch = 1
			elseif state.command == "down" then
				state.state = "idle"
				inch = -1
			end
			
			state.command = "none"
		end
		
		
		local pcmeta, pcinv 
		if state.state == "drilling" or state.state == "retracting" then
			pcmeta = minetest.get_meta(alts.pipe_chest)
			pcinv = pcmeta:get_inventory()
		end
		
		
		if state.state == "drilling" or inch == -1 then
			local pcmeta = minetest.get_meta(alts.pipe_chest)
			local pcinv = pcmeta:get_inventory()
			
			if pcinv:contains_item("main", "bitumen:drill_pipe 1") then
			
				local n, y, hit_oil = drill(pos)
				if n then
					state.last_drilled_node = n
					state.depth = y
					state.max_depth = math.min(y, state.max_depth or y)
					
					pcinv:remove_item("main", "bitumen:drill_pipe 1")
					
					if hit_oil and inch == 0 then
						state.state = "idle"
					end
				end
			else
				-- out of pipe
				state.state = "idle"
			end
		elseif state.state == "retracting" or inch == 1 then
			local y, removed, ended
			
			for i = 1,3 do
				y, removed, ended = retract(pos)
				if removed then
					pcinv:add_item("main", "bitumen:drill_pipe")
				end
				
				state.depth = y
				
				if ended or inch == 1 then
					break
				end
			end
			
		elseif state.state == "pump" then
			local expos = alts.mud_extractor
			expos.x = expos.x + 1
			local exnet = bitumen.pipes.get_net(expos)
			if exnet and (exnet.fluid == "bitumen:crude_oil" or exnet.fluid == "air") then
				-- pump oil
				local dp = {x=pos.x, y = state.depth - 1, z=pos.z}
				local n = minetest.get_node(dp)
				
				if n.name == "bitumen:crude_oil" or n.name == "bitumen:crude_oil_full" then
-- 					minetest.set_node(dp, {name="air"})
					
-- 					local expos = alts.mud_extractor
-- 					expos.x = expos.x + 1
					local p = bitumen.pipes.push_fluid(expos, "bitumen:crude_oil", 15, 20)
					--print("pushed " .. p)
				end
				
				
			else
				-- must empty the mud out of the pipe first
				
				print("well not connected " .. dump(exnet))
			end
			
		end
		
		-- update the control box formspec
		local control_meta = minetest.get_meta(alts.controls)
		control_meta:set_string("formspec", get_controls_formspec(state))
		
		meta:set_string("state", minetest.serialize(state))
	end
})






minetest.register_node("bitumen:well_pump", {
	description = "Drill Rig",
	tiles = {"default_gold_block.png",  "default_steel_block.png", "default_copper_block.png",
	         "default_tin_block.png", "default_gold_block.png",   "default_steel_block.png"},
	paramtype2 = "facedir",
	groups = {cracky=2, petroleum_fixture=1},
	sounds = default.node_sound_wood_defaults(),
	can_dig = function(pos,player)
		return true
	end,
	
	on_timer = dcb_node_timer,
	on_punch = function(pos)
		pump_oil(pos)
		
	end,
	
})















local rig_builder_formspec =
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




minetest.register_node("bitumen:oil_rig_constructor", {
	description = "Oil Rig Constructor",
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
		
		meta:set_string("formspec", rig_builder_formspec);
	end,
	

	on_receive_fields = function(pos, form, fields, player)
		
		local meta = minetest.get_meta(pos)
		
		if fields.build then
			-- tanks can only be built on thick foundations
--[[
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
			]]
-- 			local inv = meta:get_inventory();
-- 			
-- 			if inv:contains_item("main", "default:steelblock 8") then
-- 				
-- 				inv:remove_item("main", "default:steelblock 8")
-- 			else
-- 				minetest.chat_send_player(player:get_player_name(), "Not enough materials: 8x SteelBlock")
-- 				return
-- 			end
			
			-- ready to go
			minetest.chat_send_player(player:get_player_name(), "Clear area, construction starting...")
			
			minetest.after(5, function()
				minetest.set_node({x=pos.x, y=pos.y + 2, z=pos.z}, {name="bitumen:drill_rig"})
			end)
		end
	end,
})


bitumen.register_blueprint({name="bitumen:drill_rig"})


minetest.register_craft({
	output = 'bitumen:oil_rig_constructor',
	recipe = {
		{'default:steelblock', 'default:steelblock', 'default:steelblock'},
		{'default:steelblock', 'bitumen:drill_rig_blueprint', 'default:steelblock'},
		{'default:steelblock', 'default:steelblock', 'default:steelblock'},
	}
})




