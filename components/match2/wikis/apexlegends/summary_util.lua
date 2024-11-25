---
-- @Liquipedia
-- wiki=apexlegends
-- page=Module:Summary/Util
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Date = require('Module:Date/Ext')
local FnUtil = require('Module:FnUtil')
local Table = require('Module:Table')
local Timezone = require('Module:Timezone')
local VodLink = require('Module:VodLink')

local OpponentLibraries = require('Module:OpponentLibraries')
local OpponentDisplay = OpponentLibraries.OpponentDisplay

local CustomSummaryHelper = {}

---@param opponent standardOpponent
---@return Html
function CustomSummaryHelper.displayOpponent(opponent)
	return OpponentDisplay.BlockOpponent{
		opponent = opponent,
		showLink = true,
		overflow = 'ellipsis',
		teamStyle = 'hybrid',
	}
end

---Creates a countdown block for a given game
---Attaches any VODs of the game as well
---@param game table
---@return Html?
function CustomSummaryHelper.gameCountdown(game)
	local timestamp = Date.readTimestamp(game.date)
	if not timestamp then
		return
	end
	-- TODO Use local TZ
	local dateString = Date.formatTimestamp('F j, Y - H:i', timestamp) .. ' ' .. Timezone.getTimezoneString('UTC')

	local stream = Table.merge(game.stream, {
		date = dateString,
		finished = CustomSummaryHelper.isFinished(game) and 'true' or nil,
	})

	return mw.html.create('div'):addClass('match-countdown-block')
			:node(require('Module:Countdown')._create(stream))
			:node(game.vod and VodLink.display{vod = game.vod} or nil)
end

---@param game table
---@return boolean
function CustomSummaryHelper.isFinished(game)
	return game.winner ~= nil
end

---@param opponent1 table
---@param opponent2 table
---@return boolean
function CustomSummaryHelper.placementSortFunction(opponent1, opponent2)
	if opponent1.placement and opponent2.placement and opponent1.placement ~= opponent2.placement then
		return opponent1.placement < opponent2.placement
	end
	if opponent1.status ~= 'S' and opponent2.status == 'S' then
		return false
	end
	if opponent2.status ~= 'S' and opponent1.status == 'S' then
		return true
	end
	if opponent1.score and opponent2.score and opponent1.score ~= opponent2.score then
		return opponent1.score > opponent2.score
	end
	return (opponent1.name or '') < (opponent2.name or '')
end

---@param match table
---@return {kill: number, placement: {rangeStart: integer, rangeEnd: integer, score:number}[]}
function CustomSummaryHelper.createScoringData(match)
	local scoreSettings = match.extradata.scoring

	local scorePlacement = {}

	local points = Table.groupBy(scoreSettings.placement, function (_, value)
		return value
	end)

	for point, placements in Table.iter.spairs(points, function (_, a, b)
		return a > b
	end) do
		local placementRange = Array.sortBy(Array.extractKeys(placements), FnUtil.identity)
		table.insert(scorePlacement, {
			rangeStart = placementRange[1],
			rangeEnd = placementRange[#placementRange],
			score = point,
		})
	end

	return {
		kill = scoreSettings.kill,
		placement = scorePlacement,
		matchPointThreadhold = scoreSettings.matchPointThreadhold,
	}
end

return CustomSummaryHelper
