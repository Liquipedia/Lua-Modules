local League = require('Module:VoganRL/Infobox/League')
local Cell = require('Module:Infobox/Cell')

local RLLeague = {}

function RLLeague.run(frame)
    League.addCustomCells = RLLeague.addCustomCells
    League.createTier = RLLeague.createTier
    League.createPrizepool = RLLeague.createPrizepool
    return League:createInfobox(frame)
end

function RLLeague.addCustomCells(company, infobox, args)
    return infobox
end

function RLLeague:createTier(args)
	return Cell	:new('Tier')
				:options({})
				:content('Hello')
end

function RLLeague:createPrizepool(args)
	return Cell	:new('Prize pool')
				:options({})
				:content('0')
end

return RLLeague
