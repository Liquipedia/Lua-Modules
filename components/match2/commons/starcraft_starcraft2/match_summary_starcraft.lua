---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchSummary/Starcraft
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Faction = require('Module:Faction')
local Icon = require('Module:Icon')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util')
local MatchGroupUtilStarcraft = Lua.import('Module:MatchGroup/Util/Starcraft')

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent
local OpponentDisplay = OpponentLibraries.OpponentDisplay

local ICONS = {
	greenCheck = Icon.makeIcon{iconName = 'winner', color = 'forest-green-text', size = '110%'},
	yellowLine = '<i class="fas fa-minus bright-sun-text" style="width: 14px; text-align: center" ></i>',
	redCross = '<i class="fas fa-times cinnabar-text" style="width: 14px; text-align: center" ></i>',
	noCheck = '[[File:NoCheck.png|link=]]',
}
local LINKS_DATA = {
	preview = {icon = 'File:Preview Icon32.png', text = 'Preview'},
	interview = {icon = 'File:Interview32.png', text = 'Interview'},
	review = {icon = 'File:Reviews32.png', text = 'Review'},
	lrthread = {icon = 'File:LiveReport32.png', text = 'Live Report Thread'},
	h2h = {icon = 'File:Match Info Stats.png', text = 'Head-to-head statistics'},
}
LINKS_DATA.preview2 = LINKS_DATA.preview
LINKS_DATA.interview2 = LINKS_DATA.interview
LINKS_DATA.recap = LINKS_DATA.review

local UNIFORM_MATCH = 'uniform'
local TBD = 'TBD'

---Custom Class for displaying game details in submatches
---@class StarcraftMatchSummarySubmatchRow: MatchSummaryRowInterface
---@operator call: StarcraftMatchSummarySubmatchRow
---@field root Html
local StarcraftMatchSummarySubmatchRow = Class.new(
	function(self)
		self.root = mw.html.create('div'):addClass('brkts-popup-sc-submatch')
	end
)

---@param element Html|string|nil
---@return self
function StarcraftMatchSummarySubmatchRow:addElement(element)
	self.root:node(element)
	return self
end

---@return Html
function StarcraftMatchSummarySubmatchRow:create()
	return self.root
end

local StarcraftMatchSummary = {}

---@param args {bracketId: string, matchId: string, config: table?}
---@return Html
function StarcraftMatchSummary.MatchSummaryContainer(args)
	--can not use commons due to ffa stuff and sc/sc2/wc specific classes
	local match, bracketResetMatch =
		MatchGroupUtil.fetchMatchForBracketDisplay(args.bracketId, args.matchId)
	---@cast match StarcraftMatchGroupUtilMatch
	---@cast bracketResetMatch StarcraftMatchGroupUtilMatch?

	if match.isFfa then
		return Lua.import('Module:MatchSummary/Ffa/Starcraft').FfaMatchSummary{
			match = match,
			bracketResetMatch = bracketResetMatch,
			config = args.config
		}
	end

	local matchSummary = MatchSummary():init()
		:addClass('brkts-popup-sc')
		:addClass(match.opponentMode ~= UNIFORM_MATCH and 'brkts-popup-sc-team-match' or nil)

	--additional header for when martin adds the the css and buttons for switching between match and reset match
	--if bracketResetMatch then
		--local createHeader = CustomMatchSummary.createHeader or MatchSummary.createDefaultHeader
		--matchSummary:header(createHeader(match, {noScore = true, teamStyle = options.teamStyle}))
		--here martin can add the buttons for switching between match and reset match
	--end

	matchSummary:addMatch(MatchSummary.createMatch(match, StarcraftMatchSummary))
	matchSummary:addMatch(MatchSummary.createMatch(bracketResetMatch, StarcraftMatchSummary))

	return matchSummary:create()
end

