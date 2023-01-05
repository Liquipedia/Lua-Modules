---
-- @Liquipedia
-- wiki=counterstrike
-- page=Module:Infobox/Company/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Company = Lua.import('Module:Infobox/Company', {requireDevIfEnabled = true})
local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local CustomCompany = Class.new()

local CustomInjector = Class.new(Injector)

local _args

function CustomCompany.run(frame)
	local company = Company(frame)
	_args = company.args

	company.createWidgetInjector = CustomCompany.createWidgetInjector

	return company:createInfobox(frame)
end

function CustomInjector:parse(id, widgets)
	if id == 'parent' then
		table.insert(widgets, Cell{name = 'Sister Company', content = {_args.sister}})
		table.insert(widgets, Cell{name = 'Subsidiaries', content = {_args.subsidiaries}})
		table.insert(widgets, Cell{name = 'Industry', content = {_args.industry}})
	elseif id == 'dates' then
		table.insert(widgets, Cell{name = 'Fate', content = {_args.fate}})
	elseif id == 'employees' then
		table.insert(widgets, Cell{name = 'People', content = {_args.people}})
	end

	return widgets
end

function CustomCompany:createWidgetInjector()
	return CustomInjector()
end

return CustomCompany
