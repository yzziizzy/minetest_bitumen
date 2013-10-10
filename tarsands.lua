

-- oil drums. plastic and steel
-- oil containers, for carrying
-- oil storage tanks
-- cracking tower

-- generators


-- add bananas/cocoa to chainsaw
-- flower seeds and garden
-- "sucker"/"fetcher" that will pull an item from the connected system

-- need to get the info for sand-type things
minetest.register_node( "bitumen:tar_sand", {
	description = "Tar Sand",
	tiles = { "bitumen_tar_sand.png" },
	is_ground_content = true,
	groups = {choppy=2},
	sounds = default.node_sound_wood_defaults(),
	drop = 'craft "bitumen:bitumen" 1',
	
}) 
	

-- upper layer
minetest.register_ore({
	ore_type       = "sheet",
	ore            = "bitumen:tar_sand",
	wherein        = "default:desertstone",
	clust_scarcity = 1,
	clust_num_ores = 1,
	clust_size     = 4,
	height_min     = 0,
	height_max     = 20,
	noise_threshhold = 0.4,
	noise_params = {offset=0, scale=15, spread={x=130, y=130, z=130}, seed=24, octaves=3, persist=0.70}
})


-- lower layer
minetest.register_ore({
	ore_type       = "sheet",
	ore            = "bitumen:tar_sand",
	wherein        = "default:stone",
	clust_scarcity = 1,
	clust_num_ores = 1,
	clust_size     = 4,
	height_min     = -50,
	height_max     = 0,
	noise_threshhold = 0.4,
	noise_params = {offset=0, scale=15, spread={x=130, y=130, z=130}, seed=24, octaves=3, persist=0.70}
})



