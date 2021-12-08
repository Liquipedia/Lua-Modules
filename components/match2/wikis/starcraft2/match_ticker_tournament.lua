---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:MatchTicker/Tournament
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Logic = require('Module:Logic')
local Variables = require('Module:Variables')
local MatchGroupWorkaround = require('Module:MatchGroup/Workaround')
local MatchTicker = Lua.import('Module:MatchTicker', {requireDevIfEnabled = true})
MatchTicker.OpponentDisplay = Lua.import('Module:OpponentDisplay/Starcraft', {requireDevIfEnabled = true})
MatchTicker.Opponent = Lua.import('Module:Opponent/Starcraft', {requireDevIfEnabled = true})

local TournamentMatchTicker = {}

function TournamentMatchTicker.run(args)
	args = args or {}

	-- tournament match ticker always has ongoing and
	-- upcoming matches but not recent matches
	args.recent = nil
	args.upcoming = true
	args.ongoing = true

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
	local limitInput = tonumber(args.limit or 8) or 8
	lpdb:limit(limitInput)

	local data = lpdb:get()
	if not data then
		return ''
	end

	local wrapper = MatchTicker.Wrapper()

	local game = Variables.varDefault('tournament_game', '')
	wrapper:addClass('fo-nttax-infobox-wrapper infobox-' .. game)
	wrapper:addInnerWrapperClass('fo-nttax-infobox wiki-bordercolor-light')

	local header = MatchTicker.Header()
	header:text('Upcoming matches')
	wrapper:addElement(header:create())

	local matchIndex = 1
	local limitCounter = 1
	while data[matchIndex] and limitCounter <= limitInput do
		local item = data[matchIndex]
		-- workaround for a lpdb bug
		-- remove when it is fixed
		MatchGroupWorkaround.applyPlayerBugWorkaround(item)
		if TournamentMatchTicker._isValidMatch(item) then
			limitCounter = limitCounter + 1
			wrapper:addElement(TournamentMatchTicker._match(item))
		end
		matchIndex = matchIndex + 1
	end

	return wrapper:create()
end

function TournamentMatchTicker._isValidMatch(match)
	return not ( MatchTicker.isByeOpponent(match.match2opponents[1])
		or MatchTicker.isByeOpponent(match.match2opponents[1])
	)
end

local _CURRENT_TIME_STAMP = os.date('!%Y-%m-%d %H:%M', os.time(os.date("!*t")))
function TournamentMatchTicker._match(matchData)
	local winner = tonumber(matchData.winner or 0) or 0
 
	local upperRow = MatchTicker.UpperRow()

	upperRow:addOpponent(matchData.match2opponents[1], 'left')
	upperRow:addOpponent(matchData.match2opponents[2], 'right')
	upperRow:winner(winner)

	local versus = MatchTicker.Versus()
	versus:bestOf(tonumber(matchData.bestof or ''))
	-- check if the match is live
	if matchData.date <= _CURRENT_TIME_STAMP then
		versus:score(matchData)
	end
	upperRow:versus(versus:create())

	local lowerRow = MatchTicker.LowerRow()

	local countDownArgs = {rawcountdown = 'true'}
	for key, item in pairs(matchData.stream or {}) do
		countDownArgs[key] = item
	end
	lowerRow:countDown(matchData, countDownArgs)

	lowerRow:tournament(matchData)

	local match = MatchTicker.Match()
	match:upperRow(upperRow:create())
	match:lowerRow(lowerRow:create())

	return match:create()
end

return Class.export(TournamentMatchTicker)
