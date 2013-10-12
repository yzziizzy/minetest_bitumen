
-- a few hacks


minetest.register_craft({
	type = 'shapeless',
	output = 'bitumen:bitumen 1',
	recipe = { 'bitumen:tar_sand' },
	}
})




-- items

minetest.register_craft({
	output = 'bitumen:oil_drum 2',
	recipe = {
		{'default:steel_ingot', 'technic:rubber',      'default:steel_ingot'},
		{'default:steel_ingot', '',                    'default:steel_ingot'},
		{'default:steel_ingot', 'default:steel_ingot', 'default:steel_ingot'},
	}
})



minetest.register_craft({
	output = 'bitumen:lpg_regulator 4',
	recipe = {
		{'default:brass_ingot', '',                 'default:brass_ingot'},
		{'',                    'bitumen:lpg_pipe', 'bitumen:lpg_pipe'},
		{'',                    'technic:rubber',   ''},
	}
}) 

minetest.register_craft({
	output = 'bitumen:gas_can 2',
	recipe = {
		{'default:reddye',          'homedecor:plastic_sheet', 'default:yellowdye'},
		{'homedecor:plastic_sheet',                    '',     'homedecor:plastic_sheet'},
		{'homedecor:plastic_sheet', 'homedecor:plastic_sheet', 'homedecor:plastic_sheet'},
	}
}) 

minetest.register_craft({
	type = 'shapeless',
	output = 'bitumen:small_lpg_bottle 1',
	recipe = { 'bitumen:lpg_regulator','vessels:steel_bottle' },
	}
})

-- stainless?
minetest.register_craft({
	output = 'bitumen:medium_lpg_tank 1',
	recipe = {
		{'default:steel_ingot', 'bitumen:lpg_regulator','default:steel_ingot'},
		{'default:steel_ingot', '',                    'default:steel_ingot'},
		{'default:steel_ingot', 'default:steel_ingot', 'default:steel_ingot'},
	}
})





minetest.register_craft({
	output = 'bitumen:cracking_boiler',
	recipe = {
		{'default:steel_ingot', '',     'default:steel_ingot'},
		{'pipeworks:steel_pipe', 'technic:lv_electric_furnace', 'pipeworks:steel_pipe'},
		{'',                'technic:lv_cable0',               ''},
	}
})
minetest.register_craft({
	output = 'bitumen:cracking_column',
	recipe = {
		{'default:steel_ingot',            '',     'default:steel_ingot'},
		{'default:steel_ingot',            '',    'pipeworks:steel_pipe'},
		{'default:steel_ingot',            '',   'default:steel_ingot'},
	}
})
