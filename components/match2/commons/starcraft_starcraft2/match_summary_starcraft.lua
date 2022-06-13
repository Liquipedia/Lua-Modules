---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchSummary/Starcraft
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local DisplayUtil = require('Module:DisplayUtil')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local StarcraftMatchExternalLinks = require('Module:MatchExternalLinks/Starcraft')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper', {requireDevIfEnabled = true})
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util', {requireDevIfEnabled = true})
local StarcraftMatchGroupUtil = Lua.import('Module:MatchGroup/Util/Starcraft', {requireDevIfEnabled = true})
local StarcraftOpponentDisplay = Lua.import('Module:OpponentDisplay/Starcraft', {requireDevIfEnabled = true})
local RaceIcon = Lua.requireIfExists('Module:RaceIcon') or {
	getTinyIcon = function() end,
}

local html = mw.html

--[[
Display component for the match summary used by the starcraft and stacraft2
wikis. Shows details of a StarCraft match, including opponents, maps,
submatches, and external media links.
]]
local StarcraftMatchSummary = {propTypes = {}}

StarcraftMatchSummary.propTypes.MatchSummaryContainer = {
	bracketId = 'string',
	matchId = 'string',
	config = 'table?',
}

function StarcraftMatchSummary.MatchSummaryContainer(props)
	local match = MatchGroupUtil.fetchMatchForBracketDisplay(props.bracketId, props.matchId)
	match.submatches = StarcraftMatchGroupUtil.mergeResetSubmatches(match, props.bracketId)
	local MatchSummary = match.isFfa
		and Lua.import('Module:MatchSummary/Ffa/Starcraft', {requireDevIfEnabled = true}).FfaMatchSummary
		or StarcraftMatchSummary.MatchSummary
	return MatchSummary({match = match, config = props.config})
end

StarcraftMatchSummary.propTypes.MatchSummary = {
	match = StarcraftMatchGroupUtil.types.Match,
	config = 'table',
}

function StarcraftMatchSummary.MatchSummary(props)
	DisplayUtil.assertPropTypes(props, StarcraftMatchSummary.propTypes.MatchSummary)
	local match = props.match

	local propsConfig = props.config or {}
	local config = {
		showScore = propsConfig.showScore or false,
	}

	-- Compute offraces
	if match.opponentMode == 'uniform' then
		StarcraftMatchSummary.computeMatchOffraces(match)
	else
		for _, submatch in pairs(match.submatches) do
			StarcraftMatchSummary.computeMatchOffraces(submatch)
		end
	end

	return html.create('div')
		:addClass('brkts-popup')
		:addClass('brkts-popup-sc')
		:addClass(match.opponentMode == 'uniform' and 'brkts-popup-sc-uniform-match' or 'brkts-popup-sc-team-match')
		:node(StarcraftMatchSummary.Header({match = match, config = config}))
		:node(StarcraftMatchSummary.Body({match = match}))
		:node(StarcraftMatchSummary.Footer({match = match, showHeadToHead = match.headToHead}))
end

StarcraftMatchSummary.propTypes.Header = {
	match = StarcraftMatchGroupUtil.types.Match,
	config = 'table'
}

function StarcraftMatchSummary.Header(props)
	DisplayUtil.assertPropTypes(props, StarcraftMatchSummary.propTypes.Header)
	local match = props.match

	local showScore = props.config.showScore

	local renderOpponent = function(opponentIx)
		local opponent = match.opponents[opponentIx]
		local flip = opponentIx == 1
		local opponentDisplay = {}
		table.insert(opponentDisplay, StarcraftOpponentDisplay.BlockOpponent{
			flip = flip,
			opponent = opponent,
			overflow = 'wrap',
			showFlag = false,
			showLink = opponent.type == 'team' or showScore,
		})
		local side = (flip and 'left' or 'right')

		local display = html.create('div')

		if showScore then
			display:addClass('brkts-popup-header-opponent-' .. side)
				:addClass('brkts-popup-sc-header-opponent-with-score')

			local scoreDisplay = StarcraftOpponentDisplay.BlockScore{
				isWinner = opponent.placement == 1 or opponent.advances,
				scoreText = StarcraftOpponentDisplay.InlineScore(opponent),
			}
			scoreDisplay:addClass('brkts-popup-header-opponent-score-' .. side)
			table.insert(opponentDisplay, scoreDisplay)
		else
			display:addClass('brkts-popup-header-opponent')
		end
		if not flip then
			opponentDisplay = Array.reverse(opponentDisplay)
		end
		Array.extendWith(display.nodes, opponentDisplay)

		return display
	end
	local header = html.create('div'):addClass('brkts-popup-header-dev')
		:node(renderOpponent(1))
		:node(renderOpponent(2))

	return header
