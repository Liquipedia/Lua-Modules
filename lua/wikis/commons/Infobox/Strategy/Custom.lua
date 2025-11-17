---
-- @Liquipedia
-- page=Module:Infobox/Strategy/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

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
