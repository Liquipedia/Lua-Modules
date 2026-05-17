---
-- @Liquipedia
-- page=Module:UnitStatisticsOverviewTable
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
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local Html = require('Module:Widget/Html')
local Image = Lua.import('Module:Widget/Image/Icon/Image')
local Link = Lua.import('Module:Widget/Basic/Link')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local SUPPLY = Lua.import('Module:Supply', {loadData = true})
local GAS = Lua.import('Module:Gas', {loadData = true})
local BUILDTIME = Lua.import('Module:Buildtime', {loadData = true})
local MINERALS = Image{
	imageLight = 'Minerals.gif',
	size = '18',
	link = 'Minerals',
	verticalAlignment = 'baseline',
}
local ARMOR = Image{
	imageLight = 'Icon Armor.png',
	size = '18',
	link = 'Armor',
}
local HELATH = Image{
	imageLight = 'Icon Hitpoints.png',
	size = '18',
	link = '',
}
local SHIELD = Image{
	imageLight = 'Icon Shields.png',
	size = '18',
	link = 'Plasma Shield',
}
local DPS = Html.Abbr{title = 'Damage', children = Link{link = 'DPS'}}

local PROTOSS = Faction.read('protoss')
local EXCLUDE_PAGE_STRINGS = {
	'campaign',
	'coop',
	'terran_minor_units',
	'cut_features',
}
local EXCLUDE_NAME_STRINGS = {
	'floating',
	'burrowed',
	'cocoon',
	'warp prism deployed',
	'liberator defender mode',
	'siege tank siege mode',
	'thor high impact mode',
	'viking assault mode',
	'infested swarm egg',
	'uprooted',
	'primal',
}

local UnitStats = {}

---@param frame Frame
---@return VNode|Widget|string?
function UnitStats.wrapper(frame)
	local args = Arguments.getArgs(frame)
	local game = Game.name{game = args.game or 'lotv'}
	assert(game, 'Invalid game: ' .. args.game)

	local tabArgs = {}
	for index, faction in ipairs(Faction.coreFactions) do
		tabArgs['name' .. index] = Faction.Icon{faction = faction} .. ' ' .. Faction.toName(faction)
		tabArgs['content' .. index] = UnitStats._forFaction{game = game, faction = faction}
	end

	return Tabs.dynamic(tabArgs)
end

---@private
---@param args {game: string, faction: string}
---@return VNode?
function UnitStats._forFaction(args)
	local units = UnitStats._queryUnits(args.game, args.faction)

	if not units or type(units[1]) ~= 'table' then
		return
	end

	--exclude some units
	units = Array.filter(units, function(unitData)
		local page = unitData.pagename:lower()
		local name = unitData.name:lower()
		return Array.all(EXCLUDE_PAGE_STRINGS, function(str)
			return string.find(page, str) == nil
		end) and Array.all(EXCLUDE_NAME_STRINGS, function(str)
			return string.find(name, str) == nil
		end)
	end)

	return TableWidgets.Table{
		children = {
			UnitStats._header(args.faction),
			TableWidgets.TableBody{children = Array.flatMap(units, FnUtil.curry(UnitStats._row, args.game))},
		}
	}
end

---@private
---@param game string
---@param faction string
---@return table[]
function UnitStats._queryUnits(game, faction)
	local lowercasedGame = game:lower():gsub(' ', '_')

	local conditions = ConditionTree(BooleanOperator.all):add{
		ConditionNode(ColumnName('type'), Comparator.eq, 'Unit'),
		ConditionNode(ColumnName('race', 'extradata'), Comparator.eq, faction),
		ConditionNode(ColumnName('iscampaignunit', 'extradata'), Comparator.eq, 'false'),
		ConditionNode(ColumnName('deprecated', 'extradata'), Comparator.eq, 'false'),
		ConditionNode(ColumnName('wasonlybeta', 'extradata'), Comparator.eq, 'false'),
	}

	local units = mw.ext.LiquipediaDB.lpdb('datapoint', {
		conditions = tostring(conditions),
		order = 'name asc',
		query = 'information, type, name, pagename, extradata',
		limit = 5000,
	})

	return Array.filter(units, function(unit)
		return unit.information == game
			or String.contains(unit.pagename:lower(), lowercasedGame)
	end)
end