end

StarcraftMatchSummary.propTypes.Body = {
	match = StarcraftMatchGroupUtil.types.Match,
}

function StarcraftMatchSummary.Body(props)
	DisplayUtil.assertPropTypes(props, StarcraftMatchSummary.propTypes.Body)
	local match = props.match

	local body = html.create('div')
		:addClass('brkts-popup-body')
		:addClass('brkts-popup-sc-body')

	-- Stream, date, and countdown
	if match.dateIsExact then
		local countdownNode = DisplayHelper.MatchCountdownBlock(match)
			:addClass('brkts-popup-body-element')
			:addClass('brkts-popup-countdown')
		body:node(countdownNode)
	end

	if match.opponentMode == 'uniform' then
		for _, game in ipairs(match.games) do
			if game.map or game.winner then
				body:node(StarcraftMatchSummary.Game(game):addClass('brkts-popup-body-element'))
			end
		end
	else -- match.opponentMode == 'team'

		-- Show the submatch score if any submatch consists of more than one game
		-- or if the Map name starts with 'Submatch' (and the submatch has a game)
		local showScore = Array.any(match.submatches, function(submatch)
			return #submatch.games > 1
				or #submatch.games == 1 and String.startsWith(submatch.games[1].map or '', 'Submatch')
		end)

		for _, submatch in ipairs(match.submatches) do
			body:node(
				StarcraftMatchSummary.TeamSubmatch({submatch = submatch, showScore = showScore})
					:addClass('brkts-popup-body-element')
			)
		end
	end

	-- Vetoes
	for ix, veto in ipairs(match.vetoes) do
		local vetoNode = StarcraftMatchSummary.Veto(veto)
		if ix == 1 then
			body:node(StarcraftMatchSummary.VetoHeader{header = 'Vetoes'})
		end
		body:node(vetoNode:addClass('brkts-popup-body-element'))
	end

	-- Match casters
	if match.casters then
		body:node(
			html.create('div'):addClass('brkts-popup-body-element brkts-popup-sc-game-comment')
				:node('Caster(s): ' .. match.casters)
		)
	end

	-- Match comment
	if match.comment then
		body:node(
			html.create('div'):addClass('brkts-popup-sc-game-comment')
				:node(match.comment)
		)
	end

	return body
end

function StarcraftMatchSummary.Game(game, config)
	DisplayUtil.assertPropTypes(game, StarcraftMatchGroupUtil.types.Game.struct)

	local centerNode = html.create('div'):addClass('brkts-popup-sc-game-center')
		:wikitext(DisplayHelper.MapAndStatus(game, config))

	local winnerIcon = function(opponentIx)
		return game.resultType == 'draw' and StarcraftMatchSummary.ColoredIcon('YellowLine')
			or game.winner == opponentIx and StarcraftMatchSummary.ColoredIcon('GreenCheck')
			or StarcraftMatchSummary.ColoredIcon('NoCheck')
	end

	local showOffraceIcons = game.offraces ~= nil and (game.offraces[1] ~= nil or game.offraces[2] ~= nil)
	local offraceIcons = function(opponentIx)
		local offraces = game.offraces ~= nil and game.offraces[opponentIx] or nil
		local opponent = game.opponents ~= nil and game.opponents[opponentIx] or nil

		if offraces and opponent then
			if opponent.isArchon then
				return StarcraftMatchSummary.OffraceIcons({offraces[1]})
			else
				return StarcraftMatchSummary.OffraceIcons(offraces)
			end
		elseif showOffraceIcons then
			return StarcraftMatchSummary.OffraceIcons({})
		else
			return nil
		end
	end

	local bodyNode = html.create('div')
		:addClass('brkts-popup-sc-game-body')
		:node(winnerIcon(1))
		:node(offraceIcons(1))
		:node(centerNode)
		:node(offraceIcons(2))
		:node(winnerIcon(2))

	local commentNode
	if game.comment then
		commentNode = html.create('div')
			:addClass('brkts-popup-sc-game-comment')
			:wikitext(game.comment)
	end

	local serverNode
	if (game.extradata or {}).server then
		serverNode = html.create('div')
			:addClass('brkts-popup-sc-game-comment')
			:wikitext('Played server: ' .. game.extradata.server)
	end

	local gameNode = html.create('div')
		:addClass('brkts-popup-sc-game')
		:node(game.header and StarcraftMatchSummary.GameHeader({header = game.header}) or nil)
		:node(bodyNode)
		:node(serverNode)
		:node(commentNode)

	return gameNode
