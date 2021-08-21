local Class = require('Module:Class')
local Infobox = require('Module:Infobox')
local String = require('Module:StringUtils')
local getArgs = require('Module:Arguments').getArgs

local _LARGE_NUMBER = 99

local BasicInfobox = Class.new(
	function(self, frame)
		self.args = getArgs(frame)
		self.pagename = mw.title.getCurrentTitle().text
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

--- Allows for using this for customCells
function BasicInfobox:getMultiArgsForType(args, argType)
	local typeArgs = {}
	if String.isEmpty(args[argType]) then
		return typeArgs
	end

	local argType1 = (args[argType .. 'link'] or args[argType])
		.. '|' .. args[argType]

	table.insert(typeArgs, '[[' .. argType1 .. ']]')

	for index = 2, _LARGE_NUMBER do
		if String.isEmpty(args[argType .. index]) then
			break
		else
			local indexedArgType = (args[argType .. index .. 'link'] or args[argType .. index])
				.. '|' .. args[argType .. index]
			table.insert(typeArgs, '[[' .. indexedArgType .. ']]')
		end
	end

	return typeArgs
end

--- Allows for using this for customCells
function BasicInfobox:getMultiArgsForTypeNoLink(args, argType)
	local typeArgs = {}
	if String.isEmpty(args[argType]) then
		return typeArgs
	end

	table.insert(typeArgs, args[argType])

	for index = 2, _LARGE_NUMBER do
		if String.isEmpty(args[argType .. index]) then
			break
		else
			table.insert(typeArgs, args[argType .. index])
		end
	end

	return typeArgs
end

return BasicInfobox
