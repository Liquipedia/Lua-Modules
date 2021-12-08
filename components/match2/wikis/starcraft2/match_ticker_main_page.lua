---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:MatchTicker/MainPage
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Logic = require('Module:Logic')
local MatchGroupWorkaround = require('Module:MatchGroup/Workaround')
local MatchTicker = Lua.import('Module:MatchTicker', {requireDevIfEnabled = true})
MatchTicker.OpponentDisplay = Lua.import('Module:OpponentDisplay/Starcraft', {requireDevIfEnabled = true})
MatchTicker.Opponent = Lua.import('Module:Opponent/Starcraft', {requireDevIfEnabled = true})

local MainPageMatchTicker = {}

function MainPageMatchTicker.run(args)
	args = args or {}

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
		return
	end

	local wrapper = MatchTicker.Wrapper()

	local matchIndex = 1
	local limitCounter = 1
	while data[matchIndex] and limitCounter <= limitInput do
		local item = data[matchIndex]
		-- workaround for a lpdb bug
		-- remove when it is fixed
		MatchGroupWorkaround.applyPlayerBugWorkaround(item)
		if MainPageMatchTicker._isValidMatch(item) then
			limitCounter = limitCounter + 1
			wrapper:addElement(MainPageMatchTicker._match(item, args))
		end
		matchIndex = matchIndex + 1
	end

	return wrapper:create()
end

function MainPageMatchTicker._isValidMatch(matchData)
	return not (
		MatchTicker.checkForTbdMatches(matchData.match2opponents[1], matchData.match2opponents[2], matchData.pagename)
		or MatchTicker.isByeOpponent(matchData.match2opponents[1])
		or MatchTicker.isByeOpponent(matchData.match2opponents[1])
	)
end

local _WINNER_LEFT = 1
local _WINNER_RIGHT = 2
function MainPageMatchTicker._match(matchData, args)
	local winner = tonumber(matchData.winner or 0) or 0

	local upperRow = MatchTicker.UpperRow()

	upperRow:addOpponent(matchData.match2opponents[1], 'left')
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
			upperRow:addClass('recent-matches-left')
		elseif winner == _WINNER_RIGHT then
			upperRow:addClass('recent-matches-right')
		else
			upperRow:addClass('recent-matches-draw')
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

return Class.export(MainPageMatchTicker)
