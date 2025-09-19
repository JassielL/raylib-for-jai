If you're looking for a more activly maintained version I'd recommend
[github.com/ahmedqarmout2/raylib-jai](github.com/ahmedqarmout2/raylib-jai)
This is just a scrappy version I whipped up prior to this existing and as a way for me to learn about the bindings generator. It's still pretty rough and I can't activly maintain the repo since this isn't my main project atm.

**The bundled bindings were generated for Raylib version 5.6-dev**

## Usage Instructions

### Basic Usage
To use these bindings on Windows you only need to clone the repo and import the module. By default it links dynamically due to conflicts with linking with user32.lib. If you want to link statically it should work so long as you don't import the `Windows` module. If you do need to import both then you can bypass this by adding this to your build.jai
```jai
Build_Game_Statically :: () 
{
	w := compiler_create_workspace();
	options := get_build_options(w);
	copy_commonly_propagated_fields(get_build_options(), *options);

	// This has to be added to the linker args if you #import "Windows";
	linker_args: [..]string;
	array_copy(*linker_args, options.additional_linker_arguments);
	array_add(*linker_args, "/libpath:<path_to_lib>/windows");
	array_add(*linker_args, "<path_to_lib>/raylib.lib");

	options.additional_linker_arguments = linker_args;
	//===
	set_build_options(options, w);

	add_build_file("main.jai", w);
}
```


### Compiling Libraries

Not as automated as I'd like it to be but here's how to do it.

##### Prerequisites
* Ensure you have the original raylib source code in directory `raylib`. If you don't have it then open a terminal and run commands.
```bash
cd raylib-for-jai
git clone "https://github.com/raysan5/raylib.git"
```
This will create the raylib directory and provide you will all the files needed to compile it into a lib.
* **C/C++ development environment** installed on your system.  
This is because Raylib’s source code depends on the standard C library headers (e.g. `math.h`, `stdio.h`, etc.).

If you don’t have a proper toolchain installed, you may see errors like:
```bash
./raylib/src/raymath.h:171:10: fatal error: 'math.h' file not found
```

To install you can see:
- **Linux**: install `build-essential` (Debian/Ubuntu) or the equivalent packages for your distro.  
- **macOS**: install Xcode Command Line Tools (`xcode-select --install`).  
- **Windows**: install [MSVC Build Tools](https://visualstudio.microsoft.com/visual-cpp-build-tools/) or [MinGW-w64](http://mingw-w64.org/).

#### Instructions
1) In your terminal run commands (omit the `-debug` flag if you want to compile a release version)
```bash
cd raylib-for-jai
jai generate.jai - -compile -debug
```

2) From the outputted `raylib.jai` file go to the very bottom and remove any constant declarations to the raylib library. The lines you want to delete will look like this
```jai
raylib :: #library,no_dll "<dir to lib>/raylib";
raylib_dll :: #library "<dir to lib>/raylib_dll";
```

You want to remove these because `module.jai` assigns the library identifier `raylib` to either the static or dynamic library based on the module_parameter LINK_KIND. For example on Windows in module.jai it looks like this.
```jai
raylib_static :: #library,no_dll "<dir to lib>/raylib";
raylib_dll    :: #library        "<dir to lib>/raylib_dll";

#if LINK_KIND == {
    case .STATIC;  raylib :: raylib_static;
    case .DYNAMIC; raylib :: raylib_dll;
}
```
If the path to lib in `module.jai` doesn't match the one outputted by the generator in `raylib.jai` then you'll want to change the path defined in `module.jai` to match the path outputted by the generator. This shouldn't happen.

#### Notes
In the future I would like to make this more automated but idk how I would go about automatically removing the library definitions in raylib.jai and redefining them as raylib_static and raylib_dll in a seperate os specific file such as windows.jai

### Flags
* `-compile`: Will compile the static and dynamic library for raylib
* `-debug`: Include debug info for the compiled libraries, only works if you pass `-compile` as well.
* `-no_bindings`: Won't generate bindings


## TODO
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
- [ ] Output rlgl.h to a seperate rlgl.jai file
- [X] Update README.md to include more detailed instructions on this modules usage
- [X] Get static library to work.
- [X] Modify certain structs for convenience params. ex. Rectangle.position, Rectangle.size 
- [X] Compile the static version to allow static linking
- [X] Allow the user to specify if they want to dynamically or statically link to raylib via `#module_parameter()(IS_STATICALLY_LINKED: bool);`
- [X] Remove PI
- [X] Strip Vector(x) structs
- [X] Strip enum prefixes
- [X] Associate enum values with the correct procs. Ex. 
        IsKeyPressed :: (key: s32) -> bool #foreign raylib;         <- bad 
        IsKeyPressed :: (key: KeyboardKey) -> bool #foreign raylib; <- desired 
- [X] Remap Raylib's Matrix to Math.jai's Matrix4
- [X] Add Raylib's color definitions to the module


## Vendored Raylib

The plan is to vendor Raylib source code in the `raylib/` directory to provide a frozen, tested version for these Jai bindings.
For now you'll have to place your own copy of the raylib source code by using command
```bash
cd raylib/
git clone "https://github.com/raysan5/raylib.git"
```

once you have the raylib source can run.
```bash
jai generate.jai - -compile -debug
```
