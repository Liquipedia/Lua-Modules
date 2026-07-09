---
-- @Liquipedia
-- page=Module:BirthCategories
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')

local Link = Lua.import('Module:Widget/Basic/Link')
local Html = Lua.import('Module:Widget/Html')

local BirthCategories = {}

---@return Widget
function BirthCategories.get()
	local yearString = string.gsub(mw.title.getCurrentTitle().text, ' births', '')
	local year = tonumber(yearString)

	local row = Html.Div{
		classes = {'hlist'},
		css = {['margin-left'] = '0'},
		children = Html.Ul{children = Array.map(Array.range(year - 4, year + 4), function(currentYear)
			return Html.Li{
				children = Link{link = ':Category:' .. currentYear .. ' births', children = currentYear}
			}
		end)}
	}

	return Html.Fragment{
		children = {
			Html.Table{
				classes = {'toccolours'},
				attributes = {align = 'right'},
				children = Html.Tr{children = Html.Td{children = row}}
			},
			Html.Br{},
			'List of people born in ' .. year .. '.'
		}
	}
end

return BirthCategories
