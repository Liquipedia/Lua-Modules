---
-- @Liquipedia
-- page=Module:Widget/Match/PageButton
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local DateExt = Lua.import('Module:Date/Ext')
local Logic = Lua.import('Module:Logic')

local Info = Lua.import('Module:Info')
local Widget = Lua.import('Module:Widget')
local Button = Lua.import('Module:Widget/Basic/Button')
local Icon = Lua.import('Module:Widget/Image/Icon/Fontawesome')

local SHOW_STREAMS_WHEN_LESS_THAN_TO_LIVE = 2 * 60 * 60 -- 2 hours in seconds

---@class MatchPageButton: Widget
---@operator call(table): MatchPageButton
local MatchPageButton = Class.new(Widget)
MatchPageButton.defaultProps = {
	buttonType = 'secondary',
}

---@return Widget?
function MatchPageButton:render()
	if not Info.config.match2.matchPage then
		return nil
	end
	local match = self.props.match
	if not match then
		return nil
	end

	-- TODO: This logic is duplicated in MatchButtonBar.lua, and should be refactored.
	local showMatchDetails = match.phase == 'finished' or match.phase == 'ongoing'
	if match.phase == 'upcoming' and match.timestamp and
		os.difftime(match.timestamp, DateExt.getCurrentTimestamp()) < SHOW_STREAMS_WHEN_LESS_THAN_TO_LIVE then

		showMatchDetails = true
	end

	-- Original Match Id must be used to link match page if it exists.
	-- It can be different from the matchId when shortened brackets are used.
	local matchId = match.extradata.originalmatchid or match.matchId

	local link = 'Match:ID ' .. matchId

	if Logic.isNotEmpty(match.bracketData.matchPage) then
		return Button{
			classes = { showMatchDetails and 'show-when-logged-in' or nil},
			title = 'View match details',
			variant = self.props.buttonType,
			size = 'sm',
			link = link,
			grow = true,
			children = {
				Icon{iconName = 'matchpagelink'},
				' ',
				'View match details',
			}
		}
	end

	return Button{
		classes = { 'show-when-logged-in' },
		title = 'Make match page',
		variant = 'ghost',
		size = 'sm',
		link = link,
		grow = true,
		children = {
			'+ Add details',
		}
	}
end

return MatchPageButton
