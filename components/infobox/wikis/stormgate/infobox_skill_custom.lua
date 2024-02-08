---
-- @Liquipedia
-- wiki=stormgate
-- page=Module:Infobox/Skill/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local CostDisplay = require('Module:Infobox/Extension/CostDisplay')
local Faction = require('Module:Faction')
local Hotkeys = require('Module:Hotkey')
local Lua = require('Module:Lua')
local Page = require('Module:Page')
local String = require('Module:StringUtils')

local Injector = Lua.import('Module:Infobox/Widget/Injector')
local Skill = Lua.import('Module:Infobox/Skill')

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Center = Widgets.Center
local Title = Widgets.Title

---@class StormgateSkillInfobox: SkillInfobox
---@field faction string?
local CustomSkill = Class.new(Skill)
local CustomInjector = Class.new(Injector)

local ENERGY_ICON = '[[File:EnergyIcon.gif|link=Energy]]'
local INFORMATIONTYPE_TO_CATEGORY = {
	spell = 'Spells',
	ability = 'Abilities',
	upgrade = 'Upgrades',
}

---@param frame Frame
---@return unknown
function CustomSkill.run(frame)
	local skill = CustomSkill(frame)

	assert(INFORMATIONTYPE_TO_CATEGORY[(skill.args.informationType or ''):lower()], 'Missing or invalid "informationType"')

	skill:setWidgetInjector(CustomInjector(skill))

	skill.faction = Faction.read(skill.args.faction)

	return skill:createInfobox()
end

---@param args table
---@return string
function CustomSkill:nameDisplay(args)
	local factionIcon = Faction.Icon{size = 'large', faction = self.faction or Faction.defaultFaction}
	factionIcon = factionIcon and (factionIcon .. '&nbsp;') or ''

	return factionIcon .. (args.name or self.pagename)
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args = caller.args

	if id == 'cost' then
		return {
			Cell{name = 'Cost', content = {caller:_costDisplay()}},
		}
	elseif id == 'duration' then
		return {
			Cell{name = 'Duration', content = {args.duration and (args.duration .. 's') or nil}},
		}
	elseif id == 'hotkey' then
		return {
			Cell{name = 'Hotkeys', content = {CustomSkill._hotkeys(args.hotkey, args.hotkey2)}},
			Cell{name = 'Macrokeys', content = {CustomSkill._hotkeys(args.macro_key, args.macro_key2)}},
		}
	elseif id == 'custom' then
		local damagePercentage = tonumber(args.damage_percentage)
		local damage = damagePercentage and (damagePercentage .. '%') or tonumber(args.damage)
		local castingTime = tonumber(args.casting_time)
		Array.appendWith(widgets,
			Cell{name = 'Researched From', content = {Page.makeInternalLink(args.from)}},
			Cell{name = 'Tech. Requirements', content = caller:_readCommaSeparatedList(args.tech_requirement, true)},
			Cell{name = 'Building Requirements', content = caller:_readCommaSeparatedList(args.building_requirement, true)},
			Cell{name = 'Unlocks', content = caller:_readCommaSeparatedList(args.unlocks, true)},
			Cell{name = 'Target', content = caller:_readCommaSeparatedList(args.target, true)},
			Cell{name = 'Damage', content = {damage}},
			Cell{name = 'DPS', content = {tonumber(args.dps)}},
			Cell{name = 'Casting Time', content = {castingTime and (castingTime .. 's') or nil}},
			args.effect and Title{name = 'Effect'} or nil,
			args.effect and Center{content = {args.effect}} or nil
		)
	end

	return widgets
end

---@param args table
---@return string[]
function CustomSkill:getCategories(args)
	local skill = INFORMATIONTYPE_TO_CATEGORY[(args.informationType or ''):lower()]
	local categories = {skill}
	if self.faction then
		table.insert(categories, self.faction .. ' ' .. skill)
	end

	return categories
end

---@param lpdbData table
---@param args table
---@return table
function CustomSkill:addToLpdb(lpdbData, args)
	lpdbData.information = self.faction
	lpdbData.extradata = {
		luminite = tonumber(args.luminite),
		totalluminite = tonumber(args.totalluminite),
		therium = tonumber(args.therium),
		totaltherium = tonumber(args.totaltherium),
		buildtime = tonumber(args.buildtime),
		totalbuildtime = tonumber(args.totalbuildtime),
		animus = tonumber(args.animus),
		totalanimus = tonumber(args.totalanimus),
		techrequirements = self:_readCommaSeparatedList(args.tech_requirement),
		buildingrequirements = self:_readCommaSeparatedList(args.building_requirement),
		targets = self:_readCommaSeparatedList(args.target),
		casters = self:getAllArgsForBase(args, 'caster'),
		hotkey = args.hotkey,
		hotkey2 = args.hotkey2,
		macrokey = args.macro_key,
		macrokey2 = args.macro_key2,
		energy = tonumber(args.energy),
		duration = tonumber(args.duration),
		damagepercentage = tonumber(args.damage_percentage),
		damage = tonumber(args.damage),
		from = args.from,
		dps = tonumber(args.dps),
		range = tonumber(args.range),
		radius = tonumber(args.radius),
		cooldown = tonumber(args.cooldown),
		castingtime = tonumber(args.casting_time),
		unlocks = self:_readCommaSeparatedList(args.unlocks),
	}

	return lpdbData
end

function CustomSkill:_costDisplay()
	local args = self.args
	local energy = tonumber(args.energy) or 0

	return table.concat(Array.append({},
		CostDisplay.run{
			faction = self.faction,
			luminite = args.luminite,
			luminiteTotal = args.totalluminite,
			therium = args.therium,
			theriumTotal = args.totaltherium,
			animus = args.animus,
			animusTotal = args.totalanimus,
			buildTime = args.buildtime,
			buildTimeTotal = args.totalbuildtime,
		},
		energy ~= 0 and (ENERGY_ICON .. '&nbsp;' .. energy) or nil
	), '&nbsp;')
end

---@param inputString string?
---@param makeLink boolean?
---@return string[]
function CustomSkill:_readCommaSeparatedList(inputString, makeLink)
	if String.isEmpty(inputString) then return {} end
	---@cast inputString -nil
	local values = Array.map(mw.text.split(inputString, ','), String.trim)
	if not makeLink then return values end
	return Array.map(values, function(value) return Page.makeInternalLink(value) end)
end

---@param hotkey1 string?
---@param hotkey2 string?
---@return string?
function CustomSkill._hotkeys(hotkey1, hotkey2)
	if String.isEmpty(hotkey1) then return end
	if String.isEmpty(hotkey2) then
		return Hotkeys.hotkey(hotkey1)
	end
	return Hotkeys.hotkey2(hotkey1, hotkey2, 'plus')
end

return CustomSkill
