---
-- @Liquipedia
-- wiki=trackmania
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Abbreviation = require('Module:Abbreviation')
local Array = require('Module:Array')
local Class = require('Module:Class')
local DateExt = require('Module:Date/Ext')
local Icon = require('Module:Icon')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local WidgetUtil = Lua.import('Module:Widget/Util')
local OpponentLibrary = require('Module:OpponentLibraries')
local OpponentDisplay = OpponentLibrary.OpponentDisplay

local GREEN_CHECK = Icon.makeIcon{iconName = 'winner', color = 'forest-green-text', size = '110%'}
local NO_CHECK = '[[File:NoCheck.png|link=]]'
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

---@param match MatchGroupUtilMatch
---@return MatchSummaryBody
function CustomMatchSummary.createBody(match)
	local showCountdown = match.timestamp ~= DateExt.defaultTimestamp

	return MatchSummaryWidgets.Body{children = WidgetUtil.collect(
		showCountdown and MatchSummaryWidgets.Row{children = DisplayHelper.MatchCountdownBlock(match)} or nil,
		Array.map(match.games, CustomMatchSummary._createGame),
		MatchSummaryWidgets.Mvp(match.extradata.mvp),
		MatchSummaryWidgets.Casters{casters = match.extradata.casters}
	)}
end

---@param game MatchGroupUtilGame
---@return Html?
function CustomMatchSummary._createGame(game)
	if not game.map then
		return
	end
	local row = MatchSummary.Row()
		:addClass('brkts-popup-body-game')
	local extradata = game.extradata or {}

	if String.isNotEmpty(game.header) then
		local gameHeader = mw.html.create('div')
			:css('font-weight','bold')
			:css('font-size','85%')
			:css('margin','auto')
			:node(game.header)

		row:addElement(gameHeader)
		row:addElement(MatchSummaryWidgets.Break{})
	end

	local centerNode = mw.html.create('div')
		:addClass('brkts-popup-spaced')
		:node(mw.html.create('div'):node(game.map))

	row:addElement(CustomMatchSummary._iconDisplay(
		GREEN_CHECK,
		game.winner == 1,
		game.scores[1],
		1
	))
	if extradata.overtime then
		row:addElement(CustomMatchSummary._iconDisplay(
			OVERTIME,
			true,
			nil,
			nil,
			'Overtime'
		))
	end
	row:addElement(centerNode)
	if extradata.overtime then
		row:addElement(CustomMatchSummary._iconDisplay(
			OVERTIME,
			true,
			nil,
			nil,
			'Overtime'
		))
	end
	row:addElement(CustomMatchSummary._iconDisplay(
		GREEN_CHECK,
		game.winner == 2,
		game.scores[2],
		2
	))

	if String.isNotEmpty(game.comment) then
		row:addElement(MatchSummaryWidgets.Break{})

		row:addElement(mw.html.create('div')
			:css('margin','auto')
			:css('max-width', '60%')
			:node(game.comment)
		)
	end

	return row:create()
end

---@param icon string?
---@param shouldDisplay boolean?
---@param additionalElement number|string|Html|nil
---@param side integer?
---@param hoverText string|number|nil
---@return Html
function CustomMatchSummary._iconDisplay(icon, shouldDisplay, additionalElement, side, hoverText)
	local flip = side == 2
	return mw.html.create('div')
		:addClass('brkts-popup-spaced')
		:node(additionalElement and flip and mw.html.create('div'):node(additionalElement) or nil)
		:node(shouldDisplay and icon or NO_CHECK)
		:node(additionalElement and (not flip) and mw.html.create('div'):node(additionalElement) or nil)
		:attr('title', hoverText)
end

return CustomMatchSummary
