local LegacyPlayerCrossTable = {}

local getArgs = require('Module:Arguments').getArgs
local json = require('Module:Json')
local Variables = require('Module:Variables')
local Logic = require('Module:Logic')
local MatchList = require('Module:MatchGroup').luaMatchlist

local _MAX_NUMBER_OF_OPPONENTS = 10
local _MAX_NUMBER_OF_MAPS = 99

function LegacyPlayerCrossTable.playerCrossTableToMatch2(frame)
	--only process stuff (for storage) if storage is not disabled
	if Variables.varDefault('disable_SMW_storage', 'false') == 'true'
		or mw.title.getCurrentTitle().namespace ~= 0 then
			return ''
	end

	local args = getArgs(frame)
	local newArgs = {}
	local counter = 0
	local doublerounded = args.doublerounded == 'true'
	local numberOfOpp = LegacyPlayerCrossTable._getOppNumber(args)

	for opp1 = 1, numberOfOpp do
		for opp2 = (doublerounded and 1 or (opp1 + 1)), numberOfOpp do
			if opp1 ~= opp2 then
				counter = counter + 1
				if args[opp1 .. 'vs' .. opp2 .. 'result'] then
					local opp1data = {
						type = 'solo',
						p1 = args['player' .. opp1],
						race = args['player' .. opp1 .. 'race'],
						flag = args['player' .. opp1 .. 'flag'],
						link = args['player' .. opp1 .. 'link'],
						score = args[opp1 .. 'vs' .. opp2 .. 'result'],
					}
					local opp2data = {
						type = 'solo',
						p1 = args['player' .. opp2],
						race = args['player' .. opp2 .. 'race'],
						flag = args['player' .. opp2 .. 'flag'],
						link = args['player' .. opp2 .. 'link'],
						score = args[opp1 .. 'vs' .. opp2 .. 'resultvs'],
					}
					newArgs['M' .. counter] = LegacyPlayerCrossTable._getMatch2(
						'1v1',
						opp1data,
						opp2data,
						args[opp1 .. 'vs' .. opp2 .. 'details']
					)
					args[opp1 .. 'vs' .. opp2 .. 'details'] = nil
				end
				if newArgs['M' .. counter] == nil then
					counter = counter - 1
				end
			end
		end
	end

	newArgs.hide = 'true'
	newArgs.id = args.id

	return MatchList(frame, newArgs)
end

--sub functions
function LegacyPlayerCrossTable._getOppNumber(args)
	local numberOfOpp = 0
	for index = 1, _MAX_NUMBER_OF_OPPONENTS do
		if args['player' .. index] or args['team' .. index] then
			numberOfOpp = numberOfOpp + 1
		else
			break
		end
	end
	return numberOfOpp
end

function LegacyPlayerCrossTable._getMatch2(modus, opp1data, opp2data, details)
	local match = {
		opponent1 = json.stringify(opp1data),
		opponent2 = json.stringify(opp2data),
	}

	match = LegacyPlayerCrossTable._processDetails(modus, match, details)

	return LegacyPlayerCrossTable._handleLiteralsForOpponents(match)
end

function LegacyPlayerCrossTable._processDetails(modus, match, details)
	details = json.parseIfString(details or '{}')
	for index = 1, _MAX_NUMBER_OF_MAPS do
		if modus == '1v1' then
			match['map' .. index] = json.stringify({
				map = details['map' .. index],
				winner = details['map' .. index .. 'win'],
				vod = details['vodgame' .. index],
				race1 = details['map' .. index .. 'p1race'],
				race2 = details['map' .. index .. 'p2race'],
			})
			details['map' .. index] = nil
			details['map' .. index .. 'win'] = nil
			details['vodgame' .. index] = nil
			details['map' .. index .. 'p1race'] = nil
			details['map' .. index .. 'p2race'] = nil
		else
		--here:needs adjusting for the team crosstable when the function is added
			match['map' .. index] = json.stringify({
				
				
			})
		end
		if match['map' .. index] == '{}' then
			break
		end
	end

	match = LegacyPlayerCrossTable._copyDetailsToMatch(match, details)

	return match, details
end

function LegacyPlayerCrossTable._copyDetailsToMatch(match, details)
	for key, value in pairs(details) do
		if Logic.isEmpty(match[key]) then
			match[key] = value
		end
	end
	return match
end

function LegacyPlayerCrossTable._handleLiteralsForOpponents(match)
	for opponentIndex = 1, 2 do
		local opponent = match['opponent' .. opponentIndex]
		if Logic.isEmpty(opponent) then
			match['opponent' .. opponentIndex] = {
				['type'] = 'literal',
				template = 'tbd',
				name = args['opponent' .. opponentIndex .. 'literal'],
			}
		end
	end

	return json.stringify(match)
end

return LegacyPlayerCrossTable
