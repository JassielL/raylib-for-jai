/* @TODO:
	- [o] Modify certain structs for convenience params. eg. Rectangle.position, Rectangle.size 
	- [X] Remove PI
	- [ ] Compile the static version to allow static linking
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
	- [X] Strip VectorX structs
	- [X] Strip enum prefixes
	- [X] Associate enum values with the correct procs. Ex. 
			IsKeyPressed :: (key: s32) -> bool #foreign raylib;         <- bad 
			IsKeyPressed :: (key: KeyboardKey) -> bool #foreign raylib; <- desired 
	- [X] Remap Raylib's Matrix to Math.jai's Matrix4
	- [X] Add Raylib's color definitions to the module
	- [ ] Get static library to work.
	- [ ] Output rlgl.h to a seperate rlgl.jai file

	// Possibly outdated, will keep around so I can investigate
	- [ ] This module doesn't properly compile the raylib library. As a result the function ShowCursor doesn't work.
	      See `https://github.com/raysan5/raylib/issues/3586` for more info.
*/
RAYLIB_PATH :: "raylib/src";

LOG_STRIPPED_DECLARATIONS_SETTING :: false;

COMPILE_FLAGS :: Compile_Flags.DYNAMIC_LIBRARY;

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
	compile        := array_find(args, "-compile");
	compile_debug  := array_find(args, "-debug");

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
					"windows/raylib",
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

	output_filename: string;
	opts: Generate_Bindings_Options;
	{
		using opts;

		#if OS == .WINDOWS {
			array_add(*libpaths, "windows");
			output_filename = "windows.jai";
		}

		array_add(*libnames,      "raylib");
		array_add(*include_paths, RAYLIB_PATH);
		array_add(*source_files,  tprint("%/raylib.h", RAYLIB_PATH));
		array_add(*source_files,  tprint("%/rcamera.h", RAYLIB_PATH));
		array_add(*source_files,  tprint("%/rlgl.h", RAYLIB_PATH));
		array_add(*source_files,  tprint("%/raymath.h", RAYLIB_PATH));

		//array_add(*extra_clang_arguments, "-x", "c++", "-DWIN32_LEAN_AND_MEAN");
		//array_add(*flatten_namespaces, "ImGui");
		//array_add(*strip_prefixes, "ImGui");
		auto_detect_enum_prefixes = true;
		log_stripped_declarations = LOG_STRIPPED_DECLARATIONS_SETTING;
		generate_compile_time_struct_checks = false;
		strip_flags |= .INLINED_FUNCTIONS; // "inline" functions are not present in the static library.

		visitor   = raylib_visitor;
		//get_func_args_for_printing = imgui_get_function_arg_for_printing;
		//footer = "";
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
					// @TODO: Better error
					print("ERROR :: Failed to change type to enum\n");

					print(
						"ERROR :: Failed to change decl % type to enum %\n",
						decl.name,
						remap.enum_name
					);

					//log_error()
				}
			}
		}
	}

	return .RECURSE;
}


/*
imgui_visitor :: (decl: *Declaration, parent_decl: *Declaration) -> Declaration_Visit_Result 
{
    // ImGui has "typedef ints" for each enum. but we want to just use the enums directly,
    // so we get nice type safety, and .unary dots, etc.
    //
    // Look for declarations inside functions (i.e., arguments) or structs (i.e., fields)
    get_associated_enum_name :: (name: string) -> string {
        if name.count > 1 && name[name.count - 1] != #char "_" {
            return tprint("%_", name);
        }
        return name;
    }

    if !parent_decl {
        if array_find(DECLARATIONS_TO_OMIT, decl.name) {
            decl.decl_flags |= .OMIT_FROM_OUTPUT;
            return .STOP;
        }
        if decl.name == "ImGuiContext" {
            decl.output_name = decl.name; // Don’t shorten ImGuiContext to Context as this would conflict
        }

        if decl.kind == .TYPEDEF {
            old_name := decl.name;
            if old_name {
                new_name := get_associated_enum_name(old_name);
                for context.generator.global_scope.members {
                    if it.kind != .ENUM  || it.name != new_name     continue;

                    en := cast(*Enum)it;

                    // Don't output the integer typedef
                    decl.decl_flags |= .OMIT_FROM_OUTPUT;

                    // Make sure the enums like "FocusFlags_" get outputted as "FocusFlags"
                    if en.output_name.count > 2 && en.output_name[en.output_name.count - 1] == #char "_" {
                        en.output_name.count -= 1;
                    }

                    // Keep the comment, if there is one:
                    if decl.comment.text && !en.comment.text {
                        en.comment = decl.comment;
                    }

                    table_add(*enums_for_typedefs, old_name, en);
                    break;
                }
            }
        }
    }

    // Look for function arguments with "typedef" types.
    if parent_decl &&
        (parent_decl.kind == .FUNCTION || parent_decl.kind == .STRUCT) &&
        decl.kind == .DECLARATION && decl.type.type_of_typedef != null
    {
        old_name := decl.type.type_of_typedef.name;
        if old_name {
            en, found := table_find(*enums_for_typedefs, old_name);
            if found {
                change_type_to_enum(decl, en);
            }
        }
    }

    if decl.kind == .ENUM {
        // ImGui has lots of enums that should be enum flags. Luckily, they all end in "…Flags_".
        if ends_with(decl.name, "Flags_") {
            en := cast(*Enum)decl;
            en.flags |= .IS_ENUM_FLAGS;
            en.flags |= .VALUES_IN_HEX;
        }
    }

    if decl.kind == .FUNCTION {
        func := cast(*Function)decl;
        type := func.type.type_of_function;
        // ImGui also has functions with pairs of arguments like "text_begin" and "text_end"
        // for the pointers to the beginning and end of a string. We'll generate wrappers for
        // those function which take a jai string.
        //
        // Here we collect pointers to "_begin" arguments, and use them in
        // get_func_args_for_printing below.
        for type.arguments {
            if it_index == 0 || !ends_with(it.name, "_end")     continue;
            arg_type := find_underlying_type(it.type);
            if !arg_type.pointer_to || !(arg_type.pointer_to.number_flags & ._8BIT) continue; // Only convert *u8 ranges to string

            name_part := slice(it.name, 0, it.name.count - "_end".count);
            if !name_part   continue;

            // the first arg may appear as "text_begin" or just "text"
            name_part_with_begin := tprint("%_begin", name_part);
            prev_arg := type.arguments[it_index - 1];
            if prev_arg.name == name_part || prev_arg.name == name_part_with_begin {
                array_add(*begin_end_string_args, prev_arg);
                func.decl_flags |= .NEEDS_ARGUMENT_WRAPPER;
            }
        }
    }

    return .RECURSE;
}
*/


#import "Basic";
#import "Bindings_Generator";
#import "BuildCpp";
#import "Compiler";
#import "File";
#import "Hash_Table";
#import "String";

#load "type_remaps.jai";
