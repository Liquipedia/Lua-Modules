---
-- @Liquipedia
-- wiki=valorant
-- page=Module:Infobox/Character/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local ClassTypes = require('Module:ClassTypes')
local Lua = require('Module:Lua')
local Namespace = require('Module:Namespace')
local String = require('Module:StringUtils')

local Injector = Lua.import('Module:Infobox/Widget/Injector')
local Character = Lua.import('Module:Infobox/Character')

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

---@class OverwatchHeroInfobox: CharacterInfobox
local CustomCharacter = Class.new(Character)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomCharacter.run(frame)
	local character = CustomCharacter(frame)
	character:setWidgetInjector(CustomInjector(character))
	character.args.informationType = 'Agent'
	return character:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args
	if id == 'class' then
		table.insert(widgets, Cell{name = 'Class', content = {CustomCharacter._getClassType(args)}})
	elseif 'custom' then
		Array.appendWith(
			widgets,
			Cell{name = 'Age', content = {args.age}},
			Cell{name = 'Voice Actor(s)', content = {args.voiceactor}}
		)
	end

	return widgets
end

---@param args table
---@return string[]
function CustomCharacter:getWikiCategories(args)
	if not Namespace.isMain() then return {} end
	return Array.append({'Agents'},
		String.isNotEmpty(args.role) and (args.role .. ' Agents') or nil
	)
end

---@param args table
---@return string?
function CustomCharacter._getClassType(args)
	if String.isEmpty(args.classtype) then
		return
	end
	local typeIcon = ClassTypes.get{type = args.classtype, date = args.releasedate, size = 15}
	return typeIcon .. ' [[' .. args.classtype .. ']]'
end

return CustomCharacter
