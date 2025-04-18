---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Page/TeamDisplay
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local TeamTemplate = require('Module:TeamTemplate')

local OpponentLibraries = Lua.import('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local Link = Lua.import('Module:Widget/Basic/Link')

---@class MatchPageTeamDisplayParameters
---@field opponent MatchPageOpponent

local RESULT_DISPLAY_TYPES = {
	['w'] = 'winner',
	['l'] = 'loser',
	['winner'] = 'winner',
	['loser'] = 'loser',
	['-'] = 'notplayed'
}

---@class MatchPageTeamDisplay: Widget
---@operator call(MatchPageTeamDisplayParameters): MatchPageTeamDisplay
---@field props MatchPageTeamDisplayParameters
local MatchPageTeamDisplay = Class.new(Widget)


---@private
---@param result string
---@return Widget
function MatchPageTeamDisplay._makeGameResultIcon(result)
	return Div{
		classes = { 'match-bm-match-header-round-result', 'result--' .. RESULT_DISPLAY_TYPES[result:lower()] }
	}
end

---@return Widget?
function MatchPageTeamDisplay:render()
	return Div{
		classes = { 'match-bm-match-header-team' },
		children = self:_buildChildren()
	}
end

---@private
---@return Widget|(string|Widget)[]?
function MatchPageTeamDisplay:_buildChildren()
	local opponent = self.props.opponent
	if Opponent.isEmpty(opponent) then return
	elseif opponent.type == Opponent.literal then
		return Div{
			classes = {'match-bm-match-header-team-literal'},
			children = opponent.name
		}
	end
	local data = self.props.opponent.teamTemplateData
	assert(data, TeamTemplate.noTeamMessage(opponent.template))
	return {
		mw.ext.TeamTemplate.teamicon(data.templatename),
		Div{
			classes = { 'match-bm-match-header-team-group' },
			children = {
				Div{
					classes = { 'match-bm-match-header-team-long' },
					children = { Link{ link = data.page } }
				},
				Div{
					classes = { 'match-bm-match-header-team-short' },
					children = { Link{ link = data.page, children = data.shortname } }
				},
				Div{
					classes = { 'match-bm-match-header-round-results' },
					children = Array.map(opponent.seriesDots, MatchPageTeamDisplay._makeGameResultIcon)
				},
			}
		}
	}
end

return MatchPageTeamDisplay
