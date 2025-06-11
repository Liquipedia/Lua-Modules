---
-- @Liquipedia
-- page=Module:Infobox/Strategy/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Strategy = Lua.import('Module:Infobox/Strategy')

---@class CustomStrategyInfobox: StrategyInfobox
local CustomStrategy = Class.new(Strategy)

---@param frame Frame
---@return Html
function CustomStrategy.run(frame)
	local customStrategy = CustomStrategy(frame)
	return customStrategy:createInfobox()
end

return CustomStrategy
