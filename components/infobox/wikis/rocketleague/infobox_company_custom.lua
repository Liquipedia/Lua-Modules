---
-- @Liquipedia
-- wiki=rocketleague
-- page=Module:Infobox/Company/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Company = Lua.import('Module:Infobox/League', {requireDevIfEnabled = true})
local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local CustomCompany = Class.new()

local CustomInjector = Class.new(Injector)

local _args

function CustomInjector:addCustomCells(widgets)
	table.insert(widgets, Cell({
		name = 'Epic Creator Code',
		content = {_args.creatorcode}
	}))
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
