---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Summary/Ffa/MatchSchedule
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local DateExt = require('Module:Date/Ext')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local ContentItemContainer = Lua.import('Module:Widget/Match/Summary/Ffa/ContentItemContainer')
local CountdownIcon = Lua.import('Module:Widget/Match/Summary/Ffa/CountdownIcon')
local GameCountdown = Lua.import('Module:Widget/Match/Summary/Ffa/GameCountdown')

---@class MatchSummaryFfaMatchSchedule: Widget
---@operator call(table): MatchSummaryFfaMatchSchedule
local MatchSummaryFfaMatchSchedule = Class.new(Widget)

---@return Widget?
function MatchSummaryFfaMatchSchedule:render()
	if not self.props.match or DateExt.isDefaultTimestamp(self.props.match.date) then
		return nil
	end

	return ContentItemContainer{
		contentClass = 'panel-content__game-schedule',
		items = {{
			icon =  CountdownIcon{game = self.props.match},
			title = 'Match:',
			content = GameCountdown{game = self.props.match},
		}}
	}
end

return MatchSummaryFfaMatchSchedule
