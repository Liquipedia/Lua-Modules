---
-- @Liquipedia
-- page=Module:Widget/W3EloRanking
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local PlayerDisplay = Lua.import('Module:Player/Display/Custom')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class W3EloRanking: Widget
---@operator call({count: integer?}): W3EloRanking
---@field props {count: integer?}
local W3EloRanking = Class.new(Widget)
W3EloRanking.defaultProps = {
	count = 10,
}

---@return Widget?
function W3EloRanking:render()
	local rawData = mw.ext.TeamLiquidIntegration.w3elo(self.props.count)

	if type(rawData) ~= 'table' then
		return rawData
	end

	return HtmlWidgets.Div{
		classes = {'table-responsive'},
		children = HtmlWidgets.Table{
			classes = {'wikitable', 'wikitable-striped', 'rankingtable'},
			css = {width = '100%'},
			children = WidgetUtil.collect(
				W3EloRanking._buildHeader(),
				Array.map(rawData, W3EloRanking._buildStandingRow)
			)
		}
	}
end

---@private
---@return Widget
function W3EloRanking._buildHeader()
	return HtmlWidgets.Tr{
		children = Array.map({'Rank', 'Player', 'Rating'}, function (header)
			return HtmlWidgets.Th{
				css = {['text-align'] = 'left'},
				children = header
			}
		end)
	}
end

---@private
---@param data table
---@param placement integer
---@return Widget
function W3EloRanking._buildStandingRow(data, placement)
	local race = string.lower(data.main_race or '')

	return HtmlWidgets.Tr{
		children = {
			HtmlWidgets.Td{children = placement},
			HtmlWidgets.Td{
				children = PlayerDisplay.InlinePlayer{player = {
					flag = data.country,
					displayName = data.name,
					pageName = Logic.emptyOr(data.liquipedia, data.name),
					faction = string.sub(race, 0, 1)
				}}
			},
			HtmlWidgets.Td{children = data.elo}
		}
	}
end

return W3EloRanking
