---
-- @Liquipedia
-- page=Module:Widget/Participants/Team/TeamMember
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')
local PlayerDisplay = Lua.import('Module:Player/Display/Custom')

local Widget = Lua.import('Module:Widget')
local Icon = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local WidgetUtil = Lua.import('Module:Widget/Util')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div

---@class ParticipantsTeamMember: Widget
---@field props {even: boolean?, roleLeft: string?, roleRight: string?, trophies: integer?, strikethrough: boolean?,
---player: standardPlayer, team: standardOpponent?}
---@operator call(table): ParticipantsTeamMember
local ParticipantsTeamMember = Class.new(Widget)

---@return Widget
function ParticipantsTeamMember:render()
	local isEven = self.props.even
	local roleLeft = self.props.roleLeft
	local roleRight = self.props.roleRight
	local trophies = self.props.trophies
	local player = self.props.player
	local team = self.props.team

	local trophyIcon = Icon{iconName = 'firstplace'}

	return Div{
		classes = {
			'team-participant-card__member',
			(not isEven) and 'team-participant-card__member--odd' or nil,
		},
		children = WidgetUtil.collect(
			roleLeft and Div{
				classes = {'team-participant-card__member-role-left'},
				children = roleLeft,
			} or nil,
			Div{
				classes = {'team-participant-card__member-name'},
				children = PlayerDisplay.BlockPlayer{
					player = player,
					showFlag = true,
					showLink = true,
					showFaction = true,
					showTbd = true,
					dq = self.props.strikethrough,
					showPlayerTeam = false,
					overflow = 'ellipsis',
				}
			},
			trophies and trophies > 0 and Div{
				classes = {'team-participant-card__member-trophies'},
				children = trophies < 4 and Array.map(Array.range(1, trophies), function()
						return trophyIcon
					end) or WidgetUtil.collect(
						Div{
							classes = {'team-participant-card__member-trophies-text'},
							children = {'x'.. trophies}
						},
						trophyIcon
					)
			} or nil,
			roleRight and Div{
				classes = {'team-participant-card__member-role-right'},
				children = roleRight,
			} or nil,
			team and Div{
				classes = {'team-participant-card__member-team'},
				children = OpponentDisplay.BlockOpponent({
					opponent = team,
					teamStyle = 'icon',
					additionalClasses = {'team-participant-icon'}
				}),
			} or nil
		)
	}
end

return ParticipantsTeamMember
