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

local CenterDot = Lua.import('Module:Widget/MainPage/CenterDot')
local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local Link = Lua.import('Module:Widget/Basic/Link')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class TransfersListParameters
---@field limit integer?
---@field rumours boolean?
---@field transferPortal string?
---@field transferPage fun():string
---@field transferQuery boolean?
---@field onlyNotableTransfers boolean?

---@class TransfersList: Widget
---@operator call(table): TransfersList
---@field props TransfersListParameters
local TransfersList = Class.new(Widget)
TransfersList.defaultProps = {
	limit = 15,
	rumours = false,
	transferPortal = 'Portal:Transfers',
	transferPage = function ()
		return 'Player Transfers/' .. os.date('%Y') .. '/' .. os.date('%B')
	end,
	transferQuery = true
}

function TransfersList:render()
	return WidgetUtil.collect(
		TransferList{
			limit = self.props.limit,
			onlyNotableTransfers = self.props.onlyNotableTransfers,
		}:fetch():create(),
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
					children = Array.interleave(WidgetUtil.collect(
						Link { children = 'See more transfers', link = self.props.transferPortal },
						Logic.readBool(self.props.transferQuery) and Link {
							children = 'Transfer query',
							link = 'Special:RunQuery/Transfer history'
						} or nil,
						Link { children = 'Input Form', link = 'lpcommons:Special:RunQuery/Transfer' },
						Logic.readBool(self.props.rumours) and Link { children = 'Rumours', link = 'Portal:Rumours' } or nil
					), CenterDot())
				},
			}
		}
	)
end

return TransfersList
