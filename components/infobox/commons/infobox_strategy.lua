local Class = require('Module:Class')
local Infobox = require('Module:Infobox')
local Namespace = require('Module:Namespace')
local Cell = require('Module:Infobox/Cell')

local getArgs = require('Module:Arguments').getArgs

local Strategy = Class.new()

function Strategy.run(frame)
	return Strategy:createInfobox(frame)
end

function Strategy:createInfobox(frame)
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
	infobox:fcell(Cell:new('Creator'):options({makeLink = true})
		:content(args.creator or args['vreated-by']):make())
	Strategy:addCustomCells(infobox, args)
	infobox:centeredCell(args.footnotes)
	infobox:bottom(Strategy.createBottomContent(infobox))

	if Namespace.isMain() then
		infobox:categories('Strategies')
	end

	return infobox:build()
end

--- Allows for overriding this functionality
function Strategy:addCustomCells(infobox, args)
	return infobox
end

--- Allows for overriding this functionality
function Strategy:createBottomContent(infobox)
	return infobox
end

return Strategy
