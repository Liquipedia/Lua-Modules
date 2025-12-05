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

---@type table<string, ParticipantsTeamCardTabs>
local PERSON_TYPE_TO_TAB = {
	player = TAB_ENUM.MAIN,
	sub = TAB_ENUM.SUB,
	former = TAB_ENUM.FORMER,
	staff = TAB_ENUM.STAFF,
}


-- The biz logic behind the role display is somewhat complicated.
-- There's 2 areas we show the role, left-role and right-role
-- * Right-role:
--   * If there's a non-ingame role assigned. It will use the first one provided
--   * Otherwise, If the person has a specific other data (former/did not play), we will use that
-- * Left-role:
--   * If the first role has an icon, we use that to render the left-role
--   * If not then we instead display the icon or text of the first ingame role
---@param player table
---@return string?, string?
local function getRoleDisplays(player)
	local roles = player.extradata.roles or {}
	local playerType = player.extradata.type
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
		for _, role in ipairs(roles) do
			if role.type ~= RoleUtil.ROLE_TYPE.INGAME then
				return role.display
			end
		end
		if playerType == 'former' then
			return 'Left'
		elseif not played then
			return 'DNP'
		end
	end
	return roleLeftDisplay(), roleRightDisplay()
end

---@class ParticipantsTeamRoster: Widget
---@operator call(table): ParticipantsTeamRoster
local ParticipantsTeamRoster = Class.new(Widget)

---@return Widget
function ParticipantsTeamRoster:render()
	local participant = self.props.participant
	local makeRostersDisplay = function(players)
		-- Used for making the sorting stable
		local playerToIndex = Table.map(players, function(index, player) return player, index end)
		-- Sort the players based on their roles first, then by their original order
		players = Array.sortBy(players, FnUtil.identity, function (a, b)
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
		return Div{
			classes = { 'team-participant-roster' },
			children = Array.map(players, function(player, index)
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
					strikethrough = player.extradata.type == 'former',
				}
			end)
		}
	end

	local tabs = Array.map(Table.entries(TAB_DATA), function(tabTuple)
		local tabTypeEnum, tabData = tabTuple[1], tabTuple[2]
		local tabPlayers = Array.filter(participant.opponent.players or {}, function(player)
			local personType = player.extradata.type
			return PERSON_TYPE_TO_TAB[personType] == tabTypeEnum
		end)
		return {
			order = tabData.order,
			title = tabData.title,
			type = tabTypeEnum,
			players = tabPlayers,
		}
	end)

	tabs = Array.filter(tabs, function(tab)
		return #tab.players > 0
	end)
	if #tabs == 2 and tabs[1].type == TAB_ENUM.MAIN and tabs[2].type == TAB_ENUM.STAFF and #tabs[2].players == 1 then
		-- If we only have main and staff, and exactly one staff, just show both rosters without a switch
		return makeRostersDisplay(Array.concat(tabs[1].players, tabs[2].players))
	end
	tabs = Array.sortBy(tabs, Operator.property('order'))

	local switchGroupUniqueId = tonumber(Variables.varDefault('teamParticipantRostersSwitchGroupId')) or 0
	switchGroupUniqueId = switchGroupUniqueId + 1
	Variables.varDefine('teamParticipantRostersSwitchGroupId', switchGroupUniqueId)

	return ContentSwitch{
		switchGroup = 'team-participant-rosters-'.. switchGroupUniqueId,
		variant = 'generic',
		storeValue = false,
		size = 'small',
		css = {margin = '0.25rem 0.5rem'},
		tabs = Array.map(tabs, function(tab)
			return {
				label = tab.title,
				content = makeRostersDisplay(tab.players),
			}
		end),
	}
end

return ParticipantsTeamRoster
