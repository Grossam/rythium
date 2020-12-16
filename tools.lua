-- support for MT game translation.
local S = minetest.get_translator(rythium)

-- Retrieving mod settings
local rythium = {}
rythium.wands_max_charge = minetest.settings:get("rythium.wands_max_charge")

--
-- Wands
--

-- Healing wand
minetest.register_tool("rythium:healing_wand", {
	description = S("Healing wand"),
	inventory_image = "rythium_healing_wand.png",
	on_use = function(itemstack, user, pointed_thing)
		minetest.sound_play("rythium_healing")
		-- pointed_thing is a table and this table contains a ref variable,
		-- i.e. another table which represents the pointed object itself.
		-- difference is tested with ~= not with != as in other languages
		if (pointed_thing.ref~=nil and pointed_thing.ref:is_player())
		then
			pointed_thing.ref:set_hp(20)
		else
			user:set_hp(20)
		end
	end,
})

--
-- Rythium Pickaxe
--

local function dig_it(pos, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		minetest.record_protection_violation(pos, player:get_player_name())
      return
   end
   local node = minetest.get_node(pos)
   if node.name == "air" or node.name == "ignore" then return end
   if node.name == "default:lava_source" then return end
   if node.name == "default:lava_flowing" then return end
	minetest.remove_node(pos)
end

local function dig_dir(player)
	local dir=player:get_look_dir()
	if math.abs(dir.x)>math.abs(dir.z) then
		if dir.x>0 then return 0 end
		return 1
	end
	if dir.z>0 then return 2 end
	return 3
end

local function dig_it1 (pos,player)
	pos.y=pos.y+1
	dig_it (pos,player)
	pos.z=pos.z+1
	dig_it (pos,player)
	pos.z=pos.z-2
	dig_it (pos,player)
	pos.z=pos.z+1
	pos.y=pos.y-1
	dig_it (pos,player)
	pos.z=pos.z+1
	dig_it (pos,player)
	pos.z=pos.z-2
	dig_it (pos,player)
	pos.z=pos.z+1
	pos.y=pos.y-1
	dig_it (pos,player)
	pos.z=pos.z+1
	dig_it (pos,player)
	pos.z=pos.z-2
	dig_it (pos,player)
end

local function dig_it2 (pos,player)
	pos.y=pos.y+1
	dig_it (pos,player)
	pos.x=pos.x+1
	dig_it (pos,player)
	pos.x=pos.x-2
	dig_it (pos,player)
	pos.x=pos.x+1
	pos.y=pos.y-1
	dig_it (pos,player)
	pos.x=pos.x+1
	dig_it (pos,player)
	pos.x=pos.x-2
	dig_it (pos,player)
	pos.x=pos.x+1
	pos.y=pos.y-1
	dig_it (pos,player)
	pos.x=pos.x+1
	dig_it (pos,player)
	pos.x=pos.x-2
	dig_it (pos,player)
end

local function dig_it3 (pos,player)
	dig_it (pos,player)
	pos.x=pos.x+1
	dig_it (pos,player)
	pos.x=pos.x-2
	dig_it (pos,player)
	pos.x=pos.x+1
	pos.z=pos.z+1
	dig_it (pos,player)
	pos.x=pos.x+1
	dig_it (pos,player)
	pos.x=pos.x-2
	dig_it (pos,player)
	pos.x=pos.x+1
	pos.z=pos.z-2
	dig_it (pos,player)
	pos.x=pos.x+1
	dig_it (pos,player)
	pos.x=pos.x-2
	dig_it (pos,player)
end

local function dig_it_dir(pos, player)
	local dir = player:get_look_dir()
	if math.abs(dir.y)<0.5 then
		dir = dig_dir(player)
		if dir == 0 or dir == 1 then -- x
			dig_it1(pos, player)
		end
		if dir == 2 or dir == 3 then -- z
			dig_it2(pos, player)
		end
	else
		dig_it3(pos, player)
	end
end

minetest.register_tool("rythium:huge_pick", {
	description = ("3*3 Pick"),
	inventory_image = "huge_pick.png",
	tool_capabilities = {
		full_punch_interval = 0.9,
		max_drop_level=3,
		groupcaps={
			cracky = {times={[1]=2.0, [2]=1.0, [3]=0.50}, uses=40, maxlevel=3},
		},
		damage_groups = {fleshy=4},
	},
	sound = {breaks = "default_tool_breaks"},
	groups = {pickaxe = 1}
})

minetest.register_on_dignode(
	function(pos, oldnode, digger)
		if not digger:is_player() then return end
		if digger:get_wielded_item():get_name() == "rythium:huge_pick" then
			dig_it_dir(pos, digger)
		end
	end
)
