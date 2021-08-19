local BasicInfobox = require('Module:Infobox/Basic')
local Class = require('Module:Class')
local Table = require('Module:Table')
local Namespace = require('Module:Namespace')

local Patch = Class.new(BasicInfobox)

function Patch.run(frame)
	local patch = Patch(frame)
	return patch:createInfobox()
end

function Patch:createInfobox(frame)
	local infobox = self.infobox
	local args = self.args
	infobox.highlights = Patch._highlights

	infobox:name(args.name)
	infobox:image(args.image, args.defaultImage)
	infobox:centeredCell(args.caption)
	infobox:header('Patch Information', true)
	infobox:cell('Version', args.version)
	infobox:cell('Release', args.release)
	Patch:addCustomCells(infobox, args)

	local chronologyData = Patch:getChronologyData(args)

	infobox:header('Highlights', args.highlight1)
	infobox:highlights(Patch:_getHighlights(args))
	infobox:header('Chronology', not Table.isEmpty(chronologyData))
	infobox:chronology(chronologyData)
	infobox:centeredCell(args.footnotes)
	Patch:addCustomContent(infobox, args)
	infobox:bottom(Patch.createBottomContent(infobox))

	if Namespace.isMain() then
		infobox:categories('Patches')
	end

	return infobox:build()
end

--- Allows for overriding this functionality
function Patch:getChronologyData(args)
	return { previous = args.previous, next = args.next }
end

function Patch:_getHighlights(args)
	local highlights = {}

	if args.highlight1 or args.highlight then
		table.insert(highlights, args.highlight1 or args.highlight)
	end

	for index = 2, 99 do
		if args['highlight' .. index] then
			table.insert(highlights, args['highlight' .. index])
		else
			break
		end
	end
	return highlights
end

--extend Infobox class
function Patch:_highlights(data)
	if Table.isEmpty(data) then
        return self
	end

	local div = mw.html.create('div')
	local highlights = mw.html.create('ul')

	for _, item in ipairs(data) do
		highlights:tag('li'):wikitext(item):done()
	end

	div:node(highlights)

	self.content:node(div)

	return self
end

return Patch
