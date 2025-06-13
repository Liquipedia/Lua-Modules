---
-- @Liquipedia
-- page=Module:Infobox/UnofficialWorldChampion/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local Injector = Lua.import('Module:Widget/Injector')
local UnofficialWorldChampion = Lua.import('Module:Infobox/UnofficialWorldChampion')
local RaceBreakdown = Lua.import('Module:Infobox/Extension/RaceBreakdown')

local Widgets = require('Module:Widget/All')
local Breakdown = Widgets.Breakdown
local Cell = Widgets.Cell
local Title = Widgets.Title

---@class Starcraft2UnofficialWorldChampionInfobox: UnofficialWorldChampionInfobox
local CustomUnofficialWorldChampion = Class.new(UnofficialWorldChampion)

local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomUnofficialWorldChampion.run(frame)
	local unofficialWorldChampion = CustomUnofficialWorldChampion(frame)
	unofficialWorldChampion:setWidgetInjector(CustomInjector(unofficialWorldChampion))
	return unofficialWorldChampion:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'defences' then
		local index = 1
		local defencesCells = {}
		while not String.isEmpty(args['most defences against ' .. index]) do
			table.insert(defencesCells, Breakdown{ content = {
				args['most defences against ' .. index],
				args['most defences against ' .. (index + 1)],
			}})
			index = index + 2
		end
		return defencesCells
	elseif id == 'custom' then
		local raceBreakdown = RaceBreakdown.run(args)


		Array.extendWith(widgets,
			{
				raceBreakdown and Title{children = 'Racial Distribution of Champions'} or nil,
				raceBreakdown and Breakdown{children = raceBreakdown.display, classes = { 'infobox-center' }} or nil,
			},
			self.caller:_buildCellsFromBase('countries with multiple champions', 'Countries with Multiple Champions'),
			self.caller:_buildCellsFromBase('teams with multiple champions', 'Teams with Multiple Champions')
		)
	end
	return widgets
end

---@param base string
---@param title string?
---@return Widget[]
function CustomUnofficialWorldChampion:_buildCellsFromBase(base, title)
	local args = self.args
	if String.isEmpty(args[base .. ' 1']) then
		return {}
	end

	local widgets = {Title{children = title}}
	for key, value in Table.iter.pairsByPrefix(args, base .. ' ') do
		table.insert(widgets, Cell{name = (args[key .. ' no'] or '?') .. ' champions', content = {value}})
	end

	return widgets
end

return CustomUnofficialWorldChampion
