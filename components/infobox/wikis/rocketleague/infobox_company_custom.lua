---
-- @Liquipedia
-- wiki=rocketleague
-- page=Module:Infobox/Company/Custom
--

local Company = require('Module:Infobox/Company')

local RocketLeagueCompany = {}

function RocketLeagueCompany.run(frame)
    local company = Company(frame)
    company.addCustomCells = RocketLeagueCompany.addCustomCells
    return company:createInfobox(frame)
end

function RocketLeagueCompany:addCustomCells(infobox, args)
    infobox:cell('Epic Creator Code', args.creatorcode)
    return infobox
end

return RocketLeagueCompany
