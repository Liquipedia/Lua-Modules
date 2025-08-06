---
-- @Liquipedia
-- page=Module:Infobox/Character/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local Page = Lua.import('Module:Page')

local Injector = Lua.import('Module:Widget/Injector')
local Character = Lua.import('Module:Infobox/Character')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell

local AutoInlineIcon = Lua.import('Module:AutoInlineIcon')

---@class HearthstoneCharacterInfobox: CharacterInfobox
local CustomCharacter = Class.new(Character)
---@class HearthstoneCharacterInfoboxWidgetInjector: WidgetInjector
---@field caller HearthstoneCharacterInfobox
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomCharacter.run(frame)
	local character = CustomCharacter(frame)
	character:setWidgetInjector(CustomInjector(character))
	return character:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'custom' then
		local alternativeHeroes = self.caller:getAllArgsForBase(args, 'althero', {makeLinks = true})
		local abilities = self.caller:getAllArgsForBase(args, 'ability', {makeLinks = true})
		local deckType = self.caller:getAllArgsForBase(args, 'decktype', {makeLinks = true})

		Array.appendWith(widgets,
			Cell{name = 'Default Hero', content = {Page.makeInternalLink(args.hero)}},
			Cell{name = 'Alternative Heroes', content = alternativeHeroes},
			Cell{name = 'Hero Power', content = {Page.makeInternalLink(args.power)}},
			Cell{name = 'Abilities', content = abilities},
			Cell{name = 'Deck types', content = deckType},
			Cell{name = 'Playable', content = {args.playable}}
		)
	end

	return widgets
end

---@param args table
---@return Widget?
function CustomCharacter:nameDisplay(args)
	return Logic.tryOrElseLog(
		function() return AutoInlineIcon.display{category = 'H', lookup = args.name, link = false} end,
		function() return args.name end
	)
end

---@param lpdbData table
---@param args table
---@return table
function CustomCharacter:addToLpdb(lpdbData, args)
	lpdbData.extradata.hero = args.hero or ''
	lpdbData.extradata.power = args.power or ''
	lpdbData.extradata.altheroes = self:getAllArgsForBase(args, 'althero')
	lpdbData.extradata.abilities = self:getAllArgsForBase(args, 'ability')

	return lpdbData
end

return CustomCharacter
