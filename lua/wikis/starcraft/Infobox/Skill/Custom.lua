---
-- @Liquipedia
-- page=Module:Infobox/Skill/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local CostDisplay = require('Module:Infobox/Extension/CostDisplay')
local Faction = require('Module:Faction')
local Hotkeys = require('Module:Hotkey')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')

local Injector = Lua.import('Module:Widget/Injector')
local Skill = Lua.import('Module:Infobox/Skill')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

---@class StarcraftSkillInfobox: SkillInfobox
local CustomSkill = Class.new(Skill)

local ENERGY_ICON = '[[File:EnergyIcon.gif|link=Energy]]'

local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomSkill.run(frame)
	local skill = CustomSkill(frame)

	assert(skill.args.informationType, 'Missing "informationType"')

	skill:setWidgetInjector(CustomInjector(skill))

	return skill:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'custom' then
		return {
			Cell{name = 'Area of Effect', content = {args.area}},
			Cell{name = 'Move Speed', content = {args.movespeed}},
			Cell{name = 'Researched from', content = {self.caller:getResearchFrom()}},
			Cell{name = 'Research Cost', content = {self.caller:getResearchCost()}},
			Cell{name = 'Research Hotkey', content = {self.caller:getResearchHotkey()}},
		}
	elseif id == 'cost' then
		return {Cell{name = 'Cost', content = {self.caller:getCostDisplay()}}}
	elseif id == 'hotkey' then
		return {Cell{name = '[[Shortcuts|Hotkey]]', content = {self.caller:getHotkeys()}}}
	elseif id == 'cooldown' then
		return {Cell{name = '[[Cooldown]]', content = {args.cooldown}}}
	elseif id == 'duration' then
		return {Cell{name = '[[Game Speed|Duration]]', content = {args.duration}}}
	end

	return widgets
end

---@return string?
function CustomSkill:getResearchCost()
	if String.isEmpty(self.args.from) then
		return nil
	end

	return CostDisplay.run{
		faction = self.args.race,
		minerals = self.args.min,
		gas = self.args.gas,
		buildTime = self.args.buildtime,
		supply = self.args.supply or self.args.control or self.args.psy,
	}
end

---@return string
function CustomSkill:getResearchFrom()
	if String.isEmpty(self.args.from) then
		return 'No research needed'
	elseif String.isEmpty(self.args.from2) then
		return '[[' .. self.args.from .. ']]'
	else
		return '[[' .. self.args.from .. ']], [[' .. self.args.from2 .. ']]'
	end
end

---@return string?
function CustomSkill:getResearchHotkey()
	if String.isEmpty(self.args.from) then
		return
	end

	return Hotkeys.hotkey{hotkey = self.args.rshortcut}
end

---@param args table
---@return string[]
function CustomSkill:getCategories(args)
	local skill = args.informationType .. 's'
	local categories = {skill}
	local race = Faction.toName(Faction.read(args.race))
	if race then
		table.insert(categories, race .. ' ' .. skill)
	end

	return categories
end

---@return string?
function CustomSkill:getHotkeys()
	if not String.isEmpty(self.args.shortcut) then
		if not String.isEmpty(self.args.shortcut2) then
			return Hotkeys.hotkey2{hotkey1 = self.args.shortcut, hotkey2 = self.args.shortcut2, seperator = 'slash'}
		else
			return Hotkeys.hotkey{hotkey = self.args.shortcut}
		end
	end
end

---@return string
function CustomSkill:getCostDisplay()
	local energy = tonumber(self.args.energy) or 0
	return ENERGY_ICON .. '&nbsp;' .. energy
end

return CustomSkill
