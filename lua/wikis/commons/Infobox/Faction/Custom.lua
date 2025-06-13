---
-- @Liquipedia
-- page=Module:Infobox/Faction/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

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
