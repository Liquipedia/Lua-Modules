---
-- @Liquipedia
-- page=Module:Widget/Infobox/Chronology
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local Table = Lua.import('Module:Table')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local InlineIconAndText = Lua.import('Module:Widget/Misc/InlineIconAndText')
local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local Title = Lua.import('Module:Widget/Infobox/Title')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class ChronologyWidget: Widget
---@operator call(table): ChronologyWidget
---@field links table<string, string|number|nil>?
---@field title string
---@field showTitle boolean
---@field args table?
local Chronology = Class.new(Widget)
Chronology.defaultProps = {
	title = 'Chronology',
	showTitle = true,
}

---@return Widget?
function Chronology:render()
	local links = self.props.links or Chronology._getChronologyData(self.props.args or {})
	if Table.isEmpty(links) then
		return
	end

	return HtmlWidgets.Fragment{
		children = WidgetUtil.collect(
			self.props.showTitle and Title{children = self.props.title} or nil,
			Array.mapIndexes(function(index)
				local prevKey, nextKey = 'previous' .. index, 'next' .. index
				if index == 1 then
					prevKey, nextKey = 'previous', 'next'
				end
				return self:_createChronologyRow(links[prevKey], links[nextKey])
			end)
		)
	}
end

---@param args table
---@return table
function Chronology._getChronologyData(args)
	return Table.filterByKey(args, function(key)
		return type(key) == 'string' and (key:match('^previous%d?$') ~= nil or key:match('^next%d?$') ~= nil)
	end)
end

---@param previous string|number|nil
---@param next string|number|nil
---@return Html?
function Chronology:_createChronologyRow(previous, next)
	local doesPreviousExist = Logic.isNotEmpty(previous)
	local doesNextExist = Logic.isNotEmpty(next)

	if not doesPreviousExist and not doesNextExist then
		return nil
	end

	local function splitInputIntoLinkAndText(input)
		return unpack(mw.text.split(input, '|'))
	end

	local function nextSlot()
		if not doesNextExist then
			return
		end
		local link, text = splitInputIntoLinkAndText(next)
		return Div{
			classes = {'infobox-cell-2', 'infobox-text-right'},
			children = {
				InlineIconAndText{
					link = link,
					text = text,
					icon = IconFa{
						iconName = 'next',
						link = link,
					},
					flipped = true,
				}
			}
		}
	end

	local function prevSlot()
		if not doesPreviousExist then
			return
		end
		local link, text = splitInputIntoLinkAndText(previous)
		return Div{
			classes = {'infobox-cell-2', 'infobox-text-left'},
			children = {
				InlineIconAndText{
					link = link,
					text = text,
					icon = IconFa{
						iconName = 'previous',
						link = link,
					},
				}
			}
		}
	end

	return Div{
		children = {
			prevSlot() or Div{classes = {'infobox-cell-2'}},
			nextSlot(),
		}
	}
end

return Chronology

