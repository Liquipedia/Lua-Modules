---
-- @Liquipedia
-- wiki=rocketleague
-- page=Module:Infobox/Company/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Company = require('Module:Infobox/Company')
local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')

local CustomCompany = Class.new()

local CustomInjector = Class.new(Injector)

local _args

function CustomInjector:parse(id, widgets)
	if id == 'custom' then
		table.insert(widgets, Cell({
			name = 'Epic Creator Code',
			content = {_args.creatorcode}
		}))
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
