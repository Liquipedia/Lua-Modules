local Company = require('Module:Infobox/Company')

local CustomCompany = {}

function CustomCompany.run(frame)
    local company = Company(frame)
    Company.addCustomCells = CustomCompany.addCustomCells
    return company:createInfobox(frame)
end

function CustomCompany.addCustomCells(company, infobox, args)
    return infobox
end

return CustomCompany
