---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchSummary/FFA/Starcraft
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local StarcraftMatchExternalLinks = require('Module:MatchExternalLinks/Starcraft')
local StarcraftMatchGroupUtil = require('Module:MatchGroup/Util/Starcraft')
local Table = require('Module:Table')

local FFAMatchSummary = Lua.import('Module:MatchSummary/FFA', {requireDevIfEnabled = true})
local StarcraftMatchSummary = Lua.import('Module:MatchSummary/Starcraft', {requireDevIfEnabled = true})
local StarcraftOpponentDisplay = Lua.import('Module:OpponentDisplay/Starcraft', {requireDevIfEnabled = true})

local CustomFfaMatchSummary = {propTypes = {}}

--[[
FFAMatchSummary module specific to the starcraft/starcraft2 wikis.
]]
function CustomFfaMatchSummary.FFAMatchSummary(props)
	if props.match.opponentMode == 'team' then
		error('Team matches are not supported in StarcraftFFAMatchSummary')
	end

	local function GamePlacement(cellProps)
		return CustomFfaMatchSummary.GamePlacement({
			opponent = cellProps.opponent,
			matchOpponent = props.match.opponents[cellProps.opponentIx],
		})
	end

	return FFAMatchSummary.FFAMatchSummary({
		match = props.match,
		config = Table.merge(props.config, {
			Footer = CustomFfaMatchSummary.Footer,
			GamePlacement = GamePlacement,
			Opponent = CustomFfaMatchSummary.Opponent,
			rowHeight = CustomFfaMatchSummary.computeRowHeight(props.match),
		})
	})
end

function CustomFfaMatchSummary.Opponent(props)
	local contentNode = StarcraftOpponentDisplay.BlockOpponent({
		opponent = props.opponent,
		overflow = props.opponent.type == 'team' and 'hidden' or 'ellipsis',
		teamStyle = 'short',
	})
		:addClass('ffa-match-summary-cell-content')
	return mw.html.create('div')
		:addClass('ffa-match-summary-cell ffa-match-summary-opponent')
		:addClass(FFAMatchSummary.getOpponentBgClass(props.opponent, props.match))
		:node(contentNode)
end

function CustomFfaMatchSummary.GamePlacement(props)
	local opponent = props.opponent
	local offraces = StarcraftMatchGroupUtil.computeOffraces(opponent, props.matchOpponent)

	return mw.html.create('div'):addClass('ffa-match-summary-cell')
		:addClass('ffa-match-summary-game-placement')
		:addClass(opponent.placement and FFAMatchSummary.getPlacementClass(opponent.placement))
		:node(offraces and StarcraftMatchSummary.OffraceIcons(offraces) or nil)
		:node(opponent.placement and tostring(opponent.placement) .. '.' or '')
end

function CustomFfaMatchSummary.Footer(props)
	local links = StarcraftMatchExternalLinks.extractFromMatch(props.match)
	if #links > 0 then
		local linksNode = StarcraftMatchExternalLinks.MatchExternalLinks({links = links})
			:addClass('brkts-popup-sc-footer-links')
		return mw.html.create('div'):addClass('ffa-match-summary-footer')
			:node(linksNode)
	else
		return nil
	end
end

function CustomFfaMatchSummary.computeRowHeight(match)
	local maxHeight = 36
	for _, opponent in ipairs(match.opponents) do
		local padding = 5
		local lineHeight = 20
		local height = math.max(1, #opponent.players) * lineHeight + 6 + 2 * padding
		maxHeight = math.max(maxHeight, height)
	end
	return maxHeight
end

return Class.export(CustomFfaMatchSummary)
