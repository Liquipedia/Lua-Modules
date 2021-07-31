local LegacyMatchList = {}

local getArgs = require('Module:Arguments').getArgs
local json = require('Module:Json')
local processMatch = require('Module:Brkts/WikiSpecific').processMatch
local Logic = require('Module:Logic')
local Variables = require('Module:Variables')
local Table = require('Module:Table')
local String = require('Module:StringUtils')
local MatchSubobjects = require('Module:Match/Subobjects')
local ALLOWED_STATUSES = { 'W', 'FF', 'DQ', 'L' }
local MatchGroup


function LegacyMatchList.convertMatchList(frame)
	local args = getArgs(frame)

	--switch matches (and headers) to the correct parameters for the new system
	for index = 1, 64 do
		if not Logic.isEmpty(args['match' .. index]) then
			args['M' .. index] = args['match' .. index]
			args['match' .. index] = nil
			--header adjusting
			local header = Variables.varDefault('M' .. index .. 'header', '')
			if header ~= '' then
				args['M' .. index .. 'header'] = header
				Variables.varDefine('M' .. index .. 'header', '')
			end
		else
			break
		end
	end

	--switch hide to collapsed param
	if string.lower(args.hide or '') == 'false' then
		args.collapsed = 'false'
	else
		args.collapsed = 'true'
	end

	--title adjusting
	if (not args.title) and args[1] then
		args.title = args[1]
	end
	args[1] = nil

	--pass the adjusted arguments to the MatchGroup
	return require('Module:MatchGroup').luaMatchlist(frame, args)
end

function LegacyMatchList.convertMatchMaps(frame)
	local args = getArgs(frame)
	local details = json.parseIfString(args.details or '{}')

	--process opponents
	for index = 1, 2 do
		local template = args['team' .. index]
		if (not template) or template == '&nbsp;' then
			template = 'tbd'
		else
			template = string.lower(template)
		end
		local score
		if args.walkover then
			if tonumber(args.walkover) == index then
				score = 'W'
			elseif Table.includes(ALLOWED_STATUSES, args['games' .. index]) then
				score = args['games' .. index]
			else
				score = 'L'
			end
		else
			score = args['games' .. index] or '-1'
			if tonumber(score) == -1 then
				score = Variables.varDefault('team' .. index .. 'wins', '0')
			end
		end

		if template ~= 'tbd' then
			args['opponent' .. index] = MatchSubobjects.luaGetOpponent(frame, {
					type = 'team',
					template = template,
					score = score,
				})
		end
		args['opponent' .. index .. 'literal'] = args['team' .. index .. 'literal']

		--empty all the stuff we set into this opponent
		args['team' .. index .. 'literal'] = nil
		args['games' .. index] = nil
		args['team' .. index] = nil
		args.walkover = nil
	end

	--process maps
	for index = 1, 15 do
		if details['map' .. index] then
			args['map' .. index] = MatchSubobjects.luaGetMap(frame, {
				map = details['map' .. index],
				winner = details['map' .. index .. 'win'],
				score1 = details['map' .. index .. 't1score'],
				score2 = details['map' .. index .. 't2score'],
				ot = details['ot' .. index],
				otlength = details['otlength' .. index],
				vod = details['vodgame' .. index],
				comment = details['map' .. index .. 'comment'],
				})
			--atm we ignore the old mapXtYgoals parameters, because
			--1) according to Lukasz they are not used nor disaplayed anymore anyways
			--2) they are pretty hard to convert, due tot the new system wanting goal times
			--tied to the participants and that info isn't available for the old stuff

			--empty all the stuff we set into this map
			details['map' .. index] = nil
			details['map' .. index .. 'win'] = nil
			details['map' .. index .. 't1score'] = nil
			details['map' .. index .. 't2score'] = nil
			details['ot' .. index] = nil
			details['otlength' .. index] = nil
			details['vodgame' .. index] = nil
			details['map' .. index .. 'comment'] = nil
		else
			break
		end
	end

	--process other stuff from details
	for key, value in pairs(details) do
		if Logic.isEmpty(args[key]) then
			args[key] = value
		end
	end
	args.details = nil

	return LegacyMatchList.toEncodedJson(args)
end

--follows later, is used for solo matches
function LegacyMatchList.convertSwissMatchMaps(frame)
	local args = getArgs(frame)

	return LegacyMatchList.toEncodedJson(args)
end

--the following function is basically copied from Module:Match
--it is adjusted a bit to fit the conversion
function LegacyMatchList.toEncodedJson(args)
	-- handle tbd and literals for opponents
	for opponentIndex = 1, 2 do
		local opponent = args['opponent' .. opponentIndex]
		if Logic.isEmpty(opponent) then
			args['opponent' .. opponentIndex] = {
				['type'] = 'literal', template = 'tbd', name = args['opponent' .. opponentIndex .. 'literal']
			}
		end
	end

	-- handle literals for qualifiers
	local bracketdata = json.parse(args.bracketdata or '{}')
	bracketdata.qualwinLiteral = args.qualwinliteral
	bracketdata.qualloseLiteral = args.qualloseliteral
	args.bracketdata = json.stringify(bracketdata)

	-- parse maps
	for mapIndex = 1, 15 do
		local map = args['map' .. mapIndex]
		if type(map) == 'string' then
			map = json.parse(map)
			args['map' .. mapIndex] = map
		else
			break
		end
	end

	return json.stringify(args)
end

return LegacyMatchList
