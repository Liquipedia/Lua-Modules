---
-- @Liquipedia
-- wiki=marvelrivals
-- page=Module:Infobox/Character/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')

local Lua = require('Module:Lua')

local Injector = Lua.import('Module:Widget/Injector')
local Character = Lua.import('Module:Infobox/Character')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

---@class MarvelRivalsHeroInfobox: CharacterInfobox
local CustomHero = Class.new(Character)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomHero.run(frame)
	local character = CustomHero(frame)
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
			Cell{name = 'Health', content = {args.health}},
			Cell{name = 'Movespeed', content = {args.movespeed}},
			Cell{name = 'Difficulty', content = {args.difficulty}},
			Cell{name = 'Affiliation', content = {args.affiliation}},
			Cell{name = 'Voice Actor(s)', content = {args.voiceactor}}
		)
		return widgets
	end

	return widgets
end

---@param lpdbData table
---@param args table
function CustomHero:addToLpdb(lpdbData, args)
	lpdbData.information = args.name
	lpdbData.image = args.image
	lpdbData.date = args.released

	lpdbData.extradata.health = args.health
	lpdbData.extradata.movespeed = args.movespeed
	lpdbData.extradata.dificulty = args.difficulty

	return lpdbData
end

return CustomHero
