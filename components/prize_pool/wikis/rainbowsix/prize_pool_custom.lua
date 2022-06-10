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
local WidgetInjector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true}) -- TODO: Move Widget modules away from Infobox/?
-- local LpdbInjector = Lua.import('Module...', {requireDevIfEnabled = true})

local CustomPrizePool = Class.new(function(self, ...) self:init(...) end)

local CustomWidgetInjector = Class.new(WidgetInjector)
-- local CustomLpdbInjector = Class.new(LpdbInjector)

-- Template entry point
function CustomPrizePool.run(frame)
	return CustomPrizePool(frame)
end

function CustomPrizePool:init(args)
	self.args = Arguments.getArgs(args)

	local prizePool = PrizePool(self.args)
	prizePool:setWidgetInjector(CustomWidgetInjector())
	--prizePool:setLpdbInjector(...)

	mw.logObject(self)
	mw.logObject(prizePool)
end

function CustomWidgetInjector:parse(id, widgets)
	-- TODO: do something
	return widgets
end

return CustomPrizePool
