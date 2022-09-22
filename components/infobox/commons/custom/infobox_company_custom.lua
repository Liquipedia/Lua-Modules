---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Company/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Company = Lua.import('Module:Infobox/Company', {requireDevIfEnabled = true})

local CustomCompany = {}

function CustomCompany.run(frame)
	local company = Company(frame)
	return company:createInfobox(frame)
end

return CustomCompany
