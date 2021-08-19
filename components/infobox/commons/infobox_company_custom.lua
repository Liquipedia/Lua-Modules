local Company = require('Module:Infobox/Company')

local CustomCompany = {}

function CustomCompany.run(frame)
    Company.addCustomCells = CustomCompany.addCustomCells
    return Company.run(frame)
end

function CustomCompany.addCustomCells(company, infobox, args)
    return infobox
end

return CustomCompany
