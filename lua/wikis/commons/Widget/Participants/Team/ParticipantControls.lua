---
-- @Liquipedia
-- page=Module:Widget/Participants/Team/ParticipantControls
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local PageVariableNamespace = Lua.import('Module:PageVariableNamespace')

local Widget = Lua.import('Module:Widget')
local AnalyticsWidget = Lua.import('Module:Widget/Analytics')
local Button = Lua.import('Module:Widget/Basic/Button')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local Icon = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local Switch = Lua.import('Module:Widget/Switch')
local WidgetUtil = Lua.import('Module:Widget/Util')

local globalVars = PageVariableNamespace()

---@class ParticipantsTeamParticipantControls: Widget
---@operator call(table): ParticipantsTeamParticipantControls
local ParticipantsTeamParticipantControls = Class.new(Widget)

---@return Widget?
function ParticipantsTeamParticipantControls:render()
	globalVars:set('teamParticipantControlsRendered', 'true')

	local pageName = mw.title.getCurrentTitle().fullText
	local link = tostring(mw.uri.fullUrl('Special:RunQuery/Tournament_player_information', {
		pfRunQueryFormName = 'Tournament player information',
		['TPI[page]'] = pageName,
		wpRunQuery = 'Run query'
	})

	local playerInfoButton
	if self.props.playerinfo then
		playerInfoButton = Button{
			title = 'Click for additional player information',
			variant = 'secondary',
			size = 'sm',
			linktype = 'external',
			link = link,
			children = WidgetUtil.collect(
				Icon{iconName = 'internal_link'},
				'Player Info'
			)
		}
	end

	local children = {
		playerInfoButton,
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
		}
	}

	children = Array.filter(children, function(child) return child ~= nil end)

	return Div{
		classes = { 'team-participant__controls' },
		children = children
	}
end

return ParticipantsTeamParticipantControls
