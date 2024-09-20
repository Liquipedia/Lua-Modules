
---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Cosmetic
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Namespace = require('Module:Namespace')

local BasicInfobox = Lua.import('Module:Infobox/Basic')

local Widgets = require('Module:Widget/All')
local Header = Widgets.Header
local Center = Widgets.Center
local CustomizableFactory = Lua.import('Module:Widget/Customizable/Factory')

---@class CosmeticInfobox: BasicInfobox
local Cosmetic = Class.new(BasicInfobox)

---@return string
function Cosmetic:createInfobox()
	local args = self.args
	local Customizable = CustomizableFactory.createCustomizable(self.injector)
	self:customParseArguments(args)

	local widgets = {
		Customizable{
			id = 'header',
			children = {
				Header{
					name = args.name,
					subHeader = args.subHeader,
					image = args.image,
					imageDefault = args.default,
					imageDark = args.imagedark or args.imagedarkmode,
					imageDefaultDark = args.defaultdark or args.defaultdarkmode,
					size = args.imagesize,
					imageText = args.imageText
				},
			}
		},
		Customizable{
			id = 'caption',
			children = {
				Center{content = {args.caption}},
			}
		},
		Customizable{id = 'custom', children = {}},
		Center{content = {args.footnotes}},
	}

	self:categories('Cosmetics')
	self:categories(unpack(self:getWikiCategories(args)))

	if Namespace.isMain() then
		self:setLpdbData(args)
	end

	return self:build(widgets)
end

---@param args table
---@return string[]
function Cosmetic:getWikiCategories(args)
	return {}
end

---@param args table
function Cosmetic:setLpdbData(args)
end

---@param args table
function Cosmetic:customParseArguments(args)
end

return Cosmetic
