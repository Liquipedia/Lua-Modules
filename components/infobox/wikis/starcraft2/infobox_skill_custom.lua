---
-- @Liquipedia
-- wiki=starcraft2
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

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Skill = Lua.import('Module:Infobox/Skill', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local CustomSkill = Class.new()

local ENERGY = '[[File:EnergyIcon.gif|link=Energy]]'
local SPELL = 'Spell'
local INFORMATIONTYPE_TO_CATEGORY = {
	spell = 'Spells',
	ability = 'Abilities',
}

local CustomInjector = Class.new(Injector)

local _args

---@param frame Frame
---@return unknown
function CustomSkill.run(frame)
	local skill = Skill(frame)
	skill.createWidgetInjector = CustomSkill.createWidgetInjector
	skill.getCategories = CustomSkill.getCategories
	_args = skill.args
	assert(INFORMATIONTYPE_TO_CATEGORY[(_args.informationType or ''):lower()], 'Missing or invalid "informationType"')
	return skill:createInfobox()
end

---@return WidgetInjector
function CustomSkill:createWidgetInjector()
	return CustomInjector()
end

---@param widgets Widget[]
---@return Widget[]
function CustomInjector:addCustomCells(widgets)
	return Array.append(
		widgets,
		Cell{name = '[[Game Speed|Duration 2]]', content = {CustomSkill:getDuration(2)}},
		Cell{name = 'Researched from', content = {CustomSkill:getResearchFrom()}},
		Cell{name = 'Research Cost', content = {CustomSkill:getResearchCost()}},
		Cell{name = 'Research Hotkey', content = {CustomSkill:getResearchHotkey()}},
		Cell{name = 'Move Speed', content = {_args.movespeed}}
	)
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	if id == 'cost' then
		return {Cell{name = 'Cost', content = {CustomSkill:getCostDisplay()}}}
	elseif id == 'hotkey' then
		return {Cell{name = '[[Hotkeys per Race|Hotkey]]', content = {CustomSkill:getHotkeys()}}}
	elseif id == 'cooldown' then
		return {
			Cell{name = Page.makeInternalLink({onlyIfExists = true},'Cooldown') or 'Cooldown', content = {_args.cooldown}}
		}
	elseif id == 'duration' then
		return {Cell{name = '[[Game Speed|Duration]]', content = {CustomSkill:getDuration()}}}
	end

	return widgets
end

---@return string?
function CustomSkill:getResearchFrom()
	if String.isEmpty(_args.from) then
		return 'No research needed'
	elseif String.isNotEmpty(_args.from2) then
		return '[[' .. _args.from .. ']], [[' .. _args.from2 .. ']]'
	else
		return '[[' .. _args.from .. ']]'
	end
end

---@return string?
function CustomSkill:getResearchHotkey()
	if String.isNotEmpty(_args.from) then
		return Hotkeys.hotkey(_args.rhotkey)
	end
end

---@return string?
function CustomSkill:getResearchCost()
	if String.isEmpty(_args.from) or _args.informationType ~= SPELL then
		return
	end

	return CostDisplay.run{
		faction = _args.race,
		minerals = _args.min,
		gas = _args.gas,
		buildTime = _args.buildtime,
	}
end

---@param args table
---@return string[]
function CustomSkill:getCategories(args)
	local skill = INFORMATIONTYPE_TO_CATEGORY[(_args.informationType or ''):lower()]
	local categories = {skill}
	local race = Faction.toName(Faction.read(_args.race))
	if race then
		table.insert(categories, race .. ' ' .. skill)
	end

	return categories
end

---@param postfix string|number|nil
---@return string?
function CustomSkill:getDuration(postfix)
	postfix = postfix or ''

	local display

	if Logic.readBool(_args['channeled' .. postfix]) and String.isNotEmpty(_args['duration' .. postfix]) then
		display = 'Channeled&nbsp;' .. _args['duration' .. postfix]
	elseif Logic.readBool(_args['channeled' .. postfix]) then
		display = 'Channeled'
	elseif String.isNotEmpty(_args['duration' .. postfix]) then
		display = _args['duration' .. postfix]
	else
		return
	end

	if String.isNotEmpty(display) and String.isNotEmpty(_args['caster' .. postfix]) then
		return display .. '&#32;([[' .. _args['caster' .. postfix] .. ']])'
	end

	return display
end

---@return string?
function CustomSkill:getHotkeys()
	if String.isNotEmpty(_args.hotkey) and String.isNotEmpty(_args.hotkey2) then
		return Hotkeys.hotkey2(_args.hotkey, _args.hotkey2, 'slash')
	elseif String.isNotEmpty(_args.hotkey) then
		return Hotkeys.hotkey(_args.hotkey)
	end
end

---@return string?
function CustomSkill:getCostDisplay()
	if _args.informationType == SPELL then
		return ENERGY .. '&nbsp;' .. (tonumber(_args.energy or 0) or 0)
	end

	return CostDisplay.run{
		faction = _args.race,
		minerals = _args.min,
		mineralsForced = true,
		gas = _args.gas,
		gasForced = true,
		buildTime = _args.buildtime,
		supply = _args.supply or _args.control or _args.psy,
	}
end

return CustomSkill
