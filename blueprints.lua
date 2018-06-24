






minetest.register_craftitem("bitumen:blueprint_paper", {
	description = "Blueprint Paper",
	stack_max = 99,
	inventory_image = "default_paper.png^[colorize:blue:120",
	groups = {flammable = 3},
})


minetest.register_craftitem("bitumen:blueprint_book", {
	description = "Blueprint Paper",
	stack_max = 99,
	inventory_image = "default_book.png^[colorize:blue:120",
	groups = {flammable = 3},
})









bitumen.registered_blueprints = {
-- 	["bitumen:cement_mixer_blueprint"] = 1,
}



-- registers the blueprint item, adds it to the bookshelf, and registers the constructor craft recipe
bitumen.register_blueprint = function(def) 
	local name = def.name.."_blueprint"
	
	local parent_def = minetest.registered_nodes[def.name]
	if parent_def == nil then
		print("Warning: parent node not registered yet. Place bitumen.register_blueprint call after node registration.")
		return
	end
	
	minetest.register_craftitem(name, {
		description = parent_def.description.." Blueprint",
		stack_max = 1,
		inventory_image = parent_def.inventory_image .. "^bitumen_blueprint.png",
		groups = {flammable = 3},
	})

	-- the actual constructor must be registered elsewhere
	minetest.register_craft({
		output = def.name..'_constructor',
		recipe = {
			{'default:steel_ingot', 'default:steel_ingot', 'default:steel_ingot'},
			{'default:steel_ingot', name, 'default:steel_ingot'},
			{'default:steel_ingot', 'default:steel_ingot', 'default:steel_ingot'},
		}
	})

	
	bitumen.registered_blueprints[name] = def
end





local blueprint_bookshelf_formspec =
	"size[8,8;]" ..
	default.gui_bg ..
	default.gui_bg_img ..
	default.gui_slots ..
	"list[context;blueprints;0,0.3;8,3;]" ..
	"list[current_player;main;0,3.85;8,1;]" ..
	"list[current_player;main;0,5.08;8,3;8]" ..
	"listring[context;blueprints]" ..
	"listring[current_player;main]" ..
	default.get_hotbar_bg(0,3.85)


minetest.register_node("bitumen:blueprint_bookshelf", {
	description = "Blueprint Bookshelf",
	tiles = {"default_junglewood.png", "default_junglewood.png", "default_junglewood.png",
		"default_junglewood.png", "default_bookshelf.png^[colorize:blue:120", "default_junglewood.png"},
	paramtype2 = "facedir",
	is_ground_content = false,
	groups = {choppy = 3, oddly_breakable_by_hand = 2, flammable = 3},
	sounds = default.node_sound_wood_defaults(),
	stack_max = 1,

	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", blueprint_bookshelf_formspec)
		local inv = meta:get_inventory()
		inv:set_size("blueprints", 8 * 3)
		
		
		-- fill in the known blueprints
		local list = {}
		for name,def in pairs(bitumen.registered_blueprints) do
			table.insert(list, name)
		end
		
		inv:set_list("blueprints", list)
		
	end,

	allow_metadata_inventory_put = function(pos, listname, index, stack)
		return 0
	end,
	allow_metadata_inventory_move = function(pos, listname, index, stack)
		return 0
	end,

	on_metadata_inventory_take = function(pos, listname, index, stack, player)
-- 		print(" -- "..listname.. " " ..index.." "..dump(stack))
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory(meta)
		inv:set_stack(listname, index, stack)
	end,
})
