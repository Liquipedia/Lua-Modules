---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Website/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Website = Lua.import('Module:Infobox/Website', {requireDevIfEnabled = true})

local CustomWebsite = Class.new()

function CustomWebsite.run(frame)
	local website = Website(frame)
	return website:createInfobox(frame)
end

return CustomWebsite
