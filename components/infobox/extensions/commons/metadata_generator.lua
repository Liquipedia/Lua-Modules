local String = require('Module:String')

local MetadataGenerator = {}

function MetadataGenerator.tournament(args)
	local output
	local frame = mw.getCurrentFrame()

	local name = not String.isEmpty(args.name) and (args.name):gsub('&nbsp;', ' ') or mw.title.getCurrentTitle()

	local type = args.type
	local locality = args.country and frame:expandTemplate({title = 'Localisation', args = {args.country}}) or nil
	local organizers = {args['organizer-name'] or args.organizer, args['organizer2-name'] or args.organizer2, args['organizer3-name'] or args.organizer3}
	local tier = args.liquipediatier and frame:expandTemplate({title = 'TierDisplay', args = {args.liquipediatier}}) or nil

	if tier then
		tier = tonumber(frame:expandTemplate({title = 'TierDisplay/number', args = {args.liquipediatier}})) > 4 and tier:lower() or tier else tier = 'Unknown Tier'
	end

	local ttype = (tier == 'qualifier' or tier == 'showmatch') and tier or 'tournament'
	local riot = mw.ext.VariablesLua.var('metadesc-riot') ~= '' and mw.ext.VariablesLua.var('metadesc-riot')
	local date, tense = MetadataGenerator.getDate(args.edate or args.date, args.sdate)
	local teams = args.team_number
	local players = args.player_number
	local game = args.game and args.game ~= 'csgo' and require('Module:Games').abbr[args.game]
	local prizepoolusd = args.prizepoolusd and ('$' .. args.prizepoolusd .. ' USD') or nil
	local prizepool = prizepoolusd or (args.prizepool and args.localcurrency and (mw.ext.VariablesLua.var('localcurrencysymbol') .. args.prizepool .. mw.ext.VariablesLua.var('localcurrencysymbolafter') .. ' ' .. mw.ext.VariablesLua.var('localcurrencycode')))
	local charity = args.charity == 'true' and true
	local dateVerb = (tense == 'past' and 'took place ') or (tense == 'future' and 'will take place ') or 'takes place '
	local dateVerbRiot = (tense == 'past' and ' which took place ') or (tense == 'future' and ' which will take place ') or ' taking place '

	output = name .. ' is a' .. (type and ('n ' .. type:lower() .. ' ') or '') .. (locality and (locality .. ' ') or '') .. (game and (game .. ' ') or '') .. (charity and 'charity ' or '') .. ttype .. (organizers[1] and (' organized by ' .. organizers[1]) or '')

	if organizers[2] then
		output = output .. (organizers[3] and ', ' or ' and ') .. organizers[2] .. (organizers[3] and (', and ' .. organizers[3]) or '') .. '. '
	else
		output = output .. '. '
	end

	output = output .. 'This ' .. (ttype ~= tier and (tier .. ' ') or '') .. ttype .. ' '
	if riot then
		output = output .. 'is a ' .. riot .. ((date and dateVerbRiot) or ((teams or players or prizepool) and ' featuring '))
	elseif date then
		output = output .. dateVerb
	elseif teams or players or prizepool then
		output = output .. 'features '
	end

	if date then
		output = output .. date .. ((teams or players or prizepool) and ' featuring ' or '')
	end

	if teams or players then
		output = output .. ((teams and (teams .. ' teams')) or (players and (players .. ' players'))) .. (prizepool and ' ' or '')
	end
	if prizepool then
		output = output .. ((teams or players) and 'competing over ' or '') .. 'a total ' .. (charity and 'charity ' or '') .. 'prize pool of ' .. prizepool
	end

	output = output .. '.'

	return output
end

function MetadataGenerator.getDate(date, sdate)
	if not date then
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
		return os.date("!from %b " .. (noStartDay and "??" or "%d"), startU) .. ' to ' .. os.date("!" .. (noEndDay and "??" or "%d") .. " %Y", endU), tense
	elseif os.date("!%Y", startU) == os.date("!%Y", endU) then
		return os.date("!from %b " .. (noStartDay and "??" or "%d"), startU) .. ' to ' .. os.date("!%b " .. (noEndDay and "??" or "%d") .. " %Y", endU), tense
	else
		return os.date("!from %b " .. (noStartDay and "??" or "%d") .. " %Y", startU) .. ' to ' .. os.date("!%b " .. (noEndDay and "??" or "%d") .. " %Y", endU), tense
	end
end

return MetadataGenerator
