--- Triple Comment to Enable our LLS Plugin
describe('NameOrder', function()
	local NameOrder = require('Module:NameOrder')

	describe('uses eastern order', function ()
		it('verify', function ()
			assert.is_true(NameOrder.usesEasternNameOrder('China'))
			assert.is_true(NameOrder.usesEasternNameOrder('Taiwan'))
			assert.is_true(NameOrder.usesEasternNameOrder('Hong Kong'))
			assert.is_true(NameOrder.usesEasternNameOrder('Vietnam'))
			assert.is_true(NameOrder.usesEasternNameOrder('South Korea'))
			assert.is_true(NameOrder.usesEasternNameOrder('Cambodia'))
			assert.is_true(NameOrder.usesEasternNameOrder('Macau'))
			assert.is_true(NameOrder.usesEasternNameOrder('Singapore'))
		end)
	end)

	describe('does not use eastern order', function ()
		it('verify', function ()
			assert.is_not_true(NameOrder.usesEasternNameOrder('United States'))
			assert.is_not_true(NameOrder.usesEasternNameOrder('Germany'))
			assert.is_not_true(NameOrder.usesEasternNameOrder('Japan'))
			assert.is_not_true(NameOrder.usesEasternNameOrder('France'))
			assert.is_not_true(NameOrder.usesEasternNameOrder('Canada'))
			assert.is_not_true(NameOrder.usesEasternNameOrder('Brazil'))
			assert.is_not_true(NameOrder.usesEasternNameOrder('Russia'))
			assert.is_not_true(NameOrder.usesEasternNameOrder('Spain'))
		end)
	end)

	describe('name reordering', function ()
		it('verify', function ()
			--Faker
			local inputFirstName1, inputLastName1 = 'Sang-hyeok', 'Lee'
			local outputLastName1, outputFirstName1 = NameOrder.reorderNames(
				inputFirstName1, inputLastName1, {country = 'South Korea'}
			)
			assert.are_equal(inputFirstName1, outputFirstName1)
			assert.are_equal(inputLastName1, outputLastName1)

			--generic western name
			local inputFirstName2, inputLastName2 = 'John', 'Doe'
			local outputFirstName2, outputLastName2 = NameOrder.reorderNames(
				inputFirstName2, inputLastName2, {country = 'United Kingdom'}
			)
			assert.are_equal(inputFirstName2, outputFirstName2)
			assert.are_equal(inputLastName2, outputLastName2)

			--Deft, with reordering suppressed
			local inputFirstName3, inputLastName3 = 'Hyuk-kyu', 'Kim'
			local outputFirstName3, outputLastName3 = NameOrder.reorderNames(
				inputFirstName3, inputLastName3, {country = 'South Korea', forceWesternOrder = true}
			)
			assert.are_equal(inputFirstName3, outputFirstName3)
			assert.are_equal(inputLastName3, outputLastName3)

			--generic western name, with force reordering
			local inputFirstName4, inputLastName4 = 'Jane', 'Doe'
			local outputLastName4, outputFirstName4 = NameOrder.reorderNames(
				inputFirstName4, inputLastName4, {country = 'United States', forceEasternOrder = true}
			)
			assert.are_equal(inputFirstName4, outputFirstName4)
			assert.are_equal(inputLastName4, outputLastName4)
		end)
	end)
end)
