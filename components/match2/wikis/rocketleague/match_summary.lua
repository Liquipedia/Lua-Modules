---
-- @Liquipedia
-- wiki=rocketleague
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')
local VodLink = require('Module:VodLink')
local Json = require('Module:Json')
local Abbreviation = require('Module:Abbreviation')
local String = require('Module:StringUtils')
local Flags = require('Module:Flags')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper', {requireDevIfEnabled = true})
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util', {requireDevIfEnabled = true})
local MatchSummary = Lua.import('Module:MatchSummary/Base', {requireDevIfEnabled = true})
local OpponentDisplay = Lua.import('Module:OpponentDisplay', {requireDevIfEnabled = true})

local _GREEN_CHECK = '[[File:GreenCheck.png|14x14px|link=]]'
local _NO_CHECK = '[[File:NoCheck.png|link=]]'
local _TIMEOUT = '[[File:Cooldown_Clock.png|14x14px|link=]]'

local _OCTANE_PREFIX = '[[File:Octane_gg.png|14x14px|link='
local _OCTANE_SUFFIX = '|Octane matchpage]]'
local _BALLCHASING_PREFIX = '[[File:Ballchasing icon.png|14x14px|link='
local _BALLCHASING_SUFFIX = '|Ballchasing replays]]'
local _HEADTOHEAD_PREFIX = '[[File:Match Info Stats.png|14x14px|link='
local _HEADTOHEAD_SUFFIX = '|Head to Head history]]'

local _TBD_ICON = mw.ext.TeamTemplate.teamicon('tbd')

-- Custom Caster Class
local Casters = Class.new(
	function(self)
		self.root = mw.html.create('div')
			:addClass('brkts-popup-comment')
			:css('white-space','normal')
			:css('font-size','85%')
		self.casters = {}
	end
)

function Casters:addCaster(caster)
	if Logic.isNotEmpty(caster) then
		local nameDisplay = '[[' .. caster.name .. '|' .. caster.displayName .. ']]'
		if caster.flag then
			table.insert(self.casters, Flags.Icon(caster['flag']) .. ' ' .. nameDisplay)
		else
			table.insert(self.casters, nameDisplay)
		end
	end
	return self
end

function Casters:create()
	return self.root
		:wikitext('Caster' .. (#self.casters > 1 and 's' or '') .. ': ')
		:wikitext(table.concat(self.casters, #self.casters > 2 and ', ' or ' & '))
end

-- Custom Header Class
local Header = Class.new(
	function(self)
		self.root = mw.html.create('div')
		self.root:addClass('brkts-popup-header-dev')
	end
)

function Header:leftOpponentTeam(content)
	self.leftElementAdditional = content
	return self
end

function Header:rightOpponentTeam(content)
	self.rightElementAdditional = content
	return self
end

function Header:scoreBoard(content)
	self.scoreBoard = content
	return self
end

function Header:leftOpponent(content)
	self.leftElement = content
	return self
end

function Header:rightOpponent(content)
	self.rightElement = content
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

	if String.isNotEmpty(bestof) and bestof > 0 and isNotFinished then
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

function Header:soloOpponentTeam(opponent, date)
	if opponent.type == 'solo' then
		local teamExists = mw.ext.TeamTemplate.teamexists(opponent.template or '')
		local display = teamExists
			and mw.ext.TeamTemplate.teamicon(opponent.template, date)
			or _TBD_ICON
		return mw.html.create('div'):wikitext(display)
			:addClass('brkts-popup-header-opponent-solo-team')
		end
end

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

function CustomMatchSummary._getHeadToHead(opponents)
	local team1, team2 = mw.uri.encode(opponents[1].name), mw.uri.encode(opponents[2].name)
	local link = tostring(mw.uri.fullUrl('Special:RunQuery/Head2head'))
		.. '?RunQuery=Run&pfRunQueryFormName=Head2head&Headtohead%5Bteam1%5D='
		.. team1 .. '&Headtohead%5Bteam2%5D=' .. team2
	return _HEADTOHEAD_PREFIX .. link .. _HEADTOHEAD_SUFFIX
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
		CustomMatchSummary._getHeadToHead(match.opponents) or nil

	if
		Table.isNotEmpty(vods) or
		String.isNotEmpty(match.vod) or
		Table.isNotEmpty(match.links) or
		headToHead
	then
		local footer = MatchSummary.Footer()

		-- Octane
		if Logic.isNotEmpty(match.links.octane) then
			footer:addElement(_OCTANE_PREFIX .. match.links.octane .. _OCTANE_SUFFIX)
		end

		-- Ballchasing
		if Logic.isNotEmpty(match.links.ballchasing) then
			footer:addElement(_BALLCHASING_PREFIX .. match.links.ballchasing .. _BALLCHASING_SUFFIX)
		end

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

	return header
end

function CustomMatchSummary._createBody(match)
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
	if String.isNotEmpty(match.extradata.casters) then
		local casters = Json.parseIfString(match.extradata.casters)
		local casterRow = Casters()
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
		:node(mw.html.create('div'):node('[[' .. game.map .. ']]'))
	if Logic.readBool(extradata.ot) then
		centerNode:node(mw.html.create('div'):node('- OT'))
		if Logic.isNotEmpty(extradata.otlength) then
			centerNode:node(mw.html.create('div'):node('(' .. extradata.otlength .. ')'))
		end
	end

	row:addElement(CustomMatchSummary._iconDisplay(
		_GREEN_CHECK,
		game.winner == 1,
		game.scores[1],
		1
	))
	row:addElement(centerNode)
	row:addElement(CustomMatchSummary._iconDisplay(
		_GREEN_CHECK,
		game.winner == 2,
		game.scores[2],
		2
	))

	if extradata.timeout then
		local timeouts = Json.parseIfString(extradata.timeout)
		row:addElement(MatchSummary.Break():create())
		row:addElement(CustomMatchSummary._iconDisplay(
			_TIMEOUT,
			Table.includes(timeouts, 1)
		))
		row:addElement(mw.html.create('div')
			:addClass('brkts-popup-spaced')
			:node(mw.html.create('div'):node('Timeout'))
		)
		row:addElement(CustomMatchSummary._iconDisplay(
			_TIMEOUT,
			Table.includes(timeouts, 2)
		))
	end

	if
		String.isNotEmpty(extradata.t1goals)
		or String.isNotEmpty(extradata.t2goals)
		or String.isNotEmpty(game.comment)
	then
		row:addElement(MatchSummary.Break():create())
	end
	if String.isNotEmpty(extradata.t1goals) then
		row:addElement(CustomMatchSummary._goalDisaplay(extradata.t1goals, 1))
	end
	if String.isNotEmpty(game.comment) then
		row:addElement(mw.html.create('div')
			:css('margin','auto')
			:css('max-width', '60%')
			:node(game.comment)
		)
	end
	if String.isNotEmpty(extradata.t2goals) then
		row:addElement(CustomMatchSummary._goalDisaplay(extradata.t2goals, 2))
	end

	return row
end

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

function CustomMatchSummary._iconDisplay(icon, shouldDisplay, additionalElement, side)
	local flip = side == 2
	return mw.html.create('div')
		:addClass('brkts-popup-spaced')
		:node(additionalElement and flip and mw.html.create('div'):node(additionalElement) or nil)
		:node(shouldDisplay and icon or _NO_CHECK)
		:node(additionalElement and (not flip) and mw.html.create('div'):node(additionalElement) or nil)
end

return CustomMatchSummary
