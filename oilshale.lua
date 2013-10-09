 -- need to get the info for stone-type things
minetest.register_node( "atomic:oil_shale", {
	description = "Oil Shale",
	tiles = { "default_coal_block.png" },
	is_ground_content = true,
	groups = {choppy=2},
	sounds = default.node_sound_wood_defaults(),
}) 
	
	
	
minetest.register_ore({
	ore_type       = "sheet",
	ore            = "atomic:oil_shale",
	wherein        = "air",
	clust_scarcity = 1,
	clust_num_ores = 1,
	clust_size     = 4,
	height_min     = 50,
	height_max     = 100,
	noise_threshhold = 0.4,
	noise_params = {offset=0, scale=15, spread={x=130, y=130, z=130}, seed=24, octaves=3, persist=0.70}
})