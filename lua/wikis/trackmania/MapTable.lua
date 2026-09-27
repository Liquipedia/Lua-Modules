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
local Flags = Lua.import('Module:Flags')
local Json = Lua.import('Module:Json')
local Links = Lua.import('Module:Links')
local Lpdb = Lua.import('Module:Lpdb')
local Namespace = Lua.import('Module:Namespace')
local Page = Lua.import('Module:Page')
local PlayerExt = Lua.import('Module:Player/Ext/Custom')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local Variables = Lua.import('Module:Variables')

local Link = Lua.import('Module:Widget/Basic/Link')
local Html = Lua.import('Module:Widget/Html')
local Table2 = Lua.import('Module:Widget/Table2/All')

-- Default variant used when building the links of a map
local LINK_VARIANT = 'map'

---@class MapTableRowArgs: table<string, string?>
---@field map string?
---@field mapper string?
---@field mapperflag string?

---@class MapTableMapper
---@field index integer
---@field displayName string
---@field page string?
---@field flag string?

---@class MapTable
---@operator call(MapTableRowArgs[]): MapTable
local MapTable = Class.new(function(self, rows) self:init(rows) end)

---@param rows MapTableRowArgs[]
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

	---@type MapTableRowArgs[]
	local rows = Array.map(
		Array.filter(
			Array.mapIndexes(function(index) return args[index] end),
			String.isNotEmpty
		),
		function(mapJson) return Json.parseIfString(mapJson) end
	)

	local mapTable = MapTable(rows)
	local renderedTable = mapTable:_renderTable()
	mapTable:_createLpdbEntry()

	return renderedTable
end

---Reads the mapper entries of a single row and resolves their links and flags
---@private
---@param row MapTableRowArgs
---@return MapTableMapper[]
function MapTable:_readMappers(row)
	---@type MapTableMapper[]
	local mappers = {}

	for key, mapper, index in Table.iter.pairsByPrefix(row, {'mapper', 'author', 'a'}, {requireIndex = false}) do
		local page = Page.pageifyLink(String.nilIfEmpty(row[key .. 'link']) or mapper)
		local flag = String.nilIfEmpty(row[key .. 'flag'])
		if not flag and page then
			flag = PlayerExt.fetchPlayerFlag(page)
		end

		table.insert(mappers, {
			index = index,
			displayName = mapper,
			page = page,
			flag = flag,
		})
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
---@param mappers MapTableMapper[]
---@return Renderable[]
function MapTable:_makeMapperDisplay(mappers)
	---@type Renderable[]
	local children = {}

	for index, mapper in ipairs(mappers) do
		if index > 1 then
			table.insert(children, Html.Br{})
		end

		local flagIcon = Flags.Icon{flag = mapper.flag, shouldLink = true}
		if String.isNotEmpty(flagIcon) then
			Array.appendWith(children, flagIcon, '&nbsp;')
		end

		table.insert(children, Link{link = mapper.page, children = mapper.displayName})
	end

	return children
end

---Creates LPDB map record for tournament_name
---@private
---@return self
function MapTable:_createLpdbEntry()
	if not Namespace.isMain() or Lpdb.isStorageDisabled() then
		return self
	end

	-- An accumulator for maps in case of multiple uses of the module
	local maps = Json.parseIfTable(Variables.varDefault('tournament_maps')) or {}
	Array.extendWith(maps, Array.map(self.rows, function(row, rowIndex)
		local mapData = {}

		for _, mapper in ipairs(self.mappers[rowIndex]) do
			mapData['author' .. mapper.index] = {
				page = mapper.page or '',
				displayName = mapper.displayName,
				flag = mapper.flag or '',
			}
		end

		mapData.map = row.map or ''

		local links = self.links[rowIndex]
		if Table.isNotEmpty(links) then
			mapData.links = links
		end

		return mapData
	end))

	if Table.isEmpty(maps) then
		return self
	end

	local tournamentName = Variables.varDefault('tournament_name', mw.title.getCurrentTitle().text)
	local tournamentMaps = Json.stringify(maps, {asArray = true})

	Variables.varDefine('tournament_maps', tournamentMaps)
	mw.ext.LiquipediaDB.lpdb_tournament('tournament_' .. tournamentName, {
		maps = tournamentMaps,
	})

	return self
end

---@private
---@return Renderable
function MapTable:_makeBody()
	return Table2.TableBody{
		children = Array.map(self.rows, function(row, index)
			return Table2.Row{
				children = {
					Table2.Cell{children = self:_makeMapperDisplay(self.mappers[index])},
					Table2.Cell{children = row.map},
					Table2.Cell{
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
	return Table2.TableHeader{
		children = {
			Table2.Row{
				children = {
					Table2.CellHeader{children = 'Author'},
					Table2.CellHeader{children = 'Map'},
					Table2.CellHeader{children = 'Links'},
				},
			},
		},
	}
end

---@private
---@return Renderable
function MapTable:_renderTable()
	return Table2.Table{
		children = {
			self:_makeHeader(),
			self:_makeBody(),
		},
	}
end

return Class.export(MapTable, {exports = {'run'}})
