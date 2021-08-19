local League = require('Module:Infobox/League')
local Cell = require('Module:Infobox/Cell')
local String = require('Module:String')
local Template = require('Module:Template')
local Variables = require('Module:Variables')

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
	local cell = Cell:new('Prize pool'):options({})
	if String.isEmpty(args.prizepool) and
		String.isEmpty(args.prizepoolusd) then
			return cell:content()
	end

	local content
	local prizepool = args.prizepool
	local prizepoolInUsd = args.prizepoolusd
	local localCurrency = args.localcurrency

	if String.isEmpty(prizepool) then
		content = '$' .. prizepoolInUsd .. ' ' .. Template.safeExpand(mw.getCurrentFrame(), 'Abbr/USD')
	else
		if not String.isEmpty(localCurrency) then
			content = Template.safeExpand(
				mw.getCurrentFrame(),
				'Local currency',
				{localCurrency:lower(), prizepool = prizepool}
			)
		else
			content = prizepool
		end

		if not String.isEmpty(prizepoolInUsd) then
			content = content .. '<br>(≃ $' .. prizepoolInUsd .. ' ' ..
				Template.safeExpand(mw.getCurrentFrame(), 'Abbr/USD') .. ')'
		end
	end

	Variables.varDefine('tournament_prizepoolusd', prizepoolInUsd)

	return cell:content(content)
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
