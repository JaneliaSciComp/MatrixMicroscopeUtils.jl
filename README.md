# MatrixMicroscopeUtils.jl

Utilities for the Matrix Microscope.

# Installation

This is currently a private repository. It may be easier to first `git clone` this repository with authentication, then use `import Pkg; Pkg.add(path="c:/path/to/MatrixMicroscopeUtils.jl")`. You can use `/` even on Windows.

If you have Github authentication, you may be able to add this via the following command.
```
] add https://github.com/JaneliaSciComp/MatrixMicroscopeUtils.jl.git#main
```

## `resave_uint12_stack_as_uint16_hdf5`

```julia
    resave_uint12_stack_as_uint16_hdf5(filename, [array_size]; h5_filename, split_timepoints, metadata, ...)
```

`resave_uint12_stack_as_uint16_hdf5(filename, array_size)` is a function to read a raw 12-bit integer stack and resave it as a 16-bit integer HDF5 file.

If the name of the file is of the form `TM0000000_CM1.stack`, then only a single argument is needed. The size of the array will be calculated from the corresponding
`cam1.xml` in the same folder. The number of time points within a stack will be derived from the array size and the file size.

### Arguments
* `filename` is a path to a file to convert. Using the absolute path is recommended. The file extension must be ".stack".
If the filename is of the format, "TM0000000CM1.stack" then timepoint and camera information will be parsed from the name.
Timepoint information will be used to create the dataset name.
Camera number information will be used to locate a metadata file such as "cam1.xml".
* `array_size` are the dimensions of the array as a tuple. Typically (X, Y, Z). If the `array_size` is not provided,
then it will be determined by finding the `dimensions_XYZ`` property in the metadata XML file.

### Keywords
* `h5_filename` is the name of the HDF5 file to create. "_uint16" is appended to the name and the extension is changed to h5 from stack
* `split_timepoints` determines whether to split timepoints into separate datasets in the HDF5 file. The default is `true` to split the timepoints.
   If `false`, a single 4D dataset will be saved with dimensions XYZT.
* `metadata` an optional `MatrixMetadata`

### Additional Keywords
Additional keywords are passed on to `HDF5.create_dataset`. Some examples of HDF5 keywords include
* `chunk` is a tuple of integers describing the chunk size. This needs to be specified to use HDF5 filters.
* `deflate` is an integer that determines the level of the standard HDF5 compression.
* `shuffle` is usually just an empty tuple `()` which indicates to do shuffle filtering.
See also the `HDF5` package for additional filters.

### Examples
```julia
julia> resave_uint12_stack_as_uint16_hdf5("TM0000000_CM5.stack")
┌ Info: Inferred the number of time points from the file size being a multiple of the number of expected bytes
│   array_size = (2304, 816, 17, 44)
└   expected_bytes = 47941632

julia> resave_uint12_stack_as_uint16_hdf5("TM0000044_CM5.stack", chunk = (288, 102, 17), shuffle=(), deflate=1)
┌ Info: Inferred the number of time points from the file size being a multiple of the number of expected bytes
│   array_size = (2304, 816, 17, 44)
└   expected_bytes = 47941632

julia> filename = raw"C:\Users\kittisopikulm\Documents\Keller_Lab\AgaroseBeads_561nm15pct_17Planes5umStep_20211011_113516\TM0000000_CM5.stack"
"C:\\Users\\kittisopikulm\\Documents\\Keller_Lab\\AgaroseBeads_561nm15pct_17Planes5umStep_20211011_113516\\TM0000000_CM5.stack"

julia> resave_uint12_stack_as_uint16_hdf5(filename, chunk = (288, 102, 17), shuffle=(), deflate=1)
┌ Info: Inferred the number of time points from the file size being a multiple of the number of expected bytes
│   array_size = (2304, 816, 17, 44)
└   expected_bytes = 47941632

julia> filename = raw"\\Keller-S10\Data\Matrix\RC_21-10-11\AgaroseBeads_561nm15pct_17Planes5umStep_20211011_113516\TM0000088_CM5.stack"
"\\\\Keller-S10\\Data\\Matrix\\RC_21-10-11\\AgaroseBeads_561nm15pct_17Planes5umStep_20211011_113516\\TM0000088_CM5.stack"

julia> resave_uint12_stack_as_uint16_hdf5(filename, chunk = (288, 102, 17), shuffle=(), deflate=1)
┌ Info: Inferred the number of time points from the file size being a multiple of the number of expected bytes
│   array_size = (2304, 816, 17, 44)
└   expected_bytes = 47941632
```

# Other functions

* `resave_uint16_stack_as_uint16_hdf5(filename)`
* `resave_stack_as_uint16_hdf5(filename)`
* `batch_resave_stacks_as_hdf5(in_path, out_path)`

# Scripts

* `scripts/install.jl` - Invoke once to instantiate the Julia environment and install all the packages.
* `scripts/batch_resave.jl` - Batch command to invoke `batch_resave_stacks_as_hdf5()`

## Example Script Usage
```powershell
PS C:\Users\kittisopikulm\Documents\Julia> git clone https://github.com/JaneliaSciComp/MatrixMicroscopeUtils.jl
remote: Enumerating objects: 73, done.
remote: Counting objects: 100% (73/73), done.
remote: Compressing objects: 100% (51/51), done.
remote: Total 73 (delta 26), reused 62 (delta 16), pack-reused 0R
Receiving objects: 100% (73/73), 40.50 KiB | 4.50 MiB/s, done.
Resolving deltas: 100% (26/26), done.

