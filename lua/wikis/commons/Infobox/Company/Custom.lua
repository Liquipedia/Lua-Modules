---
-- @Liquipedia
-- page=Module:Infobox/Company/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

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
