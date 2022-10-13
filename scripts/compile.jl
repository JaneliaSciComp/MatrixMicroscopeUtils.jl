# This script does optional native compilation of the MatrixMicroscopeUtils environment
# Redo the compilation after updating the packages
using Pkg

# Activate the package compiler environment and load it
Pkg.activate(joinpath(@__DIR__, "compile"))
Pkg.resolve()
Pkg.instantiate()
using PackageCompiler

# Switch back to the MatrixMicroscopeUtils environment and compile it
Pkg.activate(dirname(@__DIR__))
sysimage_path = "matrix_microscope_utils.dll"
create_sysimage(; sysimage_path)

@info "Compilation completed!" sysimage_path
@info "Invoke the Julia scripts using the following invocation for faster execution:"
@info "julia -J $sysimage_path scripts/get_template_for_acquisition.jl"