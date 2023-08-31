---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:Infobox/Skill/Spell
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

local Spell = Class.new()

local ENERGY = '[[File:EnergyIcon.gif|link=Energy]]'

local CustomInjector = Class.new(Injector)

local _args

---@param frame Frame
---@return unknown
function Spell.run(frame)
	local spell = Skill(frame)
	spell.createWidgetInjector = Spell.createWidgetInjector
	spell.getCategories = Spell.getCategories
	_args = spell.args
	return spell:createInfobox()
end

---@param widgets Widget[]
---@return Widget[]
function CustomInjector:addCustomCells(widgets)
	return Array.append(
		widgets,
		Cell{name = '[[Game Speed|Duration 2]]', content = {Spell:getDuration(2)}},
		Cell{name = 'Researched from', content = {Spell:getResearchFrom()}},
		Cell{name = 'Research Cost', content = {Spell:getResearchCost()}},
		Cell{name = 'Research Hotkey', content = {Spell:getResearchHotkey()}},
		Cell{name = 'Move Speed', content = {_args.movespeed}}
	)
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	if id == 'cost' then
		return {Cell{name = 'Cost', content = {Spell:getCostDisplay()}}}
	elseif id == 'hotkey' then
		return {Cell{name = '[[Hotkeys per Race|Hotkey]]', content = {Spell:getHotkeys()}}}
	elseif id == 'cooldown' then
		return {
			Cell{ame = Page.makeInternalLink({onlyIfExists = true},'Cooldown') or 'Cooldown', content = {_args.cooldown}}
		}
	elseif id == 'duration' then
		return {Cell{name = '[[Game Speed|Duration]]', content = {Spell:getDuration()}}}
	end

	return widgets
end

---@return WidgetInjector
function Spell:createWidgetInjector()
	return CustomInjector()
end

---@return string?
function Spell:getResearchCost()
	if String.isEmpty(_args.from) then
		return nil
	end

	return CostDisplay.run{
		faction = _args.race,
		minerals = _args.min,
		gas = _args.gas,
		buildTime = _args.buildtime,
	}
end

---@return string?
function Spell:getResearchFrom()
	if String.isEmpty(_args.from) then
		return 'No research needed'
	elseif String.isNotEmpty(_args.from2) then
		return '[[' .. _args.from .. ']], [[' .. _args.from2 .. ']]'
	else
		return '[[' .. _args.from .. ']]'
	end
end

---@return string?
function Spell:getResearchHotkey()
	if String.isNotEmpty(_args.from) then
		return Hotkeys.hotkey(_args.rhotkey)
	end
end

---@return string[]
function Spell:getCategories()
	local categories = {'Spells'}
	local race = Faction.toName(Faction.read(_args.race))
	if race then
		table.insert(categories, race .. ' Spells')
	end

	return categories
end

---@param postfix string|number|nil
---@return string?
function Spell:getDuration(postfix)
	postfix = postfix or ''

	local display

	if Logic.readBool(_args['channeled' .. postfix]) then
		display = 'Channeled&nbsp;' .. _args['duration' .. postfix]
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
function Spell:getHotkeys()
	if String.isNotEmpty(_args.hotkey) and String.isNotEmpty(_args.hotkey2) then
		return Hotkeys.hotkey2(_args.hotkey, _args.hotkey2, 'slash')
	elseif String.isNotEmpty(_args.hotkey) then
		return Hotkeys.hotkey(_args.hotkey)
	end
end

---@return string
function Spell:getCostDisplay()
	local energy = tonumber(_args.energy or 0) or 0
	return ENERGY .. '&nbsp;' .. energy
end

return Spell
