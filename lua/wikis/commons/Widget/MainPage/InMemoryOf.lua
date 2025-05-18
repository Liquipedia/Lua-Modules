---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/MainPage/InMemoryOf
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local NameOrder = require('Module:NameOrder')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Link = Lua.import('Module:Widget/Basic/Link')

---@class InMemoryOfProperties
---@field pageLink string
---@field nameOrder ('eastern'|'western')?
---@field id string?
---@field nationality string?
---@field givenName string
---@field familyName string

---@class InMemoryOfWidget: Widget
---@field props InMemoryOfProperties
---@operator call(table): InMemoryOfWidget
local InMemoryOfWidget = Class.new(Widget)

function InMemoryOfWidget:_loadFromLPDB()
	local data = mw.ext.LiquipediaDB.lpdb('player', {
		conditions = '[[pagename::' .. self.props.pageLink .. ']]',
		query = 'pagename, id, nationality',
		limit = 1,
	})
	if type(data) ~= 'table' then
		return
	end
	self.props.id = Logic.emptyOr(self.props.id, data[1].id)
	self.props.nationality = Logic.emptyOr(self.props.nationality, data[1].nationality)
end

function InMemoryOfWidget:render()
	self:_loadFromLPDB()

	local firstname, lastname = NameOrder.reorderNames(
		self.props.givenName,
		self.props.familyName,
		{
			forceEasternOrder = self.props.nameOrder == 'eastern',
			forceWesternOrder = self.props.nameOrder == 'western',
			country = self.props.nationality
		}
	)

	return HtmlWidgets.Div{
		classes = { 'sadbox' },
		children = {
			Link {
				link = self.props.pageLink,
				children = HtmlWidgets.Fragment{
					children = {
						'In memory of ',
						firstname,
						' "',
						HtmlWidgets.Strong{
							children = { self.props.id }
						},
						'" ',
						lastname,
						' 🖤'
					}
				}
			}
		}
	}
end

return InMemoryOfWidget
