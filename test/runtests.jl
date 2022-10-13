using MatrixMicroscopeUtils
using Test

@testset "MatrixMicroscopeUtils.jl" verbose=true begin
    include("metadata.jl")
    include("template.jl")
end
