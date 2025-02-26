---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Summary/CharacterBanTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local Icon = Lua.import('Module:Icon')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Abbr, Tr, Th, Td = HtmlWidgets.Abbr, HtmlWidgets.Tr, HtmlWidgets.Th, HtmlWidgets.Td
local Characters = Lua.import('Module:Widget/Match/Summary/Characters')
local Collapsible = Lua.import('Module:Widget/Match/Summary/Collapsible')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class MatchSummaryCharacterBanTable: Widget
---@operator call(table): MatchSummaryCharacterBanTable
local MatchSummaryCharacterBanTable = Class.new(Widget)
MatchSummaryCharacterBanTable.defaultProps = {
	flipped = false,
}

local ICONS = {
	left = Icon.makeIcon{iconName = 'startleft', size = '110%'},
	right = Icon.makeIcon{iconName = 'startright', size = '110%'},
	empty = '[[File:NoCheck.png|link=|16px]]',
}

---@return Widget[]?
function MatchSummaryCharacterBanTable:render()
	if Logic.isDeepEmpty(self.props.bans) then
		return nil
	end

	local hasStartIndicator = Array.any(self.props.bans, function(banData)
		return Logic.isNotEmpty(banData.start)
	end)

	---@param teamIndex integer
	---@param startIndex integer
	---@return string
	local startIndicator = function(teamIndex, startIndex)
		if teamIndex ~= startIndex then
			return ICONS.empty
		elseif teamIndex == 1 then
			return ICONS.left
		end
		return ICONS.right
	end

	local rows = Array.map(self.props.bans, function(banData, gameNumber)
		if Logic.isDeepEmpty(banData) then
			return nil
		end
		return Tr{
			children = WidgetUtil.collect(
				Td{
					css = {float = 'left'},
					children = {Characters{characters = banData[1], flipped = false, date = self.props.date}}
				},
				hasStartIndicator and Td{
					children = {startIndicator(1, banData.start)}
				} or nil,
				Td{
					css = {['font-size'] = '80%'},
					children = {Abbr{
						title = 'Bans in game ' .. gameNumber,
						children = {'Game ' .. gameNumber},
					}}
				},
				hasStartIndicator and Td{
					children = {startIndicator(2, banData.start)}
				} or nil,
				Td{
					css = {float = 'right'},
					children = {Characters{characters = banData[2], flipped = true, date = self.props.date}}
				}
			),
		}
	end)

	return Collapsible{
		tableClasses = {'wikitable-striped'},
		header = Tr{children = WidgetUtil.collect(
			Th{css = {width = hasStartIndicator and '35%' or '40%'}},
			hasStartIndicator and Th{css = {width = '5%'}} or nil,
			Th{css = {width = '20%'}, children = {'Bans'}},
			hasStartIndicator and Th{css = {width = '5%'}} or nil,
			Th{css = {width = hasStartIndicator and '35%' or '40%'}}
		)},
		children = rows,
	}
end

return MatchSummaryCharacterBanTable
