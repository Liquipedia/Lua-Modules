---
-- @Liquipedia
-- wiki=rainbowsix
-- page=Module:PrizePool/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local PrizePool = Lua.import('Module:PrizePool', {requireDevIfEnabled = true})
 -- TODO: Move some Widget modules away from Infobox?
local WidgetInjector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})

local CustomPrizePool = {}
local CustomWidgetInjector = Class.new(WidgetInjector)

-- Template entry point
function CustomPrizePool.run(frame)
	local args = Arguments.getArgs(frame)
	local prizePool = PrizePool(args)
	prizePool:readInput()

	prizePool:setWidgetInjector(CustomWidgetInjector())

	return prizePool:create()
end

function CustomWidgetInjector:parse(id, widgets)
	-- TODO: do something
	return widgets
end

return CustomPrizePool
