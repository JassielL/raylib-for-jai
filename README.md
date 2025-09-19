## Instructions
cd into the directory and run
```bash
jai .\generate.jai - -compile -debug
```

make sure you have a copy of [Raylib's source code](https://github.com/raysan5/raylib) in the `raylib/` directory.


## TODO
- [ ] Allow the user to specify if they want to dynamically or statically link to raylib via `#module_parameter()(IS_STATICALLY_LINKED: bool);`
- [ ] Compile the static version to allow static linking
- [ ] struct rAudioBuffer and struct rAudioProcessor are both empty. Assuming this
      didn't generate properly
    * Turns out it is generating correctly after looking at the other jai-raylib
      module. So instead add this comment to the structs or add it in the header as 
      a note
        rAudioBuffer    :: struct { /* only used as a pointer in this header */ }
        rAudioProcessor :: struct { /* only used as a pointer in this header */ }
- [ ] Define ConfigFlags as enum_flags
- [ ] There may be some duplicate enum types due to rlgl such as enum BlendMode and rlBlendMode
- [ ] Convert rlgl to use enum types
- [ ] For building define a config file that allows the user to specify what
      config options they want to for compiling Raylib when flag -compile is passed
- [ ] Get static library to work.
- [ ] Output rlgl.h to a seperate rlgl.jai file
- [ ] Update README.md to include more detailed instructions on this modules usage
- [o] Modify certain structs for convenience params. ex. Rectangle.position, Rectangle.size 
- [X] Remove PI
- [X] Strip VectorX structs
- [X] Strip enum prefixes
- [X] Associate enum values with the correct procs. Ex. 
        IsKeyPressed :: (key: s32) -> bool #foreign raylib;         <- bad 
        IsKeyPressed :: (key: KeyboardKey) -> bool #foreign raylib; <- desired 
- [X] Remap Raylib's Matrix to Math.jai's Matrix4
- [X] Add Raylib's color definitions to the module


## Prerequisites

You need to have Raylib's source code in `raylib/` directory for the generator to work
you can get a copy from [https://github.com/raysan5/raylib]


## Vendored Raylib

The plan is to vendor Raylib source code in the `raylib/` directory to provide a frozen, tested version for these Jai bindings.
For now you'll have to place your own copy of the raylib source code by using command
```bash
cd raylib/
git clone "https://github.com/raysan5/raylib.git"
```

once you have the raylib source can run.
```bash
jai .\generate.jai - -compile -debug
```
