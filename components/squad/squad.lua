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
	local makeHeader = function(wikiText)
		local div = mw.html.create('div')

		if wikiText == nil then
			return div
		end

		return div:wikitext(wikiText):css('text-align', 'center')
	end

	local headerRow = DivTable.HeaderRow()
	headerRow	:cell(makeHeader('ID'))
				:cell(makeHeader('Name'))
				:cell(makeHeader())
				:cell(makeHeader('Join Date'))
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
