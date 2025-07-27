---
-- @Liquipedia
-- page=Module:Infobox/Faction/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local FactionInfobox = Lua.import('Module:Infobox/Faction')

---@class CustomFactionInfobox: FactionInfobox
local CustomFactionInfobox = Class.new(FactionInfobox)

---@param frame Frame
---@return string
function CustomFactionInfobox.run(frame)
	local infobox = CustomFactionInfobox(frame)
	return infobox:createInfobox()
end

return CustomFactionInfobox
