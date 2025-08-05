---
-- @Liquipedia
-- page=Module:WarningBox
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local WarningBox = {}

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')

---@param text string|number
---@return Html
function WarningBox.display(text)
	local tbl = mw.html.create('table')
		:tag('tr')
			:tag('td'):addClass('ambox-image'):wikitext('[[File:Emblem-important.svg|40px|link=]]'):done()
			:tag('td'):addClass('ambox-text'):wikitext(text):allDone()

	return mw.html.create('div')
		:addClass('show-when-logged-in')
		:addClass('navigation-not-searchable')
		:addClass('ambox-wrapper')
		:addClass('ambox')
		:addClass('wiki-bordercolor-dark')
		:addClass('wiki-backgroundcolor-light')
		:addClass('ambox-red')
		:node(tbl)
end

---@param arr (string|number)[]
---@return Html
function WarningBox.displayAll(arr)
	local wrapper = mw.html.create()
	Array.forEach(arr, function(text)
		wrapper:node(WarningBox.display(text))
	end)
	return wrapper
end

return WarningBox