end

StarcraftMatchSummary.propTypes.TeamSubmatch = {
	showScore = 'boolean',
	submatch = StarcraftMatchGroupUtil.types.Submatch,
}

function StarcraftMatchSummary.TeamSubmatch(props)
	DisplayUtil.assertPropTypes(props, StarcraftMatchSummary.propTypes.TeamSubmatch)
	local submatch = props.submatch

	local centerNode = html.create('div')
		:addClass('brkts-popup-sc-submatch-center')
	for _, game in ipairs(submatch.games) do
		if game.map or game.winner then
			centerNode:node(StarcraftMatchSummary.Game(
					game,
					{noLink = String.startsWith(game.map or '', 'Submatch')}
				)
			)
		end
	end

	local renderOpponent = function(opponentIx)
		local opponent = submatch.opponents[opponentIx]
		local node = opponent
			and StarcraftOpponentDisplay.BlockOpponent({
				opponent = opponent,
				flip = opponentIx == 1,
			})
			or html.create('div'):wikitext('&nbsp;')
		return node:addClass('brkts-popup-sc-submatch-opponent')
	end

	-- Render scores
	local renderScore = function(opponentIx)
		local isWinner = opponentIx == submatch.winner
		local text
		if submatch.resultType == 'default' then
			text = isWinner and 'W' or submatch.walkover
		else
			local score = submatch.scores[opponentIx]
			text = score and tostring(score) or ''
		end
		return html.create('div')
			:addClass('brkts-popup-sc-submatch-score')
			:wikitext(text)
	end

	local renderSide = function(opponentIx)
		local sideNode = html.create('div')
			:addClass('brkts-popup-sc-submatch-side')
			:addClass(opponentIx == 1 and 'brkts-popup-left' or 'brkts-popup-right')
			:addClass(opponentIx == submatch.winner and 'bg-win' or nil)
			:addClass(submatch.resultType == 'draw' and 'bg-draw' or nil)
			:node(opponentIx == 1 and renderOpponent(1) or nil)
			:node(props.showScore and renderScore(opponentIx) or nil)
			:node(opponentIx == 2 and renderOpponent(2) or nil)

		return sideNode
	end

	local bodyNode = html.create('div')
		:addClass('brkts-popup-sc-submatch-body')
		:addClass(props.showScore and 'brkts-popup-sc-submatch-has-score' or nil)
		:node(renderSide(1))
		:node(centerNode)
		:node(renderSide(2))

	local headerNode
	if submatch.header then
		headerNode = html.create('div')
			:addClass('brkts-popup-sc-submatch-header')
			:wikitext(submatch.header)
	end

	local submatchNode = html.create('div')
		:addClass('brkts-popup-sc-submatch')
		:node(headerNode)
		:node(bodyNode)

	return submatchNode
end

StarcraftMatchSummary.propTypes.GameHeader = {
	header = 'string',
}

function StarcraftMatchSummary.GameHeader(props)
	DisplayUtil.assertPropTypes(props, StarcraftMatchSummary.propTypes.GameHeader)
	return html.create('div')
		:addClass('brkts-popup-sc-game-header')
		:wikitext(props.header)
end

StarcraftMatchSummary.propTypes.VetoHeader = {
	header = 'string',
}

