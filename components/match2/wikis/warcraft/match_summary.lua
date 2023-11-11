---
-- @Liquipedia
-- wiki=warcraft
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Faction = require('Module:Faction')
local HeroData = mw.loadData('Module:HeroData')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper', {requireDevIfEnabled = true})
local MatchSummary = Lua.import('Module:MatchSummary/Base', {requireDevIfEnabled = true})
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom', {requireDevIfEnabled = true})

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent
local OpponentDisplay = OpponentLibraries.OpponentDisplay

local ICONS = {
	greenCheck = '<i class="fa fa-check forest-green-text" style="width: 14px; text-align: center" ></i>',
	yellowLine = '<i class="fas fa-minus bright-sun-text" style="width: 14px; text-align: center" ></i>',
	yellowQuestionMark = '<i class="fas fa-question bright-sun-text" style="width: 14px; text-align: center" ></i>',
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
---@class WarcraftMatchSummarySubmatchCollapsible
---@operator call: WarcraftMatchSummarySubmatchCollapsible
---@field root Html
---@field table Html
local SubmatchCollapsible = Class.new(
	function(self, header)
		self.root = mw.html.create('div'):addClass('brkts-popup-mapveto'):css('width', '100%')
			:css('margin-bottom', '-8px')
		self.table = self.root:tag('table'):addClass('inherit-bg collapsible collapsed')

		self.table
			:tag('tr'):tag('th'):wikitext('Submatch Details')
	end
)

---@param gameNodes Html[]
---@return self
function SubmatchCollapsible:game(gameNodes)
	self.table:tag('tr'):tag('td'):node(MatchSummary.Row():addClass('brkts-popup-sc-game'):addClass('inherit-bg')
		:addElements(gameNodes):create())

	return self
end

---@return Html
function SubmatchCollapsible:create()
	return self.root
end

local CustomMatchSummary = {}

---@param args {bracketId: string, matchId: string, config: table?}
---@return Html
function CustomMatchSummary.getByMatchId(args)
	--can not use commons due to ffa stuff and sc/sc2/wc specific classes
	local match, bracketResetMatch =
		MatchGroupUtil.fetchMatchForBracketDisplay(args.bracketId, args.matchId, {returnBoth = true})

	if match.isFfa then
		error('FFA is not yet supported in warcraft match2')
		--later call ffa matchsummary from here
	end

	local matchSummary = MatchSummary():init('400px')
		:addClass('brkts-popup-sc')

	--additional header for when martin adds the the css and buttons for switching between match and reset match
	--if bracketResetMatch then
		--local createHeader = CustomMatchSummary.createHeader or MatchSummary.createDefaultHeader
		--matchSummary:header(createHeader(match, {noScore = true, teamStyle = options.teamStyle}))
		--here martin can add the buttons for switching between match and reset match
	--end

	matchSummary:addMatch(MatchSummary.createMatch(match, CustomMatchSummary))
	matchSummary:addMatch(MatchSummary.createMatch(bracketResetMatch, CustomMatchSummary))

	return matchSummary:create()
end

---@param match table
---@param footer MatchSummaryFooter
---@return MatchSummaryFooter
function CustomMatchSummary.addToFooter(match, footer)
	footer = MatchSummary.addVodsToFooter(match, footer)

	match.links.lrthread = match.links.lrthread or match.lrthread

	if not match.headToHead or #match.opponents ~= 2 or Array.any(match.opponents, function(opponent)
		return opponent.type ~= Opponent.solo or not ((opponent.players or {})[1] or {}).pageName end)
	then
		return footer:addLinks(LINKS_DATA, match.links)
	end

	match.links.h2h = tostring(mw.uri.fullUrl('Special:RunQuery/Head-to-Head'))
		.. '?pfRunQueryFormName=Head-to-Head&Head+to+head+query%5Bplayer%5D='
		.. match.opponents[1].players[1].pageName
		.. '&Head_to_head_query%5Bopponent%5D='
		.. match.opponents[2].players[1].pageName
		.. '&wpRunQuery=Run+query'
	match.links.h2h = string.gsub(match.links.h2h, ' ', '_')

	return footer:addLinks(LINKS_DATA, match.links)
end

