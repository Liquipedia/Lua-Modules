---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchTicker/MainPage
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Logic = require('Module:Logic')
local MatchGroupWorkaround = require('Module:MatchGroup/Workaround')

local MatchTicker = Lua.import('Module:MatchTicker', {requireDevIfEnabled = true})
local Query = MatchTicker.Query
local Display = MatchTicker.Display
local HelperFunctions = MatchTicker.HelperFunctions

local _WINNER_LEFT = 1
local _WINNER_RIGHT = 2

local MainPageMatchTicker = {}

function MainPageMatchTicker.run(args)
	args = args or {}

	local lpdbConditions = Query.BaseConditions()
		:addDefaultConditions(args)
		:build(args)
		:toString()

	local lpdb = Query.Query()
	lpdb:setConditions(lpdbConditions)
	if Logic.readBool(args.recent) then
		lpdb:setOrder('date desc, liquipediatier asc, tournament asc')
	end
	local limitInput = tonumber(args.limit or 30) or 30
	lpdb:setLimit(limitInput)

	local data = lpdb:get()
	if not data then
		return
	end

	local wrapper = Display.Wrapper()

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
		HelperFunctions.checkForTbdMatches(matchData.match2opponents[1], matchData.match2opponents[2], matchData.pagename)
		or HelperFunctions.isByeOpponent(matchData.match2opponents[1])
		or HelperFunctions.isByeOpponent(matchData.match2opponents[1])
	)
end

function MainPageMatchTicker._match(matchData, args)
	local winner = tonumber(matchData.winner or 0) or 0

	local upperRow = Display.UpperRow()

	upperRow:addOpponent(matchData.match2opponents[1], 1)
	upperRow:addOpponent(matchData.match2opponents[2], 2)
	upperRow:winner(winner)

	local versus = Display.Versus()
	versus:bestOf(tonumber(matchData.bestof or ''))
	if not Logic.readBool(args.upcoming) then
		versus:score(matchData)
	end
	upperRow:versus(versus:create())

	local lowerRow = Display.LowerRow()

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
		countDownArgs = matchData.stream or {}
		countDownArgs.rawcountdown = 'true'
	end
	lowerRow:countDown(matchData, countDownArgs)

	lowerRow:tournament(matchData)

	if HelperFunctions.isFeatured(matchData) then
		lowerRow:addClass(HelperFunctions.featuredClass)
	end

	local match = Display.Match()
	match:upperRow(upperRow:create())
	match:lowerRow(lowerRow:create())

	return match:create()
end

return Class.export(MainPageMatchTicker)
