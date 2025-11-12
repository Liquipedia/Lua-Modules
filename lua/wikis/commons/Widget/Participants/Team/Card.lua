---
-- @Liquipedia
-- page=Module:Widget/Participants/Team/Card
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Operator = Lua.import('Module:Operator')
local Opponent = Lua.import('Module:Opponent/Custom')
local Table = Lua.import('Module:Table')
local RoleUtil = Lua.import('Module:Role/Util')

local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')
local Collapsible = Lua.import('Module:Widget/GeneralCollapsible/Default')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local TeamHeader = Lua.import('Module:Widget/Participants/Team/Header')
local ParticipantsTeamMember = Lua.import('Module:Widget/Participants/Team/TeamMember')
local ParticipantNotification = Lua.import('Module:Widget/Participants/Team/ParticipantNotification')
local TeamQualifierInfo = Lua.import('Module:Widget/Participants/Team/QualifierInfo')
local ContentSwitch = Lua.import('Module:Widget/ContentSwitch')

local TAB_ENUM = {
	main = 'main',
	sub = 'sub',
	staff = 'staff',
	former = 'former',
}

local TAB_DATA = {
	[TAB_ENUM.main] = {title = 'Main', order = 1},
	[TAB_ENUM.sub] = {title = 'Subs', order = 2},
	[TAB_ENUM.former] = {title = 'Former', order = 3},
	[TAB_ENUM.staff] = {title = 'Staff', order = 4},
}

local PERSON_TYPE_TO_TAB = {
	player = TAB_ENUM.main,
	sub = TAB_ENUM.sub,
	former = TAB_ENUM.former,
	staff = TAB_ENUM.staff,
}

---@class ParticipantsTeamCard: Widget
---@operator call(table): ParticipantsTeamCard
local ParticipantsTeamCard = Class.new(Widget)

---@return Widget
function ParticipantsTeamCard:render()
	local participant = self.props.participant

	local qualifierInfoHeader = TeamQualifierInfo{participant = participant, location = 'header'}
	local qualifierInfoContent = TeamQualifierInfo{participant = participant, location = 'content'}

	return Collapsible{
		shouldCollapse = true,
		collapseAreaClasses = {'team-participant-card-collapsible-content'},
		classes = {'team-participant-card'},
		titleWidget = Div{
			children = {
				TeamHeader{
					participant = participant,
				},
				qualifierInfoHeader
			}
		},
		children = {
			qualifierInfoContent,
			self:_renderContent(participant)
		}
	}
end

-- The biz logic behind the role display is somewhat complicated.
-- There's 2 areas we show the role, left-role and right-role
-- * Right-role:
--   * is only shown if there's a non-ingame role assigned. It will use the first one provided
-- * Left-role:
--   * If the first role has an icon, we use that to render the left-role
--   * If not then we instead display the icon or text of the first ingame role
---@param roles RoleData[]
---@return string?, string?
local function getRoleDisplays(roles)
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
	end
	return roleLeftDisplay(), roleRightDisplay()
end

---@private
---@param participant TeamParticipant
---@return Widget
function ParticipantsTeamCard:_renderContent(participant)
	local makeRostersDisplay = function(players)
		return Div{
			classes = { 'team-participant-roster' },
			children = Array.map(players, function(player, index)
				local playerTeam = participant.opponent.template ~= player.team and player.team or nil
				local playerTeamAsOpponent = playerTeam and Opponent.readOpponentArgs{
					type = Opponent.team,
					template = playerTeam,
				} or nil
				local roleLeft, roleRight = getRoleDisplays(player.extradata.roles or {})
				return ParticipantsTeamMember{
					player = player,
					team = playerTeamAsOpponent,
					even = index % 2 == 0,
					roleLeft = roleLeft,
					roleRight = roleRight,
					trophies = player.extradata.trophies or 0,
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
			players = tabPlayers,
		}
	end)

	tabs = Array.filter(tabs, function(tab)
		return #tab.players > 0
	end)
	tabs = Array.sortBy(tabs, Operator.property('order'))

	return Div{
		classes = { 'team-participant-card-collapsible-content' },
		children = WidgetUtil.collect(
			participant.opponent.name,
			-- TODO: Qualifier box here
			(#tabs > 1 and ContentSwitch{
				switchGroup = 'team-participant-rosters',
				variant = 'generic',
				storeValue = false,
				size = 'small',
				tabs = Array.map(tabs, function(tab)
					return {
						label = tab.title,
						content = makeRostersDisplay(tab.players),
					}
				end),
			}) or (#tabs == 1 and makeRostersDisplay(tabs[1].players)) or nil,
			Array.map(participant.notes or {}, function(note)
				return ParticipantNotification{
					text = note.text,
					highlighted = note.highlighted,
				}
			end)
		)
	}
end

return ParticipantsTeamCard
