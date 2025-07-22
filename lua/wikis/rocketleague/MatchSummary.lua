---
-- @Liquipedia
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Abbreviation = require('Module:Abbreviation')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local WidgetUtil = Lua.import('Module:Widget/Util')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

local NO_CHECK = '[[File:NoCheck.png|link=]]'
local TIMEOUT = '[[File:Cooldown_Clock.png|14x14px|link=]]'

local CustomMatchSummary = {}

---@param args table
---@return Html
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args)
end

---@param date string
---@param game MatchGroupUtilGame
---@param gameIndex integer
---@return Widget?
function CustomMatchSummary.createGame(date, game, gameIndex)
	if not game.map then
		return
	end
	local extradata = game.extradata or {}

	local function makeTeamSection(opponentIndex)
		return {
			DisplayHelper.MapScore(game.opponents[opponentIndex], game.status),
			MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = opponentIndex},
		}
	end

	local header = String.isNotEmpty(game.header) and {
		HtmlWidgets.Div{
			children = game.header,
			css = {
				['font-weight'] = 'bold',
				['font-size'] = '85%',
				margin = 'auto'
			}
		},
	} or nil

	local comments = WidgetUtil.collect(
		CustomMatchSummary._goalDisaplay(extradata.t1goals, 1),
		String.nilIfEmpty(game.comment),
		CustomMatchSummary._goalDisaplay(extradata.t2goals, 2)
	)

	return MatchSummaryWidgets.Row{
		classes = {'brkts-popup-body-game'},
		children = WidgetUtil.collect(
			header,
			MatchSummaryWidgets.GameTeamWrapper{children = makeTeamSection(1)},
			MatchSummaryWidgets.GameCenter{children = WidgetUtil.collect(
				DisplayHelper.Map(game),
				Logic.readBool(extradata.ot) and ' - OT' or nil,
				Logic.isNotEmpty(extradata.otlength) and ' (' .. extradata.otlength .. ')' or nil
			)},
			MatchSummaryWidgets.GameTeamWrapper{children = makeTeamSection(2), flipped = true},
			CustomMatchSummary._timeoutDisplay(extradata.timeout),
			MatchSummaryWidgets.GameComment{children = comments}
		)
	}
end

---@param timeout table?
---@return Widget[]?
function CustomMatchSummary._timeoutDisplay(timeout)
	if not timeout then
		return nil
	end
	local timeouts = timeout
	return {
		CustomMatchSummary._iconDisplay(TIMEOUT, Table.includes(timeouts, 1)),
		MatchSummaryWidgets.GameCenter{children = 'Timeout'},
		CustomMatchSummary._iconDisplay(TIMEOUT, Table.includes(timeouts, 2)),
	}
end

---@param goalesValue string|number
---@param side 1|2
---@return Html?
function CustomMatchSummary._goalDisaplay(goalesValue, side)
	if Logic.isNotEmpty(goalesValue) then
		return nil
	end

	local goalsDisplay = mw.html.create('div')
		:cssText(side == 2 and 'float:right; margin-right:10px;' or nil)
		:node(Abbreviation.make{text = goalesValue, title = 'Team ' .. side .. ' Goaltimes'})

	return mw.html.create('div')
			:css('max-width', '50%')
			:css('maxfont-size', '11px;')
			:node(goalsDisplay)
end

---@param icon string?
---@param shouldDisplay boolean?
---@return Html
function CustomMatchSummary._iconDisplay(icon, shouldDisplay)
	return mw.html.create('div')
		:addClass('brkts-popup-spaced')
		:node(shouldDisplay and icon or NO_CHECK)
end

return CustomMatchSummary
