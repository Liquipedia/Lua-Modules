---
-- @Liquipedia
-- wiki=formula1
-- page=Module:Infobox/Company/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Template = require('Module:Template')
local Variables = require('Module:Variables')
local Table = require('Module:Table')
local Company = require('Module:Infobox/Company')
local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')

local CustomCompany = Class.new()

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Header = Widgets.Header
local Title = Widgets.Title
local Center = Widgets.Center
local Customizable = Widgets.Customizable
local Builder = Widgets.Builder
local Chronology = Widgets.Chronology

local CustomTeam = Class.new()
local CustomInjector = Class.new(Injector)
local Chronology = Widgets.Chronology

local _args 
local _team


function CustomInjector:addCustomCells()
	local widgets = {}
	local statisticsCells = {
		president = {order = 1, name = 'President'},
		deputypresidentmobility = {order = 2, name = 'Deputy President of Mobility'},
		deputypresidentsport = {order = 3, name = 'Deputy President of Sport'},
		senatepresident = {order = 4, name = 'Senate President'},
		chiefexecutiveofficer = {order = 5, name = 'Chief Executive Officer'},
		singleseaterdirector = {order = 6, name = 'Single-Seater Director'},
		circuitsportdirector = {order = 7, name = 'Circuit Sport Director'},
		roadsportdirector = {order = 8, name = 'Road Sport Director'},
	}
	if Table.any(_args, function(key) return statisticsCells[key] end) then
		table.insert(widgets, Title{name = 'Staff Information'})
		local statisticsCellsOrder = function(tbl, a, b) return tbl[a].order < tbl[b].order end
		for key, item in Table.iter.spairs(statisticsCells, statisticsCellsOrder) do
			table.insert(widgets, Cell{name = item.name, content = {_args[key]}})
		end
	end
	
	return widgets
end

function CustomCompany.run(frame)
	local company = Company(frame)
	company.createWidgetInjector = CustomCompany.createWidgetInjector
	_args = company.args
	return company:createInfobox(frame)
end

function CustomCompany:createWidgetInjector()
	return CustomInjector()
end

return CustomCompany
