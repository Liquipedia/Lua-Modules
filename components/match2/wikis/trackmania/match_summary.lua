---
-- @Liquipedia
-- wiki=trackmania
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Table = require('Module:Table')
local VodLink = require('Module:VodLink')
local Json = require('Module:Json')
local Abbreviation = require('Module:Abbreviation')
local String = require('Module:StringUtils')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper', {requireDevIfEnabled = true})
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util', {requireDevIfEnabled = true})
local MatchSummary = Lua.import('Module:MatchSummary/Base', {requireDevIfEnabled = true})
local OpponentDisplay = require('Module:OpponentLibraries').OpponentDisplay

local GREEN_CHECK = '[[File:GreenCheck.png|14x14px|link=]]'
local NO_CHECK = '[[File:NoCheck.png|link=]]'
local OVERTIME = '[[File:Cooldown_Clock.png|14x14px|link=]]'

local HEADTOHEAD = '[[File:Match Info Stats.png|14x14px|link=%s|Head to Head history]]'

-- Custom Header Class
local Header = Class.new(MatchSummary.Header)

function Header:scoreBoard(content)
	self.scoreBoard = content
	return self
end
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

function Header:createScoreBoard(score, bestof, isNotFinished)
	local scoreBoardNode = mw.html.create('div')
		:addClass('brkts-popup-spaced')

	if bestof > 0 and isNotFinished then
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
function Header:create()
	self.root:tag('div'):addClass('brkts-popup-header-opponent'):addClass('brkts-popup-header-opponent-left')
		:node(self.leftElementAdditional)
		:node(self.leftElement)
	self.root:node(self.scoreBoard)
	self.root:tag('div'):addClass('brkts-popup-header-opponent'):addClass('brkts-popup-header-opponent-right')
		:node(self.rightElement)
		:node(self.rightElementAdditional)
	return self.root
end


local CustomMatchSummary = {}

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

function CustomMatchSummary.getByMatchId(args)
	local match = MatchGroupUtil.fetchMatchForBracketDisplay(args.bracketId, args.matchId)

	local matchSummary = MatchSummary():init()

	matchSummary:header(CustomMatchSummary._createHeader(match))
				:body(CustomMatchSummary._createBody(match))

	if match.comment then
		local comment = MatchSummary.Comment():content(match.comment)
		matchSummary:comment(comment)
	end

	-- footer
	local vods = {}
	for index, game in ipairs(match.games) do
		if game.vod then
			vods[index] = game.vod
		end
	end

	local headToHead = match.extradata.showh2h and
		CustomMatchSummary._getHeadToHead(match) or nil

	if
		Table.isNotEmpty(vods) or
		String.isNotEmpty(match.vod) or
		Table.isNotEmpty(match.links) or
		headToHead
	then
		local footer = MatchSummary.Footer()

		-- Match Vod
		if String.isNotEmpty(match.vod) then
			footer:addElement(VodLink.display{
				vod = match.vod,
			})
		end

		-- Game Vods
		for index, vod in pairs(vods) do
			footer:addElement(VodLink.display{
				gamenum = index,
				vod = vod,
			})
		end

		-- Head-to-head
		if headToHead then
			footer:addElement(headToHead)
		end

		matchSummary:footer(footer)
	end

	return matchSummary:create()
end

function CustomMatchSummary._createHeader(match)
	local header = Header()

	header
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

	return header
end

function CustomMatchSummary._createBody(match)
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
