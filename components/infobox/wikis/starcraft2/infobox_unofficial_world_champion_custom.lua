---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:Infobox/UnofficialWorldChampion/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local RaceIcon = require('Module:RaceIcon')
local String = require('Module:StringUtils')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local UnofficialWorldChampion = Lua.import('Module:Infobox/UnofficialWorldChampion', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Breakdown = Widgets.Breakdown
local Builder = Widgets.Builder
local Cell = Widgets.Cell
local Title = Widgets.Title

local CustomUnofficialWorldChampion = Class.new()

local CustomInjector = Class.new(Injector)

local _args

function CustomUnofficialWorldChampion.run(frame)
	local unofficialWorldChampion = UnofficialWorldChampion(frame)
	_args = unofficialWorldChampion.args
	unofficialWorldChampion.createWidgetInjector = CustomUnofficialWorldChampion.createWidgetInjector
	return unofficialWorldChampion:createInfobox(frame)
end

function CustomInjector:addCustomCells(widgets)
	return {
		Builder{
			builder = function()
				local raceBreakDown = CustomUnofficialWorldChampion.raceBreakDown()
				if raceBreakDown.playernumber then
					return {
						Title{name = 'Racial Distribution of Champions'},
						Breakdown{content = raceBreakDown.display, classes = { 'infobox-center' }}
					}
				end
			end
		},
		Builder{
			builder = function()
				local countryCells = {}
				if not String.isEmpty(_args['countries with multiple champions 1']) then
					countryCells = CustomUnofficialWorldChampion.getCellsFromBasedArgs(
						'countries with multiple champions'
					)
					table.insert(countryCells, 1, Title{name = 'Countries with Multiple Champions'})
				end
				return countryCells
			end
		},
		Builder{
			builder = function()
				local countryCells = {}
				if not String.isEmpty(_args['teams with multiple champions 1']) then
					countryCells = CustomUnofficialWorldChampion.getCellsFromBasedArgs(
						'teams with multiple champions'
					)
					table.insert(countryCells, 1, Title{name = 'Teams with Multiple Champions'})
				end
				return countryCells
			end
		},
	}
end

function CustomInjector:parse(id, widgets)
	if id == 'defences' then
		local index = 1
		local defencesCells = {}
		while not String.isEmpty(_args['most defences against ' .. index]) do
			table.insert(defencesCells, Breakdown{ content = {
						_args['most defences against ' .. index],
						_args['most defences against ' .. (index + 1)],
					}
				}
			)
			index = index + 2
		end
		return defencesCells
	end
	return widgets
end

function CustomUnofficialWorldChampion:createWidgetInjector()
	return CustomInjector()
end

function CustomUnofficialWorldChampion.getCellsFromBasedArgs(base)
	local foundCells = {}
	local index = 1
	while not String.isEmpty(_args[base .. ' ' .. index]) do
		table.insert(foundCells, Cell{
				name = (_args[base .. ' ' .. index .. ' no'] or '?')
					.. ' champions',
				content = { _args[base .. ' ' .. index] },
			}
		)
		index = index + 1
	end
	return foundCells
end

function CustomUnofficialWorldChampion.raceBreakDown()
	local playerBreakDown = {}
	local playernumber = tonumber(_args.player_number or 0) or 0
	local zergnumber = tonumber(_args.zerg_number or 0) or 0
	local terrannumbner = tonumber(_args.terran_number or 0) or 0
	local protossnumber = tonumber(_args.protoss_number or 0) or 0
	local randomnumber = tonumber(_args.random_number or 0) or 0
	if playernumber == 0 then
		playernumber = zergnumber + terrannumbner + protossnumber + randomnumber
	end

	if playernumber > 0 then
		playerBreakDown.playernumber = playernumber
		if zergnumber + terrannumbner + protossnumber + randomnumber > 0 then
			playerBreakDown.display = {}
			if protossnumber > 0 then
				playerBreakDown.display[#playerBreakDown.display + 1]
					= RaceIcon.getSmallIcon({'p'}) .. ' ' .. protossnumber
			end
			if terrannumbner > 0 then
				playerBreakDown.display[#playerBreakDown.display + 1]
					= RaceIcon.getSmallIcon({'t'}) .. ' ' .. terrannumbner
			end
			if zergnumber > 0 then
				playerBreakDown.display[#playerBreakDown.display + 1]
					= RaceIcon.getSmallIcon({'z'}) .. ' ' .. zergnumber
			end
			if randomnumber > 0 then
				playerBreakDown.display[#playerBreakDown.display + 1]
					= RaceIcon.getSmallIcon({'r'}) .. ' ' .. randomnumber
			end
		end
	end
	return playerBreakDown
end

return CustomUnofficialWorldChampion
