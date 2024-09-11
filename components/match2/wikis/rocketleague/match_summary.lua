---
-- @Liquipedia
-- wiki=rocketleague
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Abbreviation = require('Module:Abbreviation')
local Class = require('Module:Class')
local Icon = require('Module:Icon')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local OpponentDisplay = Lua.import('Module:OpponentDisplay')

local GREEN_CHECK = Icon.makeIcon{iconName = 'winner', color = 'forest-green-text', size = '110%'}
local NO_CHECK = '[[File:NoCheck.png|link=]]'
local TIMEOUT = '[[File:Cooldown_Clock.png|14x14px|link=]]'

local TBD_ICON = mw.ext.TeamTemplate.teamicon('tbd')

local LINK_DATA = {
	shift = {icon = 'File:ShiftRLE icon.png', text = 'ShiftRLE matchpage'},
	ballchasing = {icon = 'File:Ballchasing icon.png', text = 'Ballchasing replays'},
	headtohead = {icon = 'File:Match Info Stats.png', text = 'Head to Head history'},
}

-- Custom Header Class
---@class RocketleagueMatchSummaryHeader: MatchSummaryHeader
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
---@return RocketleagueMatchSummaryHeader
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

---@param match MatchGroupUtilMatch
---@param footer MatchSummaryFooter
---@return MatchSummaryFooter
function CustomMatchSummary.addToFooter(match, footer)
	for linkType, linkData in pairs(LINK_DATA) do
		for _, link in Table.iter.pairsByPrefix(match.links, linkType, {requireIndex = false}) do
			footer:addLink(link, linkData.icon, linkData.iconDark, linkData.text)
		end
	end

	footer = MatchSummary.addVodsToFooter(match, footer)

	if not match.extradata.showh2h then
		return footer
	end

	local h2hLinkData = LINK_DATA.headtohead
	return footer:addLink(CustomMatchSummary._getHeadToHead(match.opponents),
		h2hLinkData.icon, h2hLinkData.iconDark, h2hLinkData.text)
end

---@param opponents standardOpponent[]
---@return string
function CustomMatchSummary._getHeadToHead(opponents)
	local team1, team2 = mw.uri.encode(opponents[1].name), mw.uri.encode(opponents[2].name)
	return tostring(mw.uri.fullUrl('Special:RunQuery/Head2head'))
		.. '?RunQuery=Run&pfRunQueryFormName=Head2head&Headtohead%5Bteam1%5D='
		.. team1 .. '&Headtohead%5Bteam2%5D=' .. team2
end

---@param match MatchGroupUtilMatch
---@return MatchSummaryBody
function CustomMatchSummary.createBody(match)
	local body = MatchSummary.Body()

	body:addRow(MatchSummary.Row():addElement(DisplayHelper.MatchCountdownBlock(match)))

	-- Iterate each map
	for _, game in ipairs(match.games) do
		if game.map then
			local rowDisplay = CustomMatchSummary._createGame(game)
			body:addRow(rowDisplay)
		end
	end

	-- casters
	body:addRow(MatchSummary.makeCastersRow(match.extradata.casters))

	return body
end

---@param game MatchGroupUtilGame
---@return MatchSummaryRow
function CustomMatchSummary._createGame(game)
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
		row:addElement(MatchSummary.Break():create())
	end

	local centerNode = mw.html.create('div')
		:addClass('brkts-popup-spaced')
		:node(mw.html.create('div'):node('[[' .. game.map .. ']]'))
	if Logic.readBool(extradata.ot) then
		centerNode:node(mw.html.create('div'):node('- OT'))
		if Logic.isNotEmpty(extradata.otlength) then
			centerNode:node(mw.html.create('div'):node('(' .. extradata.otlength .. ')'))
		end
	end
	local function scoreDisplay(oppIdx)
		return DisplayHelper.MapScore(game.scores[oppIdx], oppIdx, game.resultType, game.walkover, game.winner)
	end

	row:addElement(CustomMatchSummary._iconDisplay(
		GREEN_CHECK,
		game.winner == 1,
		scoreDisplay(1),
		1
	))
	row:addElement(centerNode)
	row:addElement(CustomMatchSummary._iconDisplay(
		GREEN_CHECK,
		game.winner == 2,
		scoreDisplay(2),
		2
	))

	if extradata.timeout then
		local timeouts = Json.parseIfString(extradata.timeout)
		row:addElement(MatchSummary.Break():create())
		row:addElement(CustomMatchSummary._iconDisplay(
			TIMEOUT,
			Table.includes(timeouts, 1)
		))
		row:addElement(mw.html.create('div')
			:addClass('brkts-popup-spaced')
			:node(mw.html.create('div'):node('Timeout'))
		)
		row:addElement(CustomMatchSummary._iconDisplay(
			TIMEOUT,
			Table.includes(timeouts, 2)
		))
	end

	if
		Logic.isNotEmpty(extradata.t1goals)
		or Logic.isNotEmpty(extradata.t2goals)
		or Logic.isNotEmpty(game.comment)
	then
		row:addElement(MatchSummary.Break():create())
	end
	if Logic.isNotEmpty(extradata.t1goals) then
		row:addElement(CustomMatchSummary._goalDisaplay(extradata.t1goals, 1))
	end
	if String.isNotEmpty(game.comment) then
		row:addElement(mw.html.create('div')
			:css('margin','auto')
			:css('max-width', '60%')
			:node(game.comment)
		)
	end
	if Logic.isNotEmpty(extradata.t2goals) then
		row:addElement(CustomMatchSummary._goalDisaplay(extradata.t2goals, 2))
	end

	return row
end

---@param goalesValue string|number
---@param side 1|2
---@return Html
function CustomMatchSummary._goalDisaplay(goalesValue, side)
	local goalsDisplay = mw.html.create('div')
		:cssText(side == 2 and 'float:right; margin-right:10px;' or nil)
		:node(Abbreviation.make(
			goalesValue,
			'Team ' .. side .. ' Goaltimes')
		)

	return mw.html.create('div')
			:css('max-width', '50%')
			:css('maxfont-size', '11px;')
			:node(goalsDisplay)
end

---@param icon string?
---@param shouldDisplay boolean?
---@param additionalElement number|string|Html|nil
---@param side integer?
---@return Html
function CustomMatchSummary._iconDisplay(icon, shouldDisplay, additionalElement, side)
	local flip = side == 2
	return mw.html.create('div')
		:addClass('brkts-popup-spaced')
		:node(additionalElement and flip and mw.html.create('div'):node(additionalElement) or nil)
		:node(shouldDisplay and icon or NO_CHECK)
		:node(additionalElement and (not flip) and mw.html.create('div'):node(additionalElement) or nil)
end

return CustomMatchSummary
