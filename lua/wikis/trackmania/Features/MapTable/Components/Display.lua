---
-- @Liquipedia
-- page=Module:Features/MapTable/Components/Display
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Links = Lua.import('Module:Links')
local Table = Lua.import('Module:Table')

local Component = Lua.import('Module:Widget/Component')
local Link = Lua.import('Module:Widget/Basic/Link')
local Html = Lua.import('Module:Widget/Html')
local InlinePlayerWidget = Lua.import('Module:Widget/PlayerDisplay/Inline')
local TableWidgets = Lua.import('Module:Widget/Table2/All')

---Builds the mapper cell content for a single map, one mapper per line
---@param mappers TrackmaniaMapTableMapper[]
---@return Renderable[]
local function makeMapperDisplay(mappers)
	return Array.interleave(
		Array.map(mappers, function(mapper) return InlinePlayerWidget{player = mapper} end),
		Html.Br{}
	)
end

---Builds the links cell content for a single map
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

---@param rows TrackmaniaMapTableRows
---@param mappers TrackmaniaMapTableMappers
---@param links TrackmaniaMapTableLinks
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

---@param props {rows: TrackmaniaMapTableRows, mappers: TrackmaniaMapTableMappers, links: TrackmaniaMapTableLinks}
---@return VNode
local MapTableDisplay = function(props)
	return TableWidgets.Table{
		children = {
			makeHeader(),
			makeBody(props.rows, props.mappers, props.links),
		},
	}
end

return Component.component(MapTableDisplay)
