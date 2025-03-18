---
-- @Liquipedia
-- wiki=counterstrike
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Page = require('Module:Page')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local Game = Lua.import('Module:Game')
local Injector = Lua.import('Module:Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

local BANNED = mw.loadData('Module:Banned')

local ContractRoles = Lua.import('Module:ContractRoles')
local StaffRoles = Lua.import('Module:StaffRoles')
local InGameRoles = Lua.import('Module:InGameRoles')
local ROLES = Table.merge(ContractRoles, StaffRoles, InGameRoles)

---@class CounterstrikePersonRoleData
---@field category string
---@field category2 string?
---@field display string
---@field display2 string?
---@field store string?
---@field coach boolean?
---@field talent boolean?
---@field management boolean?

---@class CounterstrikeInfoboxPlayer: Person
---@field gamesList string[]
---@field role CounterstrikePersonRoleData?
---@field role2 CounterstrikePersonRoleData?
---@field roles CounterstrikePersonRoleData?
local CustomPlayer = Class.new(Player)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)
	player:setWidgetInjector(CustomInjector(player))

	player.args.history = player.args.team_history

	for steamKey, steamInput, steamIndex in Table.iter.pairsByPrefix(player.args, 'steam', {requireIndex = false}) do
		player.args['steamalternative' .. steamIndex] = steamInput
		player.args[steamKey] = nil
	end

	player.args.informationType = player.args.informationType or 'Player'

	player.args.banned = tostring(player.args.banned or '')

	player.gamesList = Array.filter(Game.listGames({ordered = true}), function (gameIdentifier)
			return player.args[gameIdentifier]
		end)

	player.role = ROLES[(player.args.role or ''):lower()]
	player.role2 = ROLES[(player.args.role2 or ''):lower()]
	player.roles = {}
	if player.args.roles then
		local roleKeys = Array.parseCommaSeparatedString(player.args.roles)
		for _, roleKey in ipairs(roleKeys) do
			local key = roleKey:lower()
			local roleData = ROLES[key]
			if roleData then
				table.insert(player.roles, roleData)
			end
		end
	end

	return player:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args = caller.args

	if id == 'custom' then
		return {
			Cell {
				name = 'Games',
				content = Array.map(caller.gamesList, function (gameIdentifier)
						return Game.text{game = gameIdentifier}
					end)
			}
		}
	elseif id == 'status' then
		return {
			Cell{name = 'Status', content = caller:_getStatusContents(args)},
			Cell{name = 'Years Active (Player)', content = {args.years_active}},
			Cell{name = 'Years Active (Org)', content = {args.years_active_manage}},
			Cell{name = 'Years Active (Coach)', content = {args.years_active_coach}},
			Cell{name = 'Years Active (Analyst)', content = {args.years_active_analyst}},
			Cell{name = 'Years Active (Talent)', content = {args.years_active_talent}},
		}
	elseif id == 'role' then
		local role = CustomPlayer._displayRole(caller.role)
		local role2 = CustomPlayer._displayRole(caller.role2)

		local inGameRoles = {}
		local contracts = {}
		local positions = {}

		if caller.roles and #caller.roles > 0 then
			for _, roleData in ipairs(caller.roles) do
				local roleDisplay = CustomPlayer._displayRole(roleData)
				if roleDisplay then
					local isInGameRole = false
					local inGameRoleKeys = {awper = true, igl = true, lurker = true, support = true, entry = true, rifler = true}
					local isContract = false
					local contractKeys = {standard = true, loan = true, standin = true, twoway = true}
					for _, data in pairs(ROLES) do
						if data == roleData and Table.includes(inGameRoleKeys, data) then
							isInGameRole = true
							break
						elseif data == roleData and Table.includes(contractKeys, data) then
							isContract = true
							break
						end
					end
					if isInGameRole then
						table.insert(inGameRoles, roleDisplay)
					elseif isContract then
						table.insert(contracts, roleDisplay)
					else
						table.insert(positions, roleDisplay)
					end
				end
			end
		end

		local inGameRolesDisplay = #inGameRoles > 0 and table.concat(inGameRoles, ", ") or nil
		local contractsDisplay = #contracts > 0 and table.concat(contracts, ", ") or nil
		local positionsDisplay = #positions > 0 and table.concat(positions, ", ") or nil

		local inGameRolesTitle = #inGameRoles > 1 and "In-game Roles" or "In-game Role"
		local contractsTitle = #contracts > 1 and "Contracts" or "Contract"
		local positionsTitle = #positions > 1 and "Positions" or "Position"

		local cells = {}

		if inGameRolesDisplay then
			table.insert(cells, Cell{name = inGameRolesTitle, content = {inGameRolesDisplay}})
		else
			table.insert(cells, Cell{name = (role2 and 'Roles' or 'Role'), content = {role, role2}})
		end

		if positionsDisplay then
			table.insert(cells, Cell{name = positionsTitle, content = {positionsDisplay}})
		end

		if contractsDisplay then
			table.insert(cells, Cell{name = contractsTitle, content = {contractsDisplay}})
		end

		return cells
	elseif id == 'region' then
		return {}
	end

	return widgets
