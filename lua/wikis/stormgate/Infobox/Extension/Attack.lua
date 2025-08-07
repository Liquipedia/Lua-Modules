---
-- @Liquipedia
-- page=Module:Infobox/Extension/Attack
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local Page = Lua.import('Module:Page')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title

local Attack = {}

---@class StormgateAttackData
---@field name string
---@field targets string[]?
---@field damage number?
---@field damagePercentage string
---@field effect string[]
---@field speed number?
---@field dps number?
---@field bonus string
---@field bonusDamage number?
---@field bonusDps number?
---@field range number?

---@param argsJson string
---@param attackIndex integer
---@param faction string
---@return Widget[]?
function Attack.run(argsJson, attackIndex, faction)
	local args = Json.parseIfTable(argsJson)
	if not args then return end
	assert(args.name, 'Please specify a name for attack ' .. attackIndex)
	assert(faction, 'Faction needs to be specified')

	local data = Attack._parse(args)

	Attack._store(data, args, faction, attackIndex)

	return {
		Title{children = 'Attack' .. attackIndex .. ': ' .. args.name},
		Cell{name = 'Target', children = {Attack._displayArray(data.targets)}},
		Cell{name = 'Damage', children = {Attack._displayDamage(data)}},
		Cell{name = 'Effect', children = {Attack._displayArray(data.effect)}},
		Cell{name = 'Attack Speed', children = {data.speed}},
		Cell{name = 'DPS', children = {Attack._displayDPS(data)}},
		Cell{name = 'Range', children = {data.range}},
	}
end

---@param data table
---@return string?
function Attack._displayDamage(data)
	if data.damagePercentage then
		return (data.damagePercentage .. '%')
	elseif not data.damage then
		return
	elseif Logic.isEmpty(data.bonusData) then
		return data.damage
	end

	local parts = Array.extend({data.damage}, Array.map(data.bonusData, function(bonusElement)
		if Logic.isEmpty(bonusElement.bonusDamage) then return end
		return ' +' .. bonusElement.bonusDamage .. ' vs ' .. Page.makeInternalLink(bonusElement.bonus)
	end))

	return table.concat(parts, '<br>')
end

---@param data table
---@return string?
function Attack._displayDPS(data)
	if not data.dps then
		return
	elseif Logic.isEmpty(data.bonusData) then
		return data.dps
	end

	local parts = Array.extend({data.dps}, Array.map(data.bonusData, function(bonusElement)
		if Logic.isEmpty(bonusElement.bonusDps) then return end
		return ' +' .. bonusElement.bonusDps .. ' vs ' .. Page.makeInternalLink(bonusElement.bonus)
	end))

	return table.concat(parts, '<br>')
end

---@param args table
---@return StormgateAttackData
function Attack._parse(args)
	local bonusInput = Array.parseCommaSeparatedString(args.bonus)
	local bonusDamageInput = Array.parseCommaSeparatedString(args.bonus_damage)
	local bonusDpsInput = Array.parseCommaSeparatedString(args.bonus_dps)
	local bonusData = Array.map(bonusInput, function(bonusElement, bonusIndex)
		return {
			bonus = bonusElement,
			bonusDamage = tonumber(bonusDamageInput[bonusIndex]),
			bonusDps = tonumber(bonusDpsInput[bonusIndex]),
		}
	end)

	return {
		targets = Array.map(Array.map(Array.parseCommaSeparatedString(args.target), string.lower), String.upperCaseFirst),
		damage = tonumber(args.damage),
		damagePercentage = tonumber(args.damage_percentage),
		effect = Array.parseCommaSeparatedString(args.effect),
		speed = tonumber(args.speed),
		dps = tonumber(args.dps),
		bonusData = bonusData,
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

---@param arr string[]
---@return string
function Attack._displayArray(arr)
	return table.concat(Array.map(arr, function(value)
		return Page.makeInternalLink(value)
	end), ', ')
end

return Attack
