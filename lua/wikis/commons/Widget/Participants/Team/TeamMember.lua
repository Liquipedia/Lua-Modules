---
-- @Liquipedia
-- page=Module:Widget/Participants/Team/TeamMember
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')
local PlayerDisplay = Lua.import('Module:Player/Display/Custom')

local Component = Lua.import('Module:Widget/Component')
local Icon = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local WidgetUtil = Lua.import('Module:Widget/Util')
local Html = Lua.import('Module:Widget/Html')
local Div = Html.Div

---@param props {even: boolean?, roleLeft: string?, roleRight: string[]?, trophies: integer?,
---strikethrough: boolean?, player: standardPlayer, team: standardOpponent?, number: integer?}
---@return Widget
local function ParticipantsTeamMember(props)
	local isEven = props.even
	local roleLeft = props.roleLeft
	local roleRight = props.roleRight
	local trophies = props.trophies
	local player = props.player
	local team = props.team
	local number = props.number

	local trophyIcon = Icon{iconName = 'firstplace'}

	local function renderRoleRight()
		if not roleRight then
			return nil
		end
		local labels = roleRight
		if #labels == 0 then
			return nil
		end
		return Array.map(labels, function(label)
			return Div{
				classes = {'team-participant-card__member-role-right'},
				children = label,
			}
		end)
	end

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
					dq = props.strikethrough,
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
			renderRoleRight(),
			team and Div{
				classes = {'team-participant-card__member-team'},
				children = OpponentDisplay.BlockOpponent({
					opponent = team,
					teamStyle = 'icon',
					additionalClasses = {'team-participant-icon'}
				}),
			} or nil,
			number and Div{
				classes = {'team-participant-card__member-role-right'},
				children = tostring(number),
			} or nil
		)
	}
end

return Component.component(ParticipantsTeamMember)
