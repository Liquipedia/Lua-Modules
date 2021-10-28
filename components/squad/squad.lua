local Class = require('Module:Class')
local DivTable = require('Module:DivTable')

local Squad = Class.new()

function Squad:init(frame)
	self.frame = frame
	self.root = mw.html.create('div')
	self.root	:addClass('table-responsive')
				-- TODO: is this needed?
				:css('margin-bottom', '10px')
				-- TODO: is this needed?
				:css('padding-bottom', '0px')

	self.content = DivTable.create():setStriped(true)

	return self
end

function Squad:header()
	local headerRow = DivTable.HeaderRow()
	headerRow	:cell(mw.html.create('div'):wikitext('ID'))
				:cell(mw.html.create('div'):wikitext('Name'))
				:cell(mw.html.create('div'))
				:cell(mw.html.create('div'):wikitext('Join Date'))
	self.content:row(headerRow)

	return self
end

function Squad:row(row)
	self.content:row(row)
	return self
end

function Squad:create()
	self.root:node(self.content:create())
	return self.root
end

return Squad
