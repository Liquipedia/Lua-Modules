---
-- @Liquipedia
-- page=Module:Components/Squad/Player
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Component = Lua.import('Module:Components/Component')
local Context = Lua.import('Module:Components/Context')
local Icon = Lua.import('Module:Icon')
local Opponent = Lua.import('Module:Opponent/Custom')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')
local String = Lua.import('Module:StringUtils')
local TeamTemplate = Lua.import('Module:TeamTemplate')
local Template = Lua.import('Module:Template')

local WidgetUtil = Lua.import('Module:Widget/Util')
local Table2Widgets = Lua.import('Module:Components/Table2/All')
local Html = Lua.import('Module:Components/Html')
local Row, Cell = Table2Widgets.Row, Table2Widgets.Cell
local SquadContexts = Lua.import('Module:Components/Contexts/Squad')

local RoleIcons = {
	captain = Icon.makeIcon{iconName = 'captain', hover = 'Captain'},
	sub = Icon.makeIcon{iconName = 'substitute', hover = 'Substitute'},
}

---@param visibility table<string, boolean>
---@param columnId string
---@return boolean
local function shouldShowColumn(visibility, columnId)
	return visibility == nil or visibility[columnId] == nil or visibility[columnId] == true
end

---@param squadPlayer ModelRow
---@param game string?
---@return Renderable
local function nickname(squadPlayer, game)
	local opponent = Opponent.resolve(
		Opponent.readOpponentArgs{
			squadPlayer.id,
			flag = squadPlayer.nationality,
			link = squadPlayer.link,
			faction = squadPlayer.extradata.faction,
			type = Opponent.solo,
			game = game,
		},
		nil, {syncPlayer = true}
	)
	return OpponentDisplay.InlineOpponent{opponent = opponent}
end

---@param squadPlayer ModelRow
---@return Renderable?
local function roleIcon(squadPlayer)
	return RoleIcons[(squadPlayer.role or ''):lower()]
end

---@param team string?
---@return boolean
local isValidTeam = function(team)
	return team and TeamTemplate.exists(team) or false
end

---@param date string?
---@param team string?
---@param teamRole string?
---@return Renderable?
local function otherTeamInformation(date, team, teamRole)
	local hasTeam = isValidTeam(team)
	if not hasTeam then
		return nil
	end
	---@cast team -nil

	return {
		OpponentDisplay.InlineTeamContainer{
			template = team,
			date = date,
			style = 'icon',
		},
		teamRole and Html.Small{
			children = {Html.I{children = {teamRole}}}
		} or nil,
	}
end

---@param squadPlayer ModelRow
---@return Renderable?
local function getRealName(squadPlayer)
	return String.nilIfEmpty(squadPlayer.name)
end

---@param squadPlayer ModelRow
---@return Renderable?
local function roleAndPositionDisplay(squadPlayer)
	if String.isEmpty(squadPlayer.position) and String.isEmpty(squadPlayer.role) then
		return
	end

	local displayRole = String.isNotEmpty(squadPlayer.role) and not RoleIcons[squadPlayer.role:lower()]

	if String.isNotEmpty(squadPlayer.position) then
		local content = {}
		table.insert(content, squadPlayer.position)
		if displayRole then
			table.insert(content, ' (' .. squadPlayer.role .. ')')
		end
		return table.concat(content)
	elseif displayRole then
		return squadPlayer.role
	end
end

---@param squadPlayer ModelRow
---@return Renderable?
local function dateDisplay(squadPlayer, dateProperty)
	if not squadPlayer[dateProperty] then
		return
	end

	return squadPlayer.extradata[dateProperty .. 'display'] or squadPlayer[dateProperty]
end

---@param squadPlayer ModelRow
---@return Renderable?
local function newTeamDisplay(squadPlayer)
	local newTeam = squadPlayer.extradata.newteam
	local newTeamRole = squadPlayer.extradata.newteamrole
	local newTeamSpecial = squadPlayer.extradata.newteamspecial
	local hasNewTeam, hasNewTeamRole = String.isNotEmpty(newTeam), String.isNotEmpty(newTeamRole)
	local hasNewTeamSpecial = String.isNotEmpty(newTeamSpecial)

	if not hasNewTeam and not hasNewTeamRole and not hasNewTeamSpecial then
		return
	end

	if hasNewTeamSpecial then
		return Template.safeExpand(mw.getCurrentFrame(), newTeamSpecial)
	end

	if not hasNewTeam then
		return newTeamRole
	end

	local teamDate = squadPlayer.extradata.newteamdate or squadPlayer.leavedate
	local teamDisplay = OpponentDisplay.InlineTeamContainer{template = newTeam, date = teamDate}

	if not hasNewTeamRole then
		return teamDisplay
	end

	return teamDisplay .. ' (' .. newTeamRole .. ')'
end

---@param props {squadPlayer: ModelRow}
---@param context Context
---@return Renderable?
local function SquadPlayer(props, context)
	local squadPlayer = props.squadPlayer
	if not squadPlayer then
		return
	end
	local visibility = Context.read(context, SquadContexts.ColumnVisibility)
	local game = Context.read(context, SquadContexts.GameTitle)
	local function addColumn(columnId, content)
		if shouldShowColumn(visibility, columnId) then
			return Cell{children = {content}}
		end
	end
	return Row{
		children = WidgetUtil.collect(
			Cell{children = {
				Html.B{children = {nickname(squadPlayer, game)}},
				roleIcon(squadPlayer) and '&nbsp;' or '',
				roleIcon(squadPlayer),
			}},
			addColumn('teamIcon', otherTeamInformation(
				squadPlayer.leavedate or squadPlayer.inactivedate,
				squadPlayer.extradata.loanedto,
				squadPlayer.extradata.loanedtorole
			)),
			addColumn('name', getRealName(squadPlayer)),
			addColumn('role', roleAndPositionDisplay(squadPlayer)),
			addColumn('joindate', dateDisplay(squadPlayer, 'joindate')),
			addColumn('inactivedate', dateDisplay(squadPlayer, 'inactivedate')),
			addColumn('activeteam', otherTeamInformation(
				squadPlayer.inactivedate,
				squadPlayer.extradata.activeteam,
				squadPlayer.extradata.activeteamrole
			)),
			addColumn('leavedate', dateDisplay(squadPlayer, 'leavedate')),
			addColumn('newteam', newTeamDisplay(squadPlayer))
		),
	}
end

return Component.component(
	SquadPlayer
)
