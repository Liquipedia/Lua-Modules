---
-- @Liquipedia
-- page=Module:Widget/Match/Page/TeamDisplay
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local TeamTemplate = Lua.import('Module:TeamTemplate')

local Opponent = Lua.import('Module:Opponent/Custom')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local Link = Lua.import('Module:Widget/Basic/Link')
local SeriesDots = Lua.import('Module:Widget/Match/Page/SeriesDots')

---@class MatchPageTeamDisplayParameters
---@field opponent MatchPageOpponent

---@class MatchPageTeamDisplay: Widget
---@operator call(MatchPageTeamDisplayParameters): MatchPageTeamDisplay
---@field props MatchPageTeamDisplayParameters
local MatchPageTeamDisplay = Class.new(Widget)

---@return Widget?
function MatchPageTeamDisplay:render()
	return Div{
		classes = { 'match-bm-match-header-team' },
		children = self:_buildChildren()
	}
end

---@private
---@return Widget|Widget[]?
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
	local hideLink = Opponent.isTbd(opponent)
	return {
		opponent.iconDisplay,
		Div{
			classes = { 'match-bm-match-header-team-group' },
			children = {
				Div{
					classes = { 'match-bm-match-header-team-long' },
					children = { hideLink and data.name or Link{ link = data.page, children = data.name } }
				},
				Div{
					classes = { 'match-bm-match-header-team-short' },
					children = { hideLink and data.shortname or Link{ link = data.page, children = data.shortname } }
				},
				SeriesDots{seriesDots = opponent.seriesDots},
			}
		}
	}
end

return MatchPageTeamDisplay
