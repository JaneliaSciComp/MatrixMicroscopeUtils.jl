using Pkg
Pkg.activate(dirname(@__DIR__))

using MatrixMicroscopeUtils
using ArgParse

s = ArgParseSettings(
    prog="scripts/batch_apply_template.jl",
    description="Turn stacks with header space in the current directory into a HDF5 file with 16-bit or 24-bit integers"
)

@add_arg_table! s begin
    "--force", "-f"
        help = "Force the application of the template. Use caution."
        action = :store_true
    "--rename_file_as_h5", "-h5"
        help = "Rename the stack file as a HDF5 file."
        action = :store_true
end

a = parse_args(ARGS, s)
keywords = ()
if a["force"]
    keywords = (truncate = true, ensure_zero = false)
end

try
    batch_apply_template(; keywords...)
catch err
    @error "Application failed" err
    @info "Consider using the -f option, with caution."
end
