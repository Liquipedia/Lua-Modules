---
-- @Liquipedia
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')

local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')

local MAX_NUM_BANS = 7
local NUM_HEROES_PICK = 5
local STATUS_NOT_PLAYED = 'notplayed'

---@class Dota2CustomMatchSummary: CustomMatchSummaryInterface
local CustomMatchSummary = {}

---@class Dota2MatchSummaryGameRowComponentImpl: MatchSummaryGameRowComponentImpl
local GameRowComponentImpl = {
	createGameOverview = MatchSummaryWidgets.GameRow.lengthDisplay,
}

local Dota2MatchSummaryGameRow = MatchSummaryWidgets.GameRow.createComponent(GameRowComponentImpl)

---@param args table
---@return Renderable
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, {width = '400px', teamStyle = 'bracket'})
end

---@param match MatchGroupUtilMatch
---@return VNode[]
function CustomMatchSummary.createBody(match)
	local characterBansData = MatchSummary.buildCharacterBanData(match.games, MAX_NUM_BANS)

	return {
		MatchSummaryWidgets.GamesContainer{
			children = Array.map(match.games, function (game, gameIndex)
				if game.status == STATUS_NOT_PLAYED then
					return
				end
				return Dota2MatchSummaryGameRow{game = game, gameIndex = gameIndex}
			end)
		},
		MatchSummaryWidgets.Mvp(match.extradata.mvp),
		MatchSummaryWidgets.CharacterBanTable{bans = characterBansData, date = match.date}
	}
end

---@param props MatchSummaryGameRowProps
---@param opponentIndex integer
---@return VNode
function GameRowComponentImpl.createGameOpponentView(props, opponentIndex)
	local game = props.game
	local extradata = game.extradata or {}

	return MatchSummaryWidgets.Characters{
		flipped = opponentIndex == 2,
		characters = MatchSummary.buildCharacterList(
			extradata, 'team' .. opponentIndex .. 'hero', NUM_HEROES_PICK
		),
		bg = 'brkts-popup-side-color brkts-popup-side-color--' .. (extradata['team' .. opponentIndex .. 'side'] or ''),
		date = game.date,
	}
end

return CustomMatchSummary
