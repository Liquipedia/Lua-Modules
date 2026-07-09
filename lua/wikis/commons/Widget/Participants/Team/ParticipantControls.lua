---
-- @Liquipedia
-- page=Module:Widget/Participants/Team/ParticipantControls
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Logic = Lua.import('Module:Logic')
local PageVariableNamespace = Lua.import('Module:PageVariableNamespace')

local Component = Lua.import('Module:Widget/Component')
local AnalyticsWidget = Lua.import('Module:Widget/Analytics')
local Button = Lua.import('Module:Widget/Basic/Button')
local Html = Lua.import('Module:Widget/Html')
local Div = Html.Div
local Icon = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local Switch = Lua.import('Module:Widget/Switch')
local WidgetUtil = Lua.import('Module:Widget/Util')

local teamParticipantsVars = PageVariableNamespace('TeamParticipants')

---@class ParticipantsTeamParticipantControlsProps
---@field showPlayerInfo boolean
---@field externalUsage boolean?

local defaultProps = {
	showPlayerInfo = false,
	externalUsage = false,
}

---@param showPlayerInfo boolean?
---@return VNode?
local function buildPlayerInfoButton(showPlayerInfo)
	if not Logic.readBool(showPlayerInfo) then
		return nil
	end

	local pageName = mw.title.getCurrentTitle().fullText
	local link = tostring(mw.uri.fullUrl('Special:RunQuery/Tournament_player_information', {
		pfRunQueryFormName = 'Tournament player information',
		['TPI[page]'] = pageName,
		wpRunQuery = 'Run query'
	}))

	return Button{
		title = 'Click for additional player information',
		variant = 'secondary',
		size = 'sm',
		linktype = 'external',
		link = link,
		children = { Icon{iconName = 'internal_link'}, 'Player Info' }
	}
end

---@param props ParticipantsTeamParticipantControlsProps
---@return VNode
local function ParticipantsTeamParticipantControls(props)
	if Logic.readBool(props.externalUsage) then
		teamParticipantsVars:set('externalControlsRendered', 'true')
	end
	local showPlayerInfo = Logic.nilOr(
		---@diagnostic disable-next-line: undefined-field
		Logic.readBoolOrNil(props.showplayerinfo),
		Logic.readBool(props.showPlayerInfo)
	) --[[@as boolean]]

	local children = WidgetUtil.collect(
		buildPlayerInfoButton(showPlayerInfo),
		AnalyticsWidget{
			analyticsName = 'ParticipantsShowRostersSwitch',
			analyticsProperties = {
				['track-value-as'] = 'participants show rosters',
			},
			children = Switch{
				label = 'Show rosters',
				switchGroup = 'team-cards-show-rosters',
				defaultActive = false,
				collapsibleSelector = '.team-participant-card',
			},
		},
		AnalyticsWidget{
			analyticsName = 'ParticipantsCompactSwitch',
			analyticsProperties = {
				['track-value-as'] = 'participants compact',
			},
			children = Switch{
				label = 'Compact view',
				switchGroup = 'team-cards-compact',
				defaultActive = true,
			},
		},
		AnalyticsWidget{
			analyticsName = 'ParticipantsHoverRosterSwitch',
			analyticsProperties = {
				['track-value-as'] = 'participants hover roster',
			},
			children = Switch{
				label = 'Enable hover',
				switchGroup = 'team-cards-hover-roster',
				defaultActive = true,
			},
		}
	)

	return Div{
		classes = { 'team-participant__controls' },
		children = children
	}
end

return Component.component(ParticipantsTeamParticipantControls, defaultProps)
