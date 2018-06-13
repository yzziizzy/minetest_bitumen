
--[[

most of this code is blatantly stolen from the technic wires system.
tiers represent the type of fluid in the pipe. pipes can change type
but machines cannot. the sources determines the type of fluid in a system.



 
]]

--[[ very old code
bitumen.pipes = {}


function bitumen.register_pipe(tier, size)
	local ltier = string.lower(tier)

	for x1 = 0, 1 do
	for x2 = 0, 1 do
	for y1 = 0, 1 do
	for y2 = 0, 1 do
	for z1 = 0, 1 do
	for z2 = 0, 1 do
		local id = bitumen.get_pipe_id({x1, x2, y1, y2, z1, z2})

		bitumen.pipes["bitumen:"..ltier.."_pipe"..id] = tier

		local groups = {snappy=2, choppy=2, oddly_breakable_by_hand=2}
		if id ~= 0 then
			groups.not_in_creative_inventory = 1
		end

		minetest.register_node("bitumen:"..ltier.."_pipe"..id, {
			description = tier.." Cable",
			tiles = {"bitumen_"..ltier.."_pipe.png"},
			inventory_image = "bitumen_"..ltier.."_pipe_wield.png",
			wield_image = "bitumen_"..ltier.."_pipe_wield.png",
			groups = groups,
			sounds = default.node_sound_wood_defaults(),
			drop = "bitumen:"..ltier.."_pipe0",
			paramtype = "light",
			sunlight_propagates = true,
			drawtype = "nodebox",
			node_box = {
				type = "fixed",
				fixed = bitumen.gen_pipe_nodebox(x1, y1, z1, x2, y2, z2, size)
			},
			after_place_node = function(pos)
				local node = minetest.get_node(pos)
				bitumen.update_pipes(pos, bitumen.get_pipe_tier(node.name))
			end,
			after_dig_node = function(pos, oldnode)
				local tier = bitumen.get_pipe_tier(oldnode.name)
				bitumen.update_pipes(pos, tier, true)
			end
		})
	end
	end
	end
	end
	end
	end
end


minetest.register_on_placenode(function(pos, node)
	for tier, machine_list in pairs(bitumen.machines) do
		for machine_name, _ in pairs(machine_list) do
			if node.name == machine_name then
				bitumen.update_pipes(pos, tier, true)
			end
		end
	end
end)


minetest.register_on_dignode(function(pos, node)
	for tier, machine_list in pairs(bitumen.machines) do
		for machine_name, _ in pairs(machine_list) do
			if node.name == machine_name then
				bitumen.update_pipes(pos, tier, true)
			end
		end
	end
end)


function bitumen.get_pipe_id(links)
	return (links[6] * 1) + (links[5] * 2)
			+ (links[4] * 4)  + (links[3] * 8)
			+ (links[2] * 16) + (links[1] * 32)
end




function bitumen.update_pipes(pos, tier, no_set, secondrun)
	local link_positions = {
		{x=pos.x+1, y=pos.y,   z=pos.z},
		{x=pos.x-1, y=pos.y,   z=pos.z},
		{x=pos.x,   y=pos.y+1, z=pos.z},
		{x=pos.x,   y=pos.y-1, z=pos.z},
		{x=pos.x,   y=pos.y,   z=pos.z+1},
		{x=pos.x,   y=pos.y,   z=pos.z-1}}

	local links = {0, 0, 0, 0, 0, 0}

	for i, link_pos in pairs(link_positions) do
		local connect_type = bitumen.pipes_should_connect(pos, link_pos, tier)
		if connect_type then
			links[i] = 1
			-- Have pipes next to us update theirselves,
			-- but only once. (We don't want to update the entire
			-- network or start an infinite loop of updates)
			if not secondrun and connect_type == "pipe" then
				bitumen.update_pipes(link_pos, tier, false, true)
			end
		end
	end
	-- We don't want to set ourselves if we have been removed or we are
	-- updating a machine
	if not no_set then
		minetest.set_node(pos, {name="bitumen:"..string.lower(tier)
				.."_pipe"..bitumen.get_pipe_id(links)})

	end
end


function bitumen.is_tier_pipe(name, tier)
	return bitumen.pipes[name] and bitumen.pipes[name] == tier
end


function bitumen.get_pipe_tier(name)
	return bitumen.pipes[name]
end


function bitumen.pipes_should_connect(pos1, pos2, tier)
	local name = minetest.get_node(pos2).name

	if bitumen.is_tier_pipe(name, tier) then
		return "pipe"
	elseif bitumen.machines[tier][name] then
		return "machine"
	end
	return false
end

 
function bitumen.gen_pipe_nodebox(x1, y1, z1, x2, y2, z2, size)
	--rounded Nodeboxes
	
	local box_center = {-size, -size, -size, size,  size, size}
	local box_y1 =     {-size, -size, -size, size,  0.5,  size} -- y+
	local box_x1 =     {-size, -size, -size, 0.5,   size, size} -- x+
	local box_z1 =     {-size, -size,  size, size,  size, 0.5}   -- z+
	local box_z2 =     {-size, -size, -0.5,  size,  size, size} -- z-
	local box_y2 =     {-size, -0.5,  -size, size,  size, size} -- y-
	local box_x2 =     {-0.5,  -size, -size, size,  size, size} -- x-

	local box = {box_center}
	if x1 == 1 then
		table.insert(box, box_x1)
	end
	if y1 == 1 then
		table.insert(box, box_y1)
	end
	if z1 == 1 then
		table.insert(box, box_z1)
	end
	if x2 == 1 then
		table.insert(box, box_x2)
	end
	if y2 == 1 then
		table.insert(box, box_y2)
	end
	if z2 == 1 then
		table.insert(box, box_z2)
	end
	return box
end

]]
