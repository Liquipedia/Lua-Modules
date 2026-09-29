---
-- @Liquipedia
-- page=Module:MapTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
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

---@class MapTable
---@operator call(TrackmaniaMapTableRowArgs[]): MapTable
local MapTable = Class.new(function(self, rows) self:init(rows) end)

---@param rows TrackmaniaMapTableRowArgs[]
---@return self
function MapTable:init(rows)
	self.rows = rows or {}
	self.mappers = Array.map(self.rows, function(row) return self:_readMappers(row) end)
	self.links = Array.map(self.rows, function(row) return self:_makeFullLinks(row) end)
	return self
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

	local mapTable = MapTable(rows)
	local renderedTable = mapTable:_renderTable()
	mapTable:_createLpdbEntry()

	return renderedTable
end

---Reads the mapper entries of a single row and resolves their links and flags
---@private
---@param row TrackmaniaMapTableRowArgs
---@return TrackmaniaMapTableMapper[]
function MapTable:_readMappers(row)
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
function MapTable:_makeFullLinks(mapInput)
	return Table.filterByKey(
		Links.makeFullLinksForTableItems(Links.transform(mapInput), LINK_VARIANT),
		function(_, link) return link ~= '' end
	)
end

---Builds the links cell content for a single map
---@private
---@param links {[string]: string}
---@return Renderable[]
function MapTable:_makeLinksDisplay(links)
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
function MapTable:_makeMapperDisplay(mappers)
	return Array.interleave(
		Array.map(mappers, function(mapper) return InlinePlayerWidget{player = mapper} end),
		Html.Br{}
	)
end

---Creates an LPDB map record per map, as `map` datapoints
---@private
---@return self
function MapTable:_createLpdbEntry()
	if not Namespace.isMain() or Lpdb.isStorageDisabled() then
		return self
	end

	Array.forEach(self.rows, function(row, rowIndex)
		local mapName = row.map
		if Logic.isEmpty(mapName) then
			return
		end

		local extradata = {}
		for _, mapper in ipairs(self.mappers[rowIndex]) do
			extradata['author' .. mapper.index] =
				mapper.pageName and mapper.pageName:gsub(' ', '_') or ''
			extradata['author' .. mapper.index .. 'dn'] = mapper.displayName
			extradata['author' .. mapper.index .. 'flag'] = mapper.flag or ''
		end

		local links = self.links[rowIndex]
		if Table.isNotEmpty(links) then
			extradata.links = links
		end

		mw.ext.LiquipediaDB.lpdb_datapoint('map_' .. mapName, Json.stringifySubTables({
			name = mapName,
			type = 'map',
			extradata = extradata,
		}))
	end)

	return self
end

---@private
---@return Renderable
function MapTable:_makeBody()
	return TableWidgets.TableBody{
		children = Array.map(self.rows, function(row, index)
			return TableWidgets.Row{
				children = {
					TableWidgets.Cell{children = self:_makeMapperDisplay(self.mappers[index])},
					TableWidgets.Cell{children = row.map},
					TableWidgets.Cell{
						classes = {'plainlinks'},
						children = self:_makeLinksDisplay(self.links[index]),
					},
				},
			}
		end),
	}
end

---@private
---@return Renderable
function MapTable:_makeHeader()
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

---@private
---@return Renderable
function MapTable:_renderTable()
	return TableWidgets.Table{
		children = {
			self:_makeHeader(),
			self:_makeBody(),
		},
	}
end

return Class.export(MapTable, {exports = {'run'}})
