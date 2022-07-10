---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Weapon
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Namespace = require('Module:Namespace')
local BasicInfobox = require('Module:Infobox/Basic')
local Flags = require('Module:Flags')
local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Header = Widgets.Header
local Title = Widgets.Title
local Center = Widgets.Center
local Builder = Widgets.Builder
local Customizable = Widgets.Customizable

local Weapon = Class.new(BasicInfobox)

function Weapon.run(frame)
	local weapon = Weapon(frame)
	return weapon:createInfobox()
end

function Weapon:createInfobox()
	local infobox = self.infobox
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
		Center{content = {args.caption}},
		Title{name = (args.informationType or 'Weapon') .. ' Information'},
		Cell{
			name = 'Class',
			content = self:getAllArgsForBase(args, 'class', {makeLink = true}),
		},
		Cell{
			name = 'Origin',
			content = {self:_createLocation(args.origin)},
		},
		Cell{name = 'Price', content = {args.price}},
		Cell{name = 'Kill Award', content = {args.killaward}},
		Cell{name = 'Base Damage', content = {args.damage}},
		Cell{name = 'Magazine Size', content = {args.magsize}},
		Cell{name = 'Ammo Capacity', content = {args.ammocap}},
		Cell{name = 'Reload Speed', content = {args.reloadspeed}},
		Cell{name = 'Rate of Fire', content = {args.rateoffire}},
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
		Center{content = {args.footnotes}},
	}

	infobox:categories('Weapons')
	infobox:categories(unpack(self:getWikiCategories(args)))

	local builtInfobox = infobox:widgetInjector(self:createWidgetInjector()):build(widgets)

	if Namespace.isMain() then
		self:setLpdbData(args)
	end

	return builtInfobox
end

function Weapon:_createLocation(location)
	if location == nil then
		return ''
	end

	return Flags.Icon({flag = location, shouldLink = true}) .. '&nbsp;' ..
		'[[:Category:' .. location .. '|' .. location .. ']]'
end

function Weapon:subHeader(args)
	return nil
end

function Weapon:getWikiCategories(args)
	return {}
end

function Weapon:nameDisplay(args)
	return args.name
end

function Weapon:setLpdbData(args)
	local lpdbData = {
		name = self.name,
		image = args.image,
		type = 'weapon',
		information = name,
		extradata = {}
	}

	lpdbData = self:addToLpdb(lpdbData, args)

	lpdbData.extradata = mw.ext.LiquipediaDB.lpdb_create_json(lpdbData.extradata or {})
	mw.ext.LiquipediaDB.lpdb_datapoint('weapon_' .. self.name, lpdbData)
end

function Weapon:addToLpdb(lpdbData, args)
	return lpdbData
end

return Weapon

