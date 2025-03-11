---
-- @Liquipedia
-- wiki=trackmania
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Abbreviation = require('Module:Abbreviation')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local WidgetUtil = Lua.import('Module:Widget/Util')
local OpponentLibrary = require('Module:OpponentLibraries')
local OpponentDisplay = OpponentLibrary.OpponentDisplay

local OVERTIME = '[[File:Cooldown_Clock.png|14x14px|link=]]'

-- Custom Header Class
---@class TrackmaniaMatchSummaryHeader: MatchSummaryHeader
---@field leftElementAdditional Html
---@field rightElementAdditional Html
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
		:addClass('brkts-popup-score')

	if bestof > 0 and isNotFinished then
		return scoreBoardNode
			:node(mw.html.create('span')
				:css('line-height', '1.1')
				:css('width', '100%')
				:css('text-align', 'center')
				:node(score)
			)
			:node(mw.html.create('span')
				:wikitext('(')
				:node(Abbreviation.make(
					'Bo' .. bestof,
					'Best of ' .. bestof
				))
				:wikitext(')')
			)
	end

	return scoreBoardNode:node(score)
end

---@return Html
function Header:create()
	self.root:tag('div'):addClass('brkts-popup-header-opponent'):addClass('brkts-popup-header-opponent-left')
		:node(self.leftElementAdditional)
		:node(self.leftElement)
	self.root:node(self.scoreBoardElement)
	self.root:tag('div'):addClass('brkts-popup-header-opponent'):addClass('brkts-popup-header-opponent-right')
		:node(self.rightElement)
		:node(self.rightElementAdditional)
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
---@return TrackmaniaMatchSummaryHeader
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

	return MatchSummaryWidgets.Row{
		classes = {'brkts-popup-body-game'},
		children = WidgetUtil.collect(
			MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 1},
			DisplayHelper.MapScore(game.opponents[1], game.status),
			extradata.overtime and CustomMatchSummary._iconDisplay(OVERTIME, 'Overtime') or nil,
			MatchSummaryWidgets.GameCenter{children = DisplayHelper.Map(game, {noLink = true})},
			extradata.overtime and CustomMatchSummary._iconDisplay(OVERTIME, 'Overtime') or nil,
			DisplayHelper.MapScore(game.opponents[2], game.status),
			MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 2},
			MatchSummaryWidgets.GameComment{children = game.comment}
		)
	}
end

---@param icon string?
---@param hoverText string|number|nil
---@return Html
function CustomMatchSummary._iconDisplay(icon, hoverText)
	return HtmlWidgets.Div{
		classes = {'brkts-popup-spaced'},
		attributes = {title = hoverText},
		children = {icon},
	}
end

return CustomMatchSummary
