local League = require('Module:Infobox/League')
local Cell = require('Module:Infobox/Cell')
local String = require('Module:String')
local Template = require('Module:Template')
local Variables = require('Module:Variables')

local RLLeague = {}

function RLLeague.run(frame)
	local league = League(frame)
	League.addCustomCells = RLLeague.addCustomCells
	League.createTier = RLLeague.createTier
	League.createPrizepool = RLLeague.createPrizepool
	League.addCustomContent = RLLeague.addCustomContent

	return league:createInfobox(frame)
end

function RLLeague:addCustomCells(league, infobox, args)
	infobox:cell('Mode', args.mode)
	infobox:cell('Misc Mode:', args.miscmode)
	return infobox
end

function RLLeague:createTier(args)
	local cell =  Cell:new('Liquipedia Tier'):options({})

	local content = ''

	local tier = args.liquipediatier

	if String.isEmpty(tier) then
		return cell:content()
	end

	local tierDisplay = Template.safeExpand(mw.getCurrentFrame(), 'TierDisplay/' .. tier)
	local tier2 = args.liquipediatier2
	local type = args.liquipediatiertype
	local type2 = args.liquipediatiertype2

	if not String.isEmpty(type) then
		local typeDisplay = Template.safeExpand(mw.getCurrentFrame(), 'TierDisplay/' .. type)
		content = content .. '[[' .. typeDisplay .. ' Tournaments|' .. type .. ']]'

		if not String.isEmpty(type2) then
			content = content .. ' ' .. type2
		end

		content = content .. ' ([[' .. tierDisplay .. ' Tournaments|' .. tierDisplay .. ']])'
	else
		content = content .. '[[' .. tierDisplay .. ' Tournaments|' .. tierDisplay .. ']]'

		if not String.isEmpty(tier2) then
			local tier2Display = Template.safeExpand(mw.getCurrentFrame(), 'TierDisplay/' .. tier2)
			content = content .. ' ([[' .. tier2Display .. ' Tournaments|' .. tier2Display .. ']])'
		end
	end

	return cell:content(content)
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
