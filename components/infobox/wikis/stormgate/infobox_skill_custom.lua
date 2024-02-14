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
local Table = require('Module:Table')

local Injector = Lua.import('Module:Infobox/Widget/Injector')
local Skill = Lua.import('Module:Infobox/Skill')

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

---@class StormgateSkillInfobox: SkillInfobox
---@field faction string?
local CustomSkill = Class.new(Skill)
local CustomInjector = Class.new(Injector)

local ENERGY_ICON = '[[File:EnergyIcon.gif|link=Energy]]'
local VALID_SKILLS = {
	'Spell',
	'Ability',
	'Upgrade',
	'Effect',
}

---@param frame Frame
---@return unknown
function CustomSkill.run(frame)
	local skill = CustomSkill(frame)

	assert(Table.includes(VALID_SKILLS, skill.args.informationType), 'Missing or invalid "informationType"')

	skill:setWidgetInjector(CustomInjector(skill))

	skill.faction = Faction.read(skill.args.faction)

	skill:_calculateDamageHealTotalAndDps('damage')
	skill:_calculateDamageHealTotalAndDps('heal')

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
		local castingTime = tonumber(args.casting_time)
		Array.extendWith(widgets, {
				Cell{name = 'Researched From', content = {Page.makeInternalLink(args.from)}},
				Cell{name = 'Upgrade Target', content = caller:_readCommaSeparatedList(args.upgrade_target, true)},
				Cell{name = 'Tech. Requirements', content = caller:_readCommaSeparatedList(args.tech_requirement, true)},
				Cell{name = 'Building Requirements', content = caller:_readCommaSeparatedList(args.building_requirement, true)},
				Cell{name = 'Unlocks', content = caller:_readCommaSeparatedList(args.unlocks, true)},
				Cell{name = 'Target', content = caller:_readCommaSeparatedList(args.target, true)},
				Cell{name = 'Casting Time', content = {castingTime and (castingTime .. 's') or nil}},
				Cell{name = 'Effect', content = caller:_readCommaSeparatedList(args.effect, true)},
				Cell{name = 'Trigger', content = {args.trigger}},
				Cell{name = 'Invulnerable', content = caller:_readCommaSeparatedList(args.invulnerable, true)},
			},
			caller:_damageHealDisplay('damage'),
			caller:_damageHealDisplay('heal')
		)
	end

	return widgets
end

---@param prefix string
function CustomSkill:_calculateDamageHealTotalAndDps(prefix)
	self.args[prefix] = tonumber(self.args[prefix])
	local value = self.args[prefix] or 0
	self.args[prefix .. '_over_time'] = tonumber(self.args[prefix .. '_over_time'])
	local overTime = self.args[prefix .. '_over_time'] or 0
	self.args.duration = tonumber(self.args.duration)
	local duration = self.args.duration or 0

	self.args[prefix .. 'Total'] = value + overTime * duration
	self.args[prefix .. 'Dps'] = duration > 0 and (self.args[prefix .. 'Total'] / duration) or 0
end

---@param prefix string
---@return Widget[]
function CustomSkill:_damageHealDisplay(prefix)
	local value = self.args[prefix]
	local overTime = self.args[prefix .. '_over_time']
	local percentage = tonumber(self.args[prefix .. '_percentage'])
	local total = self.args[prefix .. 'Total']
	local dps = self.args[prefix .. 'Dps']

	local valueText = percentage and (percentage .. '%') or table.concat(Array.append({},
		value,
		overTime and (overTime .. '/s') or nil
	), ' +')

	local textPrefix = mw.getContentLanguage():ucfirst(prefix)
	return {
		Cell{name = textPrefix, content = {valueText}},
		Cell{name = 'Total ' .. textPrefix, content = {total ~= 0 and total or nil}},
		Cell{name = textPrefix .. ' per second', content = {dps ~= 0 and dps ~= overTime and dps or nil}},
	}
end

---@param args table
---@return string[]
function CustomSkill:getCategories(args)
	local categories = {args.informationType}
	if self.faction then
		table.insert(categories, self.faction .. ' ' .. args.informationType)
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
		from = args.from,
		upgradetarget = self:_readCommaSeparatedList(args.upgrade_target),
		range = tonumber(args.range),
		radius = tonumber(args.radius),
		cooldown = tonumber(args.cooldown),
		castingtime = tonumber(args.casting_time),
		unlocks = self:_readCommaSeparatedList(args.unlocks),
		effect = self:_readCommaSeparatedList(args.effect),
		trigger = args.trigger,
		invulnerable = self:_readCommaSeparatedList(args.invulnerable),
		damage = args.damage,
		damagepercentage = args.damage_percentage,
		damagetotal = args.damageTotal,
		damagedps = args.damageDps,
		damageovertime = args.damage_over_time,
		health = args.health,
		healthpercentage = args.health_percentage,
		healthtotal = args.healthTotal,
		healthdps = args.healthDps,
		healthovertime = args.health_over_time,
		specialcost = args.special_cost
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
		energy ~= 0 and (ENERGY_ICON .. '&nbsp;' .. energy) or nil,
		args.special_cost
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
