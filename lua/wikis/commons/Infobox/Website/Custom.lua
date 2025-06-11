---
-- @Liquipedia
-- page=Module:Infobox/Website/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Website = Lua.import('Module:Infobox/Website')

---@class CustomWebsiteInfobox: WebsiteInfobox
local CustomWebsite = Class.new(Website)

---@param frame Frame
---@return Html
function CustomWebsite.run(frame)
	local website = CustomWebsite(frame)
	return website:createInfobox()
end

return CustomWebsite
