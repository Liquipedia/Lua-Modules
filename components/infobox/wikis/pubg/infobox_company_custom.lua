---
-- @Liquipedia
-- wiki=rocketleague
-- page=Module:Infobox/Company/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Company = require('Module:Infobox/Company')
local Cell = require('Module:Infobox/Cell')

local CustomCompany = {}

function CustomCompany.run(frame)
    local company = Company(frame)
    company.addCustomCells = CustomCompany.addCustomCells
    return company:createInfobox(frame)
end

function CustomCompany:addCustomCells(infobox, args)
    infobox:fcell(Cell:new(CustomCompany._createSisterCompaniesDescription(args))
					:content(
						unpack(self:getAllArgsForBase(args, 'sister', {}))
					)
					:make()
				)

    return infobox
end

function CustomCompany._createSisterCompaniesDescription(args)
    if args.sister2 then
      return 'Sister Companies'
    end
    return 'Sister Company'
end

return CustomCompany
