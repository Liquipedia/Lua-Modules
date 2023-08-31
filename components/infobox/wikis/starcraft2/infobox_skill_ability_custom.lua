---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:Infobox/Skill/Ability/Custom
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

local Ability = Class.new()

local CustomInjector = Class.new(Injector)

local _args

---@param frame Frame
---@return Html
function Ability.run(frame)
	local ability = Skill(frame)
	ability.createWidgetInjector = Ability.createWidgetInjector
	ability.getCategories = Ability.getCategories
	_args = ability.args
	return ability:createInfobox()
end

---@param widgets Widget[]
---@return Widget[]
function CustomInjector:addCustomCells(widgets)
	return Array.append(
		widgets,
		Cell{name = '[[Game Speed|Duration 2]]', content = {Ability:getDuration(2)}},
		Cell{name = 'Researched from', content = {Ability:getResearchFrom()}},
		Cell{name = 'Research Hotkey', content = {Ability:getResearchHotkey()}}
	)
end

---@return WidgetInjector
function Ability:createWidgetInjector()
	return CustomInjector()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	if id == 'cost' then
		return {
			Cell{name = 'Cost', content = {CostDisplay.run{
				faction = _args.race,
				minerals = _args.min,
				mineralsForced = true,
				gas = _args.gas,
				gasForced = true,
				buildTime = _args.buildtime,
				supply = _args.supply or _args.control or _args.psy,
			}}}
		}
	elseif id == 'hotkey' then
		return {Cell{name = '[[Hotkeys per Race|Hotkey]]', content = {Ability:getHotkeys()}}}
	elseif id == 'cooldown' then
		return {
			Cell{name = Page.makeInternalLink({onlyIfExists = true},'Cooldown') or 'Cooldown', content = {_args.cooldown}}
		}
	elseif id == 'duration' then
		return {Cell{name = '[[Game Speed|Duration]]', content = {Ability:getDuration()}}}
	end

	return widgets
end

---@return string
function Ability:getResearchFrom()
	if String.isEmpty(_args.from) then
		return 'No research needed'
	elseif String.isNotEmpty(_args.from2) then
		return '[[' .. _args.from .. ']], [[' .. _args.from2 .. ']]'
	else
		return '[[' .. _args.from .. ']]'
	end
end

---@return string?
function Ability:getResearchHotkey()
	if String.isNotEmpty(_args.from) then
		return Hotkeys.hotkey(_args.rhotkey)
	end
end

---@return string[]
function Ability:getCategories()
	local categories = {'Abilities'}
	local race = Faction.toName(Faction.read(_args.race))
	if race then
		table.insert(categories, race .. ' Abilities')
	end

	return categories
end

---@param postfix string|number|nil
---@return string?
function Ability:getDuration(postfix)
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
function Ability:getHotkeys()
	if String.isNotEmpty(_args.hotkey) and String.isNotEmpty(_args.hotkey2) then
		return Hotkeys.hotkey2(_args.hotkey, _args.hotkey2, 'slash')
	elseif String.isNotEmpty(_args.hotkey) then
		return Hotkeys.hotkey(_args.hotkey)
	end
end

return Ability