PS C:\Users\kittisopikulm\Documents\Julia> cd .\MatrixMicroscopeUtils.jl\

PS C:\Users\kittisopikulm\Documents\Julia\MatrixMicroscopeUtils.jl> julia .\scripts\install.jl
  Activating environment at `C:\Users\kittisopikulm\Documents\Julia\MatrixMicroscopeUtils.jl\Project.toml`
    Updating registry at `C:\Users\kittisopikulm\.julia\registries\General`
    Updating `C:\Users\kittisopikulm\Documents\Julia\MatrixMicroscopeUtils.jl\Project.toml`
  [f67ccb44] + HDF5 v0.15.7
  [9c8b4983] + LightXML v0.9.0
  [c28d94ed] + UInt12Arrays v0.2.0
    Updating `C:\Users\kittisopikulm\Documents\Julia\MatrixMicroscopeUtils.jl\Manifest.toml`
  [c3b6d118] + BitIntegers v0.2.6
  [a74b3585] + Blosc v0.7.2
  [34da2185] + Compat v3.41.0
  [f67ccb44] + HDF5 v0.15.7
  [692b3bcd] + JLLWrappers v1.4.0
  [9c8b4983] + LightXML v0.9.0
  [21216c6a] + Preferences v1.2.3
  [ae029012] + Requires v1.3.0
  [fdea26ae] + SIMD v3.4.0
  [c28d94ed] + UInt12Arrays v0.2.0
  [0b7ba130] + Blosc_jll v1.21.1+0
  [0234f1f7] + HDF5_jll v1.12.1+0
  [94ce4f54] + Libiconv_jll v1.16.1+1
  [5ced341a] + Lz4_jll v1.9.3+0
  [458c3c95] + OpenSSL_jll v1.1.13+0
  [02c8fc9c] + XML2_jll v2.9.12+0
  [3161d3a3] + Zstd_jll v1.5.0+0
  [0dad84c5] + ArgTools
  [56f22d72] + Artifacts
  [2a0f44e3] + Base64
  [ade2ca70] + Dates
  [8bb1440f] + DelimitedFiles
  [8ba89e20] + Distributed
  [f43a241f] + Downloads
  [b77e0a4c] + InteractiveUtils
  [b27032c2] + LibCURL
  [76f85450] + LibGit2
  [37e2e46d] + LinearAlgebra
  [56ddb016] + Logging
  [d6f4376e] + Markdown
  [a63ad114] + Mmap
  [ca575930] + NetworkOptions
  [44cfe95a] + Pkg
  [de0858da] + Printf
  [3fa0cd96] + REPL
  [9a3f8284] + Random
  [ea8e919c] + SHA
  [9e88b42a] + Serialization
  [1a1011a3] + SharedArrays
  [6462fe0b] + Sockets
  [2f01184e] + SparseArrays
  [10745b16] + Statistics
  [fa267f1f] + TOML
  [a4e569a6] + Tar
  [8dfed614] + Test
  [cf7118a7] + UUIDs
  [4ec0a83e] + Unicode
  [deac9b47] + LibCURL_jll
  [29816b5a] + LibSSH2_jll
  [c8ffd9c3] + MbedTLS_jll
  [14a3606d] + MozillaCACerts_jll
  [83775a58] + Zlib_jll
  [8e850ede] + nghttp2_jll
  [3f19e933] + p7zip_jll

PS C:\Users\kittisopikulm\Documents\Julia\MatrixMicroscopeUtils.jl> julia .\scripts\batch_resave.jl \\Keller-S10\Data\Matrix\RC_22-01-17\USAF_16bit_20220117_161054 \\Keller-S10\Data\Matrix\RC_22-01-17\USAF_16bit_20220117_161054\hdf5
  Activating environment at `C:\Users\kittisopikulm\Documents\Julia\MatrixMicroscopeUtils.jl\Project.toml`
