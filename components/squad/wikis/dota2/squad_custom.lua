---
-- @Liquipedia
-- wiki=dota2
-- page=Module:Squad/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Table = require('Module:Table')
local Widget = require('Module:Infobox/Widget/All')

local Squad = Lua.import('Module:Squad')
local SquadRow = Lua.import('Module:Squad/Row')
local SquadUtils = Lua.import('Module:Squad/Utils')

local CustomSquad = {}
local CustomInjector = Class.new(SquadUtils.positionHeaderInjector())

function CustomInjector:parse(id, widgets)
	if id == 'header_inactive' then
		table.insert(widgets, Widget.TableCellNew{content = {'Active Team'}, header = true})
	end

	return self._base:parse(id, widgets)
end

---@class Dota2SquadRow: SquadRow
local ExtendedSquadRow = Class.new(SquadRow)

---@return self
function ExtendedSquadRow:activeteam()
	local activeTeam, activeTeamRole = self.model.extradata.activeteam, self.model.activeteamrole
	local date = self.model.inactivedate

	if not activeTeam then
		return self
	end

	local content = {}

	table.insert(content, mw.ext.TeamTemplate.team(activeTeam, date))

	if activeTeamRole then
		table.insert(content, '&nbsp;')
		table.insert(content, mw.html.create('i'):tag('small'):wikitext('(' .. activeTeamRole .. ')'))
	end

	table.insert(self.children,
		Widget.TableCellNew{classes = {'NewTeam'}, content = content}
	)

	return self
end

---@param frame Frame
---@return Html
function CustomSquad.run(frame)
	return SquadUtils.defaultRunManual(frame, Squad, CustomSquad._playerRow, CustomInjector)
end

function CustomSquad._playerRow(person, squadType)
	local squadPerson = SquadUtils.readSquadPersonArgs(Table.merge(person, {type = squadType}))
	squadPerson.extradata.activeteam = person.activeteam
	squadPerson.extradata.activeteamrole = person.activeteamrole
	SquadUtils.storeSquadPerson(squadPerson)

	local row = ExtendedSquadRow(squadPerson)
	row:id()
	row:name()
	row:position()
	row:date('joindate', 'Join Date:&nbsp;')

	if squadType == SquadUtils.SquadType.INACTIVE or squadType == SquadUtils.SquadType.FORMER_INACTIVE then
		row:date('inactivedate', 'Inactive Date:&nbsp;')
		row:activeteam()
	end
	if squadType == SquadUtils.SquadType.FORMER or squadType == SquadUtils.SquadType.FORMER_INACTIVE then
		row:date('leavedate', 'Leave Date:&nbsp;')
		row:newteam()
	end

	return row:create()
end

return CustomSquad