---@param match table
---@return MatchSummaryBody
function CustomMatchSummary.createBody(match)
	CustomMatchSummary.computeOffraces(match)
	local hasHeroes = CustomMatchSummary.hasHeroes(match)

	local body = MatchSummary.Body()
	-- Stream, date, and countdown
	if match.dateIsExact then
		body:addRow(MatchSummary.Row():addElement(
			DisplayHelper.MatchCountdownBlock(match)
		):addClass('brkts-popup-countdown'))
	end

	-- add a comment if there is a pre match map advantage
	for _, opponent in ipairs(match.opponents or {}) do
		CustomMatchSummary.addAdvantagePenaltyInfo(body, opponent)
	end

	if match.opponentMode == UNIFORM_MATCH then
		Array.forEach(match.games, function(game)
			body:addRow(MatchSummary.Row():addClass('brkts-popup-sc-game')
				:addElements(CustomMatchSummary.Game(game, hasHeroes))) end)
	else -- team games
		Array.forEach(match.submatches, function(submatch)
			body:addRow(CustomMatchSummary.TeamSubmatch(submatch)) end)
	end

	if Table.isNotEmpty(match.vetoes) then
		-- add Veto Header
		body:addRow(MatchSummary.Row():addClass('brkts-popup-sc-game-header brkts-popup-sc-veto-center'):addElement('Vetoes'))
	end
	Array.forEach(match.vetoes, function(veto)
		body:addRow(CustomMatchSummary.Veto(veto))
	end)

	if match.casters then
		local casters = Json.parseIfString(match.casters)
		local casterRow = MatchSummary.Casters()
		for _, caster in pairs(casters) do
			casterRow:addCaster(caster)
		end

		body:addRow(casterRow)
	end

	return body
end

---@param match table
function CustomMatchSummary.computeOffraces(match)
	if match.opponentMode == UNIFORM_MATCH then
		CustomMatchSummary.computeMatchOffraces(match)
	else
		for _, submatch in pairs(match.submatches) do
			CustomMatchSummary.computeMatchOffraces(submatch)
		end
	end
end

---@param match table
function CustomMatchSummary.computeMatchOffraces(match)
	for _, game in ipairs(match.games) do
		game.offraces = {}
		for opponentIndex, gameOpponent in pairs(game.opponents) do
			game.offraces[opponentIndex] = MatchGroupUtil.computeOffraces(
				gameOpponent,
				match.opponents[opponentIndex]
			)
		end
	end
end

---@param match table
---@return boolean
function CustomMatchSummary.hasHeroes(match)
	return Array.any(match.games, function(game) return Table.any(game.participants, function(key, participant)
		return Table.isNotEmpty(participant.heroes)
	end) end)
end

---@param body MatchSummaryBody
---@param opponent WarcraftStandardOpponent
function CustomMatchSummary.addAdvantagePenaltyInfo(body, opponent)
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
			showRace = false,
			teamStyle = 'short',
		}):wikitext(' starts with a ' .. value .. ' map ' .. infoType .. '.')))
end

---@param game table
---@param hasHeroes boolean
---@return (Html|string)[]
function CustomMatchSummary.Game(game, hasHeroes)
	local getWinnerIcon = function(opponentIndex)
		return CustomMatchSummary.toIcon(game.resultType == 'draw' and 'yellowLine'
			or game.winner == opponentIndex and 'greenCheck')
	end

	local showOffraceIcons = game.offraces ~= nil and (game.offraces[1] ~= nil or game.offraces[2] ~= nil)
	local offraceIcons = function(opponentIndex)
		local offraces = game.offraces ~= nil and game.offraces[opponentIndex] or nil
		local opponent = game.opponents ~= nil and game.opponents[opponentIndex] or nil

		if offraces and opponent then
			return CustomMatchSummary.OffraceIcons(offraces)
		elseif showOffraceIcons then
			return CustomMatchSummary.OffraceIcons({})
		end
	end

	local gameNodes = {CustomMatchSummary.GameHeader(game.header)}

	local centerNode = mw.html.create('div'):addClass('brkts-popup-sc-game-center')
		:wikitext(DisplayHelper.MapAndStatus(game))

	table.insert(gameNodes, mw.html.create('div')
		:addClass('brkts-popup-sc-game-body')
		:node(CustomMatchSummary.DispalyHeroes(game.opponents[1], hasHeroes))
		:node(getWinnerIcon(1))
		:node(offraceIcons(1))
		:node(centerNode)
		:node(offraceIcons(2))
		:node(getWinnerIcon(2))
		:node(CustomMatchSummary.DispalyHeroes(game.opponents[2], hasHeroes, true))
	)

	if game.comment then
		table.insert(gameNodes, mw.html.create('div'):addClass('brkts-popup-sc-game-comment'):wikitext(game.comment))
	end

	return gameNodes
end

---Renders off-races as Nx2 grid of tiny icons
---@param races string[]
---@return Html
function CustomMatchSummary.OffraceIcons(races)
	local racesNode = mw.html.create('div')
		:addClass('brkts-popup-sc-game-offrace-icons')
	for _, race in ipairs(races) do
		racesNode:node(Faction.Icon{size = '12px', faction = race})
	end

	return racesNode
end

---@param header string|number|nil
---@return Html?
function CustomMatchSummary.GameHeader(header)
	if not header then return end
	return mw.html.create('div')
		:addClass('brkts-popup-sc-game-header')
		:wikitext(header)
end