function StarcraftMatchSummary.VetoHeader(props)
	DisplayUtil.assertPropTypes(props, StarcraftMatchSummary.propTypes.VetoHeader)
	return html.create('div')
		:addClass('brkts-popup-body-element brkts-popup-sc-game-header brkts-popup-sc-veto-center')
		:wikitext(props.header)
end

function StarcraftMatchSummary.Veto(veto)
	DisplayUtil.assertPropTypes(veto, StarcraftMatchGroupUtil.types.MatchVeto.struct)

	local centerNode = html.create('div'):addClass('brkts-popup-sc-veto-center')
		:node('[[' .. veto.map .. ']]')

	local statusIcon = function(opponentIx)
		return opponentIx == veto.by
			and StarcraftMatchSummary.ColoredIcon('RedCross')
			or StarcraftMatchSummary.ColoredIcon('NoCheck')
	end

	return html.create('div')
		:addClass('brkts-popup-sc-veto-body')
		:node(statusIcon(1))
		:node(centerNode)
		:node(statusIcon(2))
end

StarcraftMatchSummary.propTypes.Footer = {
	match = StarcraftMatchGroupUtil.types.Match,
	showHeadToHead = 'boolean',
}

function StarcraftMatchSummary.Footer(props)
	DisplayUtil.assertPropTypes(props, StarcraftMatchSummary.propTypes.Footer)
	local match = props.match

	local links = StarcraftMatchExternalLinks.extractFromMatch(match)

	local headToHeadNode
	if props.showHeadToHead
		and match.mode == '1_1'
		and match.opponents[1].players[1]
		and match.opponents[1].players[1].pageName
		and match.opponents[2].players[1]
		and match.opponents[2].players[1].pageName
	then
		local link = tostring(mw.uri.fullUrl('Special:RunQuery/Match_history'))
			.. '?pfRunQueryFormName=Match+history&Head_to_head_query%5Bplayer%5D='
			.. match.opponents[1].players[1].pageName
			.. '&Head_to_head_query%5Bopponent%5D='
			.. match.opponents[2].players[1].pageName
			.. '&wpRunQuery=Run+query'
		link = string.gsub(link, ' ', '_')
		headToHeadNode = '[[File:Match Info Stats.png|link=' .. link .. '|16px|Head-to-head statistics]]'
	end

	local hasFooter = (0 < #links) or headToHeadNode
	if hasFooter then
		local linksNode = StarcraftMatchExternalLinks.MatchExternalLinks({links = links})
			:node(headToHeadNode)
			:addClass('brkts-popup-sc-footer-links')
		return html.create('div')
			:addClass('brkts-popup-footer')
			:addClass('brkts-popup-sc-footer')
			:node(linksNode)
	else
		return nil
	end
end

function StarcraftMatchSummary.ColoredIcon(icon)
	if icon == 'GreenCheck' then
		return '<i class="fa fa-check forest-green-text" style="width: 14px; text-align: center" ></i>'
	elseif icon == 'YellowLine' then
		return '<i class="fas fa-minus bright-sun-text" style="width: 14px; text-align: center" ></i>'
	elseif icon == 'YellowQuestionMark' then
		return '[[File:YellowQuestionMark.png|14x14px|link=]]'
	elseif icon == 'RedCross' then
		return '<i class="fas fa-times cinnabar-text" style="width: 14px; text-align: center" ></i>'
	elseif icon == 'NoCheck' then
		return '[[File:NoCheck.png|link=]]'
	else
		return nil
	end
end

-- Renders off-races as Nx2 grid of tiny icons
function StarcraftMatchSummary.OffraceIcons(races)
	local racesNode = html.create('div')
		:addClass('brkts-popup-sc-game-offrace-icons')
	for _, race in ipairs(races) do
		racesNode:node(RaceIcon.getTinyIcon({race}))
	end

	return racesNode
end

--[[
Populate game.offraces if the played races differ from the races listed in the
match
]]
function StarcraftMatchSummary.computeMatchOffraces(match)
	for _, game in ipairs(match.games) do
		game.offraces = {}
		for opponentIx, gameOpponent in pairs(game.opponents) do
			game.offraces[opponentIx] = StarcraftMatchGroupUtil.computeOffraces(
				gameOpponent,
				match.opponents[opponentIx]
			)
		end
	end
end

return StarcraftMatchSummary