---@param match StarcraftMatchGroupUtilMatch
---@param footer MatchSummaryFooter
---@return MatchSummaryFooter
function StarcraftMatchSummary.addToFooter(match, footer)
	footer = MatchSummary.addVodsToFooter(match, footer)

	if not match.headToHead or #match.opponents ~= 2 or Array.any(match.opponents, function(opponent)
		return opponent.type ~= Opponent.solo or not ((opponent.players or {})[1] or {}).pageName end)
	then
		return footer:addLinks(LINKS_DATA, match.links)
	end
	match.links.h2h = tostring(mw.uri.fullUrl('Special:RunQuery/Match_history'))
		.. '?pfRunQueryFormName=Match+history&Head_to_head_query%5Bplayer%5D='
		.. match.opponents[1].players[1].pageName
		.. '&Head_to_head_query%5Bopponent%5D='
		.. match.opponents[2].players[1].pageName
		.. '&wpRunQuery=Run+query'
	match.links.h2h = string.gsub(match.links.h2h, ' ', '_')

	return footer:addLinks(LINKS_DATA, match.links)
end

---@param match StarcraftMatchGroupUtilMatch
---@return MatchSummaryBody
function StarcraftMatchSummary.createBody(match)
	StarcraftMatchSummary.computeOffFactions(match)

	local body = MatchSummary.Body()

	--this if can be removed once the "switching between match and reset match" stuff has been implemented
	if String.endsWith(match.matchId, '_RxMBR') then
		body:addRow(MatchSummary.Row()
			:addClass('brkts-popup-sc-veto-center')
			:css('line-height', '80%')
			:css('font-weight', 'bold')
			:addElement('Reset match')
		)
	end

	-- Stream, date, and countdown
	if match.dateIsExact then
		body:addRow(MatchSummary.Row():addElement(
			DisplayHelper.MatchCountdownBlock(match)
		):addClass('brkts-popup-countdown'))
	end

	-- add a comment if there is a pre match map advantage
	for _, opponent in ipairs(match.opponents or {}) do
		StarcraftMatchSummary.addAdvantagePenaltyInfo(body, opponent)
	end

	if match.opponentMode == UNIFORM_MATCH then
		Array.forEach(match.games, function(game)
			body:addRow(MatchSummary.Row():addClass('brkts-popup-sc-game')
				:addElements(StarcraftMatchSummary.Game(game))) end)
	else -- team games
		-- Show the submatch score if any submatch consists of more than one game
		-- or if the Map name starts with 'Submatch' (and the submatch has a game)
		local showScore = Array.any(match.submatches, function(submatch)
			return #submatch.games > 1
				or #submatch.games == 1 and String.startsWith(submatch.games[1].map or '', 'Submatch')
		end)

		Array.forEach(match.submatches, function(submatch)
			body:addRow(StarcraftMatchSummary.TeamSubmatch{submatch = submatch, showScore = showScore}) end)
	end

	if Table.isNotEmpty(match.vetoes) then
		-- add Veto Header
		body:addRow(MatchSummary.Row():addClass('brkts-popup-sc-game-header brkts-popup-sc-veto-center'):addElement('Vetoes'))
	end
	Array.forEach(match.vetoes, function(veto)
		body:addRow(StarcraftMatchSummary.Veto(veto))
	end)

	if match.casters then
		body:addRow(MatchSummary.makeCastersRow(match.casters))
	end

	return body
end

---@param match StarcraftMatchGroupUtilMatch
function StarcraftMatchSummary.computeOffFactions(match)
	if match.opponentMode == UNIFORM_MATCH then
		StarcraftMatchSummary.computeMatchOffFactions(match)
	else
		for _, submatch in pairs(match.submatches) do
			StarcraftMatchSummary.computeMatchOffFactions(submatch)
		end
	end
end

---@param match StarcraftMatchGroupUtilMatch|StarcraftMatchGroupUtilSubmatch
function StarcraftMatchSummary.computeMatchOffFactions(match)
	for _, game in ipairs(match.games) do
		game.offFactions = {}
		for opponentIndex, gameOpponent in pairs(game.opponents) do
			game.offFactions[opponentIndex] = MatchGroupUtilStarcraft.computeOffFactions(
				gameOpponent,
				match.opponents[opponentIndex]
			)
		end
	end
