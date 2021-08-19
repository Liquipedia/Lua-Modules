local Class = require('Module:Class')
local Infobox = require('Module:Infobox')
local Table = require('Module:Table')
local Namespace = require('Module:Namespace')

local getArgs = require('Module:Arguments').getArgs

local Patch = Class.new()

function Patch.run(frame)
	return Patch:createInfobox(frame)
end

function Patch:createInfobox(frame)
	local args = getArgs(frame)
	self.frame = frame
	self.pagename = mw.title.getCurrentTitle().text
	self.name = args.name or self.pagename

	if args.game == nil then
		return error('Please provide a game!')
	end

	local infobox = Infobox:create(frame, args.game)

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
function Patch:addCustomContent(infobox, args)
	return infobox
end

--- Allows for overriding this functionality
function Patch:addCustomCells(infobox, args)
	return infobox
end

--- Allows for overriding this functionality
function Patch:createBottomContent(infobox)
	return infobox
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
function Infobox:highlights(data)
	if Table.isEmpty(data) then
        return self
	end

	local outerDiv = mw.html.create('div')
	local innerDiv = mw.html.create('div')
	local highlights = mw.html.create('ul')

	for _, item in ipairs(data) do
		highlights:tag('li'):wikitext(item):done()
	end

	outerDiv:node(innerDiv:node(highlights))

	self.content:node(outerDiv)

	return self
end

return Patch
