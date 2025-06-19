---
-- @Liquipedia
-- page=Module:Widget/Match/PageButton
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Info = Lua.import('Module:Info')
local Widget = Lua.import('Module:Widget')
local Button = Lua.import('Module:Widget/Basic/Button')
local Icon = Lua.import('Module:Widget/Image/Icon/Fontawesome')

---@class MatchPageButton: Widget
---@operator call(table): MatchPageButton
local MatchPageButton = Class.new(Widget)

---@return Widget?
function MatchPageButton:render()
	if not Info.config.match2.matchPage then
		return nil
	end
	local matchId = self.props.matchId
	if not matchId then
		return nil
	end

	local link = 'Match:ID ' .. matchId

	if self.props.hasMatchPage then
		return Button{
			classes = { 'btn--match-details' },
			title = 'View Match Page',
			variant = 'secondary',
			size = 'sm',
			link = link,
			children = {
				Icon{iconName = 'matchpagelink'},
				'  ',
				'Details',
			}
		}
	end

	return Button{
		classes = { 'btn--add-match-details', 'show-when-logged-in' },
		title = 'Add Match Page',
		variant = 'ghost',
		size = 'sm',
		link = link,
		children = {
			'+ Add details',
		}
	}
end

return MatchPageButton
