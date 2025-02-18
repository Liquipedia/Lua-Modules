---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Ratings/Dropdown
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Patch = Lua.import('Module:Patch')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Widget = Lua.import('Module:Widget')

---@class RatingsDropdown: Widget
---@operator call(table): RatingsDropdown
local RatingsDropdown = Class.new(Widget)

--todo: rename to select instead of dropdown later
function RatingsDropdown:render()
	return HtmlWidgets.Div{
		attributes = {
			class = 'ranking-table__select-container',
			['data-ranking-table'] = 'select-container',
		},
		children = {
			HtmlWidgets.Div{
				attributes = {
					['data-ranking-table'] = 'select-data-container',
				},
				children = Array.map(self.props.dates, function(date)
					local patchOnDate = Patch.getPatchByDate(date)
					local patchName = patchOnDate and patchOnDate.displayName or 'Unknown'

					return HtmlWidgets.Div{
						attributes = {
							['data-ranking-table'] = 'select-data',
							['data-date'] = date,
							['data-name'] = patchName,
						},
					}
				end),
			},
			HtmlWidgets.Span{
				attributes = {
					class = 'ranking-table__patch-label',
					['data-ranking-table'] = 'patch-label',
				},
			},
		},
	}
end

return RatingsDropdown
