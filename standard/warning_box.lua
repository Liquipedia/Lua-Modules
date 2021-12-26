---
-- @Liquipedia
-- wiki=commons
-- page=Module:WarningBox
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local WarningBox = {}

local Class = require('Module:Class')

function WarningBox.display(text)
	local div = mw.html.create('div'):addClass('show-when-logged-in navigation-not-searchable ambox-wrapper'
		.. 'ambox wiki-bordercolor-dark wiki-backgroundcolor-light ambox-red')
	local tbl = mw.html.create('table')
	tbl:tag('tr')
		:tag('td'):addClass('ambox-image'):wikitext('[[File:Emblem-important.svg|40px|link=]]'):done()
		:tag('td'):addClass('ambox-text'):wikitext(text)
	return div:node(tbl)
end

function WarningBox.displayAll(tbl)
	local display = ''
	for _, text in pairs(tbl) do
		display = display .. tostring(WarningBox.display(text))
	end
	return display
end

return Class.export(WarningBox)
