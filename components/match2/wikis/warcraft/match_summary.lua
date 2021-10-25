---
-- @Liquipedia
-- wiki=warcraft
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local DisplayHelper = require('Module:MatchGroup/Display/Helper')
local DisplayUtil = require('Module:DisplayUtil')
local Lua = require('Module:Lua')
local WarcraftMatchExternalLinks = require('Module:MatchExternalLinks/Warcraft')

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util', {requireDevIfEnabled = true})
local WarcraftMatchGroupUtil = Lua.import('Module:MatchGroup/Util/Warcraft', {requireDevIfEnabled = true})
local WarcraftOpponentDisplay = Lua.import('Module:OpponentDisplay/Warcraft', {requireDevIfEnabled = true})
local RaceIcon = Lua.requireIfExists('Module:RaceIcon') or {
	getTinyIcon = function() end,
}

local html = mw.html

--[[
Display component for the match summary used by the starcraft and stacraft2
wikis. Shows details of a StarCraft match, including opponents, maps,
submatches, and external media links.
]]
local WarcraftMatchSummary = {propTypes = {}}

WarcraftMatchSummary.propTypes.MatchSummaryContainer = {
	bracketId = 'string',
	matchId = 'string',
}

function WarcraftMatchSummary.MatchSummaryContainer(props)
	local match = MatchGroupUtil.fetchMatchForBracketDisplay(props.bracketId, props.matchId)
	local MatchSummary = match.isFfa
		and Lua.import('Module:MatchSummary/Ffa/Warcraft', {requireDevIfEnabled = true}).FfaMatchSummary
		or WarcraftMatchSummary.MatchSummary
	return MatchSummary({match = match})
end

WarcraftMatchSummary.propTypes.MatchSummary = {
	match = WarcraftMatchGroupUtil.types.Match,
}

function WarcraftMatchSummary.MatchSummary(props)
	DisplayUtil.assertPropTypes(props, WarcraftMatchSummary.propTypes.MatchSummary)
	local match = props.match

	-- Compute offraces
	if match.opponentMode == 'uniform' then
		WarcraftMatchSummary.computeMatchOffraces(match)
	else
		for _, submatch in pairs(match.submatches) do
			WarcraftMatchSummary.computeMatchOffraces(submatch)
		end
	end

	return html.create('div')
		:addClass('brkts-popup')
		:addClass('brkts-popup-wc')
		:addClass(match.opponentMode == 'uniform' and 'brkts-popup-wc-uniform-match' or 'brkts-popup-wc-team-match')
		:node(WarcraftMatchSummary.Header({match = match}))
		:node(WarcraftMatchSummary.Body({match = match}))
		:node(WarcraftMatchSummary.Footer({match = match, showHeadToHead = match.headToHead}))
end

WarcraftMatchSummary.propTypes.Header = {
	match = WarcraftMatchGroupUtil.types.Match,
}

function WarcraftMatchSummary.Header(props)
	DisplayUtil.assertPropTypes(props, WarcraftMatchSummary.propTypes.Header)
	local match = props.match

	local renderOpponent = function(opponentIx)
		local opponent = match.opponents[opponentIx]
		return WarcraftOpponentDisplay.BlockOpponent({
			flip = opponentIx == 1,
			opponent = opponent,
			overflow = 'wrap',
			showFlag = false,
			showLink = opponent.type == 'team',
		})
			:addClass('brkts-popup-header-opponent')
	end

	local header = html.create('div'):addClass('brkts-popup-header-dev')
		:node(renderOpponent(1))
		:node(renderOpponent(2))

	return header
end

WarcraftMatchSummary.propTypes.Body = {
	match = WarcraftMatchGroupUtil.types.Match,
}

