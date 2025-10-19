---
-- @Liquipedia
-- page=Module:Widget/CharacterStats
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local CharacterIcon = Lua.import('Module:CharacterIcon')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local MathUtil = Lua.import('Module:MathUtil')
local String = Lua.import('Module:StringUtils')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class CharacterStatsWidgetProps
---@field characterSize string
---@field characterType string
---@field data CharacterStatistic[]
---@field includeBans boolean?
---@field numGames integer
---@field sides string[]
---@field sideWins table<string, integer>

---@class CharacterStatsWidget: Widget
---@operator call(CharacterStatsWidgetProps): CharacterStatsWidget
---@field props CharacterStatsWidgetProps
local CharacterStatsWidget = Class.new(Widget)
CharacterStatsWidget.defaultProps = {
	characterSize = '25x25px',
	numGames = 0
}

---@return Widget?
function CharacterStatsWidget:render()
	local data = self.props.data
	if Logic.isEmpty(data) then
		return
	end
	return HtmlWidgets.Div{
		classes = {'table-responsive'},
		children = HtmlWidgets.Table{
			classes = {'wikitable', 'table-striped', 'sortable'},
			css = {
				margin = 0,
				['text-align'] = 'center',
			},
			children = WidgetUtil.collect(
				self:_buildHeaderRow(),
				Array.map(data, function (dataEntry, dataIndex)
					return self:_buildCharacterRow(dataEntry, dataIndex)
				end),
				self:_buildFooterRow()
			)
		}
	}
end

---@private
---@return Widget
function CharacterStatsWidget:_buildHeaderRow()
	return {
		HtmlWidgets.Tr{children = WidgetUtil.collect(
			HtmlWidgets.Th{attributes = {colspan = 2}},
			HtmlWidgets.Th{attributes = {colspan = 5}, children = 'Picks'},
			Array.map(self.props.sides, function (side)
				return HtmlWidgets.Th{attributes = {colspan = 4}, children = String.upperCaseFirst(side)}
			end),
			HtmlWidgets.Th{}
		)},
		HtmlWidgets.Tr{children = WidgetUtil.collect(
			HtmlWidgets.Th{},
			HtmlWidgets.Th{children = String.upperCaseFirst(self.props.characterType)},
			HtmlWidgets.Th{children = '∑'},
			HtmlWidgets.Th{children = 'W'},
			HtmlWidgets.Th{children = 'L'},
			HtmlWidgets.Th{children = 'WR'},
			HtmlWidgets.Th{children = '%T'},
			Array.flatMap(Array.range(1, 2), function (_)
				return {
					HtmlWidgets.Th{children = '∑'},
					HtmlWidgets.Th{children = 'W'},
					HtmlWidgets.Th{children = 'L'},
					HtmlWidgets.Th{children = 'WR'},
				}
			end),
			self.props.includeBans and {
				HtmlWidgets.Th{children = '∑'},
				HtmlWidgets.Th{children = '%T'},
				HtmlWidgets.Th{children = '∑'},
				HtmlWidgets.Th{children = '%T'},
			} or nil,
			HtmlWidgets.Th{classes = {'unsortable'}, children = 'Details'}
		)}
	}
end

---@private
---@param characterData CharacterStatistic
---@param characterIndex integer
---@return Widget
function CharacterStatsWidget:_buildCharacterRow(characterData, characterIndex)
	return HtmlWidgets.Tr{
		classes = {'dota-stat-row'},
		children = WidgetUtil.collect(
			HtmlWidgets.Td{children = characterIndex},
			HtmlWidgets.Td{
				css = {
					['text-align'] = 'left',
					['white-space'] = 'nowrap'
				},
				children = CharacterIcon.Icon{character = characterData.name, size = self.props.characterSize, addTextLink = true}
			},
			HtmlWidgets.Td{
				css = {['font-weight'] = 'bolder'},
				children = characterData.total.pick
			},
			HtmlWidgets.Td{children = characterData.total.win},
			HtmlWidgets.Td{children = characterData.total.loss},
			HtmlWidgets.Td{children = CharacterStatsWidget._calculatePercentage(characterData.total.win, characterData.total.pick)},
			HtmlWidgets.Td{children = CharacterStatsWidget._calculatePercentage(characterData.total.pick, self.props.numGames)},
			Array.flatMap(self.props.sides, function (side)
				local picks = characterData.side[side].win + characterData.side[side].loss
				return {
					HtmlWidgets.Td{
						css = {['font-weight'] = 'bolder'},
						children = picks
					},
					HtmlWidgets.Td{children = characterData.side[side].win},
					HtmlWidgets.Td{children = characterData.side[side].loss},
					HtmlWidgets.Td{children = CharacterStatsWidget._calculatePercentage(characterData.side[side].win, picks)}
				}
			end),
			self.props.includeBans and {
				HtmlWidgets.Td{children = characterData.bans},
				HtmlWidgets.Td{children = CharacterStatsWidget._calculatePercentage(characterData.bans, self.props.numGames)},
				HtmlWidgets.Td{children = characterData.total.pick + characterData.bans},
				HtmlWidgets.Td{children = CharacterStatsWidget._calculatePercentage(characterData.total.pick + characterData.bans, self.props.numGames)}
			} or nil,
			HtmlWidgets.Td{children = '-'}
		)
	}
end

---@private
---@return Widget
function CharacterStatsWidget:_buildFooterRow()
	return HtmlWidgets.Tr{children = WidgetUtil.collect(
		HtmlWidgets.Th{
			classes = {'sortbottom'},
			attributes = {colspan = 2}
		},
		HtmlWidgets.Th{
			classes = {'sortbottom'},
			attributes = {colspan = 5},
			children = {
				self.props.numGames,
				' games played'
			}
		},
		Array.map(self.props.sides, function (side)
			local sideWin = self.props.sideWins[side]
			local sideLoss = self.props.numGames - sideWin
			return HtmlWidgets.Th{
				classes = {'sortbottom'},
				attributes = {colspan = 4},
				children = sideWin .. ' W - ' ..  sideLoss .. ' L (' .. CharacterStatsWidget._calculatePercentage(sideWin, self.props.numGames) .. ')'
			}
		end),
		HtmlWidgets.Th{
			classes = {'sortbottom'},
			attributes = {colspan = 5}
		}
	)}
end

---@param count integer
---@param total integer
---@return string
function CharacterStatsWidget._calculatePercentage(count, total)
	if total == 0 then
		return '-'
	end
	return string.format('%.2f', MathUtil.round(count / total * 100, 2)) .. '%'
end

return CharacterStatsWidget
