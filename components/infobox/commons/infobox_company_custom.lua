local Company = require('Module:Infobox/Company')

local CustomCompany = {}

function CustomCompany.run(frame)
    local company = Company(frame)
    Company.addCustomCells = CustomCompany.addCustomCells
    return company:createInfobox(frame)
end

return CustomCompany
