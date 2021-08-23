---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Company/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Company = require('Module:Infobox/Company')

local CustomCompany = {}

function CustomCompany.run(frame)
    local company = Company(frame)
    company.addCustomCells = CustomCompany.addCustomCells
    return company:createInfobox(frame)
end

return CustomCompany
