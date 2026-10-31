---
-- @Liquipedia
-- page=Module:Features/TournamentAppearances/Components/Table
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Page = Lua.import('Module:Page')
local Types = Lua.import('Module:Features/TournamentAppearances/Types')

local Component = Lua.import('Module:Widget/Component')
local QueryLink = Lua.import('Module:Widget/QueryLink')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local TournamentAppearancesHeader = Lua.import('Module:Features/TournamentAppearances/Components/Header')
local TournamentAppearancesRow = Lua.import('Module:Features/TournamentAppearances/Components/Row')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@param config TournamentAppearancesConfig
---@return VNode?
local buildFooter = function(config)
	if not config.restrictToPlayersParticipatingIn or config.isFormQuery then
		return
	elseif not Page.exists('Form:' .. Types.FORM_NAME) then
		return
	end
	return QueryLink{
		mediawikiForm = Types.FORM_NAME,
		form = Types.FORM_NAME .. '/LH',
		display = 'Click here to modify this table',
		template = 'PTA',
		queryArgs = {
			series = (config.series or {})[1] or '',
			pages = table.concat(config.pages, ','),
			tiers = table.concat(config.tiers, ','),
			limit = config.limit or '',
			playerspage = config.restrictToPlayersParticipatingIn or '',
		},
	}
end

---@param props {tournaments: StandardTournament[], config: TournamentAppearancesConfig, players: standardPlayer[]}
---@return VNode
local TournamentAppearancesTable = function(props)
	local numberOfPlayers = #props.players
	local limit = math.min(props.config.limit or numberOfPlayers, numberOfPlayers)
	return TableWidgets.Table{
		sortable = true,
		children = WidgetUtil.collect(
			TournamentAppearancesHeader{
				tournaments = props.tournaments,
				config = props.config,
			},
			TableWidgets.TableBody{
				children = Array.mapRange(1, limit, function(playerIndex)
					return TournamentAppearancesRow{
						tournaments = props.tournaments,
						player = props.players[playerIndex],
						config = props.config
					}
				end)
			}
		),
		footer = buildFooter(props.config)
	}
end

return Component.component(TournamentAppearancesTable)
