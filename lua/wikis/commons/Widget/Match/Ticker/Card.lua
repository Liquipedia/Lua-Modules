---
-- @Liquipedia
-- page=Module:Widget/Match/Ticker/Card
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local MatchCountdown = Lua.import('Module:Widget/Match/Countdown')
local MatchTickerCardOpponents = Lua.import('Module:Widget/Match/Ticker/Opponents')
local TournamentInfo = Lua.import('Module:Widget/Match/Ticker/TournamentInfo')
local MatchButtonBar = Lua.import('Module:Widget/Match/ButtonBar')

---@class MatchTickerCardProps
---@field match MatchGroupUtilMatch
---@field gameData MatchTickerGameData?
---@field onlyHighlightOnValue string?
---@field displayGameIcons boolean?
---@field hideTournament boolean?

local MatchTickerCard = {}

---@param props MatchTickerCardProps
---@return VNode
function MatchTickerCard.render(props)
	local match = props.match

	return Html.Div{
		classes = {'match-ticker-card'},
		attributes = {['data-match-timestamp'] = match.timestamp},
		children = {
			MatchTickerCard.buildHeader(match),
			MatchTickerCardOpponents{match = match},
			TournamentInfo(props),
			MatchButtonBar{match = match, showVods = true, buttonSize = 'xs'}
		}
	}
end

---@param match MatchGroupUtilMatch
---@return VNode
function MatchTickerCard.buildHeader(match)
	return Html.Div{
		classes = {'match-ticker-card__header'},
		children = {
			MatchCountdown{match = match, format = 'minimal'},
			MatchTickerCard.buildSectionAndBestOf(match),
		}
	}
end

---@param match MatchGroupUtilMatch
---@return VNode?
function MatchTickerCard.buildSectionAndBestOf(match)
	local function buildBestOfDisplay()
		if not match.bestof or match.bestof == 0 then
			return
		end
		return 'Bo' .. match.bestof
	end
	local function buildSectionDisplay()
		if match.section == 'Results' then
			return
		end
		return match.section
	end

	local children = Array.extend(buildSectionDisplay(), buildBestOfDisplay())
	if Logic.isEmpty(children) then
		return
	end

	return Html.Div{
		children = Array.interleave(children, ' - ')
	}
end

return Component.component(MatchTickerCard.render)
