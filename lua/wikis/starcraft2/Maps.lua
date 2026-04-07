local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local Table = Lua.import('Module:Table')
local Variables = Lua.import('Module:Variables')

---for variations and data of maps that have no page
---@type table<string, SC2MapsMap>
local MapData = Lua.requireIfExists('Module:MapData', {loadData = true}) or {}

local Image = Lua.import('Module:Widget/Image/Icon/Image')
local Link = Lua.import('Module:Widget/Basic/Link')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class SC2MapsMap
---@field link string
---@field displayname string?
---@field author string?
---@field authorLink string?
---@field image string?
---@field imageDark string?

---@class SC2MapsConfig
---@field note string?
---@field showAuthor boolean
---@field sort boolean
---@field size string
---@field title string?
---@field tournament string?

local DEFAULT_THUMB_SIZE = 'x120px'
local PLACEHOLDER_IMAGE = 'MapImagePlaceholder.jpg'

local Maps = {}

---@private
---@param input string?
---@return SC2MapsMap?
function Maps._getData(input)
	if Logic.isEmpty(input) then
		return
	end
	---@cast key -nil

	local key = key:gsub('%s*LE$', ''):gsub('%s*TE$', ''):gsub('%s*CE$', ''):gsub(' %([mM]ap%)$', ''):gsub('_', ' ')
	return MapData[key:lower()] or Maps._fetchMapData(input)
end

---@private
---@param input string?
---@return SC2MapsMap?
function Maps._fetchMapData(input)
	todo
end

-- EntryPoint Template:MapThumb
---@param args {[1]: string?, size: string|number?}?
---@return Widget?
function Maps.thumb(args)
	args = args or {}
	local data = Maps._getData(args[1])
	if not data then
		return
	end

	return Maps._displayThumb(data, args.size)
end

---@private
---@param data SC2MapsMap
---@param size string|number?
---@return Widget
function Maps._displayThumb(data, size)
	return Image{
		imageLight = data.image or PLACEHOLDER_IMAGE,
		imageDark = data.imageDark,
		link = data.link,
		size = size or DEFAULT_THUMB_SIZE,
		alt = data.displayname or data.link,
	}
end

---@private
---@param data SC2MapsMap
---@return Widget|string?
function Maps._displayAuthor(data)
	if not data.authorLink then
		return data.author
	end

	return Link{link = data.authorLink, children = data.author}
end

-- EntryPoint Template:Maps
---@param args table?
---@return Widget?
function Maps.run(args)
	args = args or {}

	local config = Maps._readConfig(args)
	local mapList = Maps._readMaps(args, config)

	if Logic.isEmpty(mapList) then
		return
	end

	mapList = Array.map(mapList, function(map)
		if Logic.isNotEmpty(map.image) and (Logic.isNotEmpty(map.author) or not config.showAuthor) then
			return map
		end

		local data = Maps._getData(map.link) or {}
		return Table.merge(data, map)
	end)

	if config.sort then
		Array.sortInPlaceBy(mapList, function(map)
			return map.link .. (map.displayname or '')
		end)
	end

	return Maps._display(mapList, config)
end

---@private
---@param args table
---@return SC2MapsConfig
function Maps._readConfig(args)
	return {
		note = args.note,
		showAuthor = Logic.readBool(args.author),
		sort = Logic.readBool(args.sort),
		size = args.size,
		title = args.title,
		tournament = args.tournament,
	}
end

---@private
---@param args table
---@param config SC2MapsConfig
---@return SC2MapsMap[]
function Maps._readMaps(args, config)
	---@type SC2MapsMap[]
	local maps = Array.mapIndexes(function(mapIndex)
		local prefix = 'map' .. mapIndex
		local map = args[prefix]
		if Logic.isEmpty(map) then
			return
		end

		return {
			displayname = args[prefix .. 'display'],
			link = mw.ext.TeamLiquidIntegration.resolve_redirect(map),
			image = args[prefix .. 'image'],
			imageDark = args[prefix .. 'imageDark'],
			author = args[prefix .. 'author'],
			authorLink = args[prefix .. 'authorLink'],
		}
	end)

	if maps[1] then
		return maps
	end

	if not config.tournament then
		maps = Json.parseIfTable(Variables.varDefault('tournament_maps')) --[[@as SC2MapsMap[] ]]
		if maps then
			return maps
		end
	end

	local tournament = config.tournament or mw.title.getCurrentTitle().prefixedText
	local data = mw.ext.LiquipediaDB.lpdb('tournament', {
		conditions = '[[pagename::' .. tournament:gsub(' ', '_') .. ']]',
		query = 'maps'
	})

	if Logic.isEmpty(data[1]) then
		return {}
	end

	return Json.parseIfTable(data[1].maps) or {}
end

---@private
---@param mapList SC2MapsMap[]
---@param config SC2MapsConfig
---@return Widget
function Maps._display(mapList, config)
	return TableWidgets.Table{
		sortable = false,
		caption = config.title,
		columns = Array.map(mapList, function()
			return {align = 'center'}
		end),
		children = {
			-- name row
			TableWidgets.Row{children = Array.map(mapList, function(map)
				return TableWidgets.CellHeader{children = Link{link = map.link, children = map.displayname}}
			end)},
			TableWidgets.TableBody{children = WidgetUtil.collect(
				-- image row
				TableWidgets.Row{children = Array.map(mapList, function(map)
					return TableWidgets.Cell{
						children = Maps._displayThumb(map, config.size),
					}
				end)},
				-- author row (if enabled)
				config.showAuthor and TableWidgets.Row{children = Array.map(mapList, function(map)
					return TableWidgets.Cell{
						children = map.authorLink and {
							'By ',
							Maps._displayAuthor(map)
						} or nil,
						css = {
							['font-size'] = '90%',
							['padding-left'] = '4px',
							['padding-right'] = '4px',
						},
					}
				end)} or nil
			)}
		},
		footer = config.note,
	}
end

return Class.export(Maps, {exports = {'thumb', 'run'}})
