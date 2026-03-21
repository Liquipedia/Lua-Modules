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

local MAX_NUM_BANS = 7
local NUM_HEROES_PICK = 5
local STATUS_NOT_PLAYED = 'notplayed'

---@class Dota2CustomMatchSummary: CustomMatchSummaryInterface
local CustomMatchSummary = {}

---@class Dota2MatchSummaryGameRow: MatchSummaryGameRow
---@operator call(MatchSummaryGameRowProps): Dota2MatchSummaryGameRow
local Dota2MatchSummaryGameRow = Class.new(MatchSummaryWidgets.GameRow)

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
				return Dota2MatchSummaryGameRow{game = game, gameIndex = gameIndex}
			end)
		},
		MatchSummaryWidgets.Mvp(match.extradata.mvp),
		MatchSummaryWidgets.CharacterBanTable{bans = characterBansData, date = match.date}
	)
end

---@return Widget[]
function Dota2MatchSummaryGameRow:createGameDetail()
	local props = self.props
	local game = props.game
	local extradata = game.extradata or {}

	-- TODO: Change to use participant data
	local characterData = {
		MatchSummary.buildCharacterList(extradata, 'team1hero', NUM_HEROES_PICK),
		MatchSummary.buildCharacterList(extradata, 'team2hero', NUM_HEROES_PICK),
	}

	return WidgetUtil.collect(
		MatchSummaryWidgets.Characters{
			flipped = false,
			characters = characterData[1],
			bg = 'brkts-popup-side-color brkts-popup-side-color--' .. (extradata.team1side or ''),
		},
		self:lengthDisplay(),
		MatchSummaryWidgets.Characters{
			flipped = true,
			characters = characterData[2],
			bg = 'brkts-popup-side-color brkts-popup-side-color--' .. (extradata.team2side or ''),
		}
	)
end

return CustomMatchSummary
