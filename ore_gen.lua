


minetest.register_ore({
	ore_type        = "blob",
	ore             = "bitumen:crude_oil_full",
	wherein         = {"default:stone"},
	clust_scarcity  = 64 * 64 * 64,
-- 	clust_scarcity  = 16 * 16 * 16,
	clust_size      = 30,
	y_min           = -10000,
	y_max           = -500,
	noise_threshold = 0.04,
	noise_params    = {
		offset = 0.5,
		scale = 0.7,
		spread = {x = 40, y = 40, z = 40},
		seed = 2316,
		octaves = 4,
		persist = 0.7
	},
	--[[ it's all "underground" anyway
	biomes = {
			"taiga", "tundra", "snowy_grassland",  "coniferous_forest",
			"coniferous_forest_dunes",
			}
	]]
})




minetest.register_ore({
	ore_type        = "blob",
	ore             = "bitumen:tar_sand",
	wherein         = {"default:desert_stone", "default:sandstone", "default:stone"},
	clust_scarcity  = 64 * 64 * 64,
	clust_size      = 20,
	y_min           = -15,
	y_max           = 500,
	noise_threshold = 0.4,
	noise_params    = {
		offset = 0.5,
		scale = 0.7,
		spread = {x = 40, y = 40, z = 40},
		seed = 2316,
		octaves = 4,
		persist = 0.7
	},
	biomes = {
			"taiga", "snowy_grassland", 
			"grassland", "desert", "sandstone_desert", "cold_desert",
			}
})

	
minetest.register_ore({
	ore_type        = "blob",
	ore             = "bitumen:oil_shale",
	wherein         = {"default:sandstone"},
	clust_scarcity  = 96 * 96 * 96,
	clust_size      = 30,
	y_min           = -15,
	y_max           = 500,
	noise_threshold = 0.4,
	noise_params    = {
		offset = 0.5,
		scale = 0.7,
		spread = {x = 40, y = 40, z = 40},
		seed = 23136,
		octaves = 4,
		persist = 0.7
	},
	biomes = { "sandstone_desert"},
})
















