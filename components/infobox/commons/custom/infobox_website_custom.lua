---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Website/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Website = require('Module:Infobox/Website')
local Class = require('Module:Class')

local CustomWebsite = Class.new()

function CustomWebsite.run(frame)
	local website = Website(frame)
	return website:createInfobox(frame)
end

return CustomWebsite
