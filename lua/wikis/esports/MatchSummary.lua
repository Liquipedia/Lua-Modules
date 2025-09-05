---
-- @Liquipedia
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local DateExt = Lua.import('Module:Date/Ext')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')
local MatchSummary = Lua.import('Module:MatchSummary/Base')

local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local WidgetUtil = Lua.import('Module:Widget/Util')
local Button = Lua.import('Module:Widget/Basic/Button')
local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')

local CustomMatchSummary = {}

---@param args table
---@return Html
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args)
end

---@param match MatchGroupUtilMatch
---@return MatchSummaryBody
function CustomMatchSummary.createBody(match)
	local phase = MatchGroupUtil.computeMatchPhase(match)
	local showCountdown = match.timestamp ~= DateExt.defaultTimestamp and phase ~='finished'

	return MatchSummaryWidgets.Body{children = WidgetUtil.collect(
		showCountdown and MatchSummaryWidgets.Row{children = DisplayHelper.MatchCountdownBlock(match)} or nil,
		Array.map(match.games, CustomMatchSummary._createMapRow)
	)}
end

---@param game MatchGroupUtilGame
---@return Widget?
function CustomMatchSummary._createMapRow(game)
	local gamePhase = MatchGroupUtil.computeMatchPhase(game)

	if gamePhase ~='finished' then
		if game.extradata.link == nil then
			return MatchSummaryWidgets.Row{
				children = MatchSummaryWidgets.GameCenter{children = 'Voting opening soon!'}
			}
		end

		return MatchSummaryWidgets.Row{
			children = MatchSummaryWidgets.GameCenter{children = Button{
				link = game.extradata.link,
				title = 'Click here to vote!',
				variant = 'secondary',
				size = 'sm',
				linktype = 'external',
				children = {
					'VOTE ',
					IconFa{
						additionalClasses = { 'wiki-color-dark' },
						iconName = 'external-link'
					},
				}
			}}
		}
	end

	local function makeTeamSection(opponentIndex)
		return {
			DisplayHelper.MapScore(game.opponents[opponentIndex], game.status) .. ' %',
		}
	end

	return MatchSummaryWidgets.Row{
		classes = {'brkts-popup-body-game'},
		children = WidgetUtil.collect(
			MatchSummaryWidgets.GameTeamWrapper{children = makeTeamSection(1)},
			MatchSummaryWidgets.GameCenter{children = 'Poll Result'},
			MatchSummaryWidgets.GameTeamWrapper{children = makeTeamSection(2), flipped = true}
		)
	}
end

return CustomMatchSummary
