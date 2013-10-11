 
minetest.register_craft({
	type = 'shapeless',
	output = 'bitumen:small_lpg_bottle 1',
	recipe = { 'bitumen:lpg_regulator','vessels:steel_bottle' },
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
	output = 'bitumen:oil_drum 2',
	recipe = {
		{'default:steel_ingot', 'technic:rubber',      'default:steel_ingot'},
		{'default:steel_ingot', '',                    'default:steel_ingot'},
		{'default:steel_ingot', 'default:steel_ingot', 'default:steel_ingot'},
	}
})