function WarcraftMatchSummary.Body(props)
	DisplayUtil.assertPropTypes(props, WarcraftMatchSummary.propTypes.Body)
	local match = props.match

	local body = html.create('div')
		:addClass('brkts-popup-body')
		:addClass('brkts-popup-wc-body')

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
				body:node(WarcraftMatchSummary.Game(game):addClass('brkts-popup-body-element'))
			end
		end
	else -- match.opponentMode == 'team'

		-- Show the submatch score if any submatch consists of more than one game
		local showScore = Array.any(match.submatches, function(submatch) return 1 < #submatch.games end)

		for _, submatch in ipairs(match.submatches) do
			body:node(
				WarcraftMatchSummary.TeamSubmatch({submatch = submatch, showScore = showScore})
					:addClass('brkts-popup-body-element')
			)
		end
	end

	-- Vetoes
	for ix, veto in ipairs(match.vetoes) do
		local vetoNode = WarcraftMatchSummary.Veto(veto)
		if ix == 1 then
			vetoNode = html.create('div')
				:node(WarcraftMatchSummary.GameHeader({header = 'Vetoes'}))
				:node(vetoNode)
		end
		body:node(vetoNode:addClass('brkts-popup-body-element'))
	end

	-- Match casters
	if match.casters then
		body:node(
			html.create('div'):addClass('brkts-popup-wc-game-comment')
				:node('Caster(s): ' .. match.casters)
		)
	end

	-- Match comment
	if match.comment then
		body:node(
			html.create('div'):addClass('brkts-popup-wc-game-comment')
				:node(match.comment)
		)
	end

	return body
end

function WarcraftMatchSummary.Game(game)
	DisplayUtil.assertPropTypes(game, WarcraftMatchGroupUtil.types.Game.struct)

	local centerNode = html.create('div'):addClass('brkts-popup-wc-game-center')
		:wikitext(DisplayHelper.MapAndStatus(game))

	local winnerIcon = function(opponentIx)
		return game.resultType == 'draw' and WarcraftMatchSummary.ColoredIcon('YellowLine')
			or game.winner == opponentIx and WarcraftMatchSummary.ColoredIcon('GreenCheck')
			or WarcraftMatchSummary.ColoredIcon('NoCheck')
	end

	local showOffraceIcons = game.offraces ~= nil and (game.offraces[1] ~= nil or game.offraces[2] ~= nil)
	local offraceIcons = function(opponentIx)
		local offraces = game.offraces ~= nil and game.offraces[opponentIx] or nil
		local opponent = game.opponents ~= nil and game.opponents[opponentIx] or nil

		if offraces and opponent then
			return WarcraftMatchSummary.OffraceIcons(offraces)
		elseif showOffraceIcons then
			return WarcraftMatchSummary.OffraceIcons({})
		else
			return nil
		end
	end

	local bodyNode = html.create('div')
		:addClass('brkts-popup-wc-game-body')
		:node(winnerIcon(1))
		:node(offraceIcons(1))
		:node(centerNode)
		:node(offraceIcons(2))
		:node(winnerIcon(2))

	local commentNode
	if game.comment then
		commentNode = html.create('div')
			:addClass('brkts-popup-wc-game-comment')
			:wikitext(game.comment)
	end

	local gameNode = html.create('div')
		:addClass('brkts-popup-wc-game')
		:node(game.header and WarcraftMatchSummary.GameHeader({header = game.header}) or nil)
		:node(bodyNode)
		:node(commentNode)

	return gameNode
end

WarcraftMatchSummary.propTypes.TeamSubmatch = {
	showScore = 'boolean',
	submatch = WarcraftMatchGroupUtil.types.Submatch,
}

function WarcraftMatchSummary.TeamSubmatch(props)
	DisplayUtil.assertPropTypes(props, WarcraftMatchSummary.propTypes.TeamSubmatch)
	local submatch = props.submatch

	local centerNode = html.create('div')
		:addClass('brkts-popup-wc-submatch-center')
	for _, game in ipairs(submatch.games) do
		if game.map or game.winner then
			centerNode:node(WarcraftMatchSummary.Game(game))
		end
	end

	local renderOpponent = function(opponentIx)
		local opponent = submatch.opponents[opponentIx]
		local node = opponent
			and WarcraftOpponentDisplay.BlockOpponent({
				opponent = opponent,
				flip = opponentIx == 1,
			})
			or html.create('div'):wikitext('&nbsp;')
		return node:addClass('brkts-popup-wc-submatch-opponent')
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
			:addClass('brkts-popup-wc-submatch-score')
			:wikitext(text)
	end

	local renderSide = function(opponentIx)
		local sideNode = html.create('div')
			:addClass('brkts-popup-wc-submatch-side')
			:addClass(opponentIx == 1 and 'brkts-popup-left' or 'brkts-popup-right')
			:addClass(opponentIx == submatch.winner and 'bg-win' or nil)
			:addClass(submatch.resultType == 'draw' and 'bg-draw' or nil)
			:node(opponentIx == 1 and renderOpponent(1) or nil)
			:node(props.showScore and renderScore(opponentIx) or nil)
			:node(opponentIx == 2 and renderOpponent(2) or nil)

		return sideNode
	end

	local bodyNode = html.create('div')
		:addClass('brkts-popup-wc-submatch-body')
		:addClass(props.showScore and 'brkts-popup-wc-submatch-has-score' or nil)
		:node(renderSide(1))
		:node(centerNode)
		:node(renderSide(2))

	local headerNode
	if submatch.header then
		headerNode = html.create('div')
			:addClass('brkts-popup-wc-submatch-header')
			:wikitext(submatch.header)
	end

	local submatchNode = html.create('div')
		:addClass('brkts-popup-wc-submatch')
		:node(headerNode)
		:node(bodyNode)

	return submatchNode
end

WarcraftMatchSummary.propTypes.GameHeader = {
	header = 'string',
}

function WarcraftMatchSummary.GameHeader(props)
	DisplayUtil.assertPropTypes(props, WarcraftMatchSummary.propTypes.GameHeader)
	return html.create('div')
		:addClass('brkts-popup-wc-game-header')
		:wikitext(props.header)
end

function WarcraftMatchSummary.Veto(veto)
	DisplayUtil.assertPropTypes(veto, WarcraftMatchGroupUtil.types.MatchVeto.struct)

	local centerNode = html.create('div'):addClass('brkts-popup-wc-veto-center')
		:node('[[' .. veto.map .. ']]')

	local statusIcon = function(opponentIx)
		return opponentIx == veto.by
			and WarcraftMatchSummary.ColoredIcon('RedCross')
			or WarcraftMatchSummary.ColoredIcon('NoCheck')
	end

	return html.create('div')
		:addClass('brkts-popup-wc-veto-body')
		:node(statusIcon(1))
		:node(centerNode)
		:node(statusIcon(2))
end

WarcraftMatchSummary.propTypes.Footer = {
	match = WarcraftMatchGroupUtil.types.Match,
	showHeadToHead = 'boolean',
}

function WarcraftMatchSummary.Footer(props)
	DisplayUtil.assertPropTypes(props, WarcraftMatchSummary.propTypes.Footer)
	local match = props.match

	local links = WarcraftMatchExternalLinks.extractFromMatch(match)

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
		local linksNode = WarcraftMatchExternalLinks.MatchExternalLinks({links = links})
			:node(headToHeadNode)
			:addClass('brkts-popup-wc-footer-links')
		return html.create('div')
			:addClass('brkts-popup-footer')
			:addClass('brkts-popup-wc-footer')
			:node(linksNode)
	else
		return nil
	end
end

function WarcraftMatchSummary.ColoredIcon(icon)
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
function WarcraftMatchSummary.OffraceIcons(races)
	local racesNode = html.create('div')
		:addClass('brkts-popup-wc-game-offrace-icons')
	for _, race in ipairs(races) do
		racesNode:node(RaceIcon.getTinyIcon({race}))
	end

	return racesNode
end

--[[
Populate game.offraces if the played races differ from the races listed in the
match
]]
function WarcraftMatchSummary.computeMatchOffraces(match)
	for _, game in ipairs(match.games) do
		game.offraces = {}
		for opponentIx, gameOpponent in pairs(game.opponents) do
			game.offraces[opponentIx] = WarcraftMatchGroupUtil.computeOffraces(
				gameOpponent,
				match.opponents[opponentIx]
			)
		end
	end
end

return WarcraftMatchSummary
