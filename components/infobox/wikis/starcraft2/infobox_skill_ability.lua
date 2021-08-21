local Ability = require('Module:Infobox/Skill')
local Hotkeys = require('Module:Hotkey')
local CleanRace = require('Module:CleanRace2')
local String = require('Module:StringUtils')

local StarCraft2Ability = {}

local _MINERALS = '[[File:Minerals.gif|baseline|link=Minerals]]'
local _GAS = mw.loadData('Module:Gas')
local _SUPPLY = mw.loadData('Module:Supply')
local _TIME = mw.loadData('Module:Buildtime')

function StarCraft2Ability.run(frame)
	local ability = Ability(frame)
	ability.getCategories = StarCraft2Ability.getCategories
	ability.getDuration = StarCraft2Ability.getDuration
	ability.getHotkeys = StarCraft2Ability.getHotkeys
	ability.getCostDisplay = StarCraft2Ability.getCostDisplay
	ability.addCustomCells = StarCraft2Ability.addCustomCells

	return ability:createInfobox(frame)
end

function StarCraft2Ability:addCustomCells(infobox, args)

	local duration2Description, duration2Display = StarCraft2Ability:getDuration2(infobox, args)

	infobox:cell(duration2Description, duration2Display)
	infobox:cell('Researched from', StarCraft2Ability:getResearchFrom(infobox, args))
	infobox:cell('Research Hotkey', StarCraft2Ability:getResearchHotkey(infobox, args))

	return infobox
end

function StarCraft2Ability:getResearchFrom(infobox, args)
	local from = args.from
	if String.isEmpty(args.from) then
		from = 'No research needed'
	elseif not String.isEmpty(args.from2) then
		from = from .. ', ' .. args.from2
	end

	return from
end

function StarCraft2Ability:getResearchHotkey(infobox, args)
	local display
	if not String.isEmpty(args.from) then
		display = Hotkeys.hotkey(args.rhotkey)
	end

	return display
end

function StarCraft2Ability:getCategories(infobox, args)
	local categories = { 'Abilities' }
	local race = CleanRace[args.race or '']
	if race then
		table.insert(categories, race .. ' Abilities')
	end

	return categories
end

function StarCraft2Ability:getDuration2(infobox, args)
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

function StarCraft2Ability:getDuration(infobox, args)
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

function StarCraft2Ability:getHotkeys(infobox, args)
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

function StarCraft2Ability:getCostDisplay(infobox, args)

	local race = string.lower(args.race)

	local minerals = tonumber(args.min or 0) or 0
	minerals = _MINERALS .. '&nbsp;' .. minerals

	local gas = tonumber(args.gas or 0) or 0
	gas = (_GAS[race or ''] or _GAS['default']) .. '&nbsp;' .. gas

	local buildtime = tonumber(args.buildtime or 0) or 0
	if buildtime ~= 0 then
		buildtime = '&nbsp;' .. (_TIME[race or ''] or _TIME['default']) .. '&nbsp;' .. buildtime
	else
		buildtime = ''
	end

	local supply = args.supply or args.control or args.psy or 0
	supply = tonumber(supply) or 0
	if supply == 0 then
		supply = ''
	else
		supply = '&nbsp;' .. (_SUPPLY[race or ''] or _SUPPLY['default']) .. '&nbsp;' .. supply
	end

	return minerals .. '&nbsp;' .. gas .. buildtime .. supply
end

return StarCraft2Ability
