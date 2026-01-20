---
-- @Liquipedia
-- page=Module:Widget/Participants/Team/Wrapper
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Controller = Lua.import('Module:TeamParticipants/Controller')
local Json = Lua.import('Module:Json')
local Table = Lua.import('Module:Table')
local Tabs = Lua.import('Module:Tabs')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local ParticipantsTeamCardSwitch = Lua.import('Module:Widget/Participants/Team/Switch')


---@class ParticipantsTeamCardsGroupWrapper: Widget
---@operator call(table): ParticipantsTeamCardsGroupWrapper
local ParticipantsTeamCardsGroupWrapper = Class.new(Widget)

---@return Widget?
function ParticipantsTeamCardsGroupWrapper:render()
	local names = {}
	local cardsGroups = Array.mapIndexes(function(inputIndex)
		local input = Json.parseIfTable(self.props[inputIndex])
		if not input then return end
		table.insert(names, self.props['header' .. inputIndex])
		return Controller.fromTemplate(Table.merge(input, {suppressSwitch = true}))
	end)

	local tabArgs = {}
	Array.forEach(cardsGroups, function(cardsGroup, tabIndex)
		tabArgs['name' .. tabIndex] = names[tabIndex]
		tabArgs['content' .. tabIndex] = cardsGroup
	end)

	return Div{
		classes = { 'team-participant' },
		children = {
			ParticipantsTeamCardSwitch(),
			Tabs.dynamic(tabArgs),
		},
	}
end

return ParticipantsTeamCardsGroupWrapper
