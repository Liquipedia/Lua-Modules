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
---@operator call(table): ParticipantsTeamMember
local ParticipantsTeamMember = Class.new(Widget)

---@return Widget
function ParticipantsTeamMember:render()
	---@type boolean
	local isEven = self.props.even
	---@type string?
	local roleLeft = self.props.roleLeft
	---@type string?
	local roleRight = self.props.roleRight
	---@type integer
	local trophies = self.props.trophies
	---@type standardPlayer
	local player = self.props.player
	---@type standardOpponent
	local team = self.props.team

	local trophyIcon = Icon{iconName = 'firstplace'}

	return Div{
		classes = {
			'team-member',
			isEven and 'even' or 'odd',
		},
		children = WidgetUtil.collect(
			roleLeft and Div{
				classes = {'team-member-role-left'},
				children = {
					roleLeft
				}
			} or nil,
			Div{
				classes = {'team-member-name'},
				children = {
					PlayerDisplay.BlockPlayer{
						player = player,
						showFlag = true,
						showLink = true,
						showFaction = true,
						showTbd = true,
						showPlayerTeam = false,
						overflow = 'ellipsis',
					}
				}
			},
			trophies and trophies > 0 and Div{
				classes = {'team-member-trophies'},
				children = trophies < 4 and Array.map(Array.range(1, trophies), function()
						return trophyIcon
					end) or 'x'.. trophies .. trophyIcon
			} or nil,
			roleRight and Div{
				classes = {'team-member-role-right'},
				children = {
					roleRight
				}
			} or nil,
			team and Div{
				classes = {'team-member-team'},
				children = {
					OpponentDisplay.BlockOpponent({
						opponent = team,
						teamStyle = 'icon',
					}),
				}
			} or nil
		)
	}
end

return ParticipantsTeamMember
