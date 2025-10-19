---
-- @Liquipedia
-- page=Module:Widget/CharacterStats
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local DateExt = Lua.import('Module:Date/Ext')
local Character = Lua.import('Module:Character')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local Operator = Lua.import('Module:Operator')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName
local ConditionUtil = Condition.Util

local Widget = Lua.import('Module:Widget')
local CharacterStatsTable = Lua.import('Module:Widget/CharacterStats/Table')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local IconImage = Lua.import('Module:Widget/Image/Icon/Image')
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

---@return Widget[]?
function CharacterStatsWidget:render()
	local data = self.props.data
	if Logic.isEmpty(data) then
		return
	end
	return WidgetUtil.collect(
		CharacterStatsTable(self.props),
		self:_displayUnpickedCharacters(),
		self.props.includeBans and {
			self:_displayUnbannedCharacters(),
			self:_displayUnpickedAndUnbannedCharacters(),
		}
	)
end

function CharacterStatsWidget:_displayUnpickedCharacters()
	---@type string[]
	local playedCharacters = Array.map(
		Array.filter(self.props.data, function (dataEntry)
			return dataEntry.total.pick > 0
		end),
		Operator.property('name')
	)

	return self:_buildUnchosenCharactersTable('Unpicked', playedCharacters)
end

function CharacterStatsWidget:_displayUnbannedCharacters()
	---@type string[]
	local bannedCharacters = Array.map(
		Array.filter(self.props.data, function (dataEntry)
			return dataEntry.bans > 0
		end),
		Operator.property('name')
	)

	return self:_buildUnchosenCharactersTable('Unpicked', bannedCharacters)
end

function CharacterStatsWidget:_displayUnpickedAndUnbannedCharacters()
	---@type string[]
	local playedCharacters = Array.map(
		Array.filter(self.props.data, function (dataEntry)
			return dataEntry.total.pick > 0 or dataEntry.bans > 0
		end),
		Operator.property('name')
	)

	return self:_buildUnchosenCharactersTable('Unpicked & Unbanned', playedCharacters)
end

---@private
---@param titlePrefix string
---@param excludedCharacters string[]
function CharacterStatsWidget:_buildUnchosenCharactersTable(titlePrefix, excludedCharacters)
	local conditions = ConditionTree(BooleanOperator.all):add{
		ConditionNode(ColumnName('date'), Comparator.le, DateExt.getContextualDateOrNow()),
		ConditionUtil.noneOf(ColumnName('name'), excludedCharacters)
	}
	local characters = Character.getAllCharacters(
		'(' .. tostring(conditions) .. ')'
	)
	return HtmlWidgets.Table{
		classes = {'wikitable'},
		children = {
			HtmlWidgets.Tr{children = HtmlWidgets.Th{
				children = {titlePrefix .. ' ' .. self.props.characterType, ' ', HtmlWidgets.I{children = {'(', #characters, ')'}}
			}}},
			HtmlWidgets.Tr{children = HtmlWidgets.Td{
				children = Array.map(characters, function (character)
					return IconImage{
						imageLight = character.iconLight,
						imageDark = character.iconDark,
						link = character.pageName,
						size = self.props.characterSize,
					}
				end)
			}}
		}
	}
end

return CharacterStatsWidget
