---
-- @Liquipedia
-- page=Module:Infobox/Map
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Game = Lua.import('Module:Game')
local Json = Lua.import('Module:Json')
local Namespace = Lua.import('Module:Namespace')
local Page = Lua.import('Module:Page')
local Table = Lua.import('Module:Table')

local BasicInfobox = Lua.import('Module:Infobox/Basic')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell
local Header = Widgets.Header
local Link = Lua.import('Module:Widget/Basic/Link')
local Title = Widgets.Title
local Center = Widgets.Center
local Customizable = Widgets.Customizable

---@class MapInfobox:BasicInfobox
---@field creators {page: string, displayName: string}[]
local Map = Class.new(BasicInfobox)

---Entry point of map infobox
---@param frame Frame
---@return Html
function Map.run(frame)
	local map = Map(frame)
	return map:createInfobox()
end

---@return string
function Map:createInfobox()
	local args = self.args

	self:_readCreators()

	local widgets = {
		Header{
			name = self:getNameDisplay(args),
			image = args.image,
			imageDark = args.imagedark or args.imagedarkmode,
			size = args.imagesize,
		},
		Center{children = {args.caption}},
		Title{children = (args.informationType or 'Map') .. ' Information'},
		Cell{name = 'Creator', content = Array.map(self.creators, function (creator)
			return Link{link = creator.page, children = creator.displayName}
		end)},
		Customizable{id = 'location', children = {
			Cell{name = 'Location', content = {args.location}}
		}},
		Customizable{id = 'release', children = {
			Cell{name = 'Release Date', content = {args.releasedate}},
		}},
		Customizable{id = 'custom', children = {}},
		Center{children = {args.footnotes}},
	}

	self:bottom(self:createBottomContent())

	if Namespace.isMain() then
		self:categories('Maps', unpack(self:getWikiCategories(args)))
		self:_setLpdbData(args)
	end

	return self:build(widgets)
end

--- Allows for overriding this functionality
---Builds the display Name for the header
---@protected
---@param args table
---@return string
function Map:getNameDisplay(args)
	return args.name
end

--- Allows for overriding this functionality
---Add wikispecific categories
---@protected
---@param args table
---@return string[]
function Map:getWikiCategories(args)
	return {}
end

--- Allows for overriding this functionality
---Adjust Lpdb data
---@protected
---@param lpdbData table
---@param args table
---@return table
function Map:addToLpdb(lpdbData, args)
	return lpdbData
end

--- Allows for overriding this functionality
---Returns the respective game for this map
---@param args table
---@return string?
function Map:getGame(args)
	local game = Game.name{
		game = args.game,
		useDefault = args.useDefaultGame
	}
	assert(game, 'Missing or invalid game specified')
	---@cast game -nil
	return game
end

--- Allows for overriding this functionality
---Returns the respective game mode(s) for this map
---@param args table
---@return string[]
function Map:getGameModes(args)
	return self:getAllArgsForBase(args, 'mode')
end

---@private
function Map:_readCreators()
	self.creators = {}
	for _, creator in Table.iter.pairsByPrefix(self.args, {'creator', 'created-by'}, {requireIndex = false}) do
		table.insert(self.creators, {page = Page.pageifyLink(creator), displayName = creator})
	end
end

---Stores the lpdb data
---@private
---@param args table
function Map:_setLpdbData(args)
	local function creatorsToLpdbData()
		local ret = {}
		Array.forEach(self.creators, function (creator, index)
			ret['creator' .. index] = creator.page
			ret['creator' .. index .. 'dn'] = creator.displayName
		end)
		return ret
	end

	local lpdbData = {
		name = self.name,
		type = 'map',
		image = args.image,
		date = args.releasedate,
		extradata = Table.merge(
			creatorsToLpdbData(),
			{
				game = self:getGame(args),
				modes = self:getGameModes(args),
			}
		)
	}

	lpdbData = self:addToLpdb(lpdbData, args)
	mw.ext.LiquipediaDB.lpdb_datapoint('map_' .. lpdbData.name, Json.stringifySubTables(lpdbData))
end

return Map
