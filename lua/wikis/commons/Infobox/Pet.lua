-- @Liquipedia
-- @Liquipedia Free Fire Wiki
-- page=Module:Infobox/Pet

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local Namespace = Lua.import('Module:Namespace')

local BasicInfobox = Lua.import('Module:Infobox/Basic')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell
local Header = Widgets.Header
local Title = Widgets.Title
local Center = Widgets.Center
local Customizable = Widgets.Customizable

---@class PetInfobox: BasicInfobox
---@operator call(Frame): PetInfobox
local Pet = Class.new(BasicInfobox)

---@param frame Frame
---@return VNode
function Pet.run(frame)
	local pet = Pet(frame)
	return pet:createInfobox()
end

---@return VNode
function Pet:createInfobox()
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
		Title{children = {'General Information'}},
		Customizable{
			id = 'release',
			children = {
				Cell{
					name = 'Release Date',
					children = {args.releasedate}
				},
			}
		},
		Customizable{
			id = 'species',
			children = {
				Cell{
					name = 'Species / Type',
					children = {args.species}
				},
			}
		},
		Customizable{id = 'custom', children = {}},
	}

	if Logic.isNotEmpty(args.ability) then
		table.insert(widgets, Title{children = {'Special Ability'}})
		table.insert(widgets, Cell{name = 'Legend Type', children = {args.ability}})
		if Logic.isNotEmpty(args.type) or Logic.isNotEmpty(args.mode) then
			table.insert(widgets, Cell{name = 'Skill Mode', children = {args.type or args.mode}})
		end
	end

	table.insert(widgets, Center{children = {args.footnotes}})

	if Namespace.isMain() then
		self:categories('Pets')
		self:categories(args.informationType)
		self:categories(unpack(self:getWikiCategories(args)))
		self:setLpdbData(args)
	end

	return self:build(widgets, 'Pet')
end

---@param args table
---@return string?
function Pet:subHeader(args)
	return args.title
end

---@param args table
---@return string[]
function Pet:getWikiCategories(args)
	return {}
end

---@param args table
---@return string?
function Pet:nameDisplay(args)
	return args.name
end

---@param args table
function Pet:setLpdbData(args)
	local lpdbData = {
		name = self.name,
		image = args.image,
		imagedark = args.imagedark or args.imagedarkmode,
		type = 'pet',
		date = args.releasedate,
		extradata = {
			species = args.species,
			ability = args.ability,
			mode = args.type or args.mode,
		},
	}

	lpdbData = self:addToLpdb(lpdbData, args)

	mw.ext.LiquipediaDB.lpdb_datapoint('pet_' .. self.name, Json.stringifySubTables(lpdbData))
end

---@param lpdbData table
---@param args table
---@return table
function Pet:addToLpdb(lpdbData, args)
	return lpdbData
end

return Pet
