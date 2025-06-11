---
-- @Liquipedia
-- page=Module:ContractRoles
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---@type PersonRoleData
local contractRoles = {
	['loan'] = {category = 'Players On Loan', display = 'On loan'},
	['standard'] = {category = 'Standard Contracts', display = 'Standard'},
	['standin'] = {category = 'Stand-in Players', display = 'Stand-in'},
	['twoway'] = {category = 'Two-way Contracts', display = 'Two-way'},
}

return contractRoles
