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

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Abbr, Tr, Th, Td = HtmlWidgets.Abbr, HtmlWidgets.Tr, HtmlWidgets.Th, HtmlWidgets.Td
local Characters = Lua.import('Module:Widget/Match/Summary/Characters')
local Collapsible = Lua.import('Module:Widget/Match/Summary/Collapsible')

---@class MatchSummaryCharacterBanTable: Widget
---@operator call(table): MatchSummaryCharacterBanTable
local MatchSummaryCharacterBanTable = Class.new(Widget)
MatchSummaryCharacterBanTable.defaultProps = {
	flipped = false,
}

---@return Widget[]?
function MatchSummaryCharacterBanTable:render()
	if Logic.isDeepEmpty(self.props.bans) then
		return nil
	end

	local rows = Array.map(self.props.bans, function(banData, gameNumber)
		if Logic.isDeepEmpty(banData) then
			return nil
		end
		return Tr{
			children = {
				Td{
					css = {float = 'left'},
					children = {Characters{characters = banData[1], flipped = false, date = self.props.date}}
				},
				Td{
					css = {['font-size'] = '80%'},
					children = {Abbr{
						title = 'Bans in game ' .. gameNumber,
						children = {'Game ' .. gameNumber},
					}}
				},
				Td{
					css = {float = 'right'},
					children = {Characters{characters = banData[2], flipped = true, date = self.props.date}}
				},
			},
		}
	end)

	return Collapsible{
		tableClasses = {'wikitable-striped'},
		header = Tr{children = {
			Th{css = {width = '40%'}},
			Th{css = {width = '20%'}, children = {'Bans'}},
			Th{css = {width = '40%'}},
		}},
		children = rows,
	}
end

return MatchSummaryCharacterBanTable
