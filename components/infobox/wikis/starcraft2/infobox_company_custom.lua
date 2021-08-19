local Company = require('Module:Infobox/Company')

local CustomCompany = {}

function CustomCompany.run(frame)
	local company = Company(frame)
	Company.addCustomCells = CustomCompany.addCustomCells
	return company:createInfobox(frame)
end

function CustomCompany.addCustomCells(company, infobox, args)
  infobox:cell('Organizer Type', args.organizertype)
	infobox:cell('Industry', args.industry)
	infobox:cell('Partners', args.partners)
	infobox:cell('Members', args.members)
	infobox:cell('Key People', args['key people'])
	infobox:cell('Products', args.products)
	infobox:cell('Events', args.events)
	infobox:cell('Founder', args.founder)
	return infobox
end

return CustomCompany