---@private
---@param faction string
---@return VNode
function UnitStats._header(faction)
	local cells = WidgetUtil.collect(
		TableWidgets.CellHeader{children = 'Name'},
		TableWidgets.CellHeader{children = SUPPLY[faction]},
		TableWidgets.CellHeader{children = MINERALS},
		TableWidgets.CellHeader{children = GAS[faction]},
		TableWidgets.CellHeader{children = WidgetUtil.collect(
			BUILDTIME[faction],
			faction == PROTOSS and {
				' / ',
				Link{link = 'Warp Gate', children = 'WG'},
			} or nil
		)},
		TableWidgets.CellHeader{children = 'Size'},
		TableWidgets.CellHeader{children = 'Cargo'},
		TableWidgets.CellHeader{children = ARMOR},
		TableWidgets.CellHeader{children = HELATH},
		faction == PROTOSS and TableWidgets.CellHeader{children = SHIELD} or nil,
		TableWidgets.CellHeader{children = 'Attributes'},
		TableWidgets.CellHeader{children = Link{link = 'Speed'}},
		TableWidgets.CellHeader{children = Link{link = 'Sight'}},
		TableWidgets.CellHeader{children = 'Attack name'},
		TableWidgets.CellHeader{children = 'G. Attack'},
		TableWidgets.CellHeader{children = 'A. Attack'},
		TableWidgets.CellHeader{children = 'Bonus'},
		TableWidgets.CellHeader{children = {'G. ', DPS}},
		TableWidgets.CellHeader{children = {'A. ', DPS}},
		TableWidgets.CellHeader{children = {'Bonus ', DPS}},
		TableWidgets.CellHeader{children = Link{link = 'Cooldown'}},
		TableWidgets.CellHeader{children = Link{link = 'Range'}}
	)

	return TableWidgets.TableHeader{children = TableWidgets.Row{children = cells}}
end

---@private
---@param game string
---@param unit table
---@return VNode
function UnitStats._row(game, unit)
	local unitAttacks = UnitStats._queryUnitAttacks(game, unit.pagename)
	unitAttacks[1] = unitAttacks[1] or {extradata = {}}

	return Array.map(unitAttacks, function(attack, index)
		local cells = {}
		if index == 1 then
			cells = UnitStats._baseRow(game, unit, #unitAttacks > 1 and #unitAttacks or nil)
		end

		local data = attack.extradata

		local target = (data.target or ''):lower()
		local isVsBuildingsAttack = String.contains(target, 'buildings')
		local isGroundAttack = isVsBuildingsAttack or String.contains(target, 'ground')
		local isAirAttack = String.contains(target, 'air')

		local groundAttackDamage = isGroundAttack and data.damage or '-'
		if isVsBuildingsAttack then
			groundAttackDamage = groundAttackDamage .. ' vs Buildings'
		end

		Array.appendWith(cells,
			UnitStats._cell(attack.name, nil),
			UnitStats._cell(groundAttackDamage),--ground attack
			UnitStats._cell(isAirAttack and data.damage or nil),--air attack
			UnitStats._cell(data.bonus),--bonus
			UnitStats._cell(isGroundAttack and data.dps or nil),--ground DPS
			UnitStats._cell(isAirAttack and data.dps or nil),--air DPS
			UnitStats._cell(data.bonus_dps),--bonus DPS
			UnitStats._cell(data.cooldown),--Cooldown
			UnitStats._cell(data.range)--range
		)

		return TableWidgets.Row{children = cells}
	end)
end

---@private
---@param val VNode|Renderable?
---@param rowSpan integer?
---@return VNode
function UnitStats._cell(val, rowSpan)
	return TableWidgets.Cell{rowspan = rowSpan, children = val or '-'}
end

---@private
---@param game string
---@param unit table
---@param rowSpan integer?
---@return VNode[]
function UnitStats._baseRow(game, unit, rowSpan)
	mw.logObject(rowSpan, 'rowSpan')
	local extradata = unit.extradata or {}

	local name = unit.name
	if unit.name == 'Liberator Fighter Mode' then
		name = 'Liberator'
	elseif unit.name == 'Siege Tank Tank Mode' then
		name = 'Siege Tank'
	elseif unit.name == 'Thor Explosive Payload' then
		name = 'Thor'
	elseif unit.name == 'Viking Fighter Mode' then
		name = 'Viking'
	end

	local minerals = extradata.minerals
	local gas = extradata.gas
	if unit.name == 'Archon' and extradata.minerals == 'varies' and extradata.gas == 'varies' then
		minerals = Link{link = unit.pagename .. '#Cost', children = 'varies'}
		gas = Link{link = unit.pagename .. '#Cost', children = 'varies'}
	end

	return WidgetUtil.collect(
		UnitStats._cell(Link{link = unit.pagename, children = name}, rowSpan),
		UnitStats._cell(extradata.supply, rowSpan),
		UnitStats._cell(minerals, rowSpan),
		UnitStats._cell(gas, rowSpan),
		UnitStats._cell(extradata.buildtime, rowSpan),
		UnitStats._cell(extradata.size, rowSpan),
		UnitStats._cell(extradata.cargo_size, rowSpan),
		UnitStats._cell(extradata.armor, rowSpan),
		UnitStats._cell(extradata.hp, rowSpan),
		extradata.race == PROTOSS and UnitStats._cell(extradata.shield, rowSpan) or nil,
		UnitStats._cell(extradata.attributes, rowSpan),
		UnitStats._cell(extradata.speed, rowSpan),
		UnitStats._cell(extradata.sight, rowSpan)
	)
end

---@private
---@param game string
---@param page string
---@return table[]
function UnitStats._queryUnitAttacks(game, page)
	return Array.filter(mw.ext.LiquipediaDB.lpdb('datapoint', {
		conditions = tostring(ConditionNode(ColumnName('pagename'), Comparator.eq, page)),
		order = 'name asc',
		query = 'information, type, name, pagename, extradata',
		limit = 5000,
	}), function(item) return String.startsWith(item.type, 'Unit attack') end)
end

return UnitStats
