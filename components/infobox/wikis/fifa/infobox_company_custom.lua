---
-- @Liquipedia
-- wiki=fifa
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
		table.insert(widgets, Cell{name = 'Focus', content = {_args.focus}})
	end

	return widgets
end

function CustomCompany:createWidgetInjector()
	return CustomInjector()
end

return CustomCompany
