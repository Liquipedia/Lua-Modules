---
-- @Liquipedia
-- wiki=trackmania
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Abbreviation = require('Module:Abbreviation')
local Class = require('Module:Class')
local Json = require('Module:Json')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper', {requireDevIfEnabled = true})
local MatchSummary = Lua.import('Module:MatchSummary/Base', {requireDevIfEnabled = true})
local OpponentLibrary = require('Module:OpponentLibraries')
local OpponentDisplay = OpponentLibrary.OpponentDisplay

local GREEN_CHECK = '[[File:GreenCheck.png|14x14px|link=]]'
local NO_CHECK = '[[File:NoCheck.png|link=]]'
local OVERTIME = '[[File:Cooldown_Clock.png|14x14px|link=]]'

local HEADTOHEAD = '[[File:Match Info Stats.png|14x14px|link=%s|Head to Head history]]'

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
---@param footer MatchSummaryFooter
---@return MatchSummaryFooter
function CustomMatchSummary.addToFooter(match, footer)
	footer = MatchSummary.addVodsToFooter(match, footer)

	return footer:addElement(match.extradata.showh2h and CustomMatchSummary._getHeadToHead(match) or nil)
end

---@param match MatchGroupUtilMatch
---@return string
function CustomMatchSummary._getHeadToHead(match)
	local opponents = match.opponents
	local team1, team2 = mw.uri.encode(opponents[1].name), mw.uri.encode(opponents[2].name)
	local buildQueryFormLink = function(form, template, arguments)
		return tostring(mw.uri.fullUrl('Special:RunQuery/' .. form,
			mw.uri.buildQueryString(Table.map(arguments, function(key, value) return template .. key, value end))
			.. '&_run'
		))
	end

	local headtoheadArgs = {
		['[team1]'] = team1,
		['[team2]'] = team2,
		['[games][is_list]'] = 1,
		['[tiers][is_list]'] = 1,
		['[fromdate][day]'] = '01',
		['[fromdate][month]'] = '01',
		['[fromdate][year]'] = string.sub(match.date,1,4)
	}

	local link = buildQueryFormLink('Head2head', 'Headtohead', headtoheadArgs)
	return HEADTOHEAD:format(link)
end

---@param match MatchGroupUtilMatch
---@return MatchSummaryBody
function CustomMatchSummary.createBody(match)
	local body = MatchSummary.Body()

	body:addRow(MatchSummary.Row():addElement(DisplayHelper.MatchCountdownBlock(match)))

	-- Iterate each map
	for _, game in ipairs(match.games) do
		if game.map then
			body:addRow(CustomMatchSummary._createGame(game))
		end
	end

	-- casters
	if String.isNotEmpty(match.extradata.casters) then
		local casters = Json.parseIfString(match.extradata.casters)
		local casterRow = MatchSummary.Casters()
		for _, caster in pairs(casters) do
			casterRow:addCaster(caster)
		end

		body:addRow(casterRow)
	end

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
		row:addElement(MatchSummary.Break():create())

		row:addElement(mw.html.create('div')
			:css('margin','auto')
			:css('max-width', '60%')
			:node(game.comment)
		)
	end

	return row
end

---@param icon string
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
