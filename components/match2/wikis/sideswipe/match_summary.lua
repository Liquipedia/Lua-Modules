---
-- @Liquipedia
-- wiki=sideswipe
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Abbreviation = require('Module:Abbreviation')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local WidgetUtil = Lua.import('Module:Widget/Util')
local OpponentDisplay = Lua.import('Module:OpponentDisplay')

local TBD_ICON = mw.ext.TeamTemplate.teamicon('tbd')

-- Custom Header Class
---@class SideswipeMatchSummaryHeader: MatchSummaryHeader
---@field leftElementAdditional Html
---@field rightElementAdditional Html
---@field scoreBoardElement Html
local Header = Class.new(MatchSummary.Header)

---@param content Html
---@return self
function Header:leftOpponentTeam(content)
	self.leftElementAdditional = content
	return self
end

---@param content Html
---@return self
function Header:rightOpponentTeam(content)
	self.rightElementAdditional = content
	return self
end

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
	return mw.html.create('div')
		:addClass('brkts-popup-spaced')
		:node(
			self:createScore(opponent1)
				:css('margin-right', 0)
		)
		:node(' : ')
		:node(self:createScore(opponent2))
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
				:node(Abbreviation.make(
					'Bo' .. bestof,
					'Best of ' .. bestof
				))
				:wikitext(')')
			)
	end

	return scoreBoardNode:node(score)
end

---@param opponent standardOpponent
---@param date string
---@return Html?
function Header:soloOpponentTeam(opponent, date)
	if opponent.type == 'solo' then
		local teamExists = mw.ext.TeamTemplate.teamexists(opponent.template or '')
		local display = teamExists
			and mw.ext.TeamTemplate.teamicon(opponent.template, date)
			or TBD_ICON
		return mw.html.create('div'):wikitext(display)
			:addClass('brkts-popup-header-opponent-solo-team')
		end
end

---@param opponent standardOpponent
---@param opponentIndex integer
---@return Html
function Header:createOpponent(opponent, opponentIndex)
	return OpponentDisplay.BlockOpponent({
		flip = opponentIndex == 1,
		opponent = opponent,
		overflow = 'ellipsis',
		teamStyle = 'short',
	})
		:addClass(opponent.type ~= 'solo'
			and 'brkts-popup-header-opponent'
			or 'brkts-popup-header-opponent-solo-with-team')
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
---@return SideswipeMatchSummaryHeader
function CustomMatchSummary.createHeader(match, options)
	local header = Header()

	return header
		:leftOpponentTeam(header:soloOpponentTeam(match.opponents[1], match.date))
		:leftOpponent(header:createOpponent(match.opponents[1], 1))
		:scoreBoard(header:createScoreBoard(
			header:createScoreDisplay(
				match.opponents[1],
				match.opponents[2]
			),
			match.bestof,
			not match.finished
		))
		:rightOpponent(header:createOpponent(match.opponents[2], 2))
		:rightOpponentTeam(header:soloOpponentTeam(match.opponents[2], match.date))
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
			DisplayHelper.MapScore(game.scores[opponentIndex], opponentIndex, game.resultType, game.walkover, game.winner),
			MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = opponentIndex},
		}
	end

	return MatchSummaryWidgets.Row{
		classes = {'brkts-popup-body-game'},
		children = WidgetUtil.collect(
			MatchSummaryWidgets.GameTeamWrapper{children = makeTeamSection(1)},
			MatchSummaryWidgets.GameCenter{children = {
				DisplayHelper.Map(game),
				Logic.readBool(extradata.ot) and ' - OT' or nil,
				Logic.isNotEmpty(extradata.otlength) and '(' .. extradata.otlength .. ')' or nil
			}},
			MatchSummaryWidgets.GameTeamWrapper{children = makeTeamSection(2), flipped = true},
			MatchSummaryWidgets.GameComment{children = game.comment}
		)
	}
end

return CustomMatchSummary
