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
# Reading HDF5 files in Python

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

# Reading HDF5 files in MATLAB

# Reading HDF5 files in FIJI

To read HDF5 files in FIJI use HDF5_Vibez package:
https://github.com/fiji/HDF5_Vibez/

FIJI HDF5 Vibez Plugin opening `resave_uint12_stack_as_uint16_hdf5`
![FIJI HDF5 Vibez Plugin opening `resave_uint12_stack_as_uint16_hdf5`](images/fiji_hdf5_vibez_uint16.png)

You can select multiple timepoints to combine them as a time series.