end

---@param body MatchSummaryBody
---@param opponent StarcraftStandardOpponent
function StarcraftMatchSummary.addAdvantagePenaltyInfo(body, opponent)
	local extradata = opponent.extradata or {}
	if not Logic.isNumeric(extradata.advantage) and not Logic.isNumeric(extradata.penalty) then
		return
	end
	local infoType = Logic.isNumeric(extradata.advantage) and 'advantage' or 'penalty'
	local value = tonumber(extradata.advantage) or tonumber(extradata.penalty)

	body:addRow(MatchSummary.Row():addClass('brkts-popup-sc-game-center')
		:addElement(mw.html.create():node(OpponentDisplay.InlineOpponent{
			opponent = Opponent.isTbd(opponent) and Opponent.tbd() or opponent,
			showFlag = false,
			showLink = true,
			showFaction = false,
			teamStyle = 'short',
		}):wikitext(' starts with a ' .. value .. ' map ' .. infoType .. '.')))
end

---@param game StarcraftMatchGroupUtilGame
---@param options {noLink: boolean}?
---@return (Html|string)[]
function StarcraftMatchSummary.Game(game, options)
	options = options or {}
	options.noLink = options.noLink or (game.map or ''):upper() == TBD
	local getWinnerIcon = function(opponentIndex)
		return StarcraftMatchSummary.toIcon(game.resultType == 'draw' and 'yellowLine'
			or game.winner == opponentIndex and 'greenCheck')
	end

	local showOffFactionIcons = game.offFactions ~= nil and (game.offFactions[1] ~= nil or game.offFactions[2] ~= nil)
	local offFactionIcons = function(opponentIndex)
		local offFactions = game.offFactions ~= nil and game.offFactions[opponentIndex] or nil
		local opponent = game.opponents ~= nil and game.opponents[opponentIndex] or nil

		if offFactions and opponent and opponent.isArchon then
			return StarcraftMatchSummary.OffFactionIcons({offFactions[1]})
		elseif offFactions and opponent then
			return StarcraftMatchSummary.OffFactionIcons(offFactions)
		elseif showOffFactionIcons then
			return StarcraftMatchSummary.OffFactionIcons({})
		else
			return nil
		end
	end

	local gameNodes = {StarcraftMatchSummary.GameHeader(game.header)}

	local centerNode = mw.html.create('div'):addClass('brkts-popup-sc-game-center')
		:wikitext(DisplayHelper.MapAndStatus(game, options))

	table.insert(gameNodes, mw.html.create('div')
		:addClass('brkts-popup-sc-game-body')
		:node(getWinnerIcon(1))
		:node(offFactionIcons(1))
		:node(centerNode)
		:node(offFactionIcons(2))
		:node(getWinnerIcon(2))
	)

	if (game.extradata or {}).server then
		table.insert(gameNodes, mw.html.create('div'):addClass('brkts-popup-sc-game-comment')
			:wikitext('Played server: ' .. (game.extradata or {}).server))
	end

	if game.comment then
		table.insert(gameNodes, mw.html.create('div'):addClass('brkts-popup-sc-game-comment'):wikitext(game.comment))
	end

	return gameNodes
end

---Renders off-factions as Nx2 grid of tiny icons
---@param factions string[]
---@return Html
function StarcraftMatchSummary.OffFactionIcons(factions)
	local factionsNode = mw.html.create('div')
		:addClass('brkts-popup-sc-game-offrace-icons')
	for _, faction in ipairs(factions) do
		factionsNode:node(Faction.Icon{size = '12px', faction = faction})
	end

	return factionsNode
end

---@param header string|number|nil
---@return Html?
function StarcraftMatchSummary.GameHeader(header)
	if not header then return end
	return mw.html.create('div')
		:addClass('brkts-popup-sc-game-header')
		:wikitext(header)
end

