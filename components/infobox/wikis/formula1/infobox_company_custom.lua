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

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Company = Lua.import('Module:Infobox/Company', {requireDevIfEnabled = true})

local CustomCompany = Class.new()

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title

local CustomInjector = Class.new(Injector)

local _args

---@param frame Frame
---@return Html
function CustomCompany.run(frame)
	local company = Company(frame)
	company.createWidgetInjector = CustomCompany.createWidgetInjector
	_args = company.args
	return company:createInfobox(frame)
end

---@return WidgetInjector
function CustomCompany:createWidgetInjector()
	return CustomInjector()
end

---@param widgets Widget[]
---@return Widget[]
function CustomInjector:addCustomCells(widgets)
	local staffInfoCells = {
		{key = 'president', name = 'President'},
		{key = 'deputypresidentmobility', name = 'Deputy President of Mobility'},
		{key = 'deputypresidentsport', name = 'Deputy President of Sport'},
		{key = 'senatepresident', name = 'Senate President'},
		{key = 'chiefexecutiveofficer', name = 'Chief Executive Officer'},
		{key = 'singleseaterdirector', name = 'Single-Seater Director'},
		{key = 'circuitsportdirector', name = 'Circuit Sport Director'},
		{key = 'roadsportdirector', name = 'Road Sport Director'},
	}
	if not Array.any(staffInfoCells, function(cellData) return _args[cellData.key] end) then
		return widgets
	end

	return Array.extendWith(widgets,
		{Title{name = 'Staff Information'}},
		Array.map(staffInfoCells, function(cellData)
			return Cell{name = cellData.name, content = {_args[cellData.key]}}
		end)
	)
end

return CustomCompany
