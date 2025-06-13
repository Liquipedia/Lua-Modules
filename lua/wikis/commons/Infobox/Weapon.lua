---
-- @Liquipedia
-- page=Module:Infobox/Weapon
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Namespace = require('Module:Namespace')

local BasicInfobox = Lua.import('Module:Infobox/Basic')
local Flags = Lua.import('Module:Flags')

local Widgets = require('Module:Widget/All')
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
		Cell{
			name = 'Class',
			content = self:getAllArgsForBase(args, 'class', {makeLink = not Logic.readBool(args.disableClassLink)}),
		},
		Cell{
			name = 'Origin',
			content = {self:_createLocation(args.origin)},
		},
		Customizable{
			id = 'price',
			children = {
				Cell{name = 'Price', content = {args.price}}
			}
		},
		Customizable{
			id = 'killaward',
			children = {
				Cell{name = 'Kill Award', content = {args.killaward}}
			}
		},
		Customizable{
			id = 'damage',
			children = { Cell{name = 'Base Damage', content = {args.damage}} }
		},
		Cell{name = 'Magazine Size', content = {args.magsize}},
		Cell{name = 'Ammo Capacity', content = {args.ammocap}},
		Cell{name = 'Reload Speed', content = {
			Logic.isNotEmpty(args.reloadspeed) and (
				args.reloadspeed .. (args.reloadspeedunit and (' ' .. args.reloadspeedunit) or '')
			) or nil
		}},
		Customizable{
			id = 'rateoffire',
			children = {
				Cell{name = 'Rate of Fire', content = {args.rateoffire}}
			}
		},
		Cell{name = 'Firing Mode', content = {args.firemode}},
		Customizable{
			id = 'side',
			children = {
				Cell{name = 'Side', content = {args.side}},
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
								content = users,
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
								content = games,
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

