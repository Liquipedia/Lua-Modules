---
-- @Liquipedia
-- wiki=stormgate
-- page=Module:Infobox/Extension/Attack
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Json = require('Module:Json')
local Page = require('Module:Page')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local Widgets = require('Module:Infobox/Widget/All')
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
		Title{name = 'Attack' .. attackIndex .. ': ' .. args.name},
		Cell{name = 'Target', content = {Attack._displayCommaSeparatedString(args.target)}},
		Cell{
			name = 'Damage',
			content = {
				data.damagePercentage and data.damagePercentage .. '%' or
				data.bonus and data.bonusDamage and data.damage .. ' (+' .. data.bonusDamage ..
				' vs ' .. Attack._displayCommaSeparatedString(args.bonus) .. ')'  or
				data.damage
			}
		},
		Cell{name = 'Effect', content = {Attack._displayCommaSeparatedString(args.effect)}},
		Cell{name = 'Attack Speed', content = {data.speed}},
		Cell{
			name = 'DPS',
			content = {
				data.bonus and data.bonusDps and data.dps and
				data.dps .. ' (+' .. data.bonusDps .. ' vs ' .. Attack._displayCommaSeparatedString(args.bonus) .. ')' or
				data.dps
			}
		},
		Cell{name = 'Range', content = {data.range}},
	}
end

---@param args table
---@return StormgateAttackData
function Attack._parse(args)
	return {
		targets = Array.map(Array.map(Array.parseCommaSeparatedString(args.target), string.lower), String.upperCaseFirst),
			function(target)
				return mw.getContentLanguage():ucfirst(String.trim(target):lower())
			end
		),
		damage = tonumber(args.damage),
		damagePercentage = tonumber(args.damage_percentage),
		effect = Array.parseCommaSeparatedString(args.effect),
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


---@param inputString string?
---@return string
function Attack._displayCommaSeparatedString(inputString)
	return table.concat(Array.map(Array.parseCommaSeparatedString(inputString),
		function(value)
			return Page.makeInternalLink(value)
		end
	), ', ')
end

return Attack
