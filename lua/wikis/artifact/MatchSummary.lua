---
-- @Liquipedia
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local CustomMatchSummary = {}

local DisplayHelper = require('Module:MatchGroup/Display/Helper')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local IconImage = Lua.import('Module:Widget/Image/Icon/Image')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@param args table
---@return Html
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, {width = '420px', teamStyle = 'bracket'})
end

---@param date string
---@param game MatchGroupUtilGame
---@param gameIndex integer
---@return Widget?
function CustomMatchSummary.createGame(date, game, gameIndex)
	local characterData = {
		(((game.opponents[1] or {}).players or {})[1] or {}).characters,
		(((game.opponents[2] or {}).players or {})[1] or {}).characters,
	}

	local deckData = {
		(((game.opponents[1] or {}).players or {})[1] or {}).deck,
		(((game.opponents[2] or {}).players or {})[1] or {}).deck,
	}

	if Logic.isEmpty(game.winner) and Logic.isEmpty(characterData) and Logic.isEmpty(deckData) then
		return nil
	end

	local function makeTeamSection(opponentIndex)
		local flipped = opponentIndex == 2
		return {
			MatchSummaryWidgets.Characters{characters = characterData[opponentIndex], flipped = flipped},
			deckData[opponentIndex] and IconImage{
				imageLight = 'Deck_icon.svg',
				link = 'Special:ArtifactDeck/' .. deckData[opponentIndex],
			} or nil
		}
	end

	local scoreOfOpponnent = function(opponentIndex)
		return DisplayHelper.MapScore(game.opponents[opponentIndex], game.status)
	end

	local scoreDisplay = (scoreOfOpponnent(1) or '') .. '&nbsp;-&nbsp;' .. (scoreOfOpponnent(2) or '')


	return MatchSummaryWidgets.Row{
		classes = {'brkts-popup-body-game'},
		css = {['font-size'] = '85%'},
		children = WidgetUtil.collect(
			MatchSummaryWidgets.GameTeamWrapper{children = makeTeamSection(1)},
			MatchSummaryWidgets.GameCenter{children = scoreDisplay},
			MatchSummaryWidgets.GameTeamWrapper{children = makeTeamSection(2), flipped = true},
			MatchSummaryWidgets.GameComment{children = game.comment}
		)
	}
end

return CustomMatchSummary
