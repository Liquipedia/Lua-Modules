local Company = require('Module:Infobox/Company')

local RocketLeagueCompany = {}

function RocketLeagueCompany.run(frame)
    Company.addCustomCells = RocketLeagueCompany.addCustomCells
    return Company:createInfobox(frame)
end

function RocketLeagueCompany.addCustomCells(company, infobox, args)
    infobox:cell('Epic Creator Code', args.creatorcode)
    return infobox
end

return RocketLeagueCompany
