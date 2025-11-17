---
-- @Liquipedia
-- page=Module:Infobox/Company/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Company = Lua.import('Module:Infobox/Company')

---@class CustomCompanyInfobox: CompanyInfobox
local CustomCompany = Class.new(Company)

---@param frame Frame
---@return Html
function CustomCompany.run(frame)
	local company = CustomCompany(frame)
	return company:createInfobox()
end

return CustomCompany
