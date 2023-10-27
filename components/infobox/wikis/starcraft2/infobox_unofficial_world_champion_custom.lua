---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:Infobox/UnofficialWorldChampion/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local UnofficialWorldChampion = Lua.import('Module:Infobox/UnofficialWorldChampion', {requireDevIfEnabled = true})
local RaceBreakdown = Lua.import('Module:Infobox/Extension/RaceBreakdown', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Breakdown = Widgets.Breakdown
local Builder = Widgets.Builder
local Cell = Widgets.Cell
local Title = Widgets.Title

local CustomUnofficialWorldChampion = Class.new()

local CustomInjector = Class.new(Injector)

local _args

---@param frame Frame
---@return Html
function CustomUnofficialWorldChampion.run(frame)
	local unofficialWorldChampion = UnofficialWorldChampion(frame)
	_args = unofficialWorldChampion.args
	unofficialWorldChampion.createWidgetInjector = CustomUnofficialWorldChampion.createWidgetInjector
	return unofficialWorldChampion:createInfobox()
end

---@param widgets Widget[]
---@return Widget[]
function CustomInjector:addCustomCells(widgets)
	return {
		Builder{
			builder = function()
				local raceBreakdown = RaceBreakdown.run(_args)
				if raceBreakdown then
					return {
						Title{name = 'Racial Distribution of Champions'},
						Breakdown{content = raceBreakdown.display, classes = { 'infobox-center' }}
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

---@param id string
---@param widgets Widget[]
---@return Widget[]
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

---@return WidgetInjector
function CustomUnofficialWorldChampion:createWidgetInjector()
	return CustomInjector()
end

---@param base string
---@return Widget[]
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

return CustomUnofficialWorldChampion
