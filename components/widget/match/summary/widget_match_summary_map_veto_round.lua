---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Summary/MapVetoRound
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Link = Lua.import('Module:Widget/Basic/Link')

local DEFAULT_VETO_TYPE_TO_TEXT = {
	ban = 'BAN',
	pick = 'PICK',
	decider = 'DECIDER',
	defaultban = 'DEFAULT BAN',
}
local VETO_DECIDER = 'decider'

---@class MatchSummaryMapVetoRound: Widget
---@operator call(table): MatchSummaryMapVetoRound
local MatchSummaryMapVetoRound = Class.new(Widget)

---@return Widget?
function MatchSummaryMapVetoRound:render()
	if not self.props.vetoType then
		return
	end
	-- TODO Support Osu's "protect" type
	local vetoText = DEFAULT_VETO_TYPE_TO_TEXT[self.props.vetoType]
	if not vetoText then
		return
	end

	local function displayMap(map)
		if not map.page then
			return map
		end
		return Link{
			children = map.name,
			link = map.page,
		}
	end

	local typeClass = 'brkts-popup-mapveto-' .. self.props.vetoType
	local function createVetoTypeElement()
		return HtmlWidgets.Span{classes = {typeClass, 'brkts-popup-mapveto-vetotype'}, text = vetoText}
	end

	local children
	if self.props.vetoType == VETO_DECIDER then
		children = {
			HtmlWidgets.Td{children = createVetoTypeElement()},
			HtmlWidgets.Td{children = displayMap(self.props.map1)},
			HtmlWidgets.Td{children = createVetoTypeElement()},
		}
	else
		children = {
			HtmlWidgets.Td{children = displayMap(self.props.map1)},
			HtmlWidgets.Td{children = createVetoTypeElement()},
			HtmlWidgets.Td{children = displayMap(self.props.map2)},
		}
	end

	return HtmlWidgets.Tr{classes = 'brkts-popup-mapveto-vetoround', children = children}
end

return MatchSummaryMapVetoRound
