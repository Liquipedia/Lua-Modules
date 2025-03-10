---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Summary/MapVeto
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local MapVetoStart = Lua.import('Module:Widget/Match/Summary/MapVetoStart')
local MapVetoRound = Lua.import('Module:Widget/Match/Summary/MapVetoRound')

---@class MatchSummaryMapVeto: Widget
---@operator call(table): MatchSummaryMapVeto
local MatchSummaryMapVeto = Class.new(Widget)

---@return Widget?
function MatchSummaryMapVeto:render()
	if Logic.isEmpty(self.props.vetoRounds) then
		return
	end

	return HtmlWidgets.Div{
		classes = {'brkts-popup-mapveto'},
		children = HtmlWidgets.Table{
			classes = {'wikitable-striped', 'collapsible', 'collapsed'},
			children = WidgetUtil.collect(
				HtmlWidgets.Tr{children = {
					HtmlWidgets.Th{css = {width = '33%'}},
					HtmlWidgets.Th{css = {width = '34%'}, children = 'Map Veto'},
					HtmlWidgets.Th{css = {width = '33%'}},
				}},
				MapVetoStart{firstVeto = self.props.firstVeto, vetoFormat = self.props.vetoFormat},
				Array.map(self.props.vetoRounds, function(veto)
					return MapVetoRound{vetoType = veto.type, map1 = veto.map1, map2 = veto.map2}
				end)
			)
		}
	}
end

return MatchSummaryMapVeto
