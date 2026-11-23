---
-- @Liquipedia
-- page=Module:Widget/Match/Ticker/Card
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local DateExt = Lua.import('Module:Date/Ext')
local Logic = Lua.import('Module:Logic')
local Timezone = Lua.import('Module:Timezone')

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
---@field countdownFormat CountdownFormat?

local MatchTickerCard = {}

---@param props MatchTickerCardProps
---@return VNode
function MatchTickerCard.render(props)
	local match = props.match

	return Html.Div{
		classes = {'match-ticker-card'},
		attributes = {
			['data-match-timestamp'] = match.timestamp,
			['data-match-timezone-offset'] = MatchTickerCard.getDisplayedTimezoneOffset(match),
		},
		children = {
			MatchTickerCard.buildHeader(match, props.countdownFormat),
			MatchTickerCardOpponents{match = match},
			TournamentInfo(props),
			MatchButtonBar{match = match, showVods = true, buttonSize = 'xs'}
		}
	}
end

---Offset in seconds from UTC of the timezone the server renders the match date in
---@param match MatchGroupUtilMatch
---@return integer
function MatchTickerCard.getDisplayedTimezoneOffset(match)
	-- Dates without a time are shown as the UTC date, see DateExt.toCountdownArg
	if not match.dateIsExact then
		return 0
	end
	return Timezone.getOffset{timezone = match.timezoneId or DateExt.defaultTimezone} or 0
end

---@param match MatchGroupUtilMatch
---@param countdownFormat CountdownFormat
---@return VNode
function MatchTickerCard.buildHeader(match, countdownFormat)
	return Html.Div{
		classes = {'match-ticker-card__header'},
		children = {
			MatchCountdown{match = match, format = countdownFormat},
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

return Component.component(MatchTickerCard.render, {countdownFormat = 'compact'})
