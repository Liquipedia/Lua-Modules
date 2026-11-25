---
-- @Liquipedia
-- page=Module:Infobox/Show/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Show = Lua.import('Module:Infobox/Show')

---@class CustomShowInfobox: ShowInfobox
---@operator call(Frame): CustomShowInfobox
local CustomShow = Class.new(Show)

---@param frame Frame
---@return VNode
function CustomShow.run(frame)
	local customShow = CustomShow(frame)
	return customShow:createInfobox()
end

return CustomShow
