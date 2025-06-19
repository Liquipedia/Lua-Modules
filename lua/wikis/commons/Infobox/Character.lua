---
-- @Liquipedia
-- page=Module:Infobox/Character
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Flags = Lua.import('Module:Flags')
local Json = Lua.import('Module:Json')
local Namespace = Lua.import('Module:Namespace')

local BasicInfobox = Lua.import('Module:Infobox/Basic')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell
local Header = Widgets.Header
local Title = Widgets.Title
local Center = Widgets.Center
local Customizable = Widgets.Customizable

---@class CharacterInfobox: BasicInfobox
local Character = Class.new(BasicInfobox)

---@param frame Frame
---@return Html
function Character.run(frame)
	local character = Character(frame)
	return character:createInfobox()
end

---@return string
function Character:createInfobox()
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
		Title{children = (args.informationType or 'Character') .. ' Information'},
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
		Center{children = {args.footnotes}},
	}

	if Namespace.isMain() then
		self:categories(args.informationType or 'Character')
		self:categories(unpack(self:getWikiCategories(args)))
		self:setLpdbData(args)
	end

	return self:build(widgets)
end

---@param location string?
---@return string
function Character:_createLocation(location)
	if location == nil then
		return ''
	end

	return Flags.Icon{flag = location, shouldLink = true} .. '&nbsp;' ..
		'[[:Category:' .. location .. '|' .. location .. ']]'
end

---@param args table
---@return string?
function Character:subHeader(args)
	return args.title
end

---@param args table
---@return string[]
function Character:getWikiCategories(args)
	return {}
end

---@param args table
---@return string?
function Character:nameDisplay(args)
	return args.name
end

---@param args table
---@return string[]
function Character:getRoles(args)
	return self:getAllArgsForBase(args, 'role')
end

---@param args table
function Character:setLpdbData(args)
	local lpdbData = {
		name = self.name,
		image = args.image,
		imagedark = args.imagedark or args.imagedarkmode,
		type = 'character',
		date = args.releasedate,
		extradata = {
			roles = self:getRoles(args),
		},
	}

	lpdbData = self:addToLpdb(lpdbData, args)

	mw.ext.LiquipediaDB.lpdb_datapoint('character_' .. self.name, Json.stringifySubTables(lpdbData))
end

---@param lpdbData table
---@param args table
---@return table
function Character:addToLpdb(lpdbData, args)
	return lpdbData
end

return Character
