---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchTicker/Tournament
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Logic = require('Module:Logic')
local String = require('Module:StringUtils')
local Variables = require('Module:Variables')
local MatchGroupWorkaround = require('Module:MatchGroup/Workaround')

local MatchTicker = Lua.import('Module:MatchTicker', {requireDevIfEnabled = true})
local Query = MatchTicker.Query
local Display = MatchTicker.Display
local HelperFunctions = MatchTicker.HelperFunctions

local _CURRENT_TIME_STAMP = os.date('!%Y-%m-%d %H:%M', os.time(os.date("!*t")))

local TournamentMatchTicker = {}

function TournamentMatchTicker.run(args)
	args = args or {}

	-- add defaultValue for args.tournament if empty
	if String.isEmpty(args.tournament) and String.isEmpty(args.tournament1) then
		args.tournament = mw.title.getCurrentTitle().text
	end

	-- tournament match ticker always has ongoing and
	-- upcoming matches but not recent matches
	args.recent = false
	args.upcoming = true
	args.ongoing = true

	local lpdbConditions = Query.BaseConditions()
		:addDefaultConditions(args)
		:build(args)
		:toString()

	local lpdb = Query.Query()
	lpdb:setConditions(lpdbConditions)
	if Logic.readBool(args.recent) then
		lpdb:setOrder('date desc, liquipediatier asc, tournament asc')
	end
	local limitInput = tonumber(args.limit or 8) or 8
	lpdb:setLimit(limitInput)

	local data = lpdb:get()
	if not data then
		return ''
	end

	local wrapper = Display.Wrapper()

	local game = Variables.varDefault('tournament_game', '')
	wrapper:addClass('fo-nttax-infobox-wrapper infobox-' .. game)
	wrapper:addInnerWrapperClass('fo-nttax-infobox wiki-bordercolor-light')

	local header = Display.Header()
	header:text('Upcoming matches')
	wrapper:addElement(header:create())

	local matchIndex = 1
	local limitCounter = 1
	local item = data[matchIndex]
	while item and limitCounter <= limitInput do
		-- workaround for a lpdb match2 bug
		-- remove when it is fixed
		MatchGroupWorkaround.applyPlayerBugWorkaround(item)
		if TournamentMatchTicker._isValidMatch(item) then
			limitCounter = limitCounter + 1
			wrapper:addElement(TournamentMatchTicker._match(item, args))
		end
		matchIndex = matchIndex + 1
		item = data[matchIndex]
	end

	return wrapper:create()
end

function TournamentMatchTicker._isValidMatch(match)
	return not ( HelperFunctions.isByeOpponent(match.match2opponents[1])
		or HelperFunctions.isByeOpponent(match.match2opponents[1])
	)
end

function TournamentMatchTicker._match(matchData, args)
	local winner = tonumber(matchData.winner or 0) or 0

	local upperRow = Display.UpperRow()

	upperRow:addOpponent(matchData.match2opponents[1], 1)
	upperRow:addOpponent(matchData.match2opponents[2], 2)
	upperRow:winner(winner)

	local versus = Display.Versus()
	versus:bestOf(tonumber(matchData.bestof or ''))
	-- check if the match is live
	if matchData.date <= _CURRENT_TIME_STAMP then
		versus:score(matchData)
	end
	upperRow:versus(versus:create())

	local lowerRow = Display.LowerRow()

	local countDownArgs = matchData.stream or {}
	countDownArgs.rawcountdown = 'true'
	lowerRow:countDown(matchData, countDownArgs)

	if Logic.readBool(args.show_tournament) then
		lowerRow:tournament(matchData)
	end

	local match = Display.Match()
	match:upperRow(upperRow:create())
	match:lowerRow(lowerRow:create())

	return match:create()
end

return Class.export(TournamentMatchTicker)
