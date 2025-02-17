---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Infobox/Chronology
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local InlineIconAndText = Lua.import('Module:Widget/Misc/InlineIconAndText')
local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')

---@class ChronologyWidget: Widget
---@operator call(table): ChronologyWidget
---@field links table<string, string|number|nil>
local Chronology = Class.new(Widget)

---@return string?
function Chronology:render()
	if Table.isEmpty(self.props.links) then
		return
	end

	return HtmlWidgets.Fragment{
		children = Array.mapIndexes(function(index)
			local prevKey, nextKey = 'previous' .. index, 'next' .. index
			if index == 1 then
				prevKey, nextKey = 'previous', 'next'
			end
			return self:_createChronologyRow(self.props.links[prevKey], self.props.links[nextKey])
		end)
	}
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

