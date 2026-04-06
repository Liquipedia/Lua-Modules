---
-- @Liquipedia
-- page=Module:Maps
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Abbreviation = Lua.import('Module:Abbreviation')
local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local Math = Lua.import('Module:MathUtil')
local Page = Lua.import('Module:Page')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local Variables = Lua.import('Module:Variables')

local WidgetUtil = Lua.import('Module:Widget/Util')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local Image = Lua.import('Module:Image')

local Maps = {}

local PLACEHOLDER = 'MapImagePlaceholder.jpg'

---@class AoEMapData
---@field link string
---@field name string?
---@field image string?
---@field icon string?

---Entrypoint
---@param args table?
---@return Renderable?
function Maps.main(args)
	args = args or {}
	local maps = Maps.getMaps(args)
	if Table.isEmpty(maps) then
		return Abbreviation.make{text = 'TBD', title = 'To be determined'}
	end

	return Maps.buildDisplay(maps, args)
end

---Retrieve maps, either from input, variable, or LPDB
---@param args table
---@return AoEMapData[]
function Maps.getMaps(args)
	local maps, failure
	if args.map1 then
		maps = Maps.getManualMaps(args)
	elseif String.isNotEmpty(Variables.varDefault('tournament_maps')) then
		maps, failure = Json.parse(Variables.varDefault('tournament_maps'))
	end
	if failure or args.tournament or String.isEmpty(Variables.varDefault('tournament_maps')) and not args.map1 then
		maps = Maps.getMapsFromLpdb(args)
	end

	return Array.map(maps, Maps.fetchMapData)
end

---Retrieve maps from LPDB
---@param args table
---@return AoEMapData[]
function Maps.getMapsFromLpdb(args)
	local tournament = args.tournament or mw.title.getCurrentTitle().prefixedText or ''
	local data = mw.ext.LiquipediaDB.lpdb('tournament', {
		conditions = '[[pagename::' .. tournament:gsub(' ', '_') .. ']]',
		query = 'maps'
	})

	if type(data) == 'table' and data[1] then
		local maps, _ = Json.parseIfString(data[1].maps)
		return maps
	else
		error("No data available for page " .. tournament)
	end
end

---Parse manual input
---@param args table
---@return AoEMapData[]
function Maps.getManualMaps(args)
	local maps = {}
	for key, value in Table.iter.pairsByPrefix(args, 'map') do
		local input = mw.text.split(value, '|', true)
		local link = args[key .. 'link'] and args[key .. 'link'] or mw.ext.TeamLiquidIntegration.resolve_redirect(input[1])
		local name = input[2] and input[2] or input[1]

		table.insert(maps, {
			link = link,
			name = name,
			image = args[key .. 'image']
		})
	end
	return maps
end

---Enrich map data from map page LPDB
---@param map AoEMapData
---@return AoEMapData
function Maps.fetchMapData(map)
	local data = mw.ext.LiquipediaDB.lpdb('datapoint', {
		conditions = '[[type::map]] AND [[pagename::' .. string.gsub(map.link, ' ', '_') .. ']]',
		query = 'name, image, extradata',
	})

	if type(data) == 'table' and data[1] then
		map.name = map.name or data[1].name
		map.image = map.image or data[1].image
		map.icon = (data[1].extradata or {}).icon
	else
		map.name = map.name or map.link
	end

	return map
end

---@param maps AoEMapData[]
---@param args table
---@return Renderable
function Maps.buildDisplay(maps, args)
	local columns = {}

	local useIcons = Logic.nilOr(
		Logic.readBoolOrNil(args.useIcons),
		Array.all(maps, function(map) return String.isNotEmpty(map.icon) end)
	)

    if args.category1 then
        local mapsLookup = Table.map(maps, function (k, v)
            return v.name, v
        end)

        for key, category in Table.iter.pairsByPrefix(args, 'category') do
            category = Json.parseIfString(category)
            assert(category.title, "Category is missing a title: " .. key)

			local column = {
				name = category.title,
				children = {}
			}

            Array.forEach(category, function (mapName, index)
                local mapData = mapsLookup[mapName]
				assert(mapData, "Unknown map: " .. mapName)

				table.insert(column.children, Maps.buildImage(mapData, args.size or 'x100px', useIcons))
				table.insert(column.children, Page.makeInternalLink(mapData.name, mapData.link))
            end)

			table.insert(columns, column)
        end
    else
		columns = Array.map(maps, function (mapData)
			return {
				name = Page.makeInternalLink(mapData.name, mapData.link),
				children = {
					{Maps.buildImage(mapData, args.size or 'x100px', useIcons)}
				}
			}
		end)
    end


	if args.note then
		mw.ext.TeamLiquidIntegration.add_category('Mappools with note')
	end

	local headerRow = TableWidgets.TableHeader{children=Array.map(columns, function (col)
		return TableWidgets.CellHeader{children = col.name}
	end)}

	local longestColumn = Array.max(Array.map(columns, function(col) return #col.children end))
	local rows = Array.map(Array.range(1, longestColumn), function (row)
		return TableWidgets.Row{
			children = Array.map(columns, function (col)
				return TableWidgets.Cell{
					children = col.children[row]
				}
			end)
		}
	end)

	return TableWidgets.Table{
		title = args.title,
		sortable = false,
		tableClasses = args.category1 and {'collapsible', 'collapsed'} or nil,
		css = {
			-- Fit besides the infobox
			['width'] = 'unset',
		},
		columns = Array.map(columns, function ()
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
			headerRow,
			TableWidgets.TableBody{
				children = rows
			}
		)
	}
end

---@param map AoEMapData
---@param size string
---@param useIcons boolean
---@return string?
function Maps.buildImage(map, size, useIcons)
	local image = PLACEHOLDER
	if useIcons and String.isNotEmpty(map.icon) then
		image = map.icon
	elseif String.isNotEmpty(map.image) then
		image = map.image
	end
	return Image.display(image, nil, {
		size = size,
		link = map.link
	})
end

return Class.export(Maps, {exports = {"main"}})
