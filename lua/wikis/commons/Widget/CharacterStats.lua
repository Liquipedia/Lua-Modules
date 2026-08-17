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
local Logic = Lua.import('Module:Logic')
local Operator = Lua.import('Module:Operator')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName
local ConditionUtil = Condition.Util

local CharacterStatsTable = Lua.import('Module:Widget/CharacterStats/Table')
local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local IconImage = Lua.import('Module:Widget/Image/Icon/Image')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local Helpers = {}

---@class CharacterStatsData
---@field name string
---@field bans integer
---@field total table<string, integer>

---@class CharacterStatsWidgetProps
---@field characterSize string
---@field characterType string
---@field data CharacterStatistic[]
---@field includeBans boolean?
---@field includeGlobalBans boolean?
---@field numGames integer
---@field sides string[]
---@field sideWins table<string, integer>
---@field statspage string

local defaultProps = {
	characterSize = '25x25px',
	includeGlobalBans = false,
	numGames = 0,
	statspage = mw.title.getCurrentTitle().prefixedText
}

---@param props CharacterStatsWidgetProps
---@return Renderable[]?
local function CharacterStatsWidget(props)
	local data = props.data
	if Logic.isEmpty(data) then
		return
	end
	local showExtraStats = props.statspage == mw.title.getCurrentTitle().prefixedText
	return WidgetUtil.collect(
		CharacterStatsTable(props),
		showExtraStats and WidgetUtil.collect(
			Helpers._displayUnpickedCharacters(props),
			props.includeBans and {
				Helpers._displayUnbannedCharacters(props),
				Helpers._displayUnpickedAndUnbannedCharacters(props),
			}
		) or nil
	)
end

---@private
---@param props CharacterStatsWidgetProps
---@return Renderable?
function Helpers._displayUnpickedCharacters(props)
	---@type string[]
	local playedCharacters = Array.map(
		Array.filter(props.data, function (dataEntry)
			---@cast dataEntry CharacterStatsData
			return dataEntry.total.pick > 0
		end),
		Operator.property('name')
	)

	return Helpers._buildUnchosenCharactersTable('Unpicked', playedCharacters, props)
end

---@private
---@param props CharacterStatsWidgetProps
---@return Renderable?
function Helpers._displayUnbannedCharacters(props)
	---@type string[]
	local bannedCharacters = Array.map(
		Array.filter(props.data, function (dataEntry)
			---@cast dataEntry CharacterStatsData
			return dataEntry.bans > 0
		end),
		Operator.property('name')
	)

	return Helpers._buildUnchosenCharactersTable('Unbanned', bannedCharacters, props)
end

---@private
---@param props CharacterStatsWidgetProps
---@return Renderable?
function Helpers._displayUnpickedAndUnbannedCharacters(props)
	---@type string[]
	local playedCharacters = Array.map(
		Array.filter(props.data, function (dataEntry)
			---@cast dataEntry CharacterStatsData
			return dataEntry.total.pick > 0 or dataEntry.bans > 0
		end),
		Operator.property('name')
	)

	return Helpers._buildUnchosenCharactersTable('Unpicked & Unbanned', playedCharacters, props)
end

---@private
---@param titlePrefix string
---@param excludedCharacters string[]
---@param props CharacterStatsWidgetProps
---@return Renderable?
function Helpers._buildUnchosenCharactersTable(titlePrefix, excludedCharacters, props)
	local conditions = ConditionTree(BooleanOperator.all):add{
		ConditionNode(ColumnName('date'), Comparator.le, DateExt.getContextualDateOrNow()),
		ConditionUtil.noneOf(ColumnName('name'), excludedCharacters)
	}
	local characters = Character.getAllCharacters(
		'(' .. tostring(conditions) .. ')'
	)
	if Logic.isEmpty(characters) then
		return
	end
	return TableWidgets.Table{
		columns = {{}},
		children = WidgetUtil.collect(
			TableWidgets.TableHeader{
				children = TableWidgets.Row{
					children = TableWidgets.CellHeader{
						align = 'center',
						children = {titlePrefix .. ' ' .. props.characterType, ' ', Html.I{children = {'(', #characters, ')'}}}
					}
				}
			},
			TableWidgets.TableBody{
				children = TableWidgets.Row{
					children = TableWidgets.Cell{
						css = {['white-space'] = 'normal'}, -- so it will wrap
						children = Array.map(characters, function (character)
							return IconImage{
								imageLight = character.iconLight,
								imageDark = character.iconDark,
								link = character.pageName,
								size = props.characterSize,
							}
						end)
					}
				}
			}
		)
	}
end

return Component.component(CharacterStatsWidget, defaultProps)
