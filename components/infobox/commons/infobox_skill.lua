local BasicInfobox = require('Module:Infobox/Basic')
local Class = require('Module:Class')
local Cell = require('Module:Infobox/Cell')
local Namespace = require('Module:Namespace')
local String = require('Module:StringUtils')
local Hotkey = require('Module:Hotkey')

local Skill = Class.new(BasicInfobox)

local _LARGE_NUMBER = 99

function Skill.run(frame)
	local skill = Skill(frame)
	return skill:createInfobox(frame)
end

function Skill:createInfobox(frame)
	local infobox = self.infobox
	local args = self.args

	if (args.informationType) then
		error('You need to specify an informationType')
	end

	local hotkeyDescription, hotkeyDisplay = self:getHotkeys(infobox, args)

	infobox:name(args.name)
	infobox:image(args.image, args.defaultImage)
	infobox:centeredCell(args.caption)
	infobox:header(args.informationType' Information', true)
	infobox:fcell(Cell:new('Caster(s)'):options({}):content(
		unpack(self:getMultiArgsForType(args, 'caster'))):make())
	infobox:cell('Cost', self:getCostDisplay(infobox, args))
	infobox:cell(hotkeyDescription, hotkeyDisplay)
	infobox:cell('Range', args.range)
	infobox:cell('Radius', args.radius)
	infobox:cell('Duration', self:getDurationDisplay(infobox, args))
	infobox:cell('Cooldown', args.cooldown)
	self.infobox:centeredCell(args.footnotes)
	self:addCustomCells(infobox, args)
	infobox:bottom(self:createBottomContent(infobox))

	if Namespace.isMain() then
		local categories = self:getCategories(infobox, args)
		infobox:categories(categories)
	end

	return infobox:build()
end

--- Allows for overriding this functionality
function Skill:getCategories(infobox, args)
	return {}
end

--- Allows for overriding this functionality
function Skill:getDurationDisplay(infobox, args)
	return args.duration
end

--- Allows for overriding this functionality
function Skill:getDurationDisplay(infobox, args)
	return args.duration
end

--- Allows for overriding this functionality
function Skill:getHotkeys(infobox, args)
	local description = 'Hotkey'
	local display
	if not String.isEmpty(args.hotkey) then
		if not String.isEmpty(args.hotkey2) then
			display = Hotkey.hotkey(args.hotkey, args.hotkey2, 'slash')
		else
			display = Hotkey.hotkey(args.hotkey)
		end
	end

	return description, display
end

--- Allows for overriding this functionality
function Skill:getCostDisplay(infobox, args)
	return args.cost
end

--- Allows for using this for customCells
function Skill:getMultiArgsForType(args, argType)
	local typeArgs = {}
	if String.isEmpty(args[argType]) then
		return typeArgs
	end

	local argType1 = (args[argType .. 'link'] or args[argType])
		.. '|' .. args[argType]

	table.insert(typeArgs, argType1)

	for index = 2, _LARGE_NUMBER do
		if String.isEmpty(args[argType .. index]) then
			break
		else
			local indexedArgType = (args[argType .. index .. 'link'] or args[argType .. index])
				.. '|' .. args[argType .. index]
			table.insert(typeArgs, indexedArgType)
		end
	end

	return typeArgs
end

return Skill
