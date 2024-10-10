---
-- @Liquipedia
-- wiki=overwatch
-- page=Module:Squad/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Widget = require('Module:Widget/All')

local Squad = Lua.import('Module:Widget/Squad/Core')
local SquadRow = Lua.import('Module:Squad/Row')
local SquadUtils = Lua.import('Module:Squad/Utils')

local CustomSquad = {}
local CustomInjector = Class.new(SquadUtils.positionHeaderInjector())
local HAS_NUMBER = false

function CustomInjector:parse(id, widgets)
	if id == 'header_name' and HAS_NUMBER then
		table.insert(widgets, 1, Widget.TableCellNew{content = {'Number'}, header = true})
	end

	return self._base:parse(id, widgets)
end

---@class OverwatchSquadRow: SquadRow
local ExtendedSquadRow = Class.new(SquadRow)

---@return self
function ExtendedSquadRow:number()
	table.insert(self.children, Widget.TableCellNew{
		classes = {'Number'},
		content = String.isNotEmpty(self.model.extradata.number) and {
			mw.html.create('div'):addClass('MobileStuff'):wikitext('Number:&nbsp;'),
			self.model.extradata.number,
		} or nil,
	})

	return self
end

---@param frame Frame
---@return string
function CustomSquad.run(frame)
	local args = Arguments.getArgs(frame)
	local props = {
		injector = CustomInjector(),
		type = SquadUtils.statusToSquadType(args.status) or SquadUtils.SquadType.ACTIVE,
		title = args.title,
	}
	local players = SquadUtils.parsePlayers(args)

	HAS_NUMBER = Array.any(players, Operator.property('number'))

	props.children = Array.map(players, function(player)
		return CustomSquad._playerRow(player, props.type)
	end)

	return tostring(Squad(props))
end

---@param playerList table[]
---@param squadType integer
---@param customTitle string?
---@return string?
function CustomSquad.runAuto(playerList, squadType, customTitle)
	return SquadUtils.defaultRunAuto(playerList, squadType, Squad, SquadUtils.defaultRow(SquadRow), customTitle)
end

---@param person table
---@param squadType integer
---@return WidgetTableRowNew
function CustomSquad._playerRow(person, squadType)
	local squadPerson = SquadUtils.readSquadPersonArgs(Table.merge(person, {type = squadType}))
	squadPerson.extradata.number = person.number
	SquadUtils.storeSquadPerson(squadPerson)

	local row = ExtendedSquadRow(squadPerson)

	row:id()
	if HAS_NUMBER then
		row:number()
	end
	row:name():position():date('joindate', 'Join Date:&nbsp;')

	if squadType == SquadUtils.SquadType.INACTIVE or squadType == SquadUtils.SquadType.FORMER_INACTIVE then
		row:date('inactivedate', 'Inactive Date:&nbsp;')
	end

	if squadType == SquadUtils.SquadType.FORMER or squadType == SquadUtils.SquadType.FORMER_INACTIVE then
		row:date('leavedate', 'Leave Date:&nbsp;')
		row:newteam()
	end

	return row:create()
end

return CustomSquad
