 
minetest.register_node("bitumen:brass_pipe", {
--	paramtype = "light",
	description = "Small Brass Pipe",
	tiles = {"bitumen_brass_pipe.png",  "bitumen_brass_pipe.png", "bitumen_brass_pipe.png",
	         "bitumen_brass_pipe.png", "bitumen_brass_pipe.png",   "bitumen_brass_pipe.png"},

	groups = {cracky=3,oddly_breakable_by_hand=3},
	legacy_facedir_simple = true,
	sounds = default.node_sound_wood_defaults(),
	on_construct = function(pos)
		
	end,
})



minetest.register_node("bitumen:carbon_steel_pipe", {
--	paramtype = "light",
	description = "Carbon Steel Pipe",
	tiles = {"bitumen_carbon_steel_pipe.png",  "bitumen_carbon_steel_pipe.png", "bitumen_carbon_steel_pipe.png",
	         "bitumen_carbon_steel_pipe.png", "bitumen_carbon_steel_pipe.png",   "bitumen_carbon_steel_pipe.png"},

	groups = {cracky=3,oddly_breakable_by_hand=3},
	legacy_facedir_simple = true,
	sounds = default.node_sound_wood_defaults(),
	on_construct = function(pos)
		
	end,
})

minetest.register_node("bitumen:medium_pipeline_segment", {
--	paramtype = "light",
	description = "Medium Pipeline Segment",
	tiles = {"bitumen_medium_pipeline_segment.png",  "bitumen_medium_pipeline_segment.png", "bitumen_medium_pipeline_segment.png",
	         "bitumen_medium_pipeline_segment.png", "bitumen_medium_pipeline_segment.png",   "bitumen_medium_pipeline_segment.png"},

	groups = {cracky=3,oddly_breakable_by_hand=3},
	legacy_facedir_simple = true,
	sounds = default.node_sound_wood_defaults(),
	on_construct = function(pos)
		
	end,
})

minetest.register_node("bitumen:medium_pipeline_elbow", {
--	paramtype = "light",
	description = "Medium Pipeline Elbow",
	tiles = {"bitumen_medium_pipeline_elbow.png",  "bitumen_medium_pipeline_elbow.png", "bitumen_medium_pipeline_elbow.png",
	         "bitumen_medium_pipeline_elbow.png", "bitumen_medium_pipeline_elbow.png",   "bitumen_medium_pipeline_elbow.png"},

	groups = {cracky=3,oddly_breakable_by_hand=3},
	legacy_facedir_simple = true,
	sounds = default.node_sound_wood_defaults(),
	on_construct = function(pos)
		
	end,
})

