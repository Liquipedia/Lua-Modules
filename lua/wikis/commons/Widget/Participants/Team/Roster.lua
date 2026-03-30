---
-- @Liquipedia
-- page=Module:Widget/Participants/Team/Roster
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local FnUtil = Lua.import('Module:FnUtil')
local Operator = Lua.import('Module:Operator')
local Opponent = Lua.import('Module:Opponent/Custom')
local RoleUtil = Lua.import('Module:Role/Util')
local Table = Lua.import('Module:Table')
local Variables = Lua.import('Module:Variables')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local ParticipantsTeamMember = Lua.import('Module:Widget/Participants/Team/TeamMember')
local ContentSwitch = Lua.import('Module:Widget/ContentSwitch')

---@enum ParticipantsTeamCardTabs
local TAB_ENUM = {
	MAIN = 'main',
	SUB = 'sub',
	STAFF = 'staff',
	FORMER = 'former',
}

---@type table<ParticipantsTeamCardTabs, {title: string, order: integer}>
local TAB_DATA = {
	[TAB_ENUM.MAIN] = {title = 'Main', order = 1},
	[TAB_ENUM.SUB] = {title = 'Subs', order = 2},
	[TAB_ENUM.FORMER] = {title = 'Former', order = 3},
	[TAB_ENUM.STAFF] = {title = 'Staff', order = 4},
}

---@param player table
---@return ParticipantsTeamCardTabs
local function getPlayerTab(player)
	local status = player.extradata.status
	if status == 'former' then return TAB_ENUM.FORMER end
	if status == 'sub' then return TAB_ENUM.SUB end
	if player.extradata.type == 'staff' then return TAB_ENUM.STAFF end
	return TAB_ENUM.MAIN
end

-- The biz logic behind the role display is somewhat complicated.
-- There's 2 areas we show the role, left-role and right-role
-- * Right-role:
--   * If the person has a specific status (did not play/former), display it first
--   * If there's a non-ingame role assigned, display it after the status
--   * Returns an array of labels to display (can be multiple)
-- * Left-role:
--   * If the first role has an icon, we use that to render the left-role
--   * If not then we instead display the icon or text of the first ingame role
---@param player table
---@return string?, string[]?
local function getRoleDisplays(player)
	local roles = player.extradata.roles or {}
	local played = player.extradata.played

	local function roleLeftDisplay()
		local firstRole = roles[1]
		if firstRole and firstRole.icon then
			return firstRole.icon
		end
		for _, role in ipairs(roles) do
			if role.type == RoleUtil.ROLE_TYPE.INGAME then
				return role.icon or role.display
			end
		end
	end
	local function roleRightDisplay()
		local rightRoles = {}
		-- Add status label first (Left or DNP)
		if player.extradata.status == 'former' then
			table.insert(rightRoles, 'Left')
		elseif not played then
			table.insert(rightRoles, 'DNP')
		end
		-- Add non-ingame role if present
		for _, role in ipairs(roles) do
			if role.type ~= RoleUtil.ROLE_TYPE.INGAME then
				table.insert(rightRoles, role.display)
				break
			end
		end
		return #rightRoles > 0 and rightRoles or nil
	end
	return roleLeftDisplay(), roleRightDisplay()
end

---@class ParticipantsTeamRoster: Widget
---@operator call(table): ParticipantsTeamRoster
local ParticipantsTeamRoster = Class.new(Widget)

---@return Widget
function ParticipantsTeamRoster:render()
	local participant = self.props.participant

	-- Used for making the sorting stable
	local sortPlayers = function(players)
		if participant.playersAreSorted then
			return players
		end

		local playerToIndex = Table.map(players, function(index, player) return player, index end)
		return Array.sortBy(players, FnUtil.identity, function(a, b)
			local function getPlayerSortOrder(player)
				local roles = player.extradata.roles or {}
				return roles[1] and roles[1].sortOrder or math.huge
			end
			local orderA = getPlayerSortOrder(a)
			local orderB = getPlayerSortOrder(b)
			if orderA == orderB then
				return playerToIndex[a] < playerToIndex[b]
			end
			return orderA < orderB
		end)
	end

	local makePlayerWidget = function(player, index)
		local playerTeam = participant.opponent.template ~= player.team and player.team or nil
		local playerTeamAsOpponent = playerTeam and Opponent.readOpponentArgs{
			type = Opponent.team,
			template = playerTeam,
		} or nil
		local roleLeft, roleRight = getRoleDisplays(player)
		return ParticipantsTeamMember{
			player = player,
			team = playerTeamAsOpponent,
			even = index % 2 == 0,
			roleLeft = roleLeft,
			roleRight = roleRight,
			trophies = player.extradata.trophies or 0,
		}
	end

	---@param groups {label: string?, players: table[]}[]
	---@return Widget
	local makeRostersDisplay = function(groups)
		local children = {}
		for _, group in ipairs(groups) do
			if group.label then
				table.insert(children, Div{
					classes = {'team-participant-card__subheader'},
					children = group.label,
				})
			end
			table.insert(children, Div{
				classes = { 'team-participant-roster' },
				children = Array.map(group.players, makePlayerWidget),
			})
		end
		return Div{
			classes = { 'team-participant-roster' },
			children = children,
		}
	end

	local tabs = Array.map(Table.entries(TAB_DATA), function(tabTuple)
		local tabTypeEnum, tabData = tabTuple[1], tabTuple[2]
		local tabPlayers = sortPlayers(Array.filter(participant.opponent.players or {}, function(player)
			return getPlayerTab(player) == tabTypeEnum
		end))

		local groups
		if tabTypeEnum == TAB_ENUM.FORMER then
			local formerPlayers = Array.filter(tabPlayers, function(player)
				return player.extradata.type ~= 'staff'
			end)
			local formerStaff = Array.filter(tabPlayers, function(player)
				return player.extradata.type == 'staff'
			end)
			if #formerPlayers > 0 and #formerStaff > 0 then
				groups = {
					{ label = 'Players', players = formerPlayers },
					{ label = 'Staff', players = formerStaff },
				}
			end
		end
		if not groups then
			groups = { { players = tabPlayers } }
		end

		return {
			order = tabData.order,
			title = tabData.title,
			type = tabTypeEnum,
			groups = groups,
			players = tabPlayers,
		}
	end)

	tabs = Array.filter(tabs, function(tab)
		return #tab.players > 0
	end)
	if self.props.mergeStaffTabIfOnlyOneStaff
		and #tabs == 2
		and tabs[1].type == TAB_ENUM.MAIN
		and tabs[2].type == TAB_ENUM.STAFF
		and #tabs[2].players == 1
	then
		-- If we only have main and staff, and exactly one staff, just show both rosters without a switch
		local mergedPlayers = sortPlayers(Array.extend(tabs[1].players, tabs[2].players))
		return makeRostersDisplay({ { players = mergedPlayers } })
	end
	tabs = Array.sortBy(tabs, Operator.property('order'))

	local switchGroupUniqueId = tonumber(Variables.varDefault('teamParticipantRostersSwitchGroupId')) or 0
	switchGroupUniqueId = switchGroupUniqueId + 1
	Variables.varDefine('teamParticipantRostersSwitchGroupId', switchGroupUniqueId)

	return ContentSwitch{
		switchGroup = 'team-participant-rosters-'.. switchGroupUniqueId,
		storeValue = false,
		css = {margin = '0.25rem 0.5rem'},
		tabs = Array.map(tabs, function(tab)
			return {
				label = tab.title,
				content = makeRostersDisplay(tab.groups),
			}
		end),
	}
end

return ParticipantsTeamRoster
