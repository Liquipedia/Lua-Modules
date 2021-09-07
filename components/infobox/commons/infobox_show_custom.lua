---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Show/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Show = require('Module:Infobox/Show')
local Injector = require('Module:Infobox/Widget/Injector')

local CustomShow = Class.new()


local CustomInjector = Class.new(Injector)

function CustomShow.run(frame)
	local customShow = Show(frame)
	customShow.createWidgetInjector = CustomShow.createWidgetInjector
	return customShow:createInfobox(frame)
end

function CustomShow:createWidgetInjector()
	return CustomInjector()
end

return CustomShow
