---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:Infobox/Skill/Spell
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local CleanRace = require('Module:CleanRace2')
local Hotkeys = require('Module:Hotkey')
local Lua = require('Module:Lua')
local Page = require('Module:Page')
local String = require('Module:StringUtils')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Skill = Lua.import('Module:Infobox/Skill', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local Spell = Class.new()

local _MINERALS = '[[File:Minerals.gif|baseline|link=Minerals]]'
local _GAS = mw.loadData('Module:Gas')
local _TIME = mw.loadData('Module:Buildtime')
local _ENERGY = '[[File:EnergyIcon.gif|link=Energy]]'

local CustomInjector = Class.new(Injector)

local _args

function Spell.run(frame)
	local spell = Skill(frame)
	spell.createWidgetInjector = Spell.createWidgetInjector
	spell.getCategories = Spell.getCategories
	_args = spell.args
	return spell:createInfobox(frame)
end

function CustomInjector:addCustomCells(widgets)

	table.insert(widgets, Cell{
		name = '[[Game Speed|Duration 2]]',
		content = {Spell:getDuration2()}
	})
	table.insert(widgets, Cell{
		name = 'Researched from',
		content = {Spell:getResearchFrom()}
	})
	table.insert(widgets, Cell{
		name = 'Research Cost',
		content = {Spell:getResearchCost()}
	})
	table.insert(widgets, Cell{
		name = 'Research Hotkey',
		content = {Spell:getResearchHotkey()}
	})
	table.insert(widgets, Cell{
		name = 'Move Speed',
		content = {_args.movespeed}
	})

	return widgets
end

function CustomInjector:parse(id, widgets)
	if id == 'cost' then
		return {
			Cell{
				name = 'Cost',
				content = {Spell:getCostDisplay()}

			}
		}
	elseif id == 'hotkey' then
		return {
			Cell{
				name = '[[Hotkeys per Race|Hotkey]]',
				content = {Spell:getHotkeys()}

			}
		}
	elseif id == 'cooldown' then
		return {
			Cell{
				name = Page.makeInternalLink({onlyIfExists = true},'Cooldown') or 'Cooldown',
				content = {_args.cooldown}

			}
		}
	elseif id == 'duration' then
		return {
			Cell{
				name = '[[Game Speed|Duration]]',
				content = {Spell:getDuration()}

			}
		}
	end

	return widgets
end

function Spell:createWidgetInjector()
	return CustomInjector()
end

function Spell:getResearchCost()
	local display
	if String.isEmpty(_args.from) then
		return nil
	end

	local race = string.lower(_args.race or '')

	local minerals = tonumber(_args.min or 0) or 0
	if minerals ~= 0 then
		minerals = _MINERALS .. '&nbsp;' .. minerals .. '&nbsp;'
	else
		minerals = ''
	end

	local gas = tonumber(_args.gas or 0) or 0
	if gas ~= 0 then
		gas = (_GAS[race] or _GAS['default']) .. '&nbsp;' .. gas .. '&nbsp;'
	else
		gas = ''
	end

	local buildtime = tonumber(_args.buildtime or 0) or 0
	if buildtime ~= 0 then
		buildtime = (_TIME[race] or _TIME['default']) .. '&nbsp;' .. buildtime
	else
		buildtime = ''
	end

	display = minerals .. gas .. buildtime
	if display == '' then
		return nil
	else
		return display
	end
end

function Spell:getResearchFrom()
	local from = _args.from
	if String.isEmpty(from) then
		from = 'No research needed'
	elseif not String.isEmpty(_args.from2) then
		from = '[[' .. from .. ']], [[' .. _args.from2 .. ']]'
	else
		from = '[[' .. from .. ']]'
	end

	return from
end

function Spell:getResearchHotkey()
	local display
	if not String.isEmpty(_args.from) then
		display = Hotkeys.hotkey(_args.rhotkey)
	end

	return display
end

function Spell:getCategories()
	local categories = { 'Spells' }
	local race = string.lower(_args.race or '')
	race = CleanRace[race]
	if race then
		table.insert(categories, race .. ' Spells')
	end

	return categories
end

function Spell:getDuration2()
	local display

	if _args.channeled2 == 'true' then
		display = 'Channeled&nbsp;' .. _args.duration2
	end
	if not String.isEmpty(_args.duration2) then
		display = (display or '') .. _args.duration2
	end

	if
		(not String.isEmpty(display))
		and (not String.isEmpty(_args.caster2))
	then
		display = display .. '&#32;([[' .. _args.caster2 .. ']])'
	end

	return display
end

function Spell:getDuration()
	local display

	if _args.channeled == 'true' then
		display = 'Channeled&nbsp;'
	end
	if not String.isEmpty(_args.duration) then
		display = (display or '') .. _args.duration
	end

	if
		(not String.isEmpty(display))
		and (not String.isEmpty(_args.duration2))
		and (not String.isEmpty(_args.caster))
	then
		display = display .. '&#32;([[' .. _args.caster .. ']])'
	end

	return display
end

function Spell:getHotkeys()
	local display
	if not String.isEmpty(_args.hotkey) then
		if not String.isEmpty(_args.hotkey2) then
			display = Hotkeys.hotkey2(_args.hotkey, _args.hotkey2, 'slash')
		else
			display = Hotkeys.hotkey(_args.hotkey)
		end
	end

	return display
end

function Spell:getCostDisplay()
	local energy = tonumber(_args.energy or 0) or 0
	energy = _ENERGY .. '&nbsp;' .. energy
	return energy
end

return Spell
