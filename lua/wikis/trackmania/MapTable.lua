---
-- @Liquipedia
-- page=Module:MapTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Json = Lua.import('Module:Json')
local Links = Lua.import('Module:Links')
local Logic = Lua.import('Module:Logic')
local Lpdb = Lua.import('Module:Lpdb')
local Namespace = Lua.import('Module:Namespace')
local Opponent = Lua.import('Module:Opponent')
local PlayerExt = Lua.import('Module:Player/Ext/Custom')
local Table = Lua.import('Module:Table')

local Link = Lua.import('Module:Widget/Basic/Link')
local Html = Lua.import('Module:Widget/Html')
local InlinePlayerWidget = Lua.import('Module:Widget/PlayerDisplay/Inline')
local TableWidgets = Lua.import('Module:Widget/Table2/All')

-- Default variant used when building the links of a map
local LINK_VARIANT = 'map'

---@class TrackmaniaMapTableRowArgs: table<string, string?>
---@field map string?
---@field mapper string?
---@field mapperFlag string?

---@class TrackmaniaMapTableMapper: standardPlayer
---@field index integer

local MapTable = {}

---Reads the mapper entries of a single row and resolves their links and flags
---@param row TrackmaniaMapTableRowArgs
---@return TrackmaniaMapTableMapper[]
local function readMappers(row)
	---@type TrackmaniaMapTableMapper[]
	local mappers = {}

	for key, mapper, index in Table.iter.pairsByPrefix(row, {'mapper', 'author', 'a'}, {requireIndex = false}) do
		---@type TrackmaniaMapTableMapper
		local player = Table.merge(
			Opponent.readSinglePlayerArgs{
				name = mapper,
				link = row[key .. 'link'],
				flag = row[key .. 'flag'],
			},
			{index = index}
		)

		PlayerExt.populatePageName(player)
		player.flag = player.flag or PlayerExt.fetchPlayerFlag(player.pageName)

		table.insert(mappers, player)
	end

	return mappers
end

---Builds the full links of a single map
---@private
---@param mapInput table
---@return {[string]: string}
local function makeFullLinks(mapInput)
	return Table.filterByKey(
		Links.makeFullLinksForTableItems(Links.transform(mapInput), LINK_VARIANT),
		function(_, link) return link ~= '' end
	)
end

---Builds the links cell content for a single map
---@private
---@param links {[string]: string}
---@return Renderable[]
local function makeLinksDisplay(links)
	return Array.interleave(
		Array.extractValues(Table.map(links, function(key, link)
			return key, Link{
				link = link,
				children = Links.makeIcon(Links.removeAppendedNumber(key), 25),
				linktype = 'external',
			}
		end), Table.iter.spairs),
		' '
	)
end

---Builds the mapper cell content for a single map
---@private
---@param mappers TrackmaniaMapTableMapper[]
---@return Renderable[]
local function makeMapperDisplay(mappers)
	return Array.interleave(
		Array.map(mappers, function(mapper) return InlinePlayerWidget{player = mapper} end),
		Html.Br{}
	)
end

---Creates an LPDB map record per map, as `map` datapoints
---@param rows TrackmaniaMapTableRowArgs[]
---@param mappers TrackmaniaMapTableMapper[][]
---@param links {[string]: string}[]
local function createLpdbEntry(rows, mappers, links)
	if not Namespace.isMain() or Lpdb.isStorageDisabled() then
		return
	end

	Array.forEach(rows, function(row, rowIndex)
		local mapName = row.map
		if Logic.isEmpty(mapName) then
			return
		end

		local extradata = {}
		for _, mapper in ipairs(mappers[rowIndex]) do
			extradata['author' .. mapper.index] =
				mapper.pageName and mapper.pageName:gsub(' ', '_') or ''
			extradata['author' .. mapper.index .. 'dn'] = mapper.displayName
			extradata['author' .. mapper.index .. 'flag'] = mapper.flag or ''
		end

		local rowLinks = links[rowIndex]
		if Table.isNotEmpty(rowLinks) then
			extradata.links = rowLinks
		end

		mw.ext.LiquipediaDB.lpdb_datapoint('map_' .. mapName, Json.stringifySubTables({
			name = mapName,
			type = 'map',
			extradata = extradata,
		}))
	end)
end

---@param rows TrackmaniaMapTableRowArgs[]
---@param mappers TrackmaniaMapTableMapper[][]
---@param links {[string]: string}[]
---@return Renderable
local function makeBody(rows, mappers, links)
	return TableWidgets.TableBody{
		children = Array.map(rows, function(row, index)
			return TableWidgets.Row{
				children = {
					TableWidgets.Cell{children = makeMapperDisplay(mappers[index])},
					TableWidgets.Cell{children = row.map},
					TableWidgets.Cell{
						classes = {'plainlinks'},
						children = makeLinksDisplay(links[index]),
					},
				},
			}
		end),
	}
end

---@return Renderable
local function makeHeader()
	return TableWidgets.TableHeader{
		children = {
			TableWidgets.Row{
				children = {
					TableWidgets.CellHeader{children = 'Author'},
					TableWidgets.CellHeader{children = 'Map'},
					TableWidgets.CellHeader{children = 'Links'},
				},
			},
		},
	}
end

-- Module entry point
---@param frame Frame
---@return Renderable
function MapTable.run(frame)
	local args = Arguments.getArgs(frame)

	---@type TrackmaniaMapTableRowArgs[]
	local rows = Array.map(
		Array.mapIndexes(function(index) return args[index] end),
		Json.parseIfString
	)

	local mappers = Array.map(rows, readMappers)
	local links = Array.map(rows, makeFullLinks)

	local renderedTable = TableWidgets.Table{
		children = {
			makeHeader(),
			makeBody(rows, mappers, links),
		},
	}

	createLpdbEntry(rows, mappers, links)

	return renderedTable
end

return MapTable
