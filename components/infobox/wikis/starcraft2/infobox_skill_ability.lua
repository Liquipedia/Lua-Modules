---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:Infobox/Skill/Ability
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local CostDisplay = require('Module:Infobox/Extension/CostDisplay')
local Faction = require('Module:Faction')
local Hotkeys = require('Module:Hotkey')
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

function Ability.run(frame)
	local ability = Skill(frame)
	ability.createWidgetInjector = Ability.createWidgetInjector
	ability.getCategories = Ability.getCategories
	_args = ability.args
	return ability:createInfobox()
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
				content = {CostDisplay.run{
					faction = _args.race,
					minerals = _args.min,
					mineralsForced = true,
					gas = _args.gas,
					gasForced = true,
					buildTime = _args.buildtime,
					supply = _args.supply or _args.control or _args.psy,
				}}
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
				name = Page.makeInternalLink({onlyIfExists = true},'Cooldown') or 'Cooldown',
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
	local race = Faction.toName(Faction.read(_args.race))
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

return Ability
