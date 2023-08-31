---
-- @Liquipedia
-- wiki=starcraft
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

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Skill = Lua.import('Module:Infobox/Skill', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local CustomSkill = Class.new()

local ENERGY_ICON = '[[File:EnergyIcon.gif|link=Energy]]'

local CustomInjector = Class.new(Injector)

local _args

---@param frame Frame
---@return Html
function CustomSkill.run(frame)
	local customSkill = Skill(frame)
	customSkill.createWidgetInjector = CustomSkill.createWidgetInjector
	customSkill.getCategories = CustomSkill.getCategories
	_args = customSkill.args
	assert(_args.informationType, 'Missing "informationType"')
	return customSkill:createInfobox()
end

---@param widgets Widget[]
---@return Widget[]
function CustomInjector:addCustomCells(widgets)
	return {
		Cell{name = 'Area of Effect', content = {_args.area}},
		Cell{name = 'Move Speed', content = {_args.movespeed}},
		Cell{name = 'Researched from', content = {CustomSkill:getResearchFrom()}},
		Cell{name = 'Research Cost', content = {CustomSkill:getResearchCost()}},
		Cell{name = 'Research Hotkey', content = {CustomSkill:getResearchHotkey()}},
	}
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	if id == 'cost' then
		return {Cell{name = 'Cost', content = {CustomSkill:getCostDisplay()}}}
	elseif id == 'hotkey' then
		return {Cell{name = '[[Shortcuts|Hotkey]]', content = {CustomSkill:getHotkeys()}}}
	elseif id == 'cooldown' then
		return {Cell{name = '[[Cooldown]]', content = {_args.cooldown}}}
	elseif id == 'duration' then
		return {Cell{name = '[[Game Speed|Duration]]', content = {_args.duration}}}
	end

	return widgets
end

---@return WidgetInjector
function CustomSkill:createWidgetInjector()
	return CustomInjector()
end

---@return string?
function CustomSkill:getResearchCost()
	if String.isEmpty(_args.from) then
		return nil
	end

	return CostDisplay.run{
		faction = _args.race,
		minerals = _args.min,
		gas = _args.gas,
		buildTime = _args.buildtime,
		supply = _args.supply or _args.control or _args.psy,
	}
end

---@return string
function CustomSkill:getResearchFrom()
	if String.isEmpty(_args.from) then
		return 'No research needed'
	elseif String.isEmpty(_args.from2) then
		return '[[' .. _args.from .. ']]'
	else
		return '[[' .. _args.from .. ']], [[' .. _args.from2 .. ']]'
	end
end

---@return string?
function CustomSkill:getResearchHotkey()
	if String.isEmpty(_args.from) then
		return
	end

	return Hotkeys.hotkey(_args.rshortcut)
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
	if not String.isEmpty(_args.shortcut) then
		if not String.isEmpty(_args.shortcut2) then
			return Hotkeys.hotkey2(_args.shortcut, _args.shortcut2, 'slash')
		else
			return Hotkeys.hotkey(_args.shortcut)
		end
	end
end

---@return string
function CustomSkill:getCostDisplay()
	local energy = tonumber(_args.energy) or 0
	return ENERGY_ICON .. '&nbsp;' .. energy
end

return CustomSkill
