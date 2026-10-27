---
-- @Liquipedia
-- page=Module:Features/TournamentAppearances/Components/Row
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Flags = Lua.import('Module:Flags')
local Logic = Lua.import('Module:Logic')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')
local Placement = Lua.import('Module:Placement')
local PlayerDisplay = Lua.import('Module:Player/Display/Custom')

local Component = Lua.import('Module:Widget/Component')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@param props {tournaments: StandardTournament[], player: standardPlayer, config: table}
---todo: add proper type for config
---@return VNode
local TournamentAppearancesRow = function(props)
	return TableWidgets.Row{children = WidgetUtil.collect(
		-- todo: add display for opponent case
		TableWidgets.Cell{children = Flags.Icon{flag = props.player.flag}},
		TableWidgets.Cell{children = PlayerDisplay.InlinePlayer{
			player = props.player, showFlag = false
		}},
		TableWidgets.Cell{children = props.player.extradata.appearances},
		Array.map(props.tournaments, function (tournament)
			local result = props.player.extradata.results[tournament.pageName] or {}
			if props.config.showPlacementInsteadOfTeam then
				local rawPlacement = Placement.raw(result.placement or '')
				return TableWidgets.Cell{
					attributes = {
						['data-sort-value'] = rawPlacement.sort
					},
					classes = {rawPlacement.backgroundClass},
					children = Placement.renderInWidget{placement = result.placement}
				}
			elseif Logic.isNotEmpty(result) then
				return TableWidgets.Cell{
					align = 'center',
					classes = tonumber(result.placement) == 1 and {'tournament-highlighted-bg'} or nil,
					attributes = {['data-sort-value'] = result.team},
					children = result.team and OpponentDisplay.InlineTeamContainer{
						template = result.team, date = result.date, style = 'icon'
					} or nil
				}
			end
			return TableWidgets.Cell{}
		end)
	)}
end

return Component.component(TournamentAppearancesRow)
