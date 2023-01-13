package.path = "../?.lua;" .. package.path

MathUtil = require('standard/math_util')

print(MathUtil.sum({ 2, 3 }))
