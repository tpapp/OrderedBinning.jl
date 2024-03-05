# OrderedBinning.jl

![lifecycle](https://img.shields.io/badge/lifecycle-experimental-orange.svg)
[![build](https://github.com/tpapp/OrderedBinning.jl/workflows/CI/badge.svg)](https://github.com/tpapp/OrderedBinning.jl/actions?query=workflow%3ACI)
[![codecov.io](http://codecov.io/github/tpapp/OrderedBinning.jl/coverage.svg?branch=master)](http://codecov.io/github/tpapp/OrderedBinning.jl?branch=master)
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)

Flexible binning of univariate arguments based on a sorted vector.

# Features

- customizable “halo” around the range or boundaries, for handling numerical error
- customizable handling of values that coincide with bin boundaries
- outside values can error or return a custom value on either side

# Why is this in a package?

At the core, it is a trivial application of `searchsortedfirst` etc. I wanted to handle corner cases and have everything tested in a package.
