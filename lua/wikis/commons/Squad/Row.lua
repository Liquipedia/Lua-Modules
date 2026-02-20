---
-- @Liquipedia
-- page=Module:Squad/Row
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Icon = Lua.import('Module:Icon')
local Opponent = Lua.import('Module:Opponent/Custom')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')
local String = Lua.import('Module:StringUtils')
local Template = Lua.import('Module:Template')

local Table2Widgets = Lua.import('Module:Widget/Table2/All')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Row, Cell = Table2Widgets.Row, Table2Widgets.Cell

local RoleIcons = {
	captain = Icon.makeIcon{iconName = 'captain', hover = 'Captain'},
	sub = Icon.makeIcon{iconName = 'substitute', hover = 'Substitute'},
}

---@class SquadRow: BaseClass
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
	local idContent = {
		HtmlWidgets.B{children = {OpponentDisplay.InlineOpponent{opponent = opponent}}},
	}

	local roleIcon = RoleIcons[(self.model.role or ''):lower()]
	if roleIcon then
		table.insert(idContent, '&nbsp;' .. roleIcon)
	end

	local cell = Cell{
		children = idContent,
	}

	local date = self.model.leavedate or self.model.inactivedate
	local hasTeam = self.model.extradata.loanedto and mw.ext.TeamTemplate.teamexists(self.model.extradata.loanedto)
	local hasTeamRole = hasTeam and self.model.extradata.loanedtorole
	local teamNode = Cell{
		children = {
			hasTeam and mw.ext.TeamTemplate.teamicon(self.model.extradata.loanedto, date) or nil,
			hasTeamRole and HtmlWidgets.Small{children = {HtmlWidgets.I{children = {self.model.extradata.loanedtorole}}}} or nil,
		}
	}

	table.insert(self.children, cell)
	table.insert(self.children, teamNode)

	return self
end

---@return self
function SquadRow:name()
	table.insert(self.children, Cell{
		children = String.isNotEmpty(self.model.name) and {self.model.name} or nil,
	})

	return self
end

---@return self
function SquadRow:role()
	local display = String.isNotEmpty(self.model.role) and not RoleIcons[self.model.role:lower()]

	table.insert(self.children, Cell{
		children = display and {self.model.role} or nil,
	})

	return self
end

---Display Position and Role in a single cell
---@return self
function SquadRow:position()
	local displayRole = String.isNotEmpty(self.model.role) and not RoleIcons[self.model.role:lower()]

	local content = {}

	if String.isNotEmpty(self.model.position) or String.isNotEmpty(self.model.role) then
		if String.isNotEmpty(self.model.position) then
			table.insert(content, self.model.position)
			if displayRole then
				table.insert(content, ' (' .. self.model.role .. ')')
			end
		elseif displayRole then
			table.insert(content, self.model.role)
		end
	end

	table.insert(self.children, Cell{
		children = content,
	})

	return self
end

---@param field string
---@return self
function SquadRow:date(field)
	table.insert(self.children, Cell{
		children = self.model[field] and {
			HtmlWidgets.I{children = {self.model.extradata[field .. 'display'] or self.model[field]}},
		} or nil,
	})

	return self
end

---@return self
function SquadRow:newteam()
	local function createContent()
		local content = {}
		local newTeam, newTeamRole, newTeamSpecial = self.model.newteam, self.model.newteamrole, self.model.newteamspecial
		local hasNewTeam, hasNewTeamRole = String.isNotEmpty(newTeam), String.isNotEmpty(newTeamRole)
		local hasNewTeamSpecial = String.isNotEmpty(newTeamSpecial)

		if not hasNewTeam and not hasNewTeamRole and not hasNewTeamSpecial then
			return content
		end

		if hasNewTeamSpecial then
			table.insert(content, Template.safeExpand(mw.getCurrentFrame(), newTeamSpecial))
			return content
		end

		if not hasNewTeam then
			table.insert(content, newTeamRole)
			return content
		end

		local date = self.model.extradata.newteamdate or self.model.leavedate
		table.insert(content, mw.ext.TeamTemplate.team(newTeam, date))

		if hasNewTeamRole then
			table.insert(content, ' (' .. newTeamRole .. ')')
		end
		return content
	end

	table.insert(self.children, Cell{
		children = createContent(),
	})

	return self
end

---@return Widget
function SquadRow:create()
	return Row{
		children = self.children,
	}
end

return SquadRow
