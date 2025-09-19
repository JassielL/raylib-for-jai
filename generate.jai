/* @TODO:
	- [ ] struct rAudioBuffer and struct rAudioProcessor are both empty. Assuming this
	      didn't generate properly
			> Turns out it is generating correctly after looking at the other jai-raylib
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
*/
RAYLIB_PATH :: "raylib/src";

LOG_STRIPPED_DECLARATIONS_SETTING :: false;

COMPILE_FLAGS :: Compile_Flags.STATIC_LIBRARY | Compile_Flags.DYNAMIC_LIBRARY;

Compile_Flags :: enum_flags 
{
	STATIC_LIBRARY;
	DYNAMIC_LIBRARY;
}

DECLARATIONS_TO_OMIT :: string.[
	// We're gonna use the math types defined in module Math instead
	"Vector2",
	"Vector3",
	"Vector4",
	"Quaternion",
	"Matrix",

	"PI", // This is defined in module Math

	// Omitted because we want to add extra fields so it's defined manually in module.jai.
	"Rectangle", 
];

#run,stallable {
	set_build_options_dc(.{do_output=false});
	root_options := get_build_options();
	args := root_options.compile_time_command_line;
	if !generate_bindings(args) {
		compiler_set_workspace_status(.FAILED);
	}
}

generate_bindings :: (args: [] string) -> bool 
{
	compile       := array_find(args, "-compile");
	compile_debug := array_find(args, "-debug");
	no_bindings   := array_find(args, "-no_bindings");

	if compile {
		raylib_sources: [..]string;

		array_add(*raylib_sources, tprint("%/raudio.c",    RAYLIB_PATH));
		array_add(*raylib_sources, tprint("%/rcore.c",     RAYLIB_PATH));
		array_add(*raylib_sources, tprint("%/rmodels.c",   RAYLIB_PATH));
		array_add(*raylib_sources, tprint("%/rshapes.c",   RAYLIB_PATH));
		array_add(*raylib_sources, tprint("%/rtext.c",     RAYLIB_PATH));
		array_add(*raylib_sources, tprint("%/rtextures.c", RAYLIB_PATH));
		array_add(*raylib_sources, tprint("%/utils.c",     RAYLIB_PATH));

		array_add(*raylib_sources, tprint("%/rglfw.c", RAYLIB_PATH));

		success := true;

		#if OS == .WINDOWS {
			// @DOC: Build flags were derived from raylib/src/Makefile
			make_directory_if_it_does_not_exist("windows");

			#if COMPILE_FLAGS & .DYNAMIC_LIBRARY {
				success &&= build_cpp_dynamic_lib(
					"windows/raylib_dll",
					..raylib_sources,
					extra = .[
						"/DBUILD_LIBTYPE_SHARED",
						"/D_CRT_SECURE_NO_WARNINGS",
						"/DPLATFORM_DESKTOP_GLFW",
						"/DGRAPHICS_API_OPENGL_33",
						tprint("/I%/external/glfw/include", RAYLIB_PATH),

						"/defaultlib:libcmt",
						"/NODEFAULTLIB:msvcrt",
					],
					library_files = .[
						//"static-libgcc",
						"user32.lib",
						"opengl32.lib",
						"gdi32.lib",
						"winmm.lib",
						"shell32.lib",
					], 
					debug=compile_debug
				); 
			}

			#if COMPILE_FLAGS & .STATIC_LIBRARY {
				success &&= build_cpp_static_lib(
					"windows/raylib",
					..raylib_sources,
					extra = .[
						"/D_CRT_SECURE_NO_WARNINGS",
						"/DPLATFORM_DESKTOP_GLFW",
						"/DGRAPHICS_API_OPENGL_33",
						tprint("/I%/external/glfw/include", RAYLIB_PATH),

						// @TODO: Pass these args to the linker. These are linker arguments not compile options!
						"/defaultlib:libcmt",
						"/NODEFAULTLIB:msvcrt",
						// ===
					],
					debug=compile_debug
				); 
			}
		}

		if !success then return false;
	}

	if no_bindings then return true;

	output_filename: string;
	opts: Generate_Bindings_Options;
	{
		using opts;

		output_filename = "raylib.jai";

		#if OS == .WINDOWS {
			array_add(*libpaths, "windows");
		}

		array_add(*libnames,      "raylib");
		array_add(*libnames,      "raylib_dll");
		array_add(*include_paths, RAYLIB_PATH);
		array_add(*source_files,  tprint("%/raylib.h", RAYLIB_PATH));
		array_add(*source_files,  tprint("%/rcamera.h", RAYLIB_PATH));
		array_add(*source_files,  tprint("%/rlgl.h", RAYLIB_PATH));
		array_add(*source_files,  tprint("%/raymath.h", RAYLIB_PATH));

		auto_detect_enum_prefixes = true;
		log_stripped_declarations = LOG_STRIPPED_DECLARATIONS_SETTING;
		generate_compile_time_struct_checks = false;
		strip_flags |= .INLINED_FUNCTIONS; // "inline" functions are not present in the static library.

		visitor = raylib_visitor;
	}

	return generate_bindings(opts, output_filename);
}

raylib_visitor :: (decl: *Declaration, parent_decl: *Declaration) 
-> Declaration_Visit_Result 
{
	if !parent_decl {
		if array_find(DECLARATIONS_TO_OMIT, decl.name) {
			//print("omitting decl %: %\n", decl.name, decl.*);
			decl.decl_flags |= .OMIT_FROM_OUTPUT;
			return .STOP;
		}

		for info: PROC_RETURN_TYPE_REMAP {
			if decl.name == info.proc_name {
				ok := change_return_type_to_enum(decl, info.enum_return_type_name); 
				if !ok {
					print(
						"ERROR :: Failed to change decl % return type to enum %\n",
						decl.name,
						info.enum_return_type_name
					);
				}
			}
		}
	}

	if parent_decl && parent_decl.kind == .FUNCTION && decl.kind == .DECLARATION {
		modifying_proc: Modify_Proc_Decl_Info;

		for proc: PROC_ARGS_TYPE_REMAP {
			for proc_name: proc.target_procs {
				if parent_decl.name == proc_name {
					//print("found parent_decl %\n", parent_decl.name);
					modifying_proc = proc;
					break proc;
				}
			}
		}

		for remap: modifying_proc.remaps {
			if decl.name == remap.arg_name {
				ok := change_type_to_enum(decl, remap.enum_name);
				if !ok {
					//log_error()
					print(
						"ERROR :: Failed to change decl % type to enum %\n",
						decl.name,
						remap.enum_name
					);
				}
			}
		}
	}

	return .RECURSE;
}


#import "Basic";
#import "Bindings_Generator";
#import "BuildCpp";
#import "Compiler";
#import "File";
#import "Hash_Table";
#import "String";

#load "type_remaps.jai";
