---
-- @Liquipedia
-- page=Module:Infobox/Weapon
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local Namespace = Lua.import('Module:Namespace')

local BasicInfobox = Lua.import('Module:Infobox/Basic')
local Flags = Lua.import('Module:Flags')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell
local Header = Widgets.Header
local Title = Widgets.Title
local Center = Widgets.Center
local Builder = Widgets.Builder
local Customizable = Widgets.Customizable

---@class WeaponInfobox: BasicInfobox
local Weapon = Class.new(BasicInfobox)

---@param frame Frame
---@return Html
function Weapon.run(frame)
	local weapon = Weapon(frame)
	return weapon:createInfobox()
end

---@return string
function Weapon:createInfobox()
	local args = self.args

	local widgets = {
		Header{
			name = self:nameDisplay(args),
			subHeader = self:subHeader(args),
			image = args.image,
			imageDefault = args.default,
			imageDark = args.imagedark or args.imagedarkmode,
			imageDefaultDark = args.defaultdark or args.defaultdarkmode,
			size = args.imagesize,
		},
		Center{children = {args.caption}},
		Title{children = (args.informationType or 'Weapon') .. ' Information'},
		Cell{name = 'Other', children = {args.othernames}},
		Cell{
			name = 'Class',
			children = self:getAllArgsForBase(args, 'class', {makeLink = not Logic.readBool(args.disableClassLink)}),
		},
		Cell{
			name = 'Origin',
			children = {self:_createLocation(args.origin)},
		},
		Customizable{
			id = 'price',
			children = {
				Cell{name = 'Price', children = {args.price}},
			},
		},
		Customizable{
			id = 'killaward',
			children = {
				Cell{name = 'Kill Award', children = {args.killaward}},
			},
		},
		Customizable{
			id = 'damage',
			children = {
				Cell{name = 'Base Damage', children = {args.damage}},
				Cell{name = 'Armor penetration', children = {args.armorpenetration}},
			},
		},
		Customizable{
			id = 'magsize',
			children = {
				Cell{name = 'Magazine Size', children = {args.magsize}},
			},
		},

		Cell{name = 'Ammo Capacity', children = {args.ammocap}},
		Cell{name = 'Ammunition/Capacity', children = {args.ammo}},
		Cell{name = 'Reload Speed', children = {
			Logic.isNotEmpty(args.reloadspeed) and (
				args.reloadspeed .. (args.reloadspeedunit and (' ' .. args.reloadspeedunit) or '')
			) or nil
		}},
		Customizable{
			id = 'rateoffire',
			children = {
				Cell{name = 'Rate of Fire', children = {args.rateoffire}}
			}
		},
		Cell{name = 'Accuracy', children = {args.accuracy}},
		Cell{name = 'Range', children = {args.range}},
		Cell{name = 'Unique Characteristics', children = {args.charact}},
		Cell{name = 'Firing Mode', children = self:getAllArgsForBase(args, 'firemode')},
		Cell{name = 'Movement Speed', children = {args.movementspeed}},
		Customizable{
			id = 'side',
			children = {
				Cell{name = 'Side', children = {args.side}},
			}
		},
		Customizable{
			id = 'user',
			children = {
				Builder{
					builder = function()
						local users = self:getAllArgsForBase(args, 'user', {makeLink = true})
						return {
							Cell{
								name = #users > 1 and 'Users' or 'User',
								children = users,
							}
						}
					end
				}
			}
		},
		Customizable{
			id = 'game',
			children = {
				Builder{
					builder = function()
						local games = self:getAllArgsForBase(args, 'game', {makeLink = true})
						return {
							Cell{
								name = #games > 1 and 'Game Appearances' or 'Game Appearance',
								children = games,
							}
						}
					end
				}
			}
		},
		Customizable{id = 'custom', children = {}},
		Center{children = {args.footnotes}},
	}

	self:categories('Weapons')
	self:categories(unpack(self:getWikiCategories(args)))

	if Namespace.isMain() then
		self:setLpdbData(args)
	end

	return self:build(widgets)
end

---@param location string?
---@return string
function Weapon:_createLocation(location)
	if location == nil then
		return ''
	end

	return Flags.Icon{flag = location, shouldLink = true} .. '&nbsp;' ..
		'[[:Category:' .. location .. '|' .. location .. ']]'
end

---@param args table
---@return nil
function Weapon:subHeader(args)
	return nil
end

---@param args table
---@return string[]
function Weapon:getWikiCategories(args)
	return {}
end

---@param args table
---@return string?
function Weapon:nameDisplay(args)
	return args.name
end

---@param args table
function Weapon:setLpdbData(args)
	local lpdbData = {
		name = self.name,
		image = args.image,
		type = 'weapon',
		extradata = {}
	}

	lpdbData = self:addToLpdb(lpdbData, args)

	mw.ext.LiquipediaDB.lpdb_datapoint('weapon_' .. self.name, Json.stringifySubTables(lpdbData))
end

---@param lpdbData table
---@param args table
---@return table
function Weapon:addToLpdb(lpdbData, args)
	return lpdbData
end

return Weapon

