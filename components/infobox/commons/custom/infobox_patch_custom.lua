---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Patch/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Patch = Lua.import('Module:Infobox/Patch')

local CustomPatch = Class.new()

---@param frame Frame
---@return Html
function CustomPatch.run(frame)
	local customPatch = Patch(frame)
	return customPatch:createInfobox()
end

return CustomPatch
