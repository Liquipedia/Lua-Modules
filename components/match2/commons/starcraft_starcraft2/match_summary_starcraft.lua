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
local FnUtil = require('Module:FnUtil')
local Icon = require('Module:Icon')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util')
local MatchGroupUtilStarcraft = Lua.import('Module:MatchGroup/Util/Starcraft')
local WidgetUtil = Lua.import('Module:Widget/Util')

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent
local OpponentDisplay = OpponentLibraries.OpponentDisplay

local ICONS = {
	veto = Icon.makeIcon{iconName = 'veto', color = 'cinnabar-text', size = '110%'},
	noCheck = '[[File:NoCheck.png|link=|16px]]',
}

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
function StarcraftMatchSummary.getByMatchId(args)
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

	return MatchSummary.defaultGetByMatchId(StarcraftMatchSummary, args, {
		width = match.opponentMode ~= UNIFORM_MATCH and '500px' or nil,
	}):addClass('brkts-popup-sc')
end

---@param match StarcraftMatchGroupUtilMatch
---@return MatchSummaryBody
function StarcraftMatchSummary.createBody(match)
	StarcraftMatchSummary.computeOffFactions(match)

	local isResetMatch = String.endsWith(match.matchId, '_RxMBR')
	local subMatches
	local showSubMatchScore
	if match.opponentMode ~= UNIFORM_MATCH then
		subMatches = match.submatches or {}
		showSubMatchScore = Array.any(subMatches, function(submatch)
			return #submatch.games > 1
				or #submatch.games == 1 and String.startsWith(submatch.games[1].map or '', 'Submatch')
		end)
	end

	return MatchSummaryWidgets.Body{children = WidgetUtil.collect(
		isResetMatch and MatchSummaryWidgets.Row{
			classes = {'brkts-popup-sc-veto-center'},
			css = {['line-height'] = '80%', ['font-weight'] = 'bold'},
			children = {'Reset match'},
		} or nil,
		match.dateIsExact and MatchSummaryWidgets.Row{children = DisplayHelper.MatchCountdownBlock(match)} or nil,
		Array.map(match.opponents, StarcraftMatchSummary.advantageOrPenalty),
		subMatches and Array.map(subMatches, FnUtil.curry(StarcraftMatchSummary.TeamSubmatch, showSubMatchScore))
			or Array.map(match.games, FnUtil.curry(StarcraftMatchSummary.Game, {})),
		Logic.isNotEmpty(match.vetoes) and MatchSummaryWidgets.Row{
			classes = {'brkts-popup-sc-game-header brkts-popup-sc-veto-center'},
			children = {'Vetoes'},
		} or nil,
		Array.map(match.vetoes or {}, StarcraftMatchSummary.Veto) or nil,
		MatchSummaryWidgets.Casters{casters = match.casters}
	)}
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

---@param opponent StarcraftStandardOpponent
---@return Widget?
function StarcraftMatchSummary.advantageOrPenalty(opponent)
	local extradata = opponent.extradata or {}
	if not Logic.isNumeric(extradata.advantage) and not Logic.isNumeric(extradata.penalty) then
		return nil
	end
	local infoType = Logic.isNumeric(extradata.advantage) and 'advantage' or 'penalty'
	local value = tonumber(extradata.advantage) or tonumber(extradata.penalty)

	return MatchSummaryWidgets.Row{
		classes = {'brkts-popup-sc-game-center'},
		children = {
			OpponentDisplay.InlineOpponent{
				opponent = Opponent.isTbd(opponent) and Opponent.tbd() or opponent,
				showFlag = false,
				showLink = true,
				showFaction = false,
				teamStyle = 'short',
			},
			' starts with a ' .. value .. ' map ' .. infoType .. '.',
		},
	}
end

---@param options {noLink: boolean?}
---@param game StarcraftMatchGroupUtilGame
---@return MatchSummaryRow
function StarcraftMatchSummary.Game(options, game)
	options.noLink = options.noLink or (game.map or ''):upper() == TBD

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

	return MatchSummaryWidgets.Row{
		classes = {'brkts-popup-body-game'},
		children = WidgetUtil.collect(
			game.header and {
				HtmlWidgets.Div{css = {margin = 'auto'},  children = {game.header}},
				MatchSummaryWidgets.Break{},
			} or nil,
			MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 1},
			offFactionIcons(1),
			MatchSummaryWidgets.GameCenter{children = DisplayHelper.MapAndStatus(game, options)},
			offFactionIcons(2),
			MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 2},
			MatchSummaryWidgets.GameComment{
				children = (game.extradata or {}).server and ('Played server: ' .. (game.extradata or {}).server) or nil,
				classes = {'brkts-popup-sc-game-comment'},
			},
			MatchSummaryWidgets.GameComment{children = game.comment, classes = {'brkts-popup-sc-game-comment'}}
		)
	}
end

---Renders off-factions as Nx2 grid of tiny icons
---@param factions string[]
---@return Html
function StarcraftMatchSummary.OffFactionIcons(factions)
	return HtmlWidgets.Div{
		classes = {'brkts-popup-sc-game-offrace-icons brkts-popup-spaced'},
		children = Array.map(factions, function(faction)
			return Faction.Icon{size = '12px', faction = faction}
		end),
	}
end

---@param showScore boolean
---@param submatch StarcraftMatchGroupUtilSubmatch
---@return StarcraftMatchSummarySubmatchRow
function StarcraftMatchSummary.TeamSubmatch(showScore, submatch)
	local centerNode = mw.html.create('div'):addClass('brkts-popup-sc-submatch-center')
	Array.forEach(submatch.games, function(game)
		if not game.map and not game.winner then return end
		for _, node in ipairs(StarcraftMatchSummary.Game({noLink = String.startsWith(game.map or '', 'Submatch')}, game)) do
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
			:node(showScore and renderScore(opponentIndex) or nil)
			:node(opponentIndex == 2 and renderOpponent(2) or nil)

		return sideNode
	end

	local bodyNode = mw.html.create('div')
		:addClass('brkts-popup-sc-submatch-body')
		:addClass(showScore and 'brkts-popup-sc-submatch-has-score' or nil)
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
		return opponentIndex == veto.by and ICONS.veto or ICONS.noCheck
	end

	local map = veto.map or TBD
	if veto.displayName then
		map = '[[' .. map .. '|' .. veto.displayName .. ']]'
	elseif map:upper() ~= TBD then
		map = '[[' .. map .. ']]'
	end

	return MatchSummaryWidgets.Row{
		classes = {'brkts-popup-body-game'},
		children = {
			HtmlWidgets.Div{
				classes = {'brkts-popup-spaced brkts-popup-winloss-icon'},
				children = {statusIcon(1)},
			},
			HtmlWidgets.Div{
				classes = {'brkts-popup-sc-veto-center'},
				children = {map},
			},
			HtmlWidgets.Div{
				classes = {'brkts-popup-spaced brkts-popup-winloss-icon'},
				children = {statusIcon(2)},
			}
		},
	}
end

return StarcraftMatchSummary
