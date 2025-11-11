---
-- @Liquipedia
-- page=Module:Widget/Participants/Team/Card
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Opponent = Lua.import('Module:Opponent/Custom')

local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local ParticipantsTeamHeader = Lua.import('Module:Widget/Participants/Team/Header')
local ParticipantsTeamMember = Lua.import('Module:Widget/Participants/Team/TeamMember')
local Collapsible = Lua.import('Module:Widget/GeneralCollapsible/Default')

---@class ParticipantsTeamCard: Widget
---@operator call(table): ParticipantsTeamCard
local ParticipantsTeamCard = Class.new(Widget)

---@return Widget
function ParticipantsTeamCard:render()
	local participant = self.props.participant

	return Collapsible{
		titleWidget = ParticipantsTeamHeader{participant = participant},
		shouldCollapse = true,
		collapseAreaClasses = {'team-participant-card-collapsible-content'},
		classes = {'team-participant-card'},
		children = self:_renderContent(participant)
	}
end

-- The biz logic behind the role display is somewhat complicated.
-- There's 2 areas we show the role, left-role and right-role
-- * Right-role:
--   * is only shown if there's a non-ingame role assigned. It will use the first one provided
-- * Left-role:
--   * If the first role has an icon, we use that to render the left-role
--   * If not then we instead display the text of the first ingame role
---@param roles RoleData
---@return string?, string?
local function getRoleDisplays(roles)
	local function roleLeftDisplay()
		for _, role in ipairs(roles) do
			if role.icon then
				return role.icon
			end
		end
		for _, role in ipairs(roles) do
			if role.type == 'ingame' then
				return role.display
			end
		end
	end
	local function roleRightDisplay()
		for _, role in ipairs(roles) do
			if role.type ~= 'ingame' then
				return role.display
			end
		end
		return nil
	end
	return roleLeftDisplay(), roleRightDisplay()
end

---@private
---@param participant TeamParticipant
---@return Widget
function ParticipantsTeamCard:_renderContent(participant)
	return Div{
		classes = { 'team-participant-card-collapsible-content' },
		children = WidgetUtil.collect(
			participant.opponent.name,
			-- TODO: Qualifier box here
			Div{
				classes = { 'team-participant-roster' },
				children = Array.map(participant.opponent.players, function(player, index)
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
			-- TODO: Notes
		)
	}
end

return ParticipantsTeamCard
