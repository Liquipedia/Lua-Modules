---
-- @Liquipedia
-- page=Module:Infobox/Cosmetic/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')

local Injector = Lua.import('Module:Widget/Injector')
local Cosmetic = Lua.import('Module:Infobox/Cosmetic')

local Widgets = require('Module:Widget/All')
local Builder = Widgets.Builder
local Cell = Widgets.Cell
local Center = Widgets.Center
local Title = Widgets.Title

local WEAPON_STYLES = {
	['solid color'] = 'Solid Color',
	['hydrographic'] = 'Hydrographic',
	['spray-paint'] = 'Spray-Paint',
	['anodized'] = 'Anodized',
	['anodized multicolored'] = 'Anodized Multicolored',
	['anodized airbrushed'] = 'Anodized Airbrushed',
	['custom paint job'] = 'Custom Paint Job',
	['patina'] = 'Patina',
}
-- For backwards compatibility
WEAPON_STYLES[1] = WEAPON_STYLES['solid color']
WEAPON_STYLES[2] = WEAPON_STYLES['hydrographic']
WEAPON_STYLES[3] = WEAPON_STYLES['spray-paint']
WEAPON_STYLES[4] = WEAPON_STYLES['anodized']
WEAPON_STYLES[5] = WEAPON_STYLES['anodized multicolored']
WEAPON_STYLES[6] = WEAPON_STYLES['anodized airbrushed']
WEAPON_STYLES[7] = WEAPON_STYLES['custom paint job']
WEAPON_STYLES[8] = WEAPON_STYLES['patina']

---@class CounterstrikeCosmeticInfobox: CosmeticInfobox
local CustomCosmetic = Class.new(Cosmetic)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomCosmetic.run(frame)
	local cosmetic = CustomCosmetic(frame)
	local args = cosmetic.args
	args.image = 'Icon inventory ' .. string.lower(args['image-weapon'] or '') .. (cosmetic.name or '') '.png'

	cosmetic:setWidgetInjector(CustomInjector(cosmetic))

	return cosmetic:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'custom' then
		Array.appendWith(widgets,
			Title{children = 'Information'},
			Builder{builder = function()
				local worst, best = args['wear-worst'], args['wear-best']
				if not worst or not best then
					return {}
				end
				if string.lower(worst) == 'varies' then
					return {Cell{name = 'Wear levels', children = '[[#Wear levels|Varying]]'}}
				end
				return {Cell{name = 'Wear levels', children = best .. ' - ' .. worst}}
			end},
			Builder{builder = function()
				local stattrak = args.stattrak
				if not stattrak then
					return {Cell{name = 'StatTrak™?', children = 'None'}}
				end
				if string.lower(stattrak) == 'yes' or string.lower(stattrak) == 'some' then
					return {Cell{name = 'StatTrak™?', children = 'Yes, ' .. stattrak}}
				end
				return {Cell{name = 'StatTrak™?', children = 'None'}}
			end},
			Builder{builder = function()
				local souvenir = args.souvenir
				if not souvenir then
					return {Cell{name = 'Souvenir?', children = 'None'}}
				end
				if string.lower(souvenir) == 'yes' or string.lower(souvenir) == 'some' then
					return {Cell{name = 'Souvenir?', children = 'Yes, ' .. souvenir}}
				end
				return {Cell{name = 'Souvenir?', children = 'None'}}
			end},
			Cell{name = 'Style', children = args.style and WEAPON_STYLES[args.style:lower()] or nil},
			Cell{name = 'Created by', children = args.created_by or 'Valve'},
			Center{children = CustomCosmetic:_buyNow()}
		)
	end

	return widgets
end

---@return string?
function CustomCosmetic:_buyNow()
	local name = self.name:gsub(' ', '_')
	local link = 'http://steamcommunity.com/market/search/?appid=730&q=' .. name

	return '['.. link .. ' <span class="buynow_button buynow_market">Buy Now on Market</span>]'
end

return CustomCosmetic
