-- support for MT game translation.
local S = minetest.get_translator("rythium")

--
-- Wands
--

-- Retrieving mod settings
-- https://dev.minetest.net/Settings (beware of the bug !)
local wands_max_use = minetest.settings:get("rythium.wands_max_use") or 20
local wands_wear = 65535/(wands_max_use-1)

-- Healing wand
minetest.register_tool("rythium:healing_wand", {
	description = S("Healing wand"),
	inventory_image = "rythium_healing_wand.png",
	on_use = function(itemstack, user, pointed_thing)
		minetest.sound_play("rythium_healing", {gain = 0.5})
		-- pointed_thing is a table and this table contains a ref variable,
		-- i.e. another table which represents the pointed object itself.
		-- difference is tested with ~= not with != as in other languages
		if pointed_thing.ref and pointed_thing.ref:is_player() then
			pointed_thing.ref:set_hp(20)
		else
			user:set_hp(20)
		end
		-- Wand wear management
		-- user is an object representing a player, is_creative_enabled needs only the name
		if not minetest.is_creative_enabled(user:get_player_name()) then
			itemstack:add_wear(wands_wear)
			if itemstack:get_count() == 0 then
				minetest.sound_play("default_tool_breaks", {gain = 1})
			end
			return itemstack -- /!\ On_use must return the modified itemstack
		end
	end,
})

--
-- Rythium Pickaxe
--

-- This is set to false when the callback runs, to prevent additional calls to
-- on_dig from making it run again
local pick_cb_enabled = true

local function dig_it(pos, player)
	local player_name = player:get_player_name()
	if minetest.is_protected(pos, player_name) then
		minetest.record_protection_violation(pos, player_name)
		return
	end
	local node = minetest.get_node(pos)
	local node_name = node.name
	local groupcracky = minetest.get_item_group(node_name, "cracky")
	if node_name == "air" or node_name == "ignore" then return end
	if node_name == "default:lava_source" then return end
	if node_name == "default:lava_flowing" then return end
	if node_name == "default:water_source" then minetest.remove_node(pos) return end
	if node_name == "default:water_flowing" then minetest.remove_node(pos) return end
	local def = minetest.registered_nodes[node_name]
	if not def then return end
	if groupcracky == 0 then return end

	def.on_dig(pos, node, player)
end

local dig_offsets = {
	{x = 0,  y = 1,  z = 0},
	{x = 1,  y = 1,  z = 0},
	{x = -1, y = 1,  z = 0},
	{x = 1,  y = 0,  z = 0},
	{x = -1, y = 0,  z = 0},
	{x = 0,  y = -1, z = 0},
	{x = 1,  y = -1, z = 0},
	{x = -1, y = -1, z = 0}
}

local function dig_it_dir(pos, player)
	local dir = player:get_look_dir()
	-- Rounded_dir has only one non-zero component
	local rounded_dir = minetest.facedir_to_dir(minetest.dir_to_facedir(dir, true))
	local rot = vector.dir_to_rotation(rounded_dir)

	for _, v in ipairs(dig_offsets) do
		local offset = vector.rotate(v, rot)
		dig_it(vector.add(pos, offset), player)
	end
end

minetest.register_tool("rythium:huge_pick", {
	description = S("3*3 Pick"),
	inventory_image = "rythium_huge_pick.png",
	tool_capabilities = {
		full_punch_interval = 0.9,
		max_drop_level=3,
		groupcaps={
			cracky = {times={[1]=3.5, [2]=2.5, [3]=1.5}, uses=200, maxlevel=3},
		},
		damage_groups = {fleshy=4},
	},
	sound = {breaks = "default_tool_breaks"},
	groups = {pickaxe = 1}
})

minetest.register_on_dignode(
	function(pos, oldnode, digger)
		if not pick_cb_enabled then return end
		pick_cb_enabled = false

		if not digger:is_player() then return end
		if digger:get_wielded_item():get_name() == "rythium:huge_pick" then
			dig_it_dir(pos, digger)
		end

		pick_cb_enabled = true
	end
)


-- Night vision googles

rythium_light={users={},timer=0}

minetest.register_on_leaveplayer(function(player)
 local name=player:get_player_name()
 if rythium_light.users[name]~=nil then rythium_light.users[name]=nil end
end)

minetest.register_node("rythium:light", {
 description = "light source",
 light_source = 12,
 paramtype = "light",
 walkable=false,
 drawtype = "airlike",
 pointable=false,
 buildable_to=true,
 sunlight_propagates = true,
 groups = {not_in_creative_inventory=1},
 on_construct=function(pos)
   minetest.get_node_timer(pos):start(2)
 end,
 on_timer = function (pos, elapsed)
   minetest.set_node(pos, {name="air"})
 end,
})

armor:register_armor("rythium:googles", {
		description = ("Night vision googles"),
		inventory_image = "rythium_night_googles.png",
		groups = {armor_head=1, armor_heal=0, armor_use=10},
		armor_groups = {fleshy=10},
		damage_groups = {cracky=1, snappy=1, level=1},
    on_equip = function(player, index, stack)
      rythium_light.users[player:get_player_name()]={player=player,slot=index,inside=0,item=player:get_inventory():get_stack("main", index):get_name()}
    end,
    on_unequip = function(player, index, stack)
      rythium_light.users[player:get_player_name()]=nil
    end,
})

minetest.register_globalstep(function(dtime)
  rythium_light.timer=rythium_light.timer+dtime
  if rythium_light.timer>1 then
    rythium_light.timer=0
    for i,ob in pairs(rythium_light.users) do
      local name=ob.player:get_inventory():get_stack("main", ob.slot):get_name()
      local pos=ob.player:get_pos()
      pos.y=pos.y+1.5
      local n=minetest.get_node(pos).name
      local light=minetest.get_node_light(pos)
      if light==nil then
        rythium_light.users[i]=nil
        return false
      end
      if ob.inside>10 or name==nil or name~=ob.item or minetest.get_node_light(pos)>12 then
        rythium_light.users[i]=nil
      elseif n=="air" or n=="rythium:light" then
        minetest.set_node(pos, {name="rythium:light"})
      else
        ob.inside=ob.inside+1
      end
    end
  end
end)

