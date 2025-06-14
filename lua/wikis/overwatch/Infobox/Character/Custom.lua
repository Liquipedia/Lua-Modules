---
-- @Liquipedia
-- page=Module:Infobox/Character/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Namespace = require('Module:Namespace')
local String = require('Module:StringUtils')

local Injector = Lua.import('Module:Widget/Injector')
local Character = Lua.import('Module:Infobox/Character')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

---@class OverwatchHeroInfobox: CharacterInfobox
local CustomCharacter = Class.new(Character)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomCharacter.run(frame)
	local character = CustomCharacter(frame)
	character:setWidgetInjector(CustomInjector(character))
	character.args.informationType = 'Hero'
	return character:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args
	if id == 'custom' then
		Array.appendWith(
			widgets,
			Cell{name = 'Age', content = {args.age}},
			Cell{name = 'Relations', content = {args.relations}},
			Cell{name = 'Occupation', content = {args.occupation}},
			Cell{name = 'Base of Operations', content = {args.baseofoperations}},
			Cell{name = 'Affiliation', content = {args.affiliation}},
			Cell{name = 'Voice Actor(s)', content = {args.voiceactor}}
		)
	end

	return widgets
end

---@param args table
---@return string[]
function CustomCharacter:getWikiCategories(args)
	if not Namespace.isMain() then return {} end
	return Array.append({'Heroes'},
		String.isNotEmpty(args.role) and (args.role .. ' Heroes') or nil
	)
end

return CustomCharacter
