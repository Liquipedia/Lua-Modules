---
-- @Liquipedia
-- page=Module:Widget/W3EloRanking
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')
local PlayerDisplay = Lua.import('Module:Player/Display/Custom')

local Component = Lua.import('Module:Widget/Component')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local Helpers = {}
local defaultProps = {
	count = 10,
}

---@return Renderable?
local function W3EloRanking(props)
	local rawData = mw.ext.TeamLiquidIntegration.w3elo(props.count)

	if type(rawData) ~= 'table' then
		return rawData
	end

	return TableWidgets.Table{
		striped = true,
		css = {width = '100%'},
		children = WidgetUtil.collect(
			TableWidgets.TableHeader{children = Helpers._buildHeader()},
			TableWidgets.TableBody{children = Array.map(rawData, Helpers._buildStandingRow)}
		)
	}
end

---@private
---@return Renderable
function Helpers._buildHeader()
	return TableWidgets.Row{
		children = {
			TableWidgets.CellHeader{children = 'Rank'},
			TableWidgets.CellHeader{children = 'Player'},
			TableWidgets.CellHeader{children = 'Rating'}
		}
	}
end

---@private
---@param data table
---@param placement integer
---@return Renderable
function Helpers._buildStandingRow(data, placement)
	local race = string.lower(data.main_race or '')

	return TableWidgets.Row{
		children = {
			TableWidgets.Cell{children = placement},
			TableWidgets.Cell{
				children = PlayerDisplay.InlinePlayer{player = {
					flag = data.country,
					displayName = data.name,
					pageName = Logic.emptyOr(data.liquipedia, data.name),
					faction = string.sub(race, 0, 1)
				}}
			},
			TableWidgets.Cell{children = data.elo}
		}
	}
end

return Component.component(W3EloRanking, defaultProps)
