---
-- @Liquipedia
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchSummary = Lua.import('Module:MatchSummary/Base')

local Html = Lua.import('Module:Widget/Html')
local Image = Lua.import('Module:Widget/Image/Icon/Image')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local SIDE_ICONS = {
	ATK = {
		light = 'DF Attacker icon lightmode.png',
		dark = 'DF Attacker icon darkmode.png',
	},
	DEF = {
		light = 'DF Defender icon lightmode.png',
		dark = 'DF Defender icon darkmode.png',
	},
}

local CustomMatchSummary = {}

---@param args table
---@return Renderable
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args)
end

---@param date string
---@param game MatchGroupUtilGame
---@param gameIndex integer
---@return Renderable?
function CustomMatchSummary.createGame(date, game, gameIndex)
	---@param opponentIndex integer
	---@return Renderable[]
	local function makeTeamSection(opponentIndex)
		return {
			MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = opponentIndex},
			DisplayHelper.MapScore(game.opponents[opponentIndex], game.status)
		}
	end

	---@param opponentIndex integer
	---@return Renderable[]?
	local function sideIndicator(opponentIndex)
		local iconData = SIDE_ICONS[game.extradata['t' .. opponentIndex .. 'side']]
		if not iconData then return end
		return {
			Html.Span{
				classes = {'brkts-popup-spaced'},
				children = Image{
					imageLight = iconData.light,
					imageDark = iconData.dark,
					size = '16px',
				}
			},
			Html.Span{
				css = {
					['font-size'] = '8px',
					['font-weight'] = 'bold',
					margin = '0 -2px',
					['white-space'] = 'nowrap',
				},
				children = game.extradata['t' .. opponentIndex .. 'side'],
			}
		}
	end

	return MatchSummaryWidgets.Row{
		classes = {'brkts-popup-body-game'},
		children = WidgetUtil.collect(
			MatchSummaryWidgets.GameTeamWrapper{children = WidgetUtil.collect(
				makeTeamSection(1),
				sideIndicator(1)
			)},
			MatchSummaryWidgets.GameCenter{children = DisplayHelper.Map(game)},
			MatchSummaryWidgets.GameTeamWrapper{children = WidgetUtil.collect(
				makeTeamSection(2),
				sideIndicator(2)
			), flipped = true},
			MatchSummaryWidgets.GameComment{children = game.comment}
		)
	}
end

return CustomMatchSummary
