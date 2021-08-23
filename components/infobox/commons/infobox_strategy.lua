local BasicInfobox = require('Module:Infobox/Basic')
local Class = require('Module:Class')
local Cell = require('Module:Infobox/Cell')
local Namespace = require('Module:Namespace')

local Strategy = Class.new(BasicInfobox)

function Strategy.run(frame)
	local strategy = Strategy(frame)
	return strategy:createInfobox(frame)
end

function Strategy:createInfobox(frame)
	local infobox = self.infobox
	local args = self.args
	infobox:name(self:getNameDisplay(args))
	infobox:image(args.image, args.defaultImage)
	infobox:centeredCell(args.caption)
	infobox:header('Strategy Information', true)
	infobox:fcell(Cell:new('Creator'):options({makeLink = true})
		:content(args.creator or args['created-by']):make())
	self:addCustomCells(infobox, args)
	infobox:centeredCell(args.footnotes)
	infobox:bottom(self:createBottomContent(infobox))

	if Namespace.isMain() then
		infobox:categories('Strategies')
	end

	return infobox:build()
end

return Strategy
