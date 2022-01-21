# MatrixMicroscopeUtils

Utilities for the Matrix Microscope.

# Installation

This is currently a private repository. It may be easier to first `git clone` this repository with authentication, then use `import Pkg; Pkg.add(path="c:/path/to/MatrixMicroscopeUtils")`. You can use `/` even on Windows.

If you have Github authentication, you may be able to add this via the following command.
```
] add https://github.com/JaneliaSciComp/MatrixMicroscopeUtils.git#main
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

# Reading HDF5 files in Julia

# Reading HDF5 files in MATLAB

# Reading HDF5 files in FIJI

To read HDF5 files in FIJI use HDF5_Vibez package:
https://github.com/fiji/HDF5_Vibez/

FIJI HDF5 Vibez Plugin opening `resave_uint12_stack_as_uint16_hdf5`
![FIJI HDF5 Vibez Plugin opening `resave_uint12_stack_as_uint16_hdf5`](images/fiji_hdf5_vibez_uint16.png)

You can select multiple timepoints to combine them as a time series.