---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/MainPage/TransfersList
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local TransferList = Lua.import('Module:TransferList')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local Link = Lua.import('Module:Widget/Basic/Link')
local Span = HtmlWidgets.Span
local WidgetUtil = Lua.import('Module:Widget/Util')

local CENTER_DOT = Span{
	css = {
		['font-style'] = 'normal',
		padding = '0 5px',
	},
	children = { '&#8226;' }
}

---@class TransfersList: Widget
---@operator call(table): TransfersList
---@field props {limit: integer?, rumours: boolean?, transferPage: fun():string}
local TransfersList = Class.new(Widget)
TransfersList.defaultProps = {
	limit = 15,
	rumours = false,
	transferPage = function ()
		return 'Player Transfers/' .. os.date('%Y') .. '/' .. os.date('%B')
	end
}

function TransfersList:render()
	return WidgetUtil.collect(
		TransferList { limit = self.props.limit }:fetch():create(),
		Div {
			css = { display = 'block', ['text-align'] = 'center', padding = '0.5em' },
			children = {
				Div {
					css = { display = 'inline', float = 'left', ['font-style'] = 'italic' },
					children = { Link { children = 'Back to top', link = '#Top' } }
				},
				Div {
					classes = { 'plainlinks', 'smalledit' },
					css = { display = 'inline', float = 'right' },
					children = {
						'&#91;',
							Link {
							children = 'edit',
							link = 'Special:EditPage/' .. self.props.transferPage()
						},
						'&#93;'
					},
				},
				Div {
					css = {
						['white-space'] = 'nowrap',
						display = 'inline',
						margin = '0 10px',
						['font-size'] = '15px',
						['font-style'] = 'italic'
					},
					children = Array.interleave({
						Link { children = 'See more transfers', link = 'Portal:Transfers' },
						Link { children = 'Transfer query', link = 'Special:RunQuery/Transfer_history' },
						Link { children = 'Input Form', link = 'lpcommons:Special:RunQuery/Transfer' },
						Logic.readBool(self.props.rumours) and Link { children = 'Rumours', link = 'Portal:Rumours' } or nil,
					}, CENTER_DOT)
				},
			}
		}
	)
end

return TransfersList