---@param props {submatch: StarcraftMatchGroupUtilSubmatch, showScore: boolean}
---@return StarcraftMatchSummarySubmatchRow
function StarcraftMatchSummary.TeamSubmatch(props)
	local submatch = props.submatch

	local centerNode = mw.html.create('div'):addClass('brkts-popup-sc-submatch-center')
	Array.forEach(submatch.games, function(game)
		if not game.map and not game.winner then return end
		for _, node in ipairs(StarcraftMatchSummary.Game(game, {noLink = String.startsWith(game.map or '', 'Submatch')})) do
			centerNode:node(node)
		end
	end)

	local renderOpponent = function(opponentIndex)
		local opponent = submatch.opponents[opponentIndex]
		local node = opponent
			and OpponentDisplay.BlockOpponent({
				opponent = opponent --[[@as standardOpponent]],
				flip = opponentIndex == 1,
			})
			or mw.html.create('div'):wikitext('&nbsp;')
		return node:addClass('brkts-popup-sc-submatch-opponent')
	end

	local hasNonZeroScore = Array.any(submatch.scores, function(score) return score ~= 0 end)
	local hasPlayers = Array.any(submatch.opponents, function(opponent) return Logic.isNotEmpty(opponent.players) end)

	local renderScore = function(opponentIndex)
		local isWinner = opponentIndex == submatch.winner
		local text
		if submatch.resultType == 'default' then
			text = isWinner and 'W' or submatch.walkover:upper()
		elseif submatch.resultType == 'np' then
			text = ''
		elseif hasNonZeroScore or hasPlayers then
			local score = submatch.scores[opponentIndex]
			text = score and tostring(score) or ''
		end
		return mw.html.create('div')
			:addClass('brkts-popup-sc-submatch-score')
			:wikitext(text)
	end

	local renderSide = function(opponentIndex)
		local sideNode = mw.html.create('div')
			:addClass('brkts-popup-sc-submatch-side')
			:addClass(opponentIndex == 1 and 'brkts-popup-left' or 'brkts-popup-right')
			:addClass(opponentIndex == submatch.winner and 'bg-win' or nil)
			:addClass(submatch.resultType == 'draw' and 'bg-draw' or nil)
			:node(opponentIndex == 1 and renderOpponent(1) or nil)
			:node(props.showScore and renderScore(opponentIndex) or nil)
			:node(opponentIndex == 2 and renderOpponent(2) or nil)

		return sideNode
	end

	local bodyNode = mw.html.create('div')
		:addClass('brkts-popup-sc-submatch-body')
		:addClass(props.showScore and 'brkts-popup-sc-submatch-has-score' or nil)
		:node(renderSide(1))
		:node(centerNode)
		:node(renderSide(2))

	local headerNode
	if submatch.header then
		headerNode = mw.html.create('div')
			:addClass('brkts-popup-sc-submatch-header')
			:wikitext(submatch.header)
	end

	return StarcraftMatchSummarySubmatchRow():addElement(headerNode):addElement(bodyNode)
end

---@param veto StarcraftMatchGroupUtilVeto
---@return MatchSummaryRow
function StarcraftMatchSummary.Veto(veto)
	local statusIcon = function(opponentIndex)
		return StarcraftMatchSummary.toIcon(opponentIndex == veto.by and 'redCross')
	end

	local map = veto.map or TBD
	if veto.displayName then
		map = '[[' .. map .. '|' .. veto.displayName .. ']]'
	elseif map:upper() ~= TBD then
		map = '[[' .. map .. ']]'
	end

	return MatchSummary.Row():addClass('brkts-popup-sc-veto-body')
		:addElement(statusIcon(1))
		:addElement(mw.html.create('div'):addClass('brkts-popup-sc-veto-center')
			:wikitext(map))
		:addElement(statusIcon(2))
end

---@param key string|boolean|nil
---@return string
function StarcraftMatchSummary.toIcon(key)
	return ICONS[key] or ICONS.noCheck
end

return StarcraftMatchSummary
