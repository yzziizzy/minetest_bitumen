-- pipelines are like pipes except much larger and more performant
-- pipelines are also only point-to-point; there are no joints
-- pipelines need pumps to force the fluid through, even downhill


local networks = {}
local net_members = {}
local storage = {}
local netname = 1

--local mod_storage = minetest.get_mod_storage()
local mod_storage = bitumen.mod_storage -- minetest.get_mod_storage()



networks = minetest.deserialize(mod_storage:get_string("pl_networks")) or {}
net_members = minetest.deserialize(mod_storage:get_string("pl_net_members")) or {}
storage =  minetest.deserialize(mod_storage:get_string("pl_storage")) or {}
netname = mod_storage:get_int("pl_netname") or 1

local function save_data() 
	--print("saving")
	
	mod_storage:set_string("pl_networks", minetest.serialize(networks))
	mod_storage:set_string("pl_net_members", minetest.serialize(net_members))
	mod_storage:set_string("pl_storage", minetest.serialize(storage))
	mod_storage:set_int("pl_netname", netname)
end


-- centralized network creation for consistency
local function new_network(pos) 
	local hash = minetest.hash_node_position(pos)
	print("new pipeline network: hash: ".. hash .." name: " ..netname); 
	
	networks[hash] = {
		hash = hash,
		pos = {x=pos.x, y=pos.y, z=pos.z},
		fluid = 'air',
		name = netname,
		count = 1,
		inputs = {
			[hash] = 1,
		},
		outputs = {},
		buffer = 0,
		in_pressure = -32000,
		
		storage = {
		--[[
			[entry_hash] = < storage_center_hash >
		]]
		}
	}
	
	net_members[hash] = hash
	
	netname = netname + 1
	
	return networks[hash], hash
end


local function pnet_for(pos)
	local hash = minetest.hash_node_position(pos)
	local ph = net_members[hash]
	if ph == nil then
		return nil, hash
	end
	
	return networks[ph], hash
end



