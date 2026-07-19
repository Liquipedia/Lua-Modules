---
-- @Liquipedia
-- page=Module:Widget/FactionLists
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Faction = Lua.import('Module:Faction')
local FnUtil = Lua.import('Module:FnUtil')
local Game = Lua.import('Module:Game')
local Table = Lua.import('Module:Table')

local Component = Lua.import('Module:Widget/Component')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local Box = Lua.import('Module:Widget/Basic/Box')

local FactionLists = {}

---@return Renderable
function FactionLists:render()
	return Box{
		children = Array.map(Game.listGames{ordered=true}, FactionLists._getTable)
	}
end

---@private
---@param game string
---@return string
function FactionLists._getTable(game)
	local factions = Faction.getFactions{game = game}
	local aliases = Table.groupBy(Faction.getAliases{game = game}, function (_, value) return value end)

	local header = Game.name{game = game} or 'Factions'

	return TableWidgets.Table{
		title = header,
		children = Array.extend(
			TableWidgets.TableHeader{
				children = {
					TableWidgets.CellHeader{children = 'Name'},
					TableWidgets.CellHeader{children = 'Aliases'},
					TableWidgets.CellHeader{children = 'Identifier'},
				}
			},
			Array.map(
				Array.sortBy(factions, FnUtil.identity),
				function (faction)
					return TableWidgets.Row{
						children = {
							TableWidgets.Cell{
								classes = {'draft', 'faction'},
								children = Faction.Icon{
									faction=faction,
									game=game,
									showLink=true,
									showTitle=true,
									showName=true,
									size=64
								},
							},
							TableWidgets.Cell{
								children = Array.interleave(Array.extractKeys(aliases[faction] or {}), ', ')
							},
							TableWidgets.Cell{
								children = faction
							}
						}
					}
				end
			)
		)
	}
end

return Component.component(FactionLists.render)
