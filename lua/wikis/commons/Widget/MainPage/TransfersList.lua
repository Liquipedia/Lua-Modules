---
-- @Liquipedia
-- page=Module:Widget/MainPage/TransfersList
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local DateExt = Lua.import('Module:Date/Ext')
local Logic = Lua.import('Module:Logic')
local Page = Lua.import('Module:Page')

local TransferList = Lua.import('Module:TransferList')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local Link = Lua.import('Module:Widget/Basic/Link')
local UnorderedList = Lua.import('Module:Widget/List/Unordered')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class TransfersListParameters
---@field limit integer?
---@field rumours boolean?
---@field transferPortal string?
---@field transferPage string?
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
	transferPage = 'Player Transfers/' .. DateExt.getYearOf() .. '/' .. os.date('%B'),
	transferQuery = true
}

---@return Renderable[]
function TransfersList:render()
	return WidgetUtil.collect(
		TransferList{
			limit = self.props.limit,
			onlyNotableTransfers = self.props.onlyNotableTransfers,
		}:fetch():create(),
		Div{
			css = {
				display = 'grid',
				['grid-template-columns'] = '1fr auto 1fr',
				['align-items'] = 'center',
				padding = '0.5rem',
				gap = '0.25rem',
			},
			children = {
				Div{
					css = {
						['font-style'] = 'italic',
						['justify-self'] = 'flex-start',
						['white-space'] = 'nowrap',
					},
					children = Link{children = 'Back to top', link = '#Top'},
				},
				Div{
					classes = {'hlist'},
					css = {
						['font-size'] = '15px',
						['font-style'] = 'italic',
						['text-align'] = 'center',
					},
					children = UnorderedList{children = WidgetUtil.collect(
						Link { children = 'See more transfers', link = self.props.transferPortal },
						Logic.readBool(self.props.transferQuery) and Link {
							children = 'Transfer query',
							link = 'Special:RunQuery/Transfer history'
						} or nil,
						Link {
							children = 'Input Form',
							link = (Page.exists('Form:Transfer') and '' or 'lpcommons:') .. 'Special:RunQuery/Transfer'
						},
						Logic.readBool(self.props.rumours) and Link { children = 'Rumours', link = 'Portal:Rumours' } or nil
					)}
				},
				Div{
					classes = { 'plainlinks', 'smalledit' },
					css = {
						['justify-self'] = 'flex-end',
					},
					children = {
						'&#91;',
							Link {
							children = 'edit',
							link = 'Special:EditPage/' .. self.props.transferPage
						},
						'&#93;'
					},
				},
			}
		}
	)
end

return TransfersList