-- merge a list of networks, if the are multiple nets in the list
local function try_merge(merge_list)
	if #merge_list > 1 then 
		print("\n merging "..#merge_list.." networks")
		
		local biggest = {count = 0}
		local mlookup = {}
		
		for _,n in ipairs(merge_list) do
			mlookup[n.hash] = 1 
			if n.count > biggest.count then
				biggest = n
			end
		end
		
		mlookup[biggest.hash] = 0
		
		for k,v in pairs(net_members) do
			if mlookup[v] == 1 then
				net_members[k] = biggest.hash
			end
		end
		
		
		for _,n in ipairs(merge_list) do
			if n.hash ~= biggest.hash then
				biggest.count = biggest.count + n.count
				networks[n.hash] = nil -- delete old networks
			end
		end
		
		return biggest
	end
	
	return merge_list[1]
end



-- check specific nearby nodes for existing networks
local function check_merge(pos, npos1, npos2) 
	local hash = minetest.hash_node_position(pos)
	
	local merge_list = {}
	local current_net = nil
	local found_net = 0
	
	local check_net = function(npos)
		local nhash = minetest.hash_node_position(npos)
		local nphash = net_members[nhash] 
		if nphash ~= nil then
			local pnet = networks[nphash]
			
			if nil == current_net then
				print("joining existing network: ".. pnet.name)
				net_members[hash] = nphash
				current_net = nphash
				pnet.count = pnet.count + 1
				pnet.inputs[hash] = 1
				table.insert(merge_list, pnet)
			elseif current_net == nphash then
				print("alternate connection to existing network")
			else
				print("found seconday network: "..pnet.name)
				table.insert(merge_list, pnet)
			end
			
			found_net = 1
		end
	end
	
	check_net(npos1)
	check_net(npos2)
	
	return found_net, merge_list
end




bitumen.pipelines = {}

-- used by external machines to find the network for a node
bitumen.pipelines.get_net = function(pos)
	local hash = minetest.hash_node_position(pos)
	local phash = net_members[hash]
	if phash == nil then
		return nil, nil, hash
	end
	
	return networks[phash], phash, hash
end



bitumen.pipes.after_change = function(pos, opos1, opos2, npos1, npos2)

	local o1net, o1phash, o1hash = bitumen.pipelines.get_net(opos1) 
	local o2net, o2phash, o2hash = bitumen.pipelines.get_net(opos2) 
	local n1net, n1phash, n1hash = bitumen.pipelines.get_net(npos1) 
	local n2net, n2phash, n2hash = bitumen.pipelines.get_net(npos2) 
	
	local check_o1 = true
	local check_o2 = true
	local check_n1 = true
	local check_n2 = true
	
	-- check if one of the nodes is still in the network. this will often be the case
	if vector.equals(opos1, npos1) then
		print("old pos 1 is new pos 1")
		check_o1 = false
		check_n1 = false
	elseif vector.equals(opos1, npos2) then
		print("old pos 1 is new pos 1")
		check_o1 = false
		check_n2 = false
	end

	if vector.equals(opos2, npos1) then
		print("old pos 1 is new pos 1")
		check_o2 = false
		check_n1 = false
	elseif vector.equals(opos2, npos2) then
		print("old pos 1 is new pos 1")
		check_o2 = false
		check_n2 = false
	end
	
	-- remove o1 from the network
	if check_o1 then
		
		
	end
	
	
	-- merge with n1's network
	if check_o1 then
		
		
	end
	
	
	
	
	
	
	
	
	local hash = minetest.hash_node_position(pos)
	local phash = net_members[hash]
	if phash == nil then
		print("wtf: pipe has no network in after_destruct")
		return
	end
	local pnet = networks[phash]
	if pnet == nil then
		print("wtf: no network in after_destruct for pipe")
		return
	end
	
	-- remove this node from the network
	net_members[hash] = nil
	pnet.count = pnet.count - 1
	
	-- neighboring nodes
	local check_pos = {
		{x=pos.x+1, y=pos.y, z=pos.z},
		{x=pos.x-1, y=pos.y, z=pos.z},
		{x=pos.x, y=pos.y+1, z=pos.z},
		{x=pos.x, y=pos.y-1, z=pos.z},
		{x=pos.x, y=pos.y, z=pos.z+1},
		{x=pos.x, y=pos.y, z=pos.z-1},
	}
	
	local stack = {}
	local found = 0
	-- check neighbors for network membership
	for _,p in ipairs(check_pos) do
		local h = minetest.hash_node_position(p)
		
		local lphash = net_members[h]
		if lphash ~= nil then
			local lpnet = networks[lphash]
			
			-- only process pipes/fixtures on the same network as the destroyed pipe
			if lpnet and lpnet.name == pnet.name then
				stack[h] = vector.new(p)
				found = found + 1
				--print("check stack: "..p.x..","..p.y..","..p.z)
			else 
				print("no lpnet")
			end
		else
			print("no lphash "..p.x..","..p.y..","..p.z)
		end
	end
	
	-- don't need to split the network if this was just on the end
	if found > 1 then
		--print("check to split the network")
		for h,p in pairs(stack) do
			print(dump(p))
			print(dump(h))
		-- BUG: spouts and intakes can be counted as pipes when walking the network
			
			-- just rename the net
			local new_pnet = rebase_network(p)
		--	print("split off pnet ".. new_pnet.name .. " at " .. minetest.pos_to_string(p))
			-- all fluid is lost in the network atm
			-- some networks might get orphaned, for example, the first
			--   net to be rebased in a loop
		end
		
		
	end
	
	save_data()
end





minetest.register_node("bitumen:pipeline", {
	description = "Petroleum pipeline segment",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-.3, -.35, -.5, .3, .35, .5},
			{-.35, -.3, -.5, .35, .3, .5},
-- 			{-.4, -.4, -.4, .4, .4, .4},
-- 			{-.4, -.4, -.4, .4, .4, .4},
		},
	},
	paramtype = "light",
	is_ground_content = false,
	paramtype2 = "facedir",
	is_ground_content = false,
	tiles = { "default_gold_block.png" },
	walkable = true,
	groups = { cracky = 3, petroleum_pipeline = 1, },
	on_place = minetest.rotate_node,
	
	on_construct = function(pos) 
		print("\npipeline placed at "..pos.x..","..pos.y..","..pos.z)
		
		
		local node   = minetest.get_node(pos)
		
		local back_dir = minetest.facedir_to_dir(node.param2)
		local backpos = vector.add(pos, back_dir) 
		local frontpos = vector.subtract(pos, back_dir) 
		
		
		
		minetest.set_node(backpos, {name="default:dirt"})
		minetest.set_node(frontpos, {name="default:dirt"})
		
	--	local found_net, merge_list = check_merge(pos)
		
		--if found_net == 0 then 
		--	local net = new_network(pos)
		--end
		
	--	try_merge(merge_list)
		
		--save_data()
	end,
	
	--after_destruct = bitumen.pipes.after_destruct,
})






