---
-- @Liquipedia
-- page=Module:MapPoolTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local FnUtil = Lua.import('Module:FnUtil')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local Map = Lua.import('Module:Map')
local Operator = Lua.import('Module:Operator')
local Page = Lua.import('Module:Page')
local Variables = Lua.import('Module:Variables')

---@class StandardMapWithIcon: StandardMap
---@field icon string?

---for variations and data of maps that have no page
---@type table<string, StandardMapWithIcon>
local MapData = Lua.requireIfExists('Module:MapPoolTable/Data', {loadData = true}) or {}

local Condition = Lua.import('Module:Condition')
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local ColumnName = Condition.ColumnName

local Image = Lua.import('Module:Widget/Image/Icon/Image')
local Link = Lua.import('Module:Widget/Basic/Link')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local DEFAULT_THUMB_SIZE = 'x100px'
local PLACEHOLDER_IMAGE = 'MapImagePlaceholder.jpg'

---@class MapPoolConfig
---@field note string?
---@field showAuthor boolean
---@field sort boolean
---@field size string
---@field title string?
---@field useIcons boolean?

---@class MapPoolTable
---@operator call(Frame): MapPoolTable
---@field args table
---@field config MapPoolConfig
---@field mapCategories {maps: StandardMapWithIcon[], title: string?}[]
local MapPoolTable = Class.new(function(self, frame)
	local args = Arguments.getArgs(frame)
	self.config = self:_readConfig(args)
	self.mapCategories = self:_readManualInput(args)
	if Logic.isEmpty(self.mapCategories) then
		self.mapCategories = self:_readFromInfobox(args)
	end
	self.config.useIcons = Logic.nilOr(
		Logic.readBoolOrNil(args.useIcons),
		Array.all(self.mapCategories, function(category)
			return Array.all(category.maps, function(map)
				return Logic.isNotEmpty(map.icon)
			end)
		end)
	)
end)

---@param frame Frame
---@return Widget?
function MapPoolTable.run(frame)
	return MapPoolTable(frame):display()
end

---@param args table
---@return MapPoolConfig
function MapPoolTable:_readConfig(args)
	return {
		note = args.note,
		showAuhor = Logic.readBool(args.author),
		sort = Logic.readBool(args.sort),
		size = args.size or DEFAULT_THUMB_SIZE,
		title = args.title,
	}
end

---@param args table
---@return {maps: StandardMapWithIcon[], title: string?}[]
function MapPoolTable:_readManualInput(args)
	local categories = Array.mapIndexes(function(categoryIndex)
		return MapPoolTable:_readManualMaps(Json.parseIfTable(args['category' .. categoryIndex]) or {}, true)
	end)
	if Logic.isNotEmpty(categories) then
		return categories
	end
	return {self:_readManualMaps(args)}
end

---@param inputs table
---@param requireTitle boolean?
---@return {maps: StandardMapWithIcon[], title: string?}?
function MapPoolTable:_readManualMaps(inputs, requireTitle)
	local maps = Logic.nilIfEmpty(Array.mapIndexes(function(mapIndex)
		local prefix = 'map' .. mapIndex
		if Logic.isEmpty(inputs[prefix]) then
			return
		end

		local author = inputs[prefix .. 'author']
		local authorDisplayName = inputs[prefix .. 'authorDisplayName']

		return self:_backFillMap{
			displayName = inputs[prefix .. 'displayName'],
			pageName = inputs[prefix],
			image = inputs[prefix .. 'image'],
			imageDark = inputs[prefix .. 'imageDark'],
			creators = {author},
			creatorDisplayNames = {authorDisplayName},
			icon = inputs[prefix .. 'icon'],
		}
	end))

	if Logic.isEmpty(maps) then
		return
	end

	assert(inputs.title or not requireTitle, 'Category is missing a title')
	return {maps = maps, title = requireTitle and inputs.title or nil}
end

---@param args table
---@return {maps: StandardMapWithIcon[], title: string?}[]
function MapPoolTable:_readFromInfobox(args)
	local maps = (not args.tournament ) and Json.parseIfTable(Variables.varDefault('tournament_maps')) or nil

	if Logic.isEmpty(maps) then
		local tournament = args.tournament or mw.title.getCurrentTitle().prefixedText
		local data = mw.ext.LiquipediaDB.lpdb('tournament', {
			conditions = tostring(ConditionNode(ColumnName('pagename'), Comparator.eq, Page.pageifyLink(tournament))),
			query = 'maps'
		})[1] or {}

		maps = Json.parseIfTable(data.maps)
	end

	if Logic.isEmpty(maps) then
		return {}
	end
	---@cast maps -nil

	return {{maps = Array.map(maps, function(map)
		return self:_backFillMap{
			displayName = map.displayname or map.name,
			pageName = map.link,
			image = map.image,
			imageDark = map.imageDark,
		}
	end)}}
end

