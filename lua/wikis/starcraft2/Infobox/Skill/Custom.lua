---
-- @Liquipedia
-- page=Module:Infobox/Skill/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local CostDisplay = require('Module:Infobox/Extension/CostDisplay')
local Faction = require('Module:Faction')
local Hotkeys = require('Module:Hotkey')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Page = require('Module:Page')
local String = require('Module:StringUtils')

local Injector = Lua.import('Module:Widget/Injector')
local Skill = Lua.import('Module:Infobox/Skill')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

---@class Starcraft2SkillInfobox: SkillInfobox
local CustomSkill = Class.new(Skill)

local ENERGY = '[[File:EnergyIcon.gif|link=Energy]]'
local SPELL = 'Spell'
local INFORMATIONTYPE_TO_CATEGORY = {
	spell = 'Spells',
	ability = 'Abilities',
}

local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomSkill.run(frame)
	local skill = CustomSkill(frame)

	assert(INFORMATIONTYPE_TO_CATEGORY[(skill.args.informationType or ''):lower()], 'Missing or invalid "informationType"')

	skill:setWidgetInjector(CustomInjector(skill))

	return skill:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args
	if id == 'custom' then
		Array.appendWith(
			widgets,
			Cell{name = '[[Game Speed|Duration 2]]', content = {self.caller:getDuration(2)}},
			Cell{name = 'Researched from', content = {self.caller:getResearchFrom()}},
			Cell{name = 'Research Cost', content = {self.caller:getResearchCost()}},
			Cell{name = 'Research Hotkey', content = {self.caller:getResearchHotkey()}},
			Cell{name = 'Move Speed', content = {args.movespeed}}
		)
	elseif id == 'cost' then
		return {Cell{name = 'Cost', content = {self.caller:getCostDisplay()}}}
	elseif id == 'hotkey' then
		return {Cell{name = '[[Hotkeys per Race|Hotkey]]', content = {self.caller:getHotkeys()}}}
	elseif id == 'cooldown' then
		return {
			Cell{name = Page.makeInternalLink({onlyIfExists = true},'Cooldown') or 'Cooldown', content = {args.cooldown}}
		}
	elseif id == 'duration' then
		return {Cell{name = '[[Game Speed|Duration]]', content = {self.caller:getDuration()}}}
	end

	return widgets
end

---@return string?
function CustomSkill:getResearchFrom()
	if String.isEmpty(self.args.from) then
		return 'No research needed'
	end

	return table.concat({Page.makeInternalLink(self.args.from), Page.makeInternalLink(self.args.from2)}, ', ')
end

---@return string?
function CustomSkill:getResearchHotkey()
	if String.isNotEmpty(self.args.from) then
		return Hotkeys.hotkey{hotkey = self.args.rhotkey}
	end
end

---@return string?
function CustomSkill:getResearchCost()
	if String.isEmpty(self.args.from) or self.args.informationType ~= SPELL then
		return
	end

	return CostDisplay.run{
		faction = self.args.race,
		minerals = self.args.min,
		gas = self.args.gas,
		buildTime = self.args.buildtime,
	}
end

---@param args table
---@return string[]
function CustomSkill:getCategories(args)
	local skill = INFORMATIONTYPE_TO_CATEGORY[(args.informationType or ''):lower()]
	local categories = {skill}
	local race = Faction.toName(Faction.read(args.race))
	if race then
		table.insert(categories, race .. ' ' .. skill)
	end

	return categories
end

---@param postfix string|number|nil
---@return string?
function CustomSkill:getDuration(postfix)
	local args = self.args
	postfix = postfix or ''

	local display

	if Logic.readBool(args['channeled' .. postfix]) and String.isNotEmpty(args['duration' .. postfix]) then
		display = 'Channeled&nbsp;' .. args['duration' .. postfix]
	elseif Logic.readBool(args['channeled' .. postfix]) then
		display = 'Channeled'
	elseif String.isNotEmpty(args['duration' .. postfix]) then
		display = args['duration' .. postfix]
	else
		return
	end

	if String.isNotEmpty(display) and String.isNotEmpty(args['caster' .. postfix]) then
		return display .. '&#32;([[' .. args['caster' .. postfix] .. ']])'
	end

	return display
end

---@return string?
function CustomSkill:getHotkeys()
	local args = self.args
	if String.isNotEmpty(args.hotkey) and String.isNotEmpty(args.hotkey2) then
		return Hotkeys.hotkey2{hotkey1 = args.hotkey, hotkey2 = args.hotkey2, seperator = 'slash'}
	elseif String.isNotEmpty(args.hotkey) then
		return Hotkeys.hotkey{hotkey = args.hotkey}
	end
end

---@return string?
function CustomSkill:getCostDisplay()
	local args = self.args
	if args.informationType == SPELL then
		return ENERGY .. '&nbsp;' .. (tonumber(args.energy or 0) or 0)
	end

	return CostDisplay.run{
		faction = args.race,
		minerals = args.min,
		mineralsForced = true,
		gas = args.gas,
		gasForced = true,
		buildTime = args.buildtime,
		supply = args.supply or args.control or args.psy,
	}
end

return CustomSkill
