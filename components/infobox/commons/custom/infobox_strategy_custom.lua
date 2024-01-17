---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Strategy/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Strategy = Lua.import('Module:Infobox/Strategy')

local CustomStrategy = Class.new()

---@param frame Frame
---@return Html
function CustomStrategy.run(frame)
	local customStrategy = Strategy(frame)
	return customStrategy:createInfobox()
end

return CustomStrategy
