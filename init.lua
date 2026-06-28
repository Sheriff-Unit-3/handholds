handholds = {}

handholds.nodes = {}

local S = core.get_translator("handholds")

-- function to safely remove climbable air
local function remove_air(pos, oldnode)
	local dir = core.facedir_to_dir(oldnode.param2)
	local airpos = vector.subtract(pos, dir)

	local north_node = core.get_node({x = airpos.x, y = airpos.y, z = airpos.z+1})
	local south_node = core.get_node({x = airpos.x, y = airpos.y, z = airpos.z-1})
	local east_node = core.get_node({x = airpos.x+1, y = airpos.y, z = airpos.z})
	local west_node = core.get_node({x = airpos.x-1, y = airpos.y, z = airpos.z})

	local keep_air =
		(core.get_item_group(north_node.name, "handholds") == 1 and
		north_node.param2 == 0) or
		(core.get_item_group(south_node.name, "handholds") == 1 and
		south_node.param2 == 2) or
		(core.get_item_group(east_node.name, "handholds") == 1 and
		east_node.param2 == 1) or
		(core.get_item_group(west_node.name, "handholds") == 1 and
		west_node.param2 == 3)

	if not keep_air then
		core.set_node(airpos, {name = "air"})
	end
end

-- remove handholds from nodes buried under falling nodes
local function remove_handholds(pos)
	local north_pos = {x = pos.x, y = pos.y, z = pos.z+1}
	local south_pos = {x = pos.x, y = pos.y, z = pos.z-1}
	local east_pos = {x = pos.x+1, y = pos.y, z = pos.z}
	local west_pos = {x = pos.x-1, y = pos.y, z = pos.z}
	local north_node = core.get_node(north_pos)
	local south_node = core.get_node(south_pos)
	local east_node = core.get_node(east_pos)
	local west_node = core.get_node(west_pos)

	local node_pos

	if core.get_item_group(north_node.name, "handholds") == 1 and
			north_node.param2 == 0 then
		node_pos = north_pos
	elseif core.get_item_group(south_node.name, "handholds") == 1 and
			south_node.param2 == 2 then
		node_pos = south_pos
	elseif core.get_item_group(east_node.name, "handholds") == 1 and
			east_node.param2 == 1 then
		node_pos = east_pos
	elseif core.get_item_group(west_node.name, "handholds") == 1 and
			west_node.param2 == 3 then
		node_pos = west_pos
	end

	if node_pos then
		local handholds_node = string.split(core.get_node(node_pos).name, ":")
		if handholds_node[1] == "handholds" then
			core.set_node(node_pos, {name = "default:"..handholds_node[2]})
		else
			handholds_node = string.split(core.get_node(node_pos).name, "_")
			core.set_node(node_pos, {name = handholds_node[1]})
		end
	end
end

-- handholds registration function
function handholds.register_handholds(name, def)
	def.original_mod = def.original_mod or core.get_current_modname()
	def.original_name = name

	def.mod = core.get_current_modname()
	if def.mod ~= "handholds" then
		name = name .. "_handholds"
	end

	handholds.nodes[def.original_mod .. ":" .. def.original_name] = true

	def.tiles = def.tiles or def.mod .. "_" .. def.original_name .. ".png"

	core.register_node(":".. def.mod .. ":" .. name, {
		description = def.description or S("Handholds"),
		tiles = {
			def.tiles, def.tiles, def.tiles, def.tiles, def.tiles,
			def.tiles .. "^handholds_holds.png"
		},
		paramtype2 = "facedir",
		on_rotate = function()
			return false
		end,
		groups = def.groups or
			{cracky = 3, stone = 1, not_in_creative_inventory = 1, handholds = 1},
		drop = def.drop or def.mod .. ":" .. def.original_name,
		sounds = def.sounds or default.node_sound_stone_defaults(),
		after_destruct = function(pos, oldnode)
			remove_air(pos, oldnode)
		end,
	})
end


-- basic handholds nodes
handholds.register_handholds("stone", {
	original_mod = "default",
	description = S("Stone Handholds"),
	tiles = "default_stone.png",
	drop = 'default:cobble',
})

