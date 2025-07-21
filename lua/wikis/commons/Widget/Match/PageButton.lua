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
MatchPageButton.defaultProps = {
	buttonType = 'secondary',
	short = true, -- Temporary until all components have been redesign with bigger buttons spaces
}

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
			title = 'View match details',
			variant = self.props.buttonType,
			size = 'sm',
			link = link,
			children = {
				Icon{iconName = 'matchpagelink'},
				'  ',
				self.props.short and 'Details' or 'View match details',
			}
		}
	end

	return Button{
		classes = { 'show-when-logged-in' },
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
