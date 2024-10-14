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
local IconFa = Lua.import('Module:Widget/Icon/Fontawesome') -- TODO

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

	local function nextSlot()
		if not doesNextExist then
			return
		end
		return Div{
			classes = {'infobox-cell-2', 'infobox-text-right'},
			children = {
				-- TODO FLIPPED
				InlineIconAndText{
					link = next,
					text = next,
					icon = IconFa{
						iconName = 'next',
						link = next,
					}
				}
			}
		}
	end

	local function prevSlot()
		if not doesPreviousExist then
			return
		end
		return Div{
			classes = {'infobox-cell-2', 'infobox-text-left'},
			children = {
				InlineIconAndText{
					link = previous,
					text = previous,
					icon = IconFa{
						iconName = 'previous',
						link = previous,
					}
				}
			}
		}
	end

	return Div{
		children = {
			prevSlot() or Div{classes = 'infobox-cell-2'},
			nextSlot(),
		}
	}
end

return Chronology