end

---@param lpdbData table
---@param args table
---@param personType string
---@return table
function CustomPlayer:adjustLPDB(lpdbData, args, personType)
	local normalizeRole = function(roleData)
		if not roleData then return end
		return (roleData.store or roleData.display2 or roleData.display or ''):lower()
	end

	lpdbData.extradata.role = normalizeRole(self.role)
	lpdbData.extradata.role2 = normalizeRole(self.role2)

	return lpdbData
end

---@param args table
---@return table
function CustomPlayer:_getStatusContents(args)
	local statusContents = {}

	if String.isNotEmpty(args.status) then
		table.insert(statusContents, Page.makeInternalLink({onlyIfExists = true}, args.status) or args.status)
	end

	if String.isNotEmpty(args.banned) then
		local banned = BANNED[string.lower(args.banned)]
		if not banned then
			table.insert(statusContents, '[[Banned Players|Multiple Bans]]')
		end

		Array.extendWith(statusContents, Array.map(self:getAllArgsForBase(args, 'banned'),
				function(item)
					return BANNED[string.lower(item)]
				end
			))
	end

	return statusContents
end

---@param categories string[]
---@return string[]
function CustomPlayer:getWikiCategories(categories)
	local typeCategory = self:getPersonType(self.args).category

	Array.forEach(self.gamesList, function (gameIdentifier)
			local prefix = Game.abbreviation{game = gameIdentifier} or Game.name{game = gameIdentifier}
			table.insert(categories, prefix .. ' ' .. typeCategory .. 's')
		end)

	if Table.isEmpty(self.gamesList) then
		table.insert(categories, 'Gameless Players')
	end

	return Array.append(categories,
		(self.role or {}).category,
		(self.role2 or {}).category,
		(self.role or {}).category2,
		(self.role2 or {}).category2
	)
end

---@param roleData CounterstrikePersonRoleData?
---@return string?
function CustomPlayer._displayRole(roleData)
	if not roleData then return end

	---@param postFix string|integer|nil
	---@return string?
	local toDisplay = function(postFix)
		postFix = postFix or ''
		if not roleData['category' .. postFix] then return end
		return Page.makeInternalLink(roleData['display' .. postFix], ':Category:' .. roleData['category' .. postFix])
	end

	local role1Display = toDisplay()
	local role2Display = toDisplay(2)
	if role1Display and role2Display then
		role2Display = '(' .. role2Display .. ')'
	end

	return table.concat({role1Display, role2Display}, ' ')
end

---@param rolesTable CounterstrikePersonRoleData[]?
---@return string?
function CustomPlayer._displayRoles(rolesTable)
	if not rolesTable or #rolesTable == 0 then
		return nil
	end

	local displayedRoles = {}

	for _, roleData in ipairs(rolesTable) do
		local roleDisplay = CustomPlayer._displayRole(roleData)
		if roleDisplay then
			table.insert(displayedRoles, roleDisplay)
		end
	end

	if #displayedRoles == 0 then
		return nil
	end

	return table.concat(displayedRoles, ", ")
end

---@param args table
---@return {store: string, category: string}
function CustomPlayer:getPersonType(args)
	local roleData = self.role
	if roleData then
		if roleData.coach then
			return {store = 'Coach', category = 'Coache'}
		elseif roleData.management then
			return {store = 'Staff', category = 'Manager'}
		elseif roleData.talent then
			return {store = 'Talent', category = 'Talent'}
		end
	end
	return {store = 'Player', category = 'Player'}
end

return CustomPlayer
