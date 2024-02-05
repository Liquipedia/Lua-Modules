---
-- @Liquipedia
-- wiki=stormgate
-- page=Module:Infobox/Extension/Attack
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Table = require('Module:Table')
local String = require('Module:StringUtils')

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title

local Attack = {}

---@class StormgateAttackData
---@field name string
---@field targets string[]?
---@field damage number?
---@field damagePercentage string
---@field effect string
---@field speed number?
---@field dps number?
---@field bonus string
---@field bonusDamage number?
---@field bonusDps number?
---@field range number?

---@param args table?
---@param attackIndex integer
---@param faction string
---@return Widget[]?
function Attack.run(args, attackIndex, faction)
	if Table.isEmpty(args) then return end
	---@cast args -nil
	assert(args.name, 'Please specify a name for attack ' .. attackIndex)
	assert(faction, 'Faction needs to be specified')

	local data = Attack._parse(args)

	Attack._store(data, args, faction, attackIndex)

	return {
		Title{name = 'Attack' .. attackIndex .. ': ' .. args.name},
		Cell{name = 'Target', content = data.targets},
		Cell{name = 'Damage', content = {data.damagePercentage and (data.damagePercentage .. '%') or data.damage}},
		Cell{name = 'Effect', content = {data.effect}},
		Cell{name = 'Attack Speed', content = {data.speed}},
		Cell{name = 'DPS', content = {data.dps}},
		Cell{name = 'Bonus vs', content = {data.bonus}},
		Cell{name = 'Bonus Damage', content = {data.bonusDamage}},
		Cell{name = 'Bonus DPS', content = {data.bonusDps}},
		Cell{name = 'Range', content = {data.range}},
	}
end

---@param args table
---@return StormgateAttackData
function Attack._parse(args)
	return {
		targets = Array.map(args.target and mw.text.split(args.target or '', ','), function(target)
			return mw.getContentLanguage():ucfirst(String.trim(target):lower())
		end),
		damage = tonumber(args.damage),
		damagePercentage = tonumber(args.damage_percentage),
		effect = args.effect,
		speed = tonumber(args.speed),
		dps = tonumber(args.dps),
		bonus = args.bonus,
		bonusDamage = tonumber(args.bonus_damage),
		bonusDps = tonumber(args.bonus_dps),
		range = tonumber(args.range),
	}
end

---@param data StormgateAttackData
---@param args table
---@param faction string
---@param attackIndex integer
function Attack._store(data, args, faction, attackIndex)
	local objectName = 'attack_' .. attackIndex .. args.name
	local extradata = Table.map(data, function (key, value) return key:lower(), value end)

	mw.ext.LiquipediaDB.lpdb_datapoint(objectName, {
		name = args.name,
		type = 'attack',
		information = faction,
		image = args.image,
		imagedark = args.imagedark,
		extradata = mw.ext.LiquipediaDB.lpdb_create_json(extradata),
	})
end

return Attack