---@param opponent table
---@param hasHeroes boolean
---@param flip boolean?
---@return Html?
function CustomMatchSummary.DispalyHeroes(opponent, hasHeroes, flip)
	if not hasHeroes then return end

	local heroes = Array.map(opponent.players or {{}}, function(player)
		local displays = Array.map(Array.range(1, 3), function(heroIndex)
			local data = HeroData[((player.heroes or {})[heroIndex] or ''):lower()] or HeroData.default
			local name = data.name or ''
			return mw.html.create('div')
				:addClass('brkts-popup-side-color-' .. (flip and 'blue' or 'red'))
				:css('float', flip and 'right' or 'left')
				:wikitext('[[File:' .. data.icon .. '|link=' .. name .. '|' .. name .. ']]')
		end)
		if flip then
			return Array.reverse(displays)
		end
		return displays
	end)

	local rowsDisplay = mw.html.create('div')
		:addClass('brkts-popup-body-element-vertical-centered')
		:css('flex-direction', 'column')
		:css('padding-' .. (flip and 'left' or 'right'), '8px')

	Array.forEach(heroes, function(displays)
		local row = mw.html.create('div')
			:addClass('brkts-popup-body-element-thumbs brkts-champion-icon')

		Array.forEach(displays, function(display) row:node(display) end)
		rowsDisplay:node(row)
	end)

	return rowsDisplay
end

---@param submatch table
---@return MatchSummaryRow
function CustomMatchSummary.TeamSubmatch(submatch)
	local submatchDisplay = MatchSummary.Row():addElement(CustomMatchSummary._submatchHeader(submatch))
	if not CustomMatchSummary._submatchHasDetails(submatch) then
		return submatchDisplay
	end

	local details = SubmatchCollapsible()
	for _, game in ipairs(submatch.games) do
		if game.map ~= 'Submatch Score Fix' then
			details:game(CustomMatchSummary.Game(game, true))
		end
	end

	return submatchDisplay:addElement(details:create()):css('margin-bottom', '8px')
end

---@param submatch table
---@return boolean
function CustomMatchSummary._submatchHasDetails(submatch)
	return #submatch.games > 0 and Array.any(submatch.games, function(game)
		return String.isNotEmpty(game.map) and game.map:upper() ~= TBD and not string.find(game.map, '^[sS]ubmatch %d+$')
			or Array.any(game.opponents, function(opponent) return Array.any(opponent.players, function(player)
				return Table.isNotEmpty(player.heroes) end) end)
	end)
end

---@param submatch table
---@return Html
function CustomMatchSummary._submatchHeader(submatch)
	local opponents = submatch.opponents or {{}, {}}

	local createOpponent = function(opponentIndex)
		local players = (opponents[opponentIndex] or {}).players or {}
		if Table.isEmpty(players) then
			players = Opponent.tbd(Opponent.solo).players
		end
		return OpponentDisplay.BlockOpponent{
			flip = opponentIndex == 1,
			opponent = {players = players, type = Opponent.partyTypes[math.max(#players, 1)]},
			showLink = true,
			overflow = 'ellipsis',
		}
	end

	local createScore = function(opponentIndex)
		local isWinner = opponentIndex == submatch.winner
		if submatch.resultType == 'default' then
			return OpponentDisplay.BlockScore{
				isWinner = isWinner,
				scoreText = isWinner and 'W' or submatch.walkover,
			}
		end
		return OpponentDisplay.BlockScore{
			isWinner = isWinner,
			scoreText = (submatch.scores or {})[opponentIndex] or '',
		}
	end

	return mw.html.create('div')
		:css('justify-content', 'center'):addClass('brkts-popup-header-dev')
		:tag('div'):addClass('brkts-popup-header-opponent'):addClass('brkts-popup-header-opponent-left')
			:node(createOpponent(1))
			:node(createScore(1):addClass('brkts-popup-header-opponent-score-left'))
			:done()
		:tag('div'):addClass('brkts-popup-header-opponent'):addClass('brkts-popup-header-opponent-right')
			:node(createScore(2):addClass('brkts-popup-header-opponent-score-right'))
			:node(createOpponent(2))
			:done()
end

---@param veto {map: string, by: number}
---@return MatchSummaryRow
function CustomMatchSummary.Veto(veto)
	local statusIcon = function(opponentIndex)
		return CustomMatchSummary.toIcon(opponentIndex == veto.by and 'redCross')
	end

	veto.map = veto.map or TBD

	return MatchSummary.Row():addClass('brkts-popup-sc-veto-body')
		:addElement(statusIcon(1))
		:addElement(mw.html.create('div'):addClass('brkts-popup-sc-veto-center')
			:wikitext(veto.map:upper() == TBD and TBD or ('[[' .. veto.map .. ']]')))
		:addElement(statusIcon(2))
end

---@param key string|boolean|nil
---@return string
function CustomMatchSummary.toIcon(key)
	return ICONS[key] or ICONS.noCheck
end

return CustomMatchSummary
