---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Show/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Show = Lua.import('Module:Infobox/Show', {requireDevIfEnabled = true})
local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})

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
