---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/InlineIconAndText
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local Link = Lua.import('Module:Widget/Link')
local Span = Lua.import('Module:Widget/Span')

---@class InlineIconAndTextWidgetParameters: WidgetParameters
---@field icon IconWidget
---@field text string?
---@field link string?

---@class InlineIconAndTextWidget: Widget
---@operator call(InlineIconAndTextWidgetParameters): InlineIconAndTextWidget

local InlineIconAndText = Class.new(
	Widget,
	function(self, input)
		local text = self:assertExistsAndCopy(input.text)
		local link = self:assertExistsAndCopy(input.link)

		local span = Span{
			classes = {'image-link'},
			children = {
				Link{
					link = link,
					linktype = 'internal',
					children = {input.icon}
				},
				' ',
				Link{
					link = link,
					linktype = 'internal',
					children = {text}
				}
			},
		}
		self.children = {span}
	end
)

---@param children string[]
---@return string
function InlineIconAndText:make(children)
	return table.concat(children)
end

return InlineIconAndText
