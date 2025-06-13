---
-- @Liquipedia
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Abbreviation = require('Module:Abbreviation')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local WidgetUtil = Lua.import('Module:Widget/Util')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local OpponentDisplay = Lua.import('Module:OpponentDisplay')

local NO_CHECK = '[[File:NoCheck.png|link=]]'
local TIMEOUT = '[[File:Cooldown_Clock.png|14x14px|link=]]'

-- Custom Header Class
---@class RocketleagueMatchSummaryHeader: MatchSummaryHeader
---@field scoreBoardElement Html
local Header = Class.new(MatchSummary.Header)

---@param content Html
---@return self
function Header:scoreBoard(content)
	self.scoreBoardElement = content
	return self
end

---@param opponent1 standardOpponent
---@param opponent2 standardOpponent
---@return Html
function Header:createScoreDisplay(opponent1, opponent2)
	local function getScore(opponent)
		local scoreText
		local isWinner = opponent.placement == 1 or opponent.advances
		if opponent.placement2 then
			-- Bracket Reset, show W/L
			if opponent.placement2 == 1 then
				isWinner = true
				scoreText = 'W'
			else
				isWinner = false
				scoreText = 'L'
			end
		elseif opponent.extradata and opponent.extradata.additionalScores then
			-- Match Series (Sets), show the series score
			scoreText = (opponent.extradata.set1win and 1 or 0)
					+ (opponent.extradata.set2win and 1 or 0)
					+ (opponent.extradata.set3win and 1 or 0)
		else
			scoreText = OpponentDisplay.InlineScore(opponent)
		end
		return OpponentDisplay.BlockScore{
			isWinner = isWinner,
			scoreText = scoreText,
		}
	end

	return mw.html.create('div')
		:addClass('brkts-popup-spaced')
		:node(
			getScore(opponent1)
				:css('margin-right', 0)
		)
		:node(' : ')
		:node(getScore(opponent2))
end

---@param score number?
---@param bestof number?
---@param isNotFinished boolean?
---@return Html
function Header:createScoreBoard(score, bestof, isNotFinished)
	local scoreBoardNode = mw.html.create('div')
		:addClass('brkts-popup-spaced')

	if Logic.isNotEmpty(bestof) and bestof > 0 and isNotFinished then
		return scoreBoardNode
			:node(mw.html.create('span')
				:css('line-height', '1.1')
				:css('width', '100%')
				:css('text-align', 'center')
				:node(score)
			)
			:node('<br>')
			:node(mw.html.create('span')
				:wikitext('(')
				:node(Abbreviation.make{text = 'Bo' .. bestof, title = 'Best of ' .. bestof})
				:wikitext(')')
			)
	end

	return scoreBoardNode:node(score)
end

---@return Html
function Header:create()
	self.root:node(mw.html.create('div'):addClass('brkts-popup-header-opponent'):node(self.leftElement))
	self.root:node(self.scoreBoardElement)
	self.root:node(mw.html.create('div'):addClass('brkts-popup-header-opponent'):node(self.rightElement))

	return self.root
end

local CustomMatchSummary = {}

---@param args table
---@return Html
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args)
end

---@param match MatchGroupUtilMatch
---@param options {teamStyle: boolean?, width: string?}?
---@return RocketleagueMatchSummaryHeader
function CustomMatchSummary.createHeader(match, options)
	local header = Header()

	return header
		:leftOpponent(header:createOpponent(match.opponents[1], 'left'))
		:scoreBoard(header:createScoreBoard(
			header:createScoreDisplay(
				match.opponents[1],
				match.opponents[2]
			),
			match.bestof,
			not match.finished
		))
		:rightOpponent(header:createOpponent(match.opponents[2], 'right'))
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
		MatchSummaryWidgets.Break{}
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
		MatchSummaryWidgets.Break{},
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