---@param map table
---@return StandardMapWithIcon
function MapPoolTable:_backFillMap(map)
	-- those 2 are not actually needed but annotations of `StandardMap` require them
	map.extradata = map.extradata or {}
	map.releaseDate = {year = 0, month = 1, day = 1, timestamp = -62167219200, string = '0000-01-01 00:00:00'}

	if Logic.isNotEmpty(map.image) and (Logic.isNotEmpty(map.creators) or not self.config.showAuthor) then
		map.displayName = map.displayName or map.pageName
		return map
	end

	---@param pageName any
	---@return unknown
	local getMapDataFromLookup = function(pageName)
		local key = pageName
			:gsub('_', ' ')
			:gsub('%s*LE$', '')
			:gsub('%s*TE$', '')
			:gsub('%s*CE$', '')
			:gsub('%s%([mM]ap%)$', '')
			:lower()
		return MapData[pageName] or MapData[key]
	end

	local mapData = Map.getMapByPageName(Page.pageifyLink(map.pageName)) or getMapDataFromLookup(map.pageName)
	assert(mapData, 'No data found for "' .. map.pageName .. '"')

	-- can not use Table.merge nor Table.deepMerge due to creators/creatorDisplayNames
	map.displayName = map.displayName or mapData.displayName
	map.image = map.image or mapData.image
	map.imageDark = map.imageDark or mapData.imageDark
	map.creators = Logic.emptyOr(map.creators, mapData.creators, {})
	map.creatorDisplayNames = Logic.emptyOr(map.creatorDisplayNames, mapData.creatorDisplayNames, {})
	map.icon = map.icon or (mapData.extradata or {}).icon

	return map
end

---@return Widget?
function MapPoolTable:display()
	if Logic.isEmpty(self.mapCategories) then
		return
	end

	local numberOfColumns = #self.mapCategories == 1 and #self.mapCategories[1].maps or #self.mapCategories

	return TableWidgets.Table{
		title = self.config.title,
		sortable = false,
		tableClasses = #self.mapCategories > 1 and {'collapsible', 'collapsed'} or nil,
		css = {
			-- Fit besides the infobox
			width = 'unset',
		},
		columns = Array.map(Array.range(1, numberOfColumns), function ()
			return {
				align = 'center',
				css = {
					['min-width'] = '6.25rem',
					['padding-left'] = '0.125rem',
					['padding-right'] = '0.125rem',
				}
			}
		end),
		children = WidgetUtil.collect(
			self:_headerRow(),
			TableWidgets.TableBody{
				children = #self.mapCategories == 1 and self:_normalDisplay() or self:_categoryDisplay()
			}
		),
		footer = self.config.note,
	}
end

---@return Widget
function MapPoolTable:_headerRow()
	if #self.mapCategories > 1 then
		return TableWidgets.Row{
			children = Array.map(self.mapCategories, function(category)
				return TableWidgets.CellHeader{children = category.title}
			end)
		}
	end

	return TableWidgets.Row{
		children = Array.map(self.mapCategories[1].maps, function(map)
			return TableWidgets.CellHeader{children = Link{link = map.pageName, children = map.displayName}}
		end)
	}
end

---@param map StandardMapWithIcon|{}
---@return Widget
function MapPoolTable:_displayImage(map)
	if Logic.isEmpty(map) then
		return TableWidgets.Cell{}
	end
	return TableWidgets.Cell{children = Image{
		imageLight = self.config.useIcons and Logic.nilIfEmpty(map.icon) or map.image or PLACEHOLDER_IMAGE,
		imageDark = self.config.useIcons and Logic.nilIfEmpty(map.icon) or map.imageDark,
		link = map.pageName,
		size = self.config.size or DEFAULT_THUMB_SIZE,
		alt = map.displayName,
	}}
end

---@param map StandardMapWithIcon|{}
---@return IconImageWidget
function MapPoolTable:_displayAuthors(map)
	---@type Renderable[]
	local authors = Array.mapIndexes(function(authorIndex)
		local author = map.creators[authorIndex]
		local authorDisplayName = map.creatorDisplayNames[authorIndex]
		if Logic.isEmpty(author) and Logic.isEmpty(authorDisplayName) then
			return
		end
		if Logic.isEmpty(author) then
			return authorDisplayName
		end
		return Link{link = author, children = authorDisplayName}
	end)

	if Logic.isEmpty(authors) then
		return TableWidgets.Cell{}
	end

	authors = Array.interleave(authors, ', ')

	return TableWidgets.Cell{
		children = WidgetUtil.collect(
			'By ',
			authors
		),
		css = {
			['font-size'] = '90%',
			['padding-left'] = '0.25rem',
			['padding-right'] = '0.25rem',
		},
	}
end

---@return Widget[]
function MapPoolTable:_normalDisplay()
	local mapList = self.mapCategories[1].maps

	if self.config.sort then
		Array.sortInPlaceBy(mapList, Operator.property('pageName'))
	end

	return {
		-- image row
		TableWidgets.Row{children = Array.map(mapList, FnUtil.curry(self._displayImage, self))},
		-- author row (if enabled)
		self.config.showAuthor
			and TableWidgets.Row{children = Array.map(mapList, FnUtil.curry(self._displayAuthors, self))}
			or nil,
	}
end

---@return Widget[]
function MapPoolTable:_categoryDisplay()
	local maxNumberOfMaps = math.max(unpack(Array.map(self.mapCategories, function(category) return #category.maps end)))

	---@param index any
	---@return Widget[]
	local makeRows = function(index)
		local mapList = Array.map(self.mapCategories, function(category)
			return category.maps[index] or {}
		end)
		return {
			-- image row
			TableWidgets.Row{children = Array.map(mapList, FnUtil.curry(self._displayImage, self))},
			-- name row
			TableWidgets.Row{
				children = Array.map(mapList, function(map)
					return TableWidgets.Cell{children = Link{link = map.pageName, children = map.displayName}}
				end)
			},
			-- author row (if enabled)
			self.config.showAuthor
				and TableWidgets.Row{children = Array.map(mapList, FnUtil.curry(self._displayAuthors, self))}
				or nil,
		}
	end

	return Array.flatMap(Array.range(1, maxNumberOfMaps), makeRows)
end

return MapPoolTable
