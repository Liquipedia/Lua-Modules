---
-- @Liquipedia
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')

local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local MAX_NUM_BANS = 5
local NUM_HEROES_PICK = 5
local STATUS_NOT_PLAYED = 'notplayed'

---@class LoLCustomMatchSummary: CustomMatchSummaryInterface
local CustomMatchSummary = {}

---@class LoLMatchSummaryGameRow: MatchSummaryGameRow
---@operator call(MatchSummaryGameRowProps): LoLMatchSummaryGameRow
local LoLMatchSummaryGameRow = Class.new(MatchSummaryWidgets.GameRow)

---@param args table
---@return Widget
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, {width = '400px', teamStyle = 'bracket'})
end

---@param match MatchGroupUtilMatch
---@return Widget[]
function CustomMatchSummary.createBody(match)
	local characterBansData = MatchSummary.buildCharacterBanData(match.games, MAX_NUM_BANS)

	return WidgetUtil.collect(
		MatchSummaryWidgets.GamesContainer{
			gridLayout = 'standard',
			children = Array.map(match.games, function (game, gameIndex)
				if game.status == STATUS_NOT_PLAYED then
					return
				end
				return LoLMatchSummaryGameRow{game = game, gameIndex = gameIndex}
			end)
		},
		MatchSummaryWidgets.Mvp(match.extradata.mvp),
		MatchSummaryWidgets.CharacterBanTable{bans = characterBansData, date = match.date}
	)
end

---@param opponentIndex integer
---@return Widget
function LoLMatchSummaryGameRow:createGameOpponentView(opponentIndex)
	local props = self.props
	local game = props.game
	local extradata = game.extradata or {}

	return MatchSummaryWidgets.Characters{
		flipped = opponentIndex == 2,
		characters = MatchSummary.buildCharacterList(
			extradata, 'team' .. opponentIndex .. 'champion', NUM_HEROES_PICK
		),
		bg = 'brkts-popup-side-color brkts-popup-side-color--' .. (extradata['team' .. opponentIndex .. 'side'] or ''),
		date = game.date,
	}
end

---@return Renderable?
function LoLMatchSummaryGameRow:createGameOverview()
	return self:lengthDisplay()
end

return CustomMatchSummary
