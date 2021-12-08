---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:MatchTicker/Participant
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Logic = require('Module:Logic')
local MatchGroupWorkaround = require('Module:MatchGroup/Workaround')
local MatchTicker = Lua.import('Module:MatchTicker', {requireDevIfEnabled = true})
MatchTicker.OpponentDisplay = Lua.import('Module:OpponentDisplay/Starcraft', {requireDevIfEnabled = true})
MatchTicker.Opponent = Lua.import('Module:Opponent/Starcraft', {requireDevIfEnabled = true})

local ParticipantMatchTicker = {}

local _LIMIT_ONGOING = 5
local _LIMIT_UPCOMING = 3
local _LIMIT_RRECENT = 5
local _wrapper = MatchTicker.Wrapper()

function ParticipantMatchTicker.run(args)
	args = args or {}
	if String.isNotEmpty(args.player) then
		args.player = mw.ext.TeamLiquidIntegration.resolve_redirect(args.player)
	elseif String.isNotEmpty(args.team) then
		args.team = mw.ext.TeamLiquidIntegration.resolve_redirect(args.team)
	end

	args.recent = false
	args.upcoming = false
	args.ongoing = true
	ParticipantMatchTicker.get(args, 'Ongoing Matches', _LIMIT_ONGOING)

	args.upcoming = true
	args.ongoing = false
	ParticipantMatchTicker.get(args, 'Upcoming Matches', _LIMIT_UPCOMING)

	args.recent = true
	args.upcoming = false
	-- we want to include non exact dates for the recent matches
	args.notExact = true
	ParticipantMatchTicker.get(args, 'Recent Matches', _LIMIT_RRECENT, true)

	return _wrapper:create()
end

function ParticipantMatchTicker.get(args, headerText, limitInput)
	local lpdbConditions = MatchTicker.LpdbConditions()
	lpdbConditions:addDefaultConditions(args)

	if Logic.readBool(args.featured) then
		lpdbConditions:addCondition('[[extradata_featured::true]]')
	end

	local lpdb = MatchTicker.Lpdb()
	lpdb:conditions(lpdbConditions:build())
	if Logic.readBool(args.recent) then
		lpdb:order('date desc, liquipediatier asc, tournament asc')
	end
	lpdb:limit(limitInput)

	local data = lpdb:get()
	if not data then
		return
	end

	local header = MatchTicker.Header()
	header:text(headerText)
	_wrapper:addElement(header:create())

	local participant = args.player or args.team

	local matchIndex = 1
	local limitCounter = 1
	while data[matchIndex] and limitCounter <= limitInput do
		local item = data[matchIndex]
		-- workaround for a lpdb bug
		-- remove when it is fixed
		MatchGroupWorkaround.applyPlayerBugWorkaround(item)
		if ParticipantMatchTicker._isValidMatch(item) then
			limitCounter = limitCounter + 1
			_wrapper:addElement(ParticipantMatchTicker._match(item, participant, args))
		end
		matchIndex = matchIndex + 1
	end
end

function ParticipantMatchTicker._isValidMatch(matchData)
	return not (
		MatchTicker.checkForTbdMatches(matchData.match2opponents[1], matchData.match2opponents[2], matchData.pagename)
		or MatchTicker.isByeOpponent(matchData.match2opponents[1])
		or MatchTicker.isByeOpponent(matchData.match2opponents[1])
	)
end

local _WINNER_LEFT = 1
local _WINNER_RIGHT = 2
function ParticipantMatchTicker._match(matchData, participant, args)
	matchData = ParticipantMatchTicker._orderOpponents(matchData, participant)

	local winner = tonumber(matchData.winner or 0) or 0

	local upperRow = MatchTicker.UpperRow()

	upperRow:addOpponent(matchData.match2opponents[1], 'left', true)
	upperRow:addOpponent(matchData.match2opponents[2], 'right')
	upperRow:winner(winner)

	local versus = MatchTicker.Versus()
	versus:bestOf(tonumber(matchData.bestof or ''))
	if not Logic.readBool(args.upcoming) then
		versus:score(matchData)
	end
	upperRow:versus(versus:create())

	local countDownArgs = {}
	if Logic.readBool(matchData.finished) then
		if winner == _WINNER_LEFT then
			upperRow:addClass('bg-win')
		elseif winner == _WINNER_RIGHT then
			upperRow:addClass('bg-down')
		else
			upperRow:addClass('bg-draw')
		end

		countDownArgs.rawdatetime = 'true'
	else
		countDownArgs.rawcountdown = 'true'
		for key, item in pairs(matchData.stream or {}) do
			countDownArgs[key] = item
		end
	end

	local lowerRow = MatchTicker.LowerRow()

	lowerRow:countDown(matchData, countDownArgs)

	lowerRow:tournament(matchData)
	if Logic.readBool((matchData.extradata or {}).featured) then
		lowerRow:addClass('sc2premier-highlighted')
	end

	local match = MatchTicker.Match()
	match:upperRow(upperRow:create())
	match:lowerRow(lowerRow:create())

	return match:create()
end

function ParticipantMatchTicker._orderOpponents(matchData, participant)
	local hasToSwitch

	if matchData.match2opponents[2].name == participant then
		hasToSwitch = true
	else
		local players = matchData.match2opponents[2].match2players
		for _, player in pairs(players) do
			if player.name == participant then
				hasToSwitch = true
				break
			end
		end
	end

	if hasToSwitch then
		local tempOpponent = matchData.match2opponents[1]
		matchData.match2opponents[1] = matchData.match2opponents[2]
		matchData.match2opponents[2] = tempOpponent
		-- since we flipped the opponents we now also have to flip the winner
		matchData.winner = tonumber(matchData.winner or 0)
		if matchData.winner == 1 then
			matchData.winner = 2
		elseif matchData.winner == 2 then
			matchData.winner = 1
		end
	end

	return matchData
end

return Class.export(ParticipantMatchTicker)
