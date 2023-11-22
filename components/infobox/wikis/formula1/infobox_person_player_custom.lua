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
local TeamHistoryAuto = require('Module:TeamHistoryAuto')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Player = Lua.import('Module:Infobox/Person', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center

local CustomPlayer = Class.new()

local CustomInjector = Class.new(Injector)

local _args

---@param frame Frame
---@return Html
function CustomPlayer.run(frame)
	local player = Player(frame)

	player.adjustLPDB = CustomPlayer.adjustLPDB
	player.createWidgetInjector = CustomPlayer.createWidgetInjector

	_args = player.args
	_args.autoTeam = true

	return player:createInfobox(frame)
end

---@param id string
---@param widgets Widget[]
---@rreturn Widget[]
function CustomInjector:parse(id, widgets)
	if id == 'history' then
		return {
			Title{name = 'History'},
			Center{content = {TeamHistoryAuto._results{
				convertrole = true,
				addlpdbdata = true
			}}},
		}

	elseif id == 'role' then
		return {
			Cell{name = 'Role(s)', content = {Role.run({role = _args.role}).display, Role.run({role = _args.role2}).display}}
		}
	end
	return widgets
end

---@param widgets Widget[]
---@return Widget[]
function CustomInjector:addCustomCells(widgets)
	table.insert(widgets, Cell{name = 'Abbreviations', content = {_args.abbreviations}})
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
		{key = 'salary', name = 'Reported Salary'},
		{key = 'contract', name = 'Current Contract'},
	}
	if Array.all(statisticsCells, function(cellData) return not _args[cellData.key] end) then
		return widgets
	end

	return Array.extendWith(widgets,
		{Title{name = 'Driver Statistics'}},
		Array.map(statisticsCells, function(cellData)
			return Cell{name = cellData.name, content = {_args[cellData.key]}}
		end)
	)
end

---@return WidgetInjector
function CustomPlayer:createWidgetInjector()
	return CustomInjector()
end

---@param lpdbData table
---@param args table
---@return table
function CustomPlayer:adjustLPDB(lpdbData, args)
	lpdbData.extradata.role = Role.run{role = args.role}.role
	lpdbData.extradata.role2 = Role.run{role = args.role2}.role
	return lpdbData
end

return CustomPlayer