handholds.register_handholds("desert_stone", {
	original_mod = "default",
	description = S("Desert Stone Handholds"),
	tiles = "default_desert_stone.png",
	drop = 'default:desert_cobble',
})

handholds.register_handholds("sandstone", {
	original_mod = "default",
	description = S("Sandstone Handholds"),
	tiles = "default_sandstone.png",
	drop = 'default:sandstone',
})

handholds.register_handholds("silver_sandstone", {
	original_mod = "default",
	description = S("Silver Sandstone Handholds"),
	tiles = "default_silver_sandstone.png",
	drop = 'default:silver_sandstone',
})

handholds.register_handholds("desert_sandstone", {
	original_mod = "default",
	description = S("Desert Sandstone Handholds"),
	tiles = "default_desert_sandstone.png",
	drop = 'default:desert_sandstone',
})

handholds.register_handholds("ice", {
	original_mod = "default",
	description = S("Ice Handholds"),
	tiles = "default_ice.png",
	drop = 'default:ice',
	sounds = default.node_sound_glass_defaults(),
})


-- climbable air
core.register_node("handholds:climbable_air", {
	description = S("Air"),
	drawtype = "airlike",
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	pointable = false,
	diggable = false,
	climbable = true,
	drop = "",
	groups = {not_in_creative_inventory = 1},
	on_destruct = function(pos)
		remove_handholds(pos)
	end,
})

-- handholds tool
core.register_tool("handholds:climbing_pick", {
	description = S("Climbing Pick"),
	inventory_image = "handholds_tool.png",
	sound = {breaks = "default_tool_breaks"},
	on_use = function(itemstack, player, pointed_thing)
		if not pointed_thing or
				pointed_thing.type ~= "node" or
				core.is_protected(pointed_thing.under, player:get_player_name()) or
				core.is_protected(pointed_thing.above, player:get_player_name()) or
				pointed_thing.under.y + 1 == pointed_thing.above.y or
				pointed_thing.under.y - 1 == pointed_thing.above.y then
			return
		end

		local node_def =
			core.registered_nodes[core.get_node(pointed_thing.above).name]
		if not node_def or not node_def.buildable_to then
			return
		end

		local node_name = core.get_node(pointed_thing.under).name

		if handholds.nodes[node_name] then
			local rotation = core.dir_to_facedir(
				vector.subtract(pointed_thing.under, pointed_thing.above))

			if node_name == "default:stone" then
				core.set_node(pointed_thing.under,
					{name = "handholds:stone", param2 = rotation})
			elseif node_name == "default:desert_stone" then
				core.set_node(pointed_thing.under,
					{name = "handholds:desert_stone", param2 = rotation})
			elseif node_name == "default:sandstone" then
				core.set_node(pointed_thing.under,
					{name = "handholds:sandstone", param2 = rotation})
			elseif node_name == "default:silver_sandstone" then
				core.set_node(pointed_thing.under,
					{name = "handholds:silver_sandstone", param2 = rotation})
			elseif node_name == "default:desert_sandstone" then
				core.set_node(pointed_thing.under,
					{name = "handholds:desert_sandstone", param2 = rotation})
			elseif node_name == "default:ice" then
				core.set_node(pointed_thing.under,
					{name = "handholds:ice", param2 = rotation})
			else
				node_name = node_name .. "_handholds"
				core.set_node(pointed_thing.under,
					{name = node_name, param2 = rotation})
			end
		else
			return
		end

		core.set_node(pointed_thing.above, {name = "handholds:climbable_air"})
		core.sound_play(
			"default_dig_cracky",
			{pos = pointed_thing.above, gain = 0.5, max_hear_distance = 8}
		)

		if not core.settings:get_bool("creative_mode") then
			local wdef = itemstack:get_definition()
			itemstack:add_wear(256)
			if itemstack:get_count() == 0 and wdef.sound and wdef.sound.breaks then
				core.sound_play(wdef.sound.breaks,
					{pos = pointed_thing.above, gain = 0.5})
			end
			return itemstack
		end
	end
})

core.register_craft({
	output = "handholds:climbing_pick",
	recipe = {
		{'default:diamond', 'default:diamond', 'default:diamond'},
		{'group:stick', '', ''},
		{'group:stick', '', ''},
	},
})
