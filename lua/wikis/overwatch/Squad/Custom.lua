---
-- @Liquipedia
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

local Widget = Lua.import('Module:Widget/All')
local Squad = Lua.import('Module:Widget/Squad/Core')
local SquadRow = Lua.import('Module:Squad/Row')
local SquadUtils = Lua.import('Module:Squad/Utils')
local SquadContexts = Lua.import('Module:Widget/Contexts/Squad')

local CustomSquad = {}

---@class OverwatchSquadRow: SquadRow
local ExtendedSquadRow = Class.new(SquadRow)

---@return self
function ExtendedSquadRow:number()
	table.insert(self.children, Widget.Td{
		classes = {'Number'},
		children = String.isNotEmpty(self.model.extradata.number) and {
			mw.html.create('div'):addClass('MobileStuff'):wikitext('Number:&nbsp;'),
			self.model.extradata.number,
		} or nil,
	})

	return self
end

---@param frame Frame
---@return Widget
function CustomSquad.run(frame)
	local args = Arguments.getArgs(frame)
	local props = {
		status = SquadUtils.statusToSquadStatus(args.status) or SquadUtils.SquadStatus.ACTIVE,
		title = args.title,
		type = SquadUtils.TypeToSquadType[args.type] or SquadUtils.SquadType.PLAYER,
	}
	local players = SquadUtils.parsePlayers(args)

	local showNumber = Array.any(players, Operator.property('number'))

	props.children = Array.map(players, function(player)
		return CustomSquad._playerRow(player, props.status, props.type, showNumber)
	end)

	local root = SquadContexts.RoleTitle{value = SquadUtils.positionTitle(), children = {Squad(props)}}
	if not showNumber then
		return root
	end

	return SquadContexts.NameSection{
		value = function(widgets)
			table.insert(widgets, 1, Widget.Th{children = {'Number'}})
			return widgets
		end,
		children = {root},
	}
end

---@param players table[]
---@param squadStatus SquadStatus
---@param squadType SquadType
---@param customTitle string?
---@return Widget
function CustomSquad.runAuto(players, squadStatus, squadType, customTitle)
	return SquadUtils.defaultRunAuto(players, squadStatus, squadType, Squad, SquadUtils.defaultRow(SquadRow), customTitle)
end

---@param person table
---@param squadStatus SquadStatus
---@param squadType SquadType
---@param showNumber boolean
---@return Widget
function CustomSquad._playerRow(person, squadStatus, squadType, showNumber)
	local squadPerson = SquadUtils.readSquadPersonArgs(Table.merge(person, {status = squadStatus, type = squadType}))
	squadPerson.extradata.number = person.number
	SquadUtils.storeSquadPerson(squadPerson)

	local row = ExtendedSquadRow(squadPerson)

	row:id()
	if showNumber then
		row:number()
	end
	row:name():position():date('joindate', 'Join Date:&nbsp;')

	if squadStatus == SquadUtils.SquadStatus.INACTIVE or squadStatus == SquadUtils.SquadStatus.FORMER_INACTIVE then
		row:date('inactivedate', 'Inactive Date:&nbsp;')
	end

	if squadStatus == SquadUtils.SquadStatus.FORMER or squadStatus == SquadUtils.SquadStatus.FORMER_INACTIVE then
		row:date('leavedate', 'Leave Date:&nbsp;')
		row:newteam()
	end

	return row:create()
end

return CustomSquad
