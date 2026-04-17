---
-- @Liquipedia
-- page=Module:Widget/Participants/Team/ParticipantControls
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local PageVariableNamespace = Lua.import('Module:PageVariableNamespace')

local Widget = Lua.import('Module:Widget')
local AnalyticsWidget = Lua.import('Module:Widget/Analytics')
local Button = Lua.import('Module:Widget/Basic/Button')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local Icon = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local Switch = Lua.import('Module:Widget/Switch')
local WidgetUtil = Lua.import('Module:Widget/Util')

local teamParticipantsVars = PageVariableNamespace('TeamParticipants')

---@class ParticipantsTeamParticipantControlsProps
---@field showPlayerInfo boolean
---@field externalUsage boolean

---@class ParticipantsTeamParticipantControls: Widget
---@operator call(ParticipantsTeamParticipantControlsProps): ParticipantsTeamParticipantControls
---@field props ParticipantsTeamParticipantControlsProps
local ParticipantsTeamParticipantControls = Class.new(Widget, function(self, props)
	if Logic.readBool(props.externalUsage) then
		teamParticipantsVars:set('externalControlsRendered', 'true')
	end
	self.props.showPlayerInfo = Logic.readBool(self.props.showPlayerInfo or self.props.showplayerinfo)
end)

ParticipantsTeamParticipantControls.defaultProps = {
	showPlayerInfo = false,
	externalUsage = false,
}

---@return Widget?
function ParticipantsTeamParticipantControls:_buildPlayerInfoButton()
	if not Logic.readBool(self.props.showPlayerInfo) then
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

---@return Widget?
function ParticipantsTeamParticipantControls:render()
	local children = WidgetUtil.collect(
		self:_buildPlayerInfoButton(),
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

return ParticipantsTeamParticipantControls