Resaving \\Keller-S10\Data\Matrix\RC_22-01-17\USAF_16bit_20220117_161054\TM0000000_CM1.stack to \\Keller-S10\Data\Matrix\RC_22-01-17\USAF_16bit_20220117_161054\hdf5\TM0000000_CM1.h5
┌ Info: Inferred the number of time points from the file size being a multiple of the number of expected bytes
│   array_size = (2304, 816, 50, 11)
└   expected_bytes = 188006400
[ Info: Saving file as \\Keller-S10\Data\Matrix\RC_22-01-17\USAF_16bit_20220117_161054\hdf5\TM0000000_CM1.h5
Resaving \\Keller-S10\Data\Matrix\RC_22-01-17\USAF_16bit_20220117_161054\TM0000000_CM2.stack to \\Keller-S10\Data\Matrix\RC_22-01-17\USAF_16bit_20220117_161054\hdf5\TM0000000_CM2.h5
┌ Info: Inferred the number of time points from the file size being a multiple of the number of expected bytes
│   array_size = (2304, 816, 50, 11)
└   expected_bytes = 188006400
[ Info: Saving file as \\Keller-S10\Data\Matrix\RC_22-01-17\USAF_16bit_20220117_161054\hdf5\TM0000000_CM2.h5
Resaving \\Keller-S10\Data\Matrix\RC_22-01-17\USAF_16bit_20220117_161054\TM0000000_CM3.stack to \\Keller-S10\Data\Matrix\RC_22-01-17\USAF_16bit_20220117_161054\hdf5\TM0000000_CM3.h5
┌ Info: Inferred the number of time points from the file size being a multiple of the number of expected bytes
│   array_size = (2304, 816, 50, 11)
└   expected_bytes = 188006400
[ Info: Saving file as \\Keller-S10\Data\Matrix\RC_22-01-17\USAF_16bit_20220117_161054\hdf5\TM0000000_CM3.h5
Resaving \\Keller-S10\Data\Matrix\RC_22-01-17\USAF_16bit_20220117_161054\TM0000000_CM4.stack to \\Keller-S10\Data\Matrix\RC_22-01-17\USAF_16bit_20220117_161054\hdf5\TM0000000_CM4.h5
┌ Info: Inferred the number of time points from the file size being a multiple of the number of expected bytes
│   array_size = (2304, 816, 50, 11)
└   expected_bytes = 188006400
[ Info: Saving file as \\Keller-S10\Data\Matrix\RC_22-01-17\USAF_16bit_20220117_161054\hdf5\TM0000000_CM4.h5
Resaving \\Keller-S10\Data\Matrix\RC_22-01-17\USAF_16bit_20220117_161054\TM0000000_CM5.stack to \\Keller-S10\Data\Matrix\RC_22-01-17\USAF_16bit_20220117_161054\hdf5\TM0000000_CM5.h5
┌ Info: Inferred the number of time points from the file size being a multiple of the number of expected bytes
│   array_size = (2304, 816, 50, 11)
└   expected_bytes = 188006400
[ Info: Saving file as \\Keller-S10\Data\Matrix\RC_22-01-17\USAF_16bit_20220117_161054\hdf5\TM0000000_CM5.h5
Resaving \\Keller-S10\Data\Matrix\RC_22-01-17\USAF_16bit_20220117_161054\TM0000000_CM6.stack to \\Keller-S10\Data\Matrix\RC_22-01-17\USAF_16bit_20220117_161054\hdf5\TM0000000_CM6.h5
┌ Info: Inferred the number of time points from the file size being a multiple of the number of expected bytes
│   array_size = (2304, 816, 50, 11)
└   expected_bytes = 188006400
[ Info: Saving file as \\Keller-S10\Data\Matrix\RC_22-01-17\USAF_16bit_20220117_161054\hdf5\TM0000000_CM6.h5
Resaving \\Keller-S10\Data\Matrix\RC_22-01-17\USAF_16bit_20220117_161054\TM0000000_CM7.stack to \\Keller-S10\Data\Matrix\RC_22-01-17\USAF_16bit_20220117_161054\hdf5\TM0000000_CM7.h5
┌ Info: Inferred the number of time points from the file size being a multiple of the number of expected bytes
│   array_size = (2304, 816, 50, 11)
└   expected_bytes = 188006400
[ Info: Saving file as \\Keller-S10\Data\Matrix\RC_22-01-17\USAF_16bit_20220117_161054\hdf5\TM0000000_CM7.h5
Resaving \\Keller-S10\Data\Matrix\RC_22-01-17\USAF_16bit_20220117_161054\TM0000000_CM8.stack to \\Keller-S10\Data\Matrix\RC_22-01-17\USAF_16bit_20220117_161054\hdf5\TM0000000_CM8.h5
┌ Info: Inferred the number of time points from the file size being a multiple of the number of expected bytes
│   array_size = (2304, 816, 50, 11)
└   expected_bytes = 188006400
[ Info: Saving file as \\Keller-S10\Data\Matrix\RC_22-01-17\USAF_16bit_20220117_161054\hdf5\TM0000000_CM8.h5
Resaving \\Keller-S10\Data\Matrix\RC_22-01-17\USAF_16bit_20220117_161054\TM0000000_CM9.stack to \\Keller-S10\Data\Matrix\RC_22-01-17\USAF_16bit_20220117_161054\hdf5\TM0000000_CM9.h5
┌ Info: Inferred the number of time points from the file size being a multiple of the number of expected bytes
│   array_size = (2304, 816, 50, 11)
└   expected_bytes = 188006400
[ Info: Saving file as \\Keller-S10\Data\Matrix\RC_22-01-17\USAF_16bit_20220117_161054\hdf5\TM0000000_CM9.h5
Resaving \\Keller-S10\Data\Matrix\RC_22-01-17\USAF_16bit_20220117_161054\TM0000011_CM1.stack to \\Keller-S10\Data\Matrix\RC_22-01-17\USAF_16bit_20220117_161054\hdf5\TM0000011_CM1.h5
┌ Info: Inferred the number of time points from the file size being a multiple of the number of expected bytes
│   array_size = (2304, 816, 50, 11)
└   expected_bytes = 188006400
[ Info: Saving file as \\Keller-S10\Data\Matrix\RC_22-01-17\USAF_16bit_20220117_161054\hdf5\TM0000011_CM1.h5
Resaving \\Keller-S10\Data\Matrix\RC_22-01-17\USAF_16bit_20220117_161054\TM0000011_CM2.stack to \\Keller-S10\Data\Matrix\RC_22-01-17\USAF_16bit_20220117_161054\hdf5\TM0000011_CM2.h5
┌ Info: Inferred the number of time points from the file size being a multiple of the number of expected bytes
│   array_size = (2304, 816, 50, 11)
└   expected_bytes = 188006400
[ Info: Saving file as \\Keller-S10\Data\Matrix\RC_22-01-17\USAF_16bit_20220117_161054\hdf5\TM0000011_CM2.h5
Resaving \\Keller-S10\Data\Matrix\RC_22-01-17\USAF_16bit_20220117_161054\TM0000011_CM3.stack to \\Keller-S10\Data\Matrix\RC_22-01-17\USAF_16bit_20220117_161054\hdf5\TM0000011_CM3.h5
┌ Info: Inferred the number of time points from the file size being a multiple of the number of expected bytes
│   array_size = (2304, 816, 50, 11)
└   expected_bytes = 188006400
[ Info: Saving file as \\Keller-S10\Data\Matrix\RC_22-01-17\USAF_16bit_20220117_161054\hdf5\TM0000011_CM3.h5
Resaving \\Keller-S10\Data\Matrix\RC_22-01-17\USAF_16bit_20220117_161054\TM0000011_CM4.stack to \\Keller-S10\Data\Matrix\RC_22-01-17\USAF_16bit_20220117_161054\hdf5\TM0000011_CM4.h5
┌ Info: Inferred the number of time points from the file size being a multiple of the number of expected bytes
│   array_size = (2304, 816, 50, 11)
└   expected_bytes = 188006400
[ Info: Saving file as \\Keller-S10\Data\Matrix\RC_22-01-17\USAF_16bit_20220117_161054\hdf5\TM0000011_CM4.h5
Resaving \\Keller-S10\Data\Matrix\RC_22-01-17\USAF_16bit_20220117_161054\TM0000011_CM5.stack to \\Keller-S10\Data\Matrix\RC_22-01-17\USAF_16bit_20220117_161054\hdf5\TM0000011_CM5.h5
┌ Info: Inferred the number of time points from the file size being a multiple of the number of expected bytes
│   array_size = (2304, 816, 50, 11)
└   expected_bytes = 188006400
[ Info: Saving file as \\Keller-S10\Data\Matrix\RC_22-01-17\USAF_16bit_20220117_161054\hdf5\TM0000011_CM5.h5
Resaving \\Keller-S10\Data\Matrix\RC_22-01-17\USAF_16bit_20220117_161054\TM0000011_CM6.stack to \\Keller-S10\Data\Matrix\RC_22-01-17\USAF_16bit_20220117_161054\hdf5\TM0000011_CM6.h5
┌ Info: Inferred the number of time points from the file size being a multiple of the number of expected bytes
│   array_size = (2304, 816, 50, 11)
└   expected_bytes = 188006400
[ Info: Saving file as \\Keller-S10\Data\Matrix\RC_22-01-17\USAF_16bit_20220117_161054\hdf5\TM0000011_CM6.h5

...
```

# Reading HDF5 files in Julia

HDF5 files can be read in Julia via HDF5.jl.

```julia
julia> using HDF5

julia> filename = raw"C:\Users\kittisopikulm\Documents\Keller_Lab\AgaroseBeads_561nm15pct_17Planes5umStep_20211011_113516\TM0000000_CM5.stack"
"C:\\Users\\kittisopikulm\\Documents\\Keller_Lab\\AgaroseBeads_561nm15pct_17Planes5umStep_20211011_113516\\TM0000000_CM5.stack"

julia> cd(dirname(filename))

julia> h5f = h5open(raw"TM0000000_CM5_uint16.h5")
🗂️ HDF5.File: (read-only) TM0000000_CM5_uint16.h5
└─ 📂 CM5
   ├─ 🏷️ bit_depth
   ├─ 🏷️ cam
   ├─ 🏷️ channel
   ├─ 🏷️ data_header
   ├─ 🏷️ defect_correction
   ├─ 🏷️ detection_filter
   ├─ 🏷️ dimensions_XYZ
   ├─ 🏷️ experiment_notes
   ├─ 🏷️ frame_exposure_time_ms
   ├─ 🏷️ laser_power
   ├─ 🏷️ planes
   ├─ 🏷️ roi_XY
   ├─ 🏷️ sampling_XYZ_um
   ├─ 🏷️ software_version
   ├─ 🏷️ specimen_name
   ├─ 🏷️ stack_direction
   ├─ 🏷️ tile_XYZ_um
   ├─ 🏷️ timepoints
   ├─ 🏷️ version
   ├─ 🏷️ wavelength_nm
   ├─ 🏷️ xml_metadata
   ├─ 🔢 TM0000000
   │  └─ 🏷️ element_size_um
   ├─ 🔢 TM0000001
   │  └─ 🏷️ element_size_um
   ├─ 🔢 TM0000002
   │  └─ 🏷️ element_size_um
   ├─ 🔢 TM0000003
   │  └─ 🏷️ element_size_um
   └─ (40 more children)

julia> h5f["CM5"]["TM0000001"][:,:,1]
2304×816 Matrix{UInt16}:
 0x0118  0x013e  0x0129  0x0148  0x0115  0x0143  0x0133  …  0x00f4  0x00ff  0x011d  0x011a  0x017c  0x0143  0x010b
 0x00df  0x011a  0x0106  0x013f  0x010e  0x0113  0x0129     0x0110  0x010f  0x0103  0x00d7  0x012a  0x012a  0x00fe
 0x0115  0x00fb  0x0105  0x0100  0x00ef  0x00f8  0x00f0     0x010b  0x0153  0x00ea  0x00eb  0x0118  0x0107  0x0108
 0x00f6  0x0107  0x0103  0x00f4  0x00ea  0x0111  0x00e6     0x0139  0x0112  0x0146  0x0111  0x013a  0x00f5  0x0158
 0x00fd  0x0116  0x010b  0x0131  0x0103  0x00fb  0x00e8     0x0120  0x0134  0x00ee  0x010f  0x011e  0x0106  0x010b
 0x0119  0x011c  0x0117  0x0136  0x00ff  0x00de  0x00dd  …  0x00fe  0x013b  0x0104  0x010d  0x019a  0x0113  0x00fd
 0x0121  0x012b  0x0104  0x0100  0x00e6  0x011c  0x0102     0x0110  0x0124  0x0174  0x0116  0x0154  0x00ed  0x0106
 0x00fd  0x0118  0x0128  0x011d  0x0101  0x0104  0x00f6     0x010d  0x00f9  0x0100  0x0112  0x0110  0x00ef  0x0100
 0x0117  0x011f  0x00ed  0x0100  0x00f9  0x010c  0x0129     0x0179  0x0126  0x0134  0x0103  0x0114  0x010d  0x0119
 0x0101  0x0100  0x0103  0x010d  0x00f7  0x00ea  0x0101     0x012f  0x012e  0x011b  0x010e  0x00f1  0x010b  0x012f
 0x010a  0x0121  0x00fa  0x0119  0x0137  0x0104  0x00ff  …  0x011c  0x017a  0x00ef  0x00fb  0x0107  0x0169  0x0168
 0x0106  0x0110  0x00f1  0x00f3  0x010e  0x010a  0x0107     0x0167  0x0192  0x014d  0x00ee  0x0110  0x0114  0x011a
 0x00f4  0x0104  0x00fa  0x010e  0x011c  0x0107  0x00fe     0x0142  0x01db  0x019b  0x00f6  0x0110  0x00fd  0x0103
 0x0112  0x0107  0x0116  0x0101  0x00ef  0x0103  0x010e     0x013c  0x0120  0x0119  0x0118  0x011c  0x00f5  0x00ef
 0x0110  0x0124  0x010e  0x0101  0x0108  0x011c  0x00ef     0x0127  0x0142  0x00fc  0x00fd  0x0112  0x00ea  0x00e7
 0x0107  0x0109  0x0112  0x0110  0x0106  0x00f0  0x00d9  …  0x016f  0x015d  0x012b  0x00fc  0x0100  0x00e0  0x012d
      ⋮                                       ⋮          ⋱               ⋮                                       ⋮
 0x00c9  0x00d5  0x00d5  0x00d9  0x00cd  0x00cd  0x00cf     0x00c2  0x00c1  0x00bc  0x00c1  0x00bc  0x00bf  0x00bd
 0x00d7  0x00ce  0x00d0  0x00d9  0x00be  0x00d5  0x00c9  …  0x00bf  0x00cc  0x00bb  0x00be  0x00c1  0x00bd  0x00c7
 0x00cb  0x00cb  0x00db  0x00d4  0x00d1  0x00ca  0x00c5     0x00c0  0x00c7  0x00c0  0x00c7  0x00cb  0x00c4  0x00bc
 0x00d8  0x00ce  0x00d7  0x00e6  0x00c7  0x00cb  0x00d3     0x00c8  0x00be  0x00c7  0x00c3  0x00c6  0x00c1  0x00c1
 0x00dd  0x00db  0x00d0  0x00d0  0x00c7  0x00d8  0x00d1     0x00cf  0x00b6  0x00c0  0x00c7  0x00c1  0x00c0  0x00c3
 0x00d4  0x00d9  0x00db  0x00d7  0x00d1  0x00e7  0x00ce     0x00f0  0x00e7  0x00ca  0x00bc  0x00c2  0x00ba  0x00d0
 0x00cd  0x00d3  0x00cc  0x00cf  0x00c8  0x00ce  0x00ca  …  0x00bb  0x00c5  0x00c4  0x00c8  0x00c0  0x00c0  0x00d1
 0x00d8  0x00d6  0x00d5  0x00c6  0x00c4  0x00c8  0x00d6     0x00c7  0x00bb  0x00bb  0x00bc  0x00c1  0x00c7  0x00c0
 0x00da  0x00ce  0x00de  0x00d4  0x00ca  0x00d0  0x00d7     0x00c1  0x00c0  0x00ba  0x00c4  0x00ba  0x00c4  0x00cc
 0x00cd  0x00d3  0x00d7  0x00d0  0x00df  0x00dd  0x009e     0x00c7  0x00c0  0x00b6  0x00c8  0x00c1  0x00c9  0x00c8
 0x00d2  0x00c7  0x00ce  0x00c9  0x00cb  0x00d5  0x00c8     0x00c7  0x00ba  0x00c2  0x00c0  0x00bd  0x00d2  0x00b8
 0x00df  0x00ce  0x00dd  0x00d5  0x00dd  0x00d4  0x00d4  …  0x00c1  0x00bc  0x00c7  0x00ce  0x00c2  0x00c3  0x00c0
 0x00d4  0x00cf  0x00dc  0x00dc  0x00c2  0x00d3  0x00cb     0x00cc  0x00c3  0x00bc  0x00c1  0x00c3  0x00c4  0x00c6
 0x00cd  0x00d0  0x00d3  0x00d6  0x00e5  0x00da  0x00c8     0x00cd  0x00c6  0x00c4  0x00c5  0x00c4  0x00c2  0x00bf
 0x00d5  0x00c8  0x00db  0x00d5  0x00d0  0x00d3  0x00cf     0x00c1  0x00c0  0x00bc  0x00d3  0x00c0  0x00c6  0x00be

julia> read(attributes(h5f["CM5"])["bit_depth"])
"12"

julia> read(attributes(h5f["CM5"])["dimensions_XYZ"])
"2304_816_17"

julia> xml = read(HDF5.attributes(h5f["CM5"])["xml_metadata"]);

julia> using LightXML

julia> xmldoc = LightXML.parse_string(xml)
<?xml version="1.0" encoding="utf-8"?>
<push_config version="1.0">
<info software_version="1.0.02590"/>
<info data_header="AgaroseBeads_561nm15pct_17Planes5umStep"/>
<info cam="5"/>
<info specimen_name="sample"/>
<info tile_XYZ_um="0.000_0.000_0.000"/>
<info sampling_XYZ_um="0.34375_0.34375_5.000"/>
<info roi_XY="1152_3456_888_1704"/>
<info channel="1"/>
<info wavelength_nm="561"/>
<info laser_power="15.00%_0.00mW"/>
<info frame_exposure_time_ms="1.42"/>
<info detection_filter="test"/>
<info dimensions_XYZ="2304_816_17"/>
<info stack_direction="+Z"/>
<info planes="1_17"/>
<info timepoints="446"/>
<info bit_depth="12"/>
<info defect_correction="off"/>
<info experiment_notes=""/>
</push_config>

julia> md = MatrixMicroscopeUtils.parse_info_xml(xmldoc)
MatrixMetadata with the following field values.
                   version: 1.0
          software_version: 1.0.02590
               data_header: AgaroseBeads_561nm15pct_17Planes5umStep
             specimen_name: sample
               tile_XYZ_um: (X = 0.0, Y = 0.0, Z = 0.0)
           sampling_XYZ_um: (X = 0.34375, Y = 0.34375, Z = 5.0)
                    roi_XY: (left = 1152, top = 3456, width = 888, height = 1704)
                   channel: 1
             wavelength_nm: 561.0
               laser_power: (percent = 15.0, mW = 0.0)
    frame_exposure_time_ms: 1.42
          detection_filter: test
            dimensions_XYZ: (X = 2304, Y = 816, Z = 17)
           stack_direction: +Z
                    planes: 1:17
                timepoints: 446
                 bit_depth: 12
         defect_correction: off
          experiment_notes:
                       cam: 5
             metadata_file:

julia> md.sampling_XYZ_um
(X = 0.34375, Y = 0.34375, Z = 5.0)

julia> md.sampling_XYZ_um.X
0.34375

julia> md.sampling_XYZ_um.Y
0.34375

julia> md.sampling_XYZ_um.Z
5.0
```

# Reading HDF5 files in Python

```python
In [1]: import h5py

In [2]: h5f = h5py.File("TM0000000_CM5_uint16.h5", "r")

In [3]: cam5 = h5f["CM5"]

In [4]: list(cam5.attrs.keys())
Out[4]:
['bit_depth',
 'cam',
 'channel',
 'data_header',
 'defect_correction',
 'detection_filter',
 'dimensions_XYZ',
 'experiment_notes',
 'frame_exposure_time_ms',
 'laser_power',
 'planes',
 'roi_XY',
 'sampling_XYZ_um',
 'software_version',
 'specimen_name',
 'stack_direction',
 'tile_XYZ_um',
 'timepoints',
 'version',
 'wavelength_nm',
 'xml_metadata']

In [5]: cam5.attrs["data_header"]
Out[5]: b'AgaroseBeads_561nm15pct_17Planes5umStep'

In [6]: cam5.attrs["wavelength_nm"]
Out[6]: b'561'

In [7]: list(cam5.keys())
Out[7]:
['TM0000000',
 'TM0000001',
 'TM0000002',
 'TM0000003',
 'TM0000004',
 'TM0000005',
 'TM0000006',
 'TM0000007',
 'TM0000008',
 'TM0000009',
 'TM0000010',
 'TM0000011',
 'TM0000012',
 'TM0000013',
 'TM0000014',
 'TM0000015',
 'TM0000016',
 'TM0000017',
 'TM0000018',
 'TM0000019',
 'TM0000020',
 'TM0000021',
 'TM0000022',
 'TM0000023',
 'TM0000024',
 'TM0000025',
 'TM0000026',
 'TM0000027',
 'TM0000028',
 'TM0000029',
 'TM0000030',
 'TM0000031',
 'TM0000032',
 'TM0000033',
 'TM0000034',
 'TM0000035',
 'TM0000036',
 'TM0000037',
 'TM0000038',
 'TM0000039',
 'TM0000040',
 'TM0000041',
 'TM0000042',
 'TM0000043']

In [8]: cam5["TM0000000"]
Out[8]: <HDF5 dataset "TM0000000": shape (17, 816, 2304), type "<u2">

In [9]: cam5["TM0000000"][1,:,:]
Out[9]:
array([[222, 204, 250, ..., 216, 272, 203],
       [220, 210, 200, ..., 208, 219, 209],
       [208, 222, 214, ..., 205, 229, 226],
       ...,
       [284, 266, 231, ..., 192, 193, 199],
       [349, 292, 260, ..., 192, 188, 188],
       [333, 279, 278, ..., 187, 192, 196]], dtype=uint16)

In [10]: type(cam5["TM0000000"][1,:,:])
Out[10]: numpy.ndarray
```

# Reading HDF5 files in MATLAB

```matlab
>> h5disp("TM0000000_CM5_uint16.h5")
HDF5 TM0000000_CM5_uint16.h5 
Group '/' 
    Group '/CM5' 
        Attributes:
            'xml_metadata':  '<?xml version="1.0" encoding="utf-8"?>
<push_config version="1.0">
<info software_version="1.0.02590" />
<info data_header="AgaroseBeads_561nm15pct_17Planes5umStep" />
<info cam="5" />
<info specimen_name="sample" />
<info tile_XYZ_um="0.000_0.000_0.000" />
<info sampling_XYZ_um="0.34375_0.34375_5.000" />
<info roi_XY="1152_3456_888_1704" />
<info channel="1" />
<info wavelength_nm="561" />
<info laser_power="15.00%_0.00mW" />
<info frame_exposure_time_ms="1.42" />
<info detection_filter="test" />
<info dimensions_XYZ="2304_816_17" />
<info stack_direction="+Z" />
<info planes="1_17" />
<info timepoints="446" />
<info bit_depth="12" />
<info defect_correction="off" />
<info experiment_notes="" />
</push_config>
'
            'data_header':  'AgaroseBeads_561nm15pct_17Planes5umStep'
            'software_version':  '1.0.02590'
            'cam':  '5'
            'tile_XYZ_um':  '0.000_0.000_0.000'
            'frame_exposure_time_ms':  '1.42'
            'planes':  '1_17'
            'version':  '1.0'
            'experiment_notes':  ''
            'laser_power':  '15.00%_0.00mW'
            'roi_XY':  '1152_3456_888_1704'
            'timepoints':  '446'
            'specimen_name':  'sample'
            'sampling_XYZ_um':  '0.34375_0.34375_5.000'
            'stack_direction':  '+Z'
            'channel':  '1'
            'bit_depth':  '12'
            'defect_correction':  'off'
            'dimensions_XYZ':  '2304_816_17'
            'wavelength_nm':  '561'
            'detection_filter':  'test'
        Dataset 'TM0000000' 
            Size:  2304x816x17
            MaxSize:  2304x816x17
            Datatype:   H5T_STD_U16LE (uint16)
            ChunkSize:  288x102x17
            Filters:  none
            FillValue:  0
            Attributes:
                'element_size_um':  5.000000 0.343750 0.343750 
        Dataset 'TM0000001' 
            Size:  2304x816x17
            MaxSize:  2304x816x17
            Datatype:   H5T_STD_U16LE (uint16)
            ChunkSize:  288x102x17
            Filters:  none
            FillValue:  0
            Attributes:
                'element_size_um':  5.000000 0.343750 0.343750 
>> h5readatt("TM0000000_CM5_uint16.h5", "/CM5", "sampling_XYZ_um")

ans =

    '0.34375_0.34375_5.000'

>> h5read("TM0000000_CM5_uint16.h5", "/CM5/TM0000000", [1,1,1], [10,10,10])

  10×10×10 uint16 array

ans(:,:,1) =

   299   257   286   319   252   318   281   321   319   301
   316   279   288   283   278   338   323   379   313   305
   293   296   314   322   304   318   283   293   288   297
   288   287   296   356   302   314   295   260   268   307
   285   315   326   332   278   286   305   296   257   301
   300   306   335   293   271   270   324   310   303   296
   316   302   305   303   312   320   302   279   330   312
   278   272   341   313   285   333   311   323   300   348
   304   291   309   314   313   306   320   325   303   336
   287   288   303   330   296   372   326   340   332   303


ans(:,:,2) =

   222   220   208   208   199   201   195   220   226   212
   204   210   222   205   200   211   213   280   196   222
   250   200   214   213   226   214   206   225   198   188
   221   215   228   210   211   224   201   233   190   213
   226   224   222   244   212   217   208   247   207   215
   213   198   212   202   208   222   218   211   200   212
   205   223   212   222   203   208   206   251   202   205
   205   207   228   219   210   225   200   209   196   202
   225   223   217   215   200   225   202   226   192   201
   224   199   216   219   211   201   225   218   202   208


ans(:,:,3) =

   219   205   211   208   205   219   207   226   206   209
   211   203   215   209   195   227   213   215   199   228
   239   207   224   220   196   226   199   222   223   215
   218   203   212   228   214   214   211   260   211   200
   223   224   219   218   203   232   224   227   200   212
   223   226   209   202   196   228   211   214   194   212
   215   220   215   222   207   215   212   211   202   196
   205   204   219   219   216   212   206   205   211   209
   224   213   216   215   215   228   215   220   197   208
   235   205   216   199   205   216   219   203   196   207


ans(:,:,4) =

   209   205   214   214   212   216   210   204   216   203
   196   210   205   219   203   215   213   221   202   209
   234   229   214   229   214   232   209   228   201   211
   214   209   215   207   217   214   211   244   198   203
   214   214   210   235   222   210   205   222   203   209
   210   201   209   199   211   216   227   218   200   203
   208   213   209   207   210   238   203   221   206   205
   209   217   222   205   206   222   206   215   201   212
   214   216   214   212   215   244   215   229   204   208
   210   194   218   196   202   216   233   216   201   213


ans(:,:,5) =

   230   211   214   202   212   238   216   214   200   212
   217   200   212   225   203   221   210   233   199   205
   207   207   221   202   207   214   209   225   198   201
   224   200   212   219   211   226   215   212   204   198
   214   220   222   206   206   210   211   212   198   202
   226   228   215   205   196   213   218   205   206   209
   219   220   215   219   203   218   218   208   191   199
   215   198   234   219   194   225   203   212   196   194
   218   213   224   221   208   245   213   220   197   203
   211   202   212   209   222   211   215   215   205   208


ans(:,:,6) =

   219   208   208   218   205   210   203   226   206   215
   211   206   212   209   210   205   203   224   208   199
   242   232   224   226   198   237   209   207   211   208
   205   212   234   210   201   218   218   244   196   210
   220   210   216   187   197   210   202   247   207   202
   216   228   219   202   196   216   196   214   206   215
   234   216   212   213   214   221   206   246   196   222
   212   207   212   212   210   228   213   222   201   196
   204   234   217   204   205   225   206   214   206   203
   214   212   216   219   215   213   222   216   202   203


ans(:,:,7) =

   209   208   214   208   209   210   207   223   206   221
   196   206   222   222   210   218   206   227   199   209
   217   204   221   229   211   214   216   225   204   215
   224   212   225   219   211   229   211   212   201   207
   207   217   216   227   181   226   214   184   195   215
   216   223   215   218   211   203   230   199   200   197
   215   210   222   203   221   227   218   221   213   212
   205   200   219   205   203   225   213   215   208   205
   215   251   217   212   207   218   212   221   207   201
   217   208   219   219   218   216   223   209   201   210


ans(:,:,8) =

   219   211   205   226   202   219   210   226   203   215
   211   200   215   228   195   218   206   224   208   199
   220   251   221   209   204   226   213   222   201   211
   218   224   222   210   214   232   215   194   201   210
   217   214   213   230   171   224   214   215   236   202
   210   244   215   205   196   190   193   214   200   209
   222   194   218   213   221   218   206   224   194   222
   212   210   231   215   203   225   213   215   205   219
   220   206   217   205   214   233   213   220   203   214
   217   205   225   218   206   199   226   207   219   207


ans(:,:,9) =

   222   211   218   208   209   216   207   211   206   229
   196   210   215   233   192   215   213   151   214   209
   239   226   230   202   217   200   220   228   217   211
   221   209   219   216   193   208   215   235   198   216
   214   198   225   194   209   224   221   218   207   225
   228   204   212   202   205   210   185   224   200   203
   215   216   212   222   192   230   224   221   196   205
   205   210   205   219   200   215   213   222   201   212
   224   220   216   202   204   219   209   220   221   207
   220   214   221   215   209   213   251   223   202   204


ans(:,:,10) =

   212   220   208   211   212   216   200   204   200   224
   217   206   205   212   207   224   213   215   199   194
   211   242   210   220   198   207   220   225   207   205
   218   212   225   222   201   232   205   212   207   210
   223   214   213   230   222   210   191   206   210   205
   220   193   209   199   208   230   196   214   206   215
   219   223   212   203   224   211   209   211   196   212
   205   195   231   209   200   215   206   219   198   215
   221   216   210   220   227   228   219   221   210   214
   201   206   219   214   219   210   215   224   201   210
```

# Reading HDF5 files in FIJI

To read HDF5 files in FIJI use HDF5_Vibez package:
https://github.com/fiji/HDF5_Vibez/

There are two ways to navigate the GUI to import HDF5 files:
* File -> Import -> HDF5
* Plugins -> HDF5 -> Load HDF5 File

FIJI HDF5 Vibez Plugin opening a H5 file generated by `resave_uint12_stack_as_uint16_hdf5`:
![FIJI HDF5 Vibez Plugin opening `resave_uint12_stack_as_uint16_hdf5`](images/fiji_hdf5_vibez_uint16.png)

You can select multiple timepoints to combine them as a time series.
