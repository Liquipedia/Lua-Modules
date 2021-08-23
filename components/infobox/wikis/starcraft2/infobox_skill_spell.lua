local Spell = require('Module:Infobox/Skill')
local Hotkeys = require('Module:Hotkey')
local CleanRace = require('Module:CleanRace2')
local String = require('Module:StringUtils')

local StarCraft2Spell = {}

local _MINERALS = '[[File:Minerals.gif|baseline|link=Minerals]]'
local _GAS = mw.loadData('Module:Gas')
local _TIME = mw.loadData('Module:Buildtime')
local _ENERGY = '[[File:EnergyIcon.gif|link=Energy]]'

function StarCraft2Spell.run(frame)
	local spell = Spell(frame)
	spell.getCategories = StarCraft2Spell.getCategories
	spell.getDuration = StarCraft2Spell.getDuration
	spell.getHotkeys = StarCraft2Spell.getHotkeys
	spell.getCostDisplay = StarCraft2Spell.getCostDisplay
	spell.addCustomCells = StarCraft2Spell.addCustomCells

	return spell:createInfobox(frame)
end

function StarCraft2Spell:addCustomCells(infobox, args)

	local duration2Description, duration2Display = StarCraft2Spell:getDuration2(infobox, args)

	infobox:cell(duration2Description, duration2Display)
	infobox:cell('Researched from', StarCraft2Spell:getResearchFrom(infobox, args))
	infobox:cell('Research Cost', StarCraft2Spell:getResearchCost(infobox, args))
	infobox:cell('Research Hotkey', StarCraft2Spell:getResearchHotkey(infobox, args))
	infobox:cell('Move Speed', args.movespeed)

	return infobox
end

function StarCraft2Spell:getResearchCost(infobox, args)
	local display
	if String.isEmpty(args.from) then
		return nil
	end

	local race = string.lower(args.race or '')

	local minerals = tonumber(args.min or 0) or 0
	if minerals ~= 0 then
		minerals = _MINERALS .. '&nbsp;' .. minerals .. '&nbsp;'
	else
		minerals = ''
	end

	local gas = tonumber(args.gas or 0) or 0
	if gas ~= 0 then
		gas = (_GAS[race] or _GAS['default']) .. '&nbsp;' .. gas .. '&nbsp;'
	else
		gas = ''
	end

	local buildtime = tonumber(args.buildtime or 0) or 0
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

function StarCraft2Spell:getResearchFrom(infobox, args)
	local from = args.from
	if String.isEmpty(args.from) then
		from = 'No research needed'
	elseif not String.isEmpty(args.from2) then
		from = '[[' .. from .. ']], [[' .. args.from2 .. ']]'
	else
		from = '[[' .. from .. ']]'
	end

	return from
end

function StarCraft2Spell:getResearchHotkey(infobox, args)
	local display
	if not String.isEmpty(args.from) then
		display = Hotkeys.hotkey(args.rhotkey)
	end

	return display
end

function StarCraft2Spell:getCategories(infobox, args)
	local categories = { 'Spells' }
	local race = CleanRace[args.race or '']
	if race then
		table.insert(categories, race .. ' Spells')
	end

	return categories
end

function StarCraft2Spell:getDuration2(infobox, args)
	local display
	local description = '[[Game Speed|Duration 2]]'

	if args.channeled2 == 'true' then
		display = 'Channeled&nbsp;' .. args.duration2
	end
	if not String.isEmpty(args.duration2) then
		display = (display or '') .. args.duration2
	end

	if
		(not String.isEmpty(display))
		and (not String.isEmpty(args.caster2))
	then
		display = display .. '&#32;([[' .. args.caster2 .. ']])'
	end

	return description, display
end

function StarCraft2Spell:getDuration(infobox, args)
	local display
	local description = '[[Game Speed|Duration]]'

	if args.channeled == 'true' then
		display = 'Channeled&nbsp;'
	end
	if not String.isEmpty(args.duration) then
		display = (display or '') .. args.duration
	end

	if
		(not String.isEmpty(display))
		and (not String.isEmpty(args.duration2))
		and (not String.isEmpty(args.caster))
	then
		display = display .. '&#32;([[' .. args.caster .. ']])'
	end

	return description, display
end

function StarCraft2Spell:getHotkeys(infobox, args)
	local description = '[[Hotkeys per Race|Hotkey]]'
	local display
	if not String.isEmpty(args.hotkey) then
		if not String.isEmpty(args.hotkey2) then
			display = Hotkeys.hotkey(args.hotkey, args.hotkey2, 'slash')
		else
			display = Hotkeys.hotkey(args.hotkey)
		end
	end

	return description, display
end

function StarCraft2Spell:getCostDisplay(infobox, args)
	local energy = tonumber(args.energy or 0) or 0
	energy = _ENERGY .. '&nbsp;' .. energy
	return energy
end

return StarCraft2Spell
