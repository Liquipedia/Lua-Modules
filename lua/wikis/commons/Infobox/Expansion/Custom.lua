---
-- @Liquipedia
-- page=Module:Infobox/Expansion/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Expansion = Lua.import('Module:Infobox/Expansion')

---@class CustomExpansionInfobox: ExpansionInfobox
local CustomExpansion = Class.new(Expansion)

---@param frame Frame
---@return Html
function CustomExpansion.run(frame)
	local customExpansion = CustomExpansion(frame)
	return customExpansion:createInfobox()
end

return CustomExpansion
