---
-- @Liquipedia
-- page=Module:Infobox/Cosmetic/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local CosmeticIcon = require('Module:Cosmetic')
local DateExt = require('Module:Date/Ext')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Template = require('Module:Template')

local Injector = Lua.import('Module:Widget/Injector')
local Cosmetic = Lua.import('Module:Infobox/Cosmetic')

local Widgets = require('Module:Widget/All')
local Builder = Widgets.Builder
local Cell = Widgets.Cell
local Center = Widgets.Center
local Title = Widgets.Title

local SpecialCategories = {
	['Strange Modifier'] = 'Strange Modifier',
	['Ethereal'] = 'Ethereal',
	['Mastery'] = 'Mastery',
	['Kinetic'] = 'Kinetic',
	['Essence'] = 'Essence',
	['Immortal Treasure I'] = 'Immortal Treasure',
	['Trust of the Benefactor 20'] = 'Trust of the Benefactor',
	['Treasure of the Crimson Witness 20'] = 'Crimson Witness',
	['Baby Roshan'] = 'Baby Roshan',
}

---@class FortniteCosmeticInfobox: CosmeticInfobox
local CustomCosmetic = Class.new(Cosmetic)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomCosmetic.run(frame)
	local cosmetic = CustomCosmetic(frame)
	cosmetic.args.image = cosmetic.args.image or ('Fortnite' .. cosmetic.name .. '.png')
	cosmetic:setWidgetInjector(CustomInjector(cosmetic))

	return mw.html.create():node(cosmetic:createInfobox()):node(cosmetic:_createIntroText())
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'custom' then
		Array.appendWith(widgets,
			Title{children = 'Skin Information'},
			Cell{name = 'Type', content = args.type},
			Cell{name = 'Rarity', content = args.rarity}
		)
	end

	return widgets
end

function CustomCosmetic:_createIntroText()
	local args = self.args
	if not Logic.readBool(args['generate description']) then
		return ''
	end
	if not args.rarity then
		return ''
	end

	return self.name .. ' is a skin that is available in ' .. args.rarity .. ' rarity.'
end

return CustomCosmetic
