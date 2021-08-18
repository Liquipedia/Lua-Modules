local League = require('Module:Infobox/League')
local Cell = require('Module:Infobox/Cell')
local String = require('Module:String')

local RLLeague = {}

function RLLeague.run(frame)
    League.addCustomCells = RLLeague.addCustomCells
    League.createTier = RLLeague.createTier
    League.createPrizepool = RLLeague.createPrizepool
	League.addCustomContent = RLLeague.addCustomContent
    return League:createInfobox(frame)
end

function RLLeague:addCustomCells(league, infobox, args)
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

function RLLeague:addCustomContent(infobox, args)
	if String.isEmpty(args.map1) then
		return infobox
	end

	infobox:header('Maps', true)

	local maps = {RLLeague:_makeInternalLink(args.map1)}
	local index  = 2

	while not String.isEmpty(args['map' .. index]) do
		table.insert(maps, '&nbsp;• ' ..
			tostring(RLLeague:_createNoWrappingSpan(
				RLLeague:_makeInternalLink(args['map' .. index])
			))
		)
		index = index + 1
	end

	infobox	:centeredCell(unpack(maps))
			:header('Teams', true)
			:cell('Number of teams', args.team_number)

    return infobox
end

function RLLeague:_createNoWrappingSpan(content)
	local span = mw.html.create('span')
	span:css('white-space', 'nowrap')
		:node(content)
	return span
end

function RLLeague:_makeInternalLink(content)
	return '[[' .. content .. ']]'
end

return RLLeague
