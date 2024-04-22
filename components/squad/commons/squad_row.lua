---
-- @Liquipedia
-- wiki=commons
-- page=Module:Squad/Row
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Icon = require('Module:Icon')
local Info = require('Module:Info')
local Lua = require('Module:Lua')
local OpponentLib = require('Module:OpponentLibraries')
local Opponent = OpponentLib.Opponent
local OpponentDisplay = OpponentLib.OpponentDisplay
local String = require('Module:StringUtils')
local Template = require('Module:Template')

local Widget = Lua.import('Module:Infobox/Widget/All')

local RoleIcons = {
	captain = Icon.makeIcon{iconName = 'captain', hover = 'Captain'},
	sub = Icon.makeIcon{iconName = 'substitute', hover = 'Substitute'},
}

---@class SquadRow
---@operator call(ModelRow): SquadRow
---@field children Widget[]
---@field model ModelRow
local SquadRow = Class.new(
	function(self, squadPerson)
		self.children = {}
		self.model = assert(squadPerson, 'No Squad Person supplied to the Row')
	end
)

---@return self
function SquadRow:id()
	local content = {}
	local opponent = Opponent.resolve(
		Opponent.readOpponentArgs{
			self.model.id,
			flag = self.model.nationality,
			link = self.model.link,
			faction = self.model.extradata.faction,
			type = Opponent.solo,
		},
		nil, {syncPlayer = true}
	)
	table.insert(content, mw.html.create('b'):node(OpponentDisplay.InlineOpponent{opponent = opponent}))

	local roleIcon = RoleIcons[(self.model.role or ''):lower()]
	if roleIcon then
		table.insert(content, '&nbsp;' .. roleIcon)
	end

	local cell = Widget.TableCellNew{
		classes = {'ID'},
		content = content,
	}

	local date = self.model.leavedate or self.model.inactivedate
	local hasTeam = self.model.extradata.loanedto and mw.ext.TeamTemplate.teamexists(self.model.extradata.loanedto)
	local hasTeamRole = hasTeam and self.model.extradata.loanedtorole
	local teamNode = Widget.TableCellNew{
		css = hasTeamRole and {'text-align', 'center'} or nil,
		content = {
			hasTeam and mw.ext.TeamTemplate.teamicon(self.model.extradata.loanedto, date) or nil,
			hasTeamRole and mw.html.create('small'):tag('i'):wikitext(self.model.extradata.loanedtorole) or nil,
		}
	}

	table.insert(self.children, cell)
	table.insert(self.children, teamNode)

	return self
end

---@return self
function SquadRow:name()
	table.insert(self.children, Widget.TableCellNew{
		classes = {'Name'},
		content = String.isNotEmpty(self.model.name) and {
			mw.html.create('div'):addClass('MobileStuff'):wikitext('(', self.model.name, ')'),
			mw.html.create('div'):addClass('LargeStuff'):wikitext(self.model.name),
		} or nil
	})

	return self
end

---@return self
function SquadRow:role()
	local display = String.isNotEmpty(self.model.role) and not RoleIcons[self.model.role:lower()]

	table.insert(self.children, Widget.TableCellNew{
		classes = {'Position'},
		content = display and {
			mw.html.create('div'):addClass('MobileStuff'):wikitext('Role:&nbsp;'),
			mw.html.create('i'):wikitext('(' .. self.model.role .. ')'),
		} or nil,
	})

	return self
end

---Display Position and Role in a single cell
---@return self
function SquadRow:position()
	local displayRole = String.isNotEmpty(self.model.role) and not RoleIcons[self.model.role:lower()]

	local content = {}

	if String.isNotEmpty(self.model.position) or String.isNotEmpty(self.model.role) then
		table.insert(content, mw.html.create('div'):addClass('MobileStuff'):wikitext('Position:&nbsp;'))

		if String.isNotEmpty(self.model.position) then
			table.insert(content, self.model.position)
			if displayRole then
				table.insert(content, '&nbsp;(' .. self.model.role .. ')')
			end
		elseif displayRole then
			table.insert(content, self.model.role)
		end
	end

	table.insert(self.children, Widget.TableCellNew{
		classes = {'Position'},
		content = content,
	})

	return self
end

---@param field string
---@param cellTitle string?
---@return self
function SquadRow:date(field, cellTitle)
	table.insert(self.children, Widget.TableCellNew{
		classes = {'Date'},
		content = self.model[field] and {
			mw.html.create('div'):addClass('MobileStuffDate'):wikitext(cellTitle),
			mw.html.create('div'):addClass('Date')
				:tag('i'):wikitext(self.model.extradata[field .. 'display'] or self.model[field])
		} or nil
	})

	return self
end

---@return self
function SquadRow:newteam()
	local function createContent()
		local content = {}
		local newTeam, newTeamRole, newTeamSpecial = self.model.newteam, self.model.newteamrole, self.model.newTeamSpecial
		local hasNewTeam, hasNewTeamRole = String.isNotEmpty(newTeam), String.isNotEmpty(newTeamRole)
		local hasNewTeamSpecial = String.isNotEmpty(newTeamSpecial)

		if not hasNewTeam and not hasNewTeamRole and not hasNewTeamSpecial then
			return content
		end

		table.insert(content, mw.html.create('div'):addClass('MobileStuff')
			:tag('i'):addClass('fa fa-long-arrow-right'):attr('aria-hidden', 'true'):done():wikitext('&nbsp;'))

		if hasNewTeamSpecial then
			table.insert(content, Template.safeExpand(mw.getCurrentFrame(), newTeamSpecial))
			return content
		end

		if not hasNewTeam then
			table.insert(content, mw.html.create('div'):addClass('NewTeamRole'):wikitext(newTeamRole))
			return content
		end

		local date = self.model.newteamdate or self.model.leavedate
		table.insert(content, mw.ext.TeamTemplate.team(newTeam, date))

		if hasNewTeamRole then
			table.insert(content, '&nbsp;')
			table.insert(content, mw.html.create('i'):tag('small'):wikitext('(' .. newTeamRole .. ')'))
		end
		return content
	end

	table.insert(self.children, Widget.TableCellNew{
		classes = {'NewTeam'},
		content = createContent(),
	})

	return self
end

---@return WidgetTableRowNew
function SquadRow:create()
	-- Set row background for certain roles
	local backgrounds = {'Player'}
	local role = string.lower(self.model.role or '')

	if role == 'sub' then
		table.insert(backgrounds, 'sub')
	elseif role:find('coach') then
		table.insert(backgrounds, role)
		table.insert(backgrounds, 'roster-coach')
	end

	return Widget.TableRowNew{
		classes = backgrounds,
		children = self.children,
	}
end

return SquadRow
