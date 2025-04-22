---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Page/TeamDisplay
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

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
	local opponent = self.props.opponent
	local data = self.props.opponent.teamTemplateData
	if Logic.isEmpty(data) then return Div{classes = { 'match-bm-match-header-team' }} end
	return Div{
		classes = { 'match-bm-match-header-team' },
		children = {
			mw.ext.TeamTemplate.teamicon(data.templatename),
			Div{
				classes = { 'match-bm-match-header-team-group' },
				children = {
					Div{
						classes = { 'match-bm-match-header-team-long' },
						children = { Link{ link = data.page, children = data.name } }
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
	}
end

return MatchPageTeamDisplay
