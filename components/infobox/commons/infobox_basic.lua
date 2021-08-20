local Class = require('Module:Class')
local Infobox = require('Module:Infobox')
local getArgs = require('Module:Arguments').getArgs

local BasicInfobox = Class.new(
	function(self, frame)
		self.args = getArgs(frame)
		self.pagename = mw.title.getCurrentTitle().title
		self.name = self.args.name or self.pagename

		if self.args.wiki == nil then
			return error('Please provide a wiki!')
		end

		self.infobox = Infobox:create(frame, self.args.wiki)
	end
)

--- Allows for overriding this functionality
function BasicInfobox:addCustomCells(infobox, args)
    return infobox
end

--- Allows for overriding this functionality
function BasicInfobox:addCustomContent(infobox, args)
    return infobox
end

--- Allows for overriding this functionality
function BasicInfobox:createBottomContent(infobox)
    return nil
end

return BasicInfobox
