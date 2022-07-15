---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:Infobox/Skill/Ability
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Skill = require('Module:Infobox/Skill')
local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')
local CleanRace = require('Module:CleanRace2')
local Hotkeys = require('Module:Hotkey')
local String = require('Module:StringUtils')
local PageLink = require('Module:Page')

local Ability = Class.new()

local _MINERALS = '[[File:Minerals.gif|baseline|link=Minerals]]'
local _GAS = mw.loadData('Module:Gas')
local _TIME = mw.loadData('Module:Buildtime')
local _SUPPLY = mw.loadData('Module:Supply')

local CustomInjector = Class.new(Injector)

local _args

function Ability.run(frame)
	local ability = Skill(frame)
	ability.createWidgetInjector = Ability.createWidgetInjector
	ability.getCategories = Ability.getCategories
	_args = ability.args
	return ability:createInfobox(frame)
end

function CustomInjector:addCustomCells(widgets)
	table.insert(widgets, Cell{
		name = '[[Game Speed|Duration 2]]',
		content = {Ability:getDuration2()}
	})
	table.insert(widgets, Cell{
		name = 'Researched from',
		content = {Ability:getResearchFrom()}
	})
	table.insert(widgets, Cell{
		name = 'Research Hotkey',
		content = {Ability:getResearchHotkey()}
	})

	return widgets
end

function Ability:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:parse(id, widgets)
	if id == 'cost' then
		return {
			Cell{
				name = 'Cost',
				content = {Ability:getCostDisplay()}

			}
		}
	elseif id == 'hotkey' then
		return {
			Cell{
				name = '[[Hotkeys per Race|Hotkey]]',
				content = {Ability:getHotkeys()}

			}
		}
	elseif id == 'cooldown' then
		return {
			Cell{
				name = PageLink.makeInternalLink({onlyIfExists = true},'Cooldown') or 'Cooldown',
				content = {_args.cooldown}

			}
		}
	elseif id == 'duration' then
		return {
			Cell{
				name = '[[Game Speed|Duration]]',
				content = {Ability:getDuration()}

			}
		}
	end

	return widgets
end

function Ability:getResearchFrom()
	local from = _args.from
	if String.isEmpty(_args.from) then
		from = 'No research needed'
	elseif not String.isEmpty(_args.from2) then
		from = '[[' .. from .. ']], [[' .. _args.from2 .. ']]'
	else
		from = '[[' .. from .. ']]'
	end

	return from
end

function Ability:getResearchHotkey()
	local display
	if not String.isEmpty(_args.from) then
		display = Hotkeys.hotkey(_args.rhotkey)
	end

	return display
end

function Ability:getCategories()
	local categories = { 'Abilities' }
	local race = string.lower(_args.race or '')
	race = CleanRace[race]
	if race then
		table.insert(categories, race .. ' Abilities')
	end

	return categories
end

function Ability:getDuration2()
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

function Ability:getDuration()
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

function Ability:getHotkeys()
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

function Ability:getCostDisplay()
	local race = string.lower(_args.race or '')

	local minerals = tonumber(_args.min or 0) or 0
	minerals = _MINERALS .. '&nbsp;' .. minerals

	local gas = tonumber(_args.gas or 0) or 0
	gas = (_GAS[race] or _GAS['default']) .. '&nbsp;' .. gas

	local buildtime = tonumber(_args.buildtime or 0) or 0
	if buildtime ~= 0 then
		buildtime = '&nbsp;' .. (_TIME[race] or _TIME['default']) .. '&nbsp;' .. buildtime
	else
		buildtime = ''
	end

	local supply = _args.supply or _args.control or _args.psy or 0
	supply = tonumber(supply) or 0
	if supply == 0 then
		supply = ''
	else
		supply = '&nbsp;' .. (_SUPPLY[race] or _SUPPLY['default']) .. '&nbsp;' .. supply
	end

	return minerals .. '&nbsp;' .. gas .. buildtime .. supply
end

return Ability
