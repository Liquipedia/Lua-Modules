local Company = require('Module:Infobox/Company')

local RocketLeagueCompany = {}

function RocketLeagueCompany.run(frame)
	local company = Company(frame)
    Company.addCustomCells = RocketLeagueCompany.addCustomCells
    return company:createInfobox(frame)
end

function RocketLeagueCompany.addCustomCells(company, infobox, args)
    infobox:cell('Epic Creator Code', args.creatorcode)
    return infobox
end

return RocketLeagueCompany
