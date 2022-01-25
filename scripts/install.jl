# Invoke this once to install the packages and its dependencies
using Pkg
Pkg.activate(dirname(@__DIR__))
Pkg.resolve()
Pkg.instantiate()