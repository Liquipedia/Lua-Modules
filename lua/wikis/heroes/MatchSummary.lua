---
-- @Liquipedia
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Abbreviation = Lua.import('Module:Abbreviation')
local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')

local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local MAX_NUM_BANS = 3
local NUM_CHAMPIONS_PICK = 5
local STATUS_NOT_PLAYED = 'notplayed'

local FP = Abbreviation.make{text = 'First Pick', title = 'First Pick for Heroes on this map'}

---@class HeroesCustomMatchSummary: CustomMatchSummaryInterface
local CustomMatchSummary = {}

---@class HeroesMatchSummaryGameRowComponentProps: MatchSummaryGameRowComponentProps
local GameRowComponentProps = {
	createGameOverview = MatchSummaryWidgets.GameRow.mapDisplay,
}

local HeroesMatchSummaryGameRow = MatchSummaryWidgets.GameRow.createComponent(GameRowComponentProps)

---@param args table
---@return Renderable
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, {width = '480px'})
end

---@param match MatchGroupUtilMatch
---@return VNode[]
function CustomMatchSummary.createBody(match)
	local characterBansData = MatchSummary.buildCharacterBanData(match.games, MAX_NUM_BANS)

	return WidgetUtil.collect(
		MatchSummaryWidgets.GamesContainer{
			children = Array.map(match.games, function (game, gameIndex)
				if game.status == STATUS_NOT_PLAYED or (Logic.isEmpty(game.length) and Logic.isEmpty(game.winner)) then
					return
				end
				return HeroesMatchSummaryGameRow{game = game, gameIndex = gameIndex}
			end)
		},
		MatchSummaryWidgets.Mvp(match.extradata.mvp),
		MatchSummaryWidgets.CharacterBanTable{bans = characterBansData, date = match.date},
		MatchSummaryWidgets.MapVeto(MatchSummary.preProcessMapVeto(match.extradata.mapveto, {emptyMapDisplay = FP}))
	)
end

---@param props MatchSummaryGameRowProps
---@param opponentIndex integer
---@return VNode
function GameRowComponentProps.createGameOpponentView(props, opponentIndex)
	local game = props.game
	local extradata = game.extradata or {}

	return MatchSummaryWidgets.Characters{
		flipped = opponentIndex == 2,
		date = game.date,
		-- TODO: Change to use participant data
		characters = MatchSummary.buildCharacterList(
			extradata, 'team' .. opponentIndex .. 'champion', NUM_CHAMPIONS_PICK
		),
		bg = 'brkts-popup-side-color brkts-popup-side-color--' .. (extradata['team' .. opponentIndex .. 'side'] or ''),
	}
end

---@param props MatchSummaryGameRowProps
---@return string?
function GameRowComponentProps.createAdditionalComment(props)
	local game = props.game
	if Logic.isEmpty(game.length) then
		return
	end
	return 'Match Duration: ' .. game.length
end

return CustomMatchSummary
