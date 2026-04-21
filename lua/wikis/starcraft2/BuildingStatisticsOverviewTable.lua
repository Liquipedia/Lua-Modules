---
-- @Liquipedia
-- page=Module:BuildingStatisticsOverviewTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Faction = Lua.import('Module:Faction')
local FnUtil = Lua.import('Module:FnUtil')
local Game = Lua.import('Module:Game')
local String = Lua.import('Module:StringUtils')
local Tabs = Lua.import('Module:Tabs')


local Condition = Lua.import('Module:Condition')
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local ColumnName = Condition.ColumnName

local Image = Lua.import('Module:Widget/Image/Icon/Image')
local Link = Lua.import('Module:Widget/Basic/Link')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local GAS = Lua.import('Module:Gas', {loadData = true})
local BUILDTIME = Lua.import('Module:Buildtime', {loadData = true})
local MINERALS = Image{imageLight = 'Minerals.gif', link = 'Minerals', verticalAlignment = 'baseline'}
local ARMOR = Image{imageLight = 'Icon Armor.png', link = 'Armor'}
local HEALTH = Image{imageLight = 'Icon Hitpoints.png'}
local SHIELD = Image{imageLight = 'Icon Shields.png', link = 'Plasma Shield'}
local PROTOSS = 'p'
local EXLUDE_PATTERNS = {
	'khaydarin_monolith',
	'cut_features',
	'drakken_laser',
	'hive_mind_emulator',
	'merc_compound',
	'campaign',
	'starbase',
	'phase_cannon',
	'monolith',
	'radar_tower',
	'obelisk',
}

local BuildingStats = {}

---@param frame Frame
---@return Widget|string?
function BuildingStats.wrapper(frame)
	local args = Arguments.getArgs(frame)

	local tabArgs = {}
	Array.forEach(Faction.coreFactions, function(faction, index)
		tabArgs['name' .. index] = Faction.Icon{faction = faction} .. ' ' .. Faction.toName(faction)
		tabArgs['content' .. index] = BuildingStats._build{game = args.game, faction = faction}
	end)

	return Tabs.dynamic(tabArgs)
end

---@private
---@param args {game: string?, faction: string}
---@return Widget?
function BuildingStats._build(args)
	local game = Game.name{game = args.game or 'Legacy of the Void'}
	assert(game, 'Invalid or missing game input')
	local faction = args.faction

	local buildings = BuildingStats._queryBuildings(game, faction)
	if not buildings or type(buildings[1]) ~= 'table' then
		return
	end

	--exclude some Buildings (Campaign)
	buildings = Array.filter(buildings, function(building)
		local page = building.pagename:lower()
		local name = building.name:lower()

		return not Array.any(EXLUDE_PATTERNS, function(pattern)
			return string.match(page,pattern)
		end) and not string.match(name,'supply depot lowered')
	end)

	return TableWidgets.Table{
		columns = BuildingStats._columns(faction),
		children = {
			BuildingStats._header(faction),
			TableWidgets.TableBody{children = Array.map(buildings, FnUtil.curry(BuildingStats._row, faction))}
		}
	}
end

---@private
---@param game string
---@param faction string
---@return table[]
function BuildingStats._queryBuildings(game, faction)
	local lowercasedGame = game:lower():gsub(' ', '_')
	local buildingType = 'Building information ' .. faction
	local buildings = mw.ext.LiquipediaDB.lpdb('datapoint', {
		conditions = tostring(ConditionNode(ColumnName('type'), Comparator.eq, buildingType)),
		order = 'name asc',
		query = 'information, name, pagename, extradata',
		limit = 5000,
	})

	return Array.filter(buildings, function(building)
		return building.information == game
			or String.contains(building.pagename:lower(), lowercasedGame)
	end)
end

---@private
---@param faction string
---@return {}[]
function BuildingStats._columns(faction)
	return WidgetUtil.collect(
		{align = 'left'}, -- name
		{align = 'center'}, -- mins
		{align = 'center'}, -- gas
		{align = 'center'}, -- time
		{align = 'center'}, -- health
		faction == PROTOSS and {align = 'center'} or nil, -- shield
		{align = 'center'}, -- armor
		{align = 'center'} -- sight
	)
end

---@private
---@param faction string
---@return Widget
function BuildingStats._header(faction)
	return TableWidgets.TableHeader{
		children = TableWidgets.Row{
			children = WidgetUtil.collect(
				TableWidgets.CellHeader{children = 'Building'},
				TableWidgets.CellHeader{children = MINERALS},
				TableWidgets.CellHeader{children = GAS[faction]},
				TableWidgets.CellHeader{children = BUILDTIME[faction]},
				TableWidgets.CellHeader{children = HEALTH},
				faction == PROTOSS and TableWidgets.CellHeader{children = SHIELD} or nil,
				TableWidgets.CellHeader{children = ARMOR},
				TableWidgets.CellHeader{children = Link{link = 'Sight'}}
			)
		}
	}
end

---@private
---@param faction string
---@param building table
---@return Html
function BuildingStats._row(faction, building)
	local extradata = building.extradata or {}

	return TableWidgets.Row{
		children = WidgetUtil.collect(
			TableWidgets.Cell{children = Link{link = building.pagename, children = building.name}},
			TableWidgets.Cell{children = extradata.minerals or '-'},
			TableWidgets.Cell{children = extradata.gas or '-'},
			TableWidgets.Cell{children = extradata.buildtime},
			TableWidgets.Cell{children = extradata.hp},
			faction == PROTOSS and TableWidgets.CellHeader{children = extradata.shield} or nil,
			TableWidgets.Cell{children = extradata.armor or 0},
			TableWidgets.Cell{children = extradata.sight or 9}
		)
	}
end

return BuildingStats
