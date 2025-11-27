local Carousel = require('Module:Widget/Basic/Carousel')

describe('Carousel', function()
	describe('render', function()
		it('creates a carousel wrapper with navigation buttons', function()
			local carousel = Carousel{}
			local result = tostring(carousel)
			assert.is_truthy(result:match('class="carousel"'))
			assert.is_truthy(result:match('carousel%-button%-%-left'))
			assert.is_truthy(result:match('carousel%-button%-%-right'))
		end)

		it('creates carousel-content container', function()
			local carousel = Carousel{
				children = {'Item 1', 'Item 2', 'Item 3'}
			}
			local result = tostring(carousel)
			assert.is_truthy(result:match('class="carousel%-content"'))
		end)

		it('wraps children in carousel-item divs', function()
			local carousel = Carousel{
				children = {'Item 1', 'Item 2', 'Item 3'}
			}
			local result = tostring(carousel)
			assert.is_truthy(result:match('class="carousel%-item"'))
		end)

		it('applies custom itemMinWidth', function()
			local carousel = Carousel{
				itemMinWidth = '300px',
				children = {'Item 1'}
			}
			local result = tostring(carousel)
			assert.is_truthy(result:match('min%-width:300px'))
		end)

		it('applies custom gap', function()
			local carousel = Carousel{
				gap = '1rem',
				children = {'Item 1'}
			}
			local result = tostring(carousel)
			assert.is_truthy(result:match('gap:1rem'))
		end)

		it('adds custom classes to wrapper', function()
			local carousel = Carousel{
				classes = {'custom-class'},
				children = {'Item 1'}
			}
			local result = tostring(carousel)
			assert.is_truthy(result:match('carousel custom%-class'))
		end)

		it('merges custom css with default css', function()
			local carousel = Carousel{
				css = {color = 'red'},
				children = {'Item 1'}
			}
			local result = tostring(carousel)
			assert.is_truthy(result:match('color:red'))
			assert.is_truthy(result:match('gap:0%.5rem'))
		end)

		it('includes edge fade elements', function()
			local carousel = Carousel{
				children = {'Item 1'}
			}
			local result = tostring(carousel)
			assert.is_truthy(result:match('carousel%-fade%-%-left'))
			assert.is_truthy(result:match('carousel%-fade%-%-right'))
		end)

		it('handles empty children array', function()
			local carousel = Carousel{
				children = {}
			}
			local result = tostring(carousel)
			assert.is_truthy(result:match('class="carousel"'))
		end)
	end)
end)
