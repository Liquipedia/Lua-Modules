---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Show/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Show = require('Module:Infobox/Show')
local Namespace = require('Module:Namespace')
local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')

local CustomShow = Class.new()

local _show

local CustomInjector = Class.new(Injector)

function CustomShow.run(frame)
    local customShow = Show(frame)
	_show = customShow
	customShow.createWidgetInjector = CustomShow.createWidgetInjector
    return customShow:createInfobox(frame)
end

function CustomShow:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:addCustomCells(widgets)
	return widgets
end

return CustomShow
