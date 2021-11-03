---
-- @Liquipedia
-- wiki=rocketleague
-- page=Module:LegacyMatchList
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local LegacyMatchList = {}

local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')
local getArgs = require('Module:Arguments').getArgs
local json = require('Module:Json')

local MatchSubobjects = Lua.import('Module:Match/Subobjects', {requireDevIfEnabled = true})

local ALLOWED_STATUSES = { 'W', 'FF', 'DQ', 'L' }
local _MAX_NUMBER_OF_MATCHES = 64
local _MAX_NUMBER_OF_MAPS = 15

function LegacyMatchList.convertMatchList(frame)
	local args = getArgs(frame)

	--switch matches (and headers) to the correct parameters for the new system
	for index = 1, _MAX_NUMBER_OF_MATCHES do
		if not Logic.isEmpty(args['match' .. index]) then
			local match = json.parse(args['match' .. index])
			--header adjusting
			args['M' .. index .. 'header'] = match.header
			match.header = nil
			--stringify match again and asign new key
			args['M' .. index] = json.stringify(match)
			--kick old key
			args['match' .. index] = nil
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
	args.hide = nil

	--title adjusting
	if (not args.title) and args[1] then
		args.title = args[1]
	end
	args[1] = nil
	args.isLegacy = true

	--pass the adjusted arguments to the MatchGroup
	return require('Module:MatchGroup').luaMatchlist(frame, args)
end

function LegacyMatchList.convertMatchMaps(frame)
	local args = getArgs(frame)
	local details = json.parseIfString(args.details or '{}')

	--process maps
	args, details = LegacyMatchList.processMaps(args, details)

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
				score = args['t' .. index .. 'wins']
			end
		end

		if template ~= 'tbd' then
			args['opponent' .. index] = {
				score = score,
				template = template,
				type = 'team',
			}
		end
		args['opponent' .. index .. 'literal'] = args['team' .. index .. 'literal']

		--empty all the stuff we set into this opponent
		args['team' .. index .. 'literal'] = nil
		args['games' .. index] = nil
		args['team' .. index] = nil
		args.walkover = nil
		args['t' .. index .. 'wins'] = nil
	end

	--sort out date params
	args = LegacyMatchList.setHeaderIfEmpty(args, details)

	--process other stuff from details
	args = LegacyMatchList.copyDetailsToArgs(args, details)

	args = LegacyMatchList.handleLiteralsForOpponents(args)

	return json.stringify(args)
end

function LegacyMatchList.convertSwissMatchMaps(frame)
	local args = getArgs(frame)
	local details = json.parseIfString(args.details or '{}')

	--process maps
	args, details = LegacyMatchList.processMaps(args, details)

	--process opponents
	for index = 1, 2 do
		local player = args['player' .. index] or args['team' .. index] or 'TBD'
		local playerLink = args['player' .. index .. 'link'] or player

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
				score = args['t' .. index .. 'wins']
			end
		end
		if player ~= 'TBD' then
			args['opponent' .. index] = {
				flag = args['p' .. index .. 'flag'],
				link = playerLink,
				name = player,
				score = score,
				template = args['p' .. index .. 'team'],
				type = 'solo',
			}
		end
		args['opponent' .. index .. 'literal'] = args['team' .. index .. 'literal']

		--atm we ignore the old teamXstanding parameters, because
		--it is used on a single page ...
		--they are not supported in the new system

		--empty all the stuff we set into this opponent
		args['player' .. index] = nil
		args['team' .. index] = nil
		args['p' .. index .. 'flag'] = nil
		args['p' .. index .. 'team'] = nil
		args['team' .. index .. 'literal'] = nil
		args['games' .. index] = nil
		args['t' .. index .. 'wins'] = nil
		args.walkover = nil
	end

	--sort out date params
	args = LegacyMatchList.setHeaderIfEmpty(args, details)

	--process other stuff from details
	args = LegacyMatchList.copyDetailsToArgs(args, details)

	args = LegacyMatchList.handleLiteralsForOpponents(args)

	return json.stringify(args)
end

--functions shared between convertMatchMaps and convertSwissMatchMaps
function LegacyMatchList.copyDetailsToArgs(args, details)
	for key, value in pairs(details) do
		if Logic.isEmpty(args[key]) then
			args[key] = value
		end
	end
	args.details = nil
	return args
end

function LegacyMatchList.processMaps(args, details)
	local t1wins = 0
	local t2wins = 0
	for index = 1, _MAX_NUMBER_OF_MAPS do
		if details['map' .. index] then
			local score1 = details['map' .. index .. 't1score'] or
				LegacyMatchList.getMapScoreFromGoals(details['map' .. index .. 't1goals'])
			local score2 = details['map' .. index .. 't2score'] or
				LegacyMatchList.getMapScoreFromGoals(details['map' .. index .. 't2goals'])

			local map = MatchSubobjects.luaGetMap(nil, {
				map = details['map' .. index],
				winner = details['map' .. index .. 'win'],
				score1 = score1,
				score2 = score2,
				ot = details['ot' .. index],
				otlength = details['otlength' .. index],
				vod = details['vodgame' .. index],
				comment = details['map' .. index .. 'comment'],
				t1goals = details['map' .. index .. 't1goals'],
				t2goals = details['map' .. index .. 't2goals'],
			})
			args['map' .. index] = map
			if map.winner == '1' then
				t1wins = t1wins + 1
			elseif map.winner == '2' then
				t2wins = t2wins + 1
			end

			--empty all the stuff we set into this map
			details['map' .. index] = nil
			details['map' .. index .. 'win'] = nil
			details['map' .. index .. 't1score'] = nil
			details['map' .. index .. 't2score'] = nil
			details['ot' .. index] = nil
			details['otlength' .. index] = nil
			details['vodgame' .. index] = nil
			details['map' .. index .. 'comment'] = nil
			details['map' .. index .. 't1goals'] = nil
			details['map' .. index .. 't2goals'] = nil
		else
			break
		end
	end
	args.t1wins = t1wins ~= 0 and t1wins or nil
	args.t2wins = t2wins ~= 0 and t2wins or nil
	return args, details
end

function LegacyMatchList.getMapScoreFromGoals(goals)
	if Logic.isEmpty(goals) then return nil end

	local indexedGoals = mw.text.split(goals, ',')
	return #indexedGoals
end

function LegacyMatchList.setHeaderIfEmpty(args, details)
	args.header = args.header or args.date
	args.date = details.date or args.date
	return args
end

function LegacyMatchList.handleLiteralsForOpponents(args)
	for opponentIndex = 1, 2 do
		local opponent = args['opponent' .. opponentIndex]
		if Logic.isEmpty(opponent) then
			args['opponent' .. opponentIndex] = {
				['type'] = 'literal', template = 'tbd', name = args['opponent' .. opponentIndex .. 'literal']
			}
		end
	end
	return args
end

return LegacyMatchList
