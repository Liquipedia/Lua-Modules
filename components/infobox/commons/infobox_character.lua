---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Character
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
local Customizable = Widgets.Customizable

local Character = Class.new(BasicInfobox)

function Character.run(frame)
	local character = Character(frame)
	return character:createInfobox()
end

function Character:createInfobox()
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
		Title{name = (args.informationType or 'Character') .. ' Information'},
		Cell{name = 'Real Name', content = {args.realname}},
		Customizable{
			id = 'country',
			children = {
				Cell{
					name = 'Country',
					content = {
						self:_createLocation(args.country)
					}
				},
			}
		},
		Customizable{
			id = 'role',
			children = {
				Cell{
					name = 'Role',
					content = {args.role}
				},
			}
		},
		Customizable{
			id = 'class',
			children = {
				Cell{
					name = 'Class',
					content = {args.class}
				},
			}
		},
		Customizable{
			id = 'release',
			children = {
				Cell{
					name = 'Release Date',
					content = {args.releasedate}
				},
			}
		},
		Customizable{id = 'custom', children = {}},
		Center{content = {args.footnotes}},
	}

	local builtInfobox = infobox:widgetInjector(self:createWidgetInjector()):build(widgets)

	if Namespace.isMain() then
		infobox:categories(args.informationType or 'Character')
		infobox:categories(unpack(self:getWikiCategories(args)))
		self:setLpdbData(args)
	end

	return builtInfobox
end

function Character:_createLocation(location)
	if location == nil then
		return ''
	end

	return Flags.Icon({flag = location, shouldLink = true}) .. '&nbsp;' ..
		'[[:Category:' .. location .. '|' .. location .. ']]'
end

function Character:subHeader(args)
	return args.title
end

function Character:getWikiCategories(args)
	return {}
end

function Character:nameDisplay(args)
	return args.name
end

function Character:setLpdbData(args)
	local lpdbData = {
		name = self.name,
		image = args.image,
		type = 'character',
		extradata = {},
	}

	lpdbData = self:addToLpdb(lpdbData, args)

	lpdbData.extradata = mw.ext.LiquipediaDB.lpdb_create_json(lpdbData.extradata or {})
	mw.ext.LiquipediaDB.lpdb_datapoint('character_' .. self.name, lpdbData)
end

function Character:addToLpdb(lpdbData, args)
	return lpdbData
end

return Character
