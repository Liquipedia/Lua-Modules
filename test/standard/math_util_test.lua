package.path = "../?.lua;" .. package.path

MathUtil = require('standard/math_util')

assert(MathUtil.sum({ 2, 3 }) == 5)
