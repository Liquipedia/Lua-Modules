---
-- @Liquipedia
-- page=Module:Infobox/Website/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Website = Lua.import('Module:Infobox/Website')

---@class CustomWebsiteInfobox: WebsiteInfobox
---@operator call(Frame): CustomWebsiteInfobox
local CustomWebsite = Class.new(Website)

---@param frame Frame
---@return VNode
function CustomWebsite.run(frame)
	local website = CustomWebsite(frame)
	return website:createInfobox()
end

return CustomWebsite
