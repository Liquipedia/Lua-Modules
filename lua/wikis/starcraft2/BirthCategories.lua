---
-- @Liquipedia
-- page=Module:BirthCategories
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')

local Link = Lua.import('Module:Widget/Basic/Link')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

local BirthCategories = {}

---@return Widget
function BirthCategories.get()
	local yearString = string.gsub(mw.title.getCurrentTitle().text, ' births', '')
	local year = tonumber(yearString)

	local row = HtmlWidgets.Div{
		classes = {'hlist'},
		css = {['margin-left'] = '0'},
		children = HtmlWidgets.Ul{children = Array.map(Array.range((year-4), (year+4)), function(currentYear)
			return HtmlWidgets.Li{
				children = Link{link = ':Category:' .. currentYear .. ' births', children = currentYear}
			}
		end)}
	}

	return HtmlWidgets.Fragment{
		children = {
			HtmlWidgets.Table{
				classes = {'toccolours'},
				attributes = {align = 'right'},
				children = HtmlWidgets.Tr{children = HtmlWidgets.Td{children = row}}
			},
			HtmlWidgets.Br{},
			'List of people born in ' .. year .. '.'
		}
	}
end

return BirthCategories
