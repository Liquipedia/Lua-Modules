---
-- @Liquipedia
-- page=Module:Features/TournamentAppearances/Components/Header
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')

local Component = Lua.import('Module:Widget/Component')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local TournamentTitle = Lua.import('Module:Widget/Tournament/Title')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@param props {tournaments: StandardTournament[], config: TournamentAppearancesConfig}
---todo: add proper type for config
---@return VNode
local TournamentAppearancesHeader = function(props)
	return TableWidgets.TableHeader{children = {
		TableWidgets.Row{children = WidgetUtil.collect(
			-- todo: adjust first 2 cells for opponent case
			TableWidgets.CellHeader{},
			TableWidgets.CellHeader{children = 'Player'},
			TableWidgets.CellHeader{children = '#'},
			Array.map(props.tournaments, function (tournament)
				return TableWidgets.CellHeader{children = TournamentTitle{
					tournament = tournament, useShortName = true
				}}
			end)
		)}
	}}
end

return Component.component(TournamentAppearancesHeader)
