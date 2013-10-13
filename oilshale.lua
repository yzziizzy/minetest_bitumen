
--[[ NEED:

textures: 
	oil shale
	crushed oil shale

node defs:
	(tweak) oil shale

craftitem:
	crushed oil shale

ore reg:
	(tweak) oil shale

grinder recipe:
	oil shale -> crushed oil shale

extractor recipe:
	crushed oil shale -> bitumen

]]


 -- need to get the info for stone-type things
minetest.register_node( "bitumen:oil_shale", {
	description = "Oil Shale",
	tiles = { "default_coal_block.png" },
	is_ground_content = true,
	groups = {choppy=2},
	sounds = default.node_sound_wood_defaults(),
}) 
	
	
	
minetest.register_ore({
	ore_type       = "sheet",
	ore            = "bitumen:oil_shale",
	wherein        = "air",
	clust_scarcity = 1,
	clust_num_ores = 1,
	clust_size     = 18,
	height_min     = 50,
	height_max     = 100,
	noise_threshhold = 0.10,
	noise_params = {offset=0, scale=0, spread={x=100, y=100, z=100}, seed=24, octaves=1, persist=0.10}
})