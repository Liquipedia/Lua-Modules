---
-- @Liquipedia
-- page=Module:Infobox/Show/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Show = Lua.import('Module:Infobox/Show')

---@class CustomShowInfobox: ShowInfobox
local CustomShow = Class.new(Show)

---@param frame Frame
---@return Html
function CustomShow.run(frame)
	local customShow = CustomShow(frame)
	return customShow:createInfobox()
end

return CustomShow