minetest.register_node("bitumen:pipeline_elbow", {
	description = "Petroleum pipeline elbow",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-.3, -.35, -.5, .3, .35, .3},
			{-.35, -.3, -.5, .35, .3, .3},
			
			{-.3, -.3, -.35, .3, .5, .35},
			{-.35, -.3, -.3, .35, .5, .3},
-- 			{-.4, -.4, -.4, .4, .4, .4},
-- 			{-.4, -.4, -.4, .4, .4, .4},
		},
	},
	paramtype = "light",
	is_ground_content = false,
	paramtype2 = "facedir",
	is_ground_content = false,
	tiles = { "default_gold_block.png" },
	walkable = true,
	groups = { cracky = 3, petroleum_pipeline = 1, },
	on_place = minetest.rotate_node,
	
	on_rotate = function(pos, node, player, mode, new_param2)
		
		
		
		local oldback_dir = minetest.facedir_to_dir(node.param2)
		local oldfrontpos = vector.subtract(pos, oldback_dir) 
		
		local oldtop_dir = ({[0]={x=0, y=1, z=0},
			{x=0, y=0, z=1},
			{x=0, y=0, z=-1},
			{x=1, y=0, z=0},
			{x=-1, y=0, z=0},
			{x=0, y=-1, z=0}})[math.floor(node.param2/4)]
		
		local oldtoppos = vector.add(pos, oldtop_dir)
		
		minetest.set_node(oldfrontpos, {name="default:glass"})
		minetest.set_node(oldtoppos, {name="default:glass"})
		
		
		
		local back_dir = minetest.facedir_to_dir(new_param2)
		local frontpos = vector.subtract(pos, back_dir) 
		
		local top_dir = ({[0]={x=0, y=1, z=0},
			{x=0, y=0, z=1},
			{x=0, y=0, z=-1},
			{x=1, y=0, z=0},
			{x=-1, y=0, z=0},
			{x=0, y=-1, z=0}})[math.floor(new_param2/4)]
		
		local toppos = vector.add(pos, top_dir)
		
		minetest.set_node(frontpos, {name="default:dirt"})
		minetest.set_node(toppos, {name="default:cobble"})
	end,
	
	on_construct = function(pos) 
		print("\npipeline elbow placed at "..pos.x..","..pos.y..","..pos.z)
		
		
		local node   = minetest.get_node(pos)
		
			
		local back_dir = minetest.facedir_to_dir(node.param2)
		local frontpos = vector.subtract(pos, back_dir) 
		
		local top_dir = ({[0]={x=0, y=1, z=0},
			{x=0, y=0, z=1},
			{x=0, y=0, z=-1},
			{x=1, y=0, z=0},
			{x=-1, y=0, z=0},
			{x=0, y=-1, z=0}})[math.floor(node.param2/4)]
		
		local toppos = vector.add(pos, top_dir)
		
		minetest.set_node(frontpos, {name="default:dirt"})
		minetest.set_node(toppos, {name="default:cobble"})
		
	--	local found_net, merge_list = check_merge(pos)
		
		--if found_net == 0 then 
		--	local net = new_network(pos)
		--end
		
	--	try_merge(merge_list)
		
		--save_data()
	end,
	
	--after_destruct = bitumen.pipelines.after_destruct,
})


















