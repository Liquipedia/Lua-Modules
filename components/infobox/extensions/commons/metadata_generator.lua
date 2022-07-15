---
-- @Liquipedia
-- wiki=commons
-- page=Module:MetadataGenerator
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local String = require('Module:StringUtils')
local Localisation = require('Module:Localisation')
local Template = require('Module:Template')
local Games = require('Module:Games')
local Variables = require('Module:Variables')
local StringUtils = require('Module:StringUtils')
local Class = require('Module:Class')
local AnOrA = require('Module:A or an')

local MetadataGenerator = {}

function MetadataGenerator.tournament(args)
	if String.isEmpty(args.publisherdescription) then
		error('You must provide the publisherdescription param!')
	end

	if String.isEmpty(args.primarygame) then
		error('You must provide the primarygame param!')
	end

	local output
	local frame = mw.getCurrentFrame()

	local name = not String.isEmpty(args.name) and (args.name):gsub('&nbsp;', ' ') or mw.title.getCurrentTitle()

	local type = args.type
	local locality = Localisation.getLocalisation({displayNoError = true}, args.country)

	local organizers = {
		args['organizer-name'] or args.organizer,
		args['organizer2-name'] or args.organizer2,
		args['organizer3-name'] or args.organizer3,
	}

	local tier = args.liquipediatier and Template.safeExpand(frame, 'TierDisplay', {args.liquipediatier}) or nil

	if tier then
		tier = (tonumber(
			Template.safeExpand(frame, 'TierDisplay/number', {args.liquipediatier})
		) or 0) > 4 and tier:lower() or tier
	else
		tier = 'Unknown Tier'
	end

	local tierType = (tier == 'qualifier' or tier == 'showmatch') and tier or 'tournament'
	local publisher = Variables.varDefault(args.publisherdescription, '')
	local date, tense = MetadataGenerator.getDate(args.edate or args.date, args.sdate)

	local teams = args.team_number
	local players = args.player_number

	local game = (not String.isEmpty(args.game) and args.game ~= args.primarygame) and Games.abbr[args.game]

	local prizepoolusd = args.prizepoolusd and ('$' .. args.prizepoolusd .. ' USD') or nil
	local prizepool = prizepoolusd or (
		args.prizepool and args.localcurrency and (
			Variables.varDefault('localcurrencysymbol', '') .. args.prizepool ..
			Variables.varDefault('localcurrencysymbolafter', '') .. ' ' ..
			Variables.varDefault('localcurrencycode', '')
		)
	)
	local charity = args.charity == 'true'
	local dateVerb = (tense == 'past' and 'took place ') or (tense == 'future' and 'will take place ') or 'takes place '
	local dateVerbPublisher =
		(tense == 'past' and ' which took place ') or
		(tense == 'future' and ' which will take place ') or
		' taking place '

	output = StringUtils.interpolate('${name} is ${a}${type}${locality}${game}${charity}${tierType}${organizer}', {
		name = name,
		a = AnOrA._main(type or locality or game or (charity and 'charity' or nil) or tierType) .. ' ',
		type = type and (type:lower() .. ' ') or '',
		locality = locality and (locality .. ' ') or '',
		game = game and (game .. ' ') or '',
		charity = charity and 'charity ' or '',
		tierType = tierType,
		organizer = organizers[1] and (' organized by ' .. organizers[1]) or ''
	})

	if organizers[2] then
		output = output .. (organizers[3] and ', ' or ' and ') ..
			organizers[2] .. (organizers[3] and (', and ' .. organizers[3]) or '') .. '. '
	else
		output = output .. '. '
	end

	output = output .. StringUtils.interpolate('This ${tier}${tierType} ', {
		tier = tierType ~= tier and (tier .. ' ') or '',
		tierType = tierType
	})
	if not String.isEmpty(publisher) then
		output = output .. StringUtils.interpolate('is a ${publisher}${tense}', {
			publisher = publisher,
			tense = ((date and dateVerbPublisher) or ((teams or players or prizepool) and ' featuring '))
		})
	elseif date then
		output = output .. dateVerb
	elseif teams or players or prizepool then
		output = output .. 'features '
	end

	if date then
		output = output .. date .. ((teams or players or prizepool) and ' featuring ' or '')
	end

	if teams or players then
		output = output .. ((teams and (teams .. ' teams')) or
			(players and (players .. ' players'))) ..
			(prizepool and ' ' or '')
	end
	if prizepool then
		output = output .. StringUtils.interpolate('${competing}a total ${charity}prize pool of ${prizepool}', {
			competing = (teams or players) and 'competing over ' or '',
			charity = charity and 'charity ' or '',
			prizepool = prizepool
		})
	end

	output = output .. '.'

	return output
end

function MetadataGenerator.getDate(date, sdate)
	if String.isEmpty(date) then
		return nil
	end

	local noStartDay, noEndDay, tense
	local startRaw = (sdate or date):gsub('%-[?X]+', '')
	local endRaw = date:gsub('%-[?X]+', '')
	local currentU = tonumber(os.date("!%s"))
	local startU = tonumber(mw.getContentLanguage():formatDate('U', startRaw))
	local endU = tonumber(mw.getContentLanguage():formatDate('U', endRaw))
	local startMD = startRaw:sub(6)
	local endMD = endRaw:sub(6)

	if tonumber(startMD) then
		noStartDay = true
	end

	if tonumber(endMD) then
		noEndDay = true
	end

	if currentU > endU then
		tense = 'past'
	elseif currentU < startU then
		tense = 'future'
	elseif startU < currentU and currentU < endU then
		tense = 'present'
	end

	if startU == endU then
		return os.date("!on %b " .. (noStartDay and "??" or "%d") .. " %Y", endU), tense
	elseif os.date("!%m, %Y", startU) == os.date("!%m %Y", endU) then
		return os.date("!from %b " .. (noStartDay and "??" or "%d"), startU) .. ' to ' ..
			os.date("!" .. (noEndDay and "??" or "%d") .. " %Y", endU), tense
	elseif os.date("!%Y", startU) == os.date("!%Y", endU) then
		return os.date("!from %b " .. (noStartDay and "??" or "%d"), startU) .. ' to ' ..
			os.date("!%b " .. (noEndDay and "??" or "%d") .. " %Y", endU), tense
	else
		return os.date("!from %b " .. (noStartDay and "??" or "%d") .. " %Y", startU) .. ' to ' ..
			os.date("!%b " .. (noEndDay and "??" or "%d") .. " %Y", endU), tense
	end
end

return Class.export(MetadataGenerator)
