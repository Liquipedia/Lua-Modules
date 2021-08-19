local BasicInfobox = require('Module:Infobox/Basic')
local Class = require('Module:Class')
local Cell = require('Module:Infobox/Cell')
local Namespace = require('Module:Namespace')

local Strategy = Class.new(BasicInfobox)

function Strategy.run(frame)
	local strategy = Strategy(frame)
	local args = strategy.args
	local infobox = strategy.infobox
	infobox:name(Strategy:getNameDisplay(args))
	infobox:image(args.image, args.defaultImage)
	infobox:centeredCell(args.caption)
	infobox:header('Strategy Information', true)
	infobox:fcell(Cell:new('Creator'):options({makeLink = true})
		:content(args.creator or args['created-by']):make())
	Strategy:addCustomCells(infobox, args)
	infobox:centeredCell(args.footnotes)
	infobox:bottom(Strategy.createBottomContent(infobox))

	if Namespace.isMain() then
		infobox:categories('Strategies')
	end

	return infobox:build()
end

return Strategy