local storage_tank_builder_formspec =
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


minetest.register_node("bitumen:storage_tank_constructor", {
	description = "Storage Tank Constructor",
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
		
		meta:set_string("formspec", storage_tank_builder_formspec);
	end,
	

	on_receive_fields = function(pos, form, fields, player)
		
		local meta = minetest.get_meta(pos)
		
		if fields.build then
			-- tanks can only be built on thick foundations
			local ret = bitumen.check_foundation(
				{x = pos.x - 15, y = pos.y - 3, z = pos.z - 15},
				{x = pos.x + 15, y = pos.y - 1, z = pos.z + 15},
				{
					["default:steelblock"] = 1,
					["bitumen:concrete"] = 1,
				}
			)
			
			if ret == false then
				minetest.chat_send_player(player:get_player_name(), "Foundation is incomplete: 30x3x30")
				return
			else
				minetest.chat_send_player(player:get_player_name(), "Foundation is complete.")
			end
			
			-- tanks need room
			local ret = bitumen.check_foundation(
				{x = pos.x - 16, y = pos.y    , z = pos.z - 16},
				{x = pos.x + 16, y = pos.y + 12, z = pos.z + 16},
				{
					["air"] = 1,
					["bitumen:storage_tank_constructor"] = 1,
				}
			)
			
			if ret == false then
				minetest.chat_send_player(player:get_player_name(), "Area is not clear: 32x12x32")
				return
			else
				minetest.chat_send_player(player:get_player_name(), "Area is clear.")
			end
			
			local inv = meta:get_inventory();
			
			-- should be ~1500 sheets
			if (inv:contains_item("main", "bitumen:galv_steel_sheet 99") and 
				inv:contains_item("main", "default:coal_lump 20")) then
				
				inv:remove_item("main", "bitumen:galv_steel_sheet 99")
				inv:remove_item("main", "default:coal_lump 20")
			else
				minetest.chat_send_player(player:get_player_name(), "Not enough materials: 99x Galvanized Steel Sheet, 20x Coal Lump")
				return
			end
			
			-- ready to go
			minetest.chat_send_player(player:get_player_name(), "Clear area, construction starting...")
			
			for i = 9,1,-1 do
				minetest.after(10-i, (function(n)
					return function() 
						minetest.chat_send_player(
							player:get_player_name(),
							"Storage Tank construction in "..n.."..."
						) 
					end
				end)(i))
			end
			
			minetest.after(10, function()
				minetest.set_node(pos, {name="bitumen:storage_tank"})
			end)
			
		end
	end,
})



bitumen.register_blueprint({
	name = "bitumen:storage_tank",
})





minetest.register_node("bitumen:storage_tank", {
	paramtype = "light",
	drawtype = "mesh",
	mesh = "storage_tank.obj",
	description = "Storage Tank",
	tiles = {
		"default_sand.png",
	},
 	inventory_image = "default_sand.png",
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
	groups = {choppy=1, petroleum_fixture=1, bitumen_magic_proof=1 },
	sounds = default.node_sound_wood_defaults(),
	
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		if placer then
			local owner = placer:get_player_name()
			meta:set_string("owner", owner)
		end
	--	meta:set_float("fluid_level", 0)
	--	meta:set_float("capacity", math.floor(3.14159 * .75 * 9 * 9 * 9 * 64))
	--	meta:set_string("infotext", "0%")
	
		bitumen.magic.set_collision_nodes(pos, bitumen.magic.gencylinder({0, 0, 0}, 14.99, 9)) 
		
-- 		bitumen.pipes.on_construct(pos)
	end,
	
	on_destruct = bitumen.magic.on_destruct,
	
	can_dig = function(pos, player)
-- 		local meta = minetest.get_meta(pos);
-- 		local owner = meta:get_string("owner")
-- 		local fluid_level = meta:get_float("fluid_level") or 0
-- 		return player:get_player_name() ~= owner and fluid_level <= 0.01
		return true
	end,
})

