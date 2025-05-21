---
-- @Liquipedia
-- wiki=formula1
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Role = require('Module:Role')

local Injector = Lua.import('Module:Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title

---@class Formula1InfoboxPlayer: Person
local CustomPlayer = Class.new(Player)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)
	player:setWidgetInjector(CustomInjector(player))

	return player:createInfobox(frame)
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'custom' then
		self.caller:addCustomCells(widgets)

	elseif id == 'names' then
		table.insert(widgets, Cell{name = 'Abbreviations', content = {args.abbreviations}})
	elseif id == 'role' then
		return {
			Cell{name = 'Role(s)', content = {
				Role.run{role = args.role, useDefault = true}.display,
				Role.run{role = args.role2}.display}
			}
		}
	end
	return widgets
end

---@param widgets Widget[]
---@return Widget[]
function CustomPlayer:addCustomCells(widgets)
	local args = self.args

	table.insert(widgets, Cell{name = 'Reported Salary', content = {args.salary}})
	table.insert(widgets, Cell{name = 'End of Contract', content = {args.contract}})
	local statisticsCells = {
		{key = 'races', name = 'Races'},
		{key = 'wins', name = 'Wins'},
		{key = 'podiums', name = 'Podiums'},
		{key = 'poles', name = 'Pole positions'},
		{key = 'fastestlaps', name = 'Fastest Laps'},
		{key = 'points', name = 'Career Points'},
		{key = 'firstrace', name = 'First race'},
		{key = 'lastrace', name = 'Last race'},
		{key = 'firstwin', name = 'First win'},
		{key = 'lastwin', name = 'Last win'},
	}
	if Array.all(statisticsCells, function(cellData) return not args[cellData.key] end) then
		return widgets
	end

	return Array.extendWith(widgets,
		{Title{children = 'F1 Driver Statistics'}},
		Array.map(statisticsCells, function(cellData)
			return Cell{name = cellData.name, content = {args[cellData.key]}}
		end)
	)
end

---@param lpdbData table
---@param args table
---@param personType string
---@return table
function CustomPlayer:adjustLPDB(lpdbData, args, personType)
	lpdbData.extradata.role = Role.run{role = args.role, useDefault = true}.role
	lpdbData.extradata.role2 = Role.run{role = args.role2}.role
	return lpdbData
end

---@param args table
---@return {store: string, category: string}
function CustomPlayer:getPersonType(args)
	local role = Role.run{role = args.role, useDefault = true}

	return {store = role.personType, category = role.category}
end

return CustomPlayer
