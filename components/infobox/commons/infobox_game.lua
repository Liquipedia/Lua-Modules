local BasicInfobox = require('Module:Infobox/Basic')
local Class = require('Module:Class')
local Cell = require('Module:Infobox/Cell')
local Namespace = require('Module:Namespace')
local String = require('Module:StringUtils')

local Game = Class.new(BasicInfobox)

local _LARGE_NUMBER = 99

function Game.run(frame)
	local game = Game(frame)
	return game:createInfobox(frame)
end

function Game:createInfobox(frame)
	local infobox = self.infobox
	local args = self.args

	infobox:name(args.name)
	infobox:image(args.image, args.defaultImage)
	infobox:centeredCell(args.caption)
	infobox:header('Game Information', true)
	infobox:fcell(Cell:new('Developer'):options({}):content(
		unpack(self:_getMultiArgsForType(args, 'developer'))):make())
	infobox:fcell(Cell:new('Release Dates'):options({}):content(
		unpack(self:_getMultiArgsForType(args, 'releasedate'))):make())
	infobox:fcell(Cell:new('Platforms'):options({}):content(
		unpack(self:_getMultiArgsForType(args, 'platform'))):make())
	self:addCustomCells(infobox, args)
	infobox:bottom(self:createBottomContent(infobox))

	if Namespace.isMain() then
		infobox:categories('Games')
	end

	return infobox:build()
end

function Game:_getMultiArgsForType(args, argType)
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

return Game
