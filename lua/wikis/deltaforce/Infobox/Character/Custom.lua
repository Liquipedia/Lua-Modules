---
-- @Liquipedia
-- page=Module:Infobox/Character/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Character = Lua.import('Module:Infobox/Character')
local Injector = Lua.import('Module:Widget/Injector')
local PositionIcon = Lua.import('Module:OperatorsPositionIcon', {loadData = true})

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell

---@class DeltaforceCharacterInfobox: CharacterInfobox
local CustomCharacter = Class.new(Character)
---@class DeltaforceCharacterInfoboxWidgetInjector: WidgetInjector
---@field caller DeltaforceCharacterInfobox
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomCharacter.run(frame)
	local character = CustomCharacter(frame)
	character:setWidgetInjector(CustomInjector(character))
	character.args.informationType = 'Characters'
	return character:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	if id == 'role' then
		return {
			Cell{
				name = 'Position',
				children = {self:_toCellContent('position')}
			},
		}
	end
	return widgets
end

---@param key string
---@return string?
function CustomInjector:_toCellContent(key)
	local args = self.caller.args
	if not args[key] or args[key] == '' then return end
	local iconData = PositionIcon[args[key]:lower()]
	if not iconData then return args[key] end
	
	return '[[File:' .. iconData.icon .. '|15px|link=' .. (iconData.link or '') .. ']] ' .. iconData.displayName
end

---@param lpdbData table
---@param args table
---@return table
function CustomCharacter:addToLpdb(lpdbData, args)
	lpdbData.extradata.position = args.position
	return lpdbData
end

return CustomCharacter
