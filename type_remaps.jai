Modify_Proc_Decl_Return_Info :: struct 
{
	proc_name: string;
	enum_return_type_name: string;
}

Modify_Proc_Decl_Info :: struct
{
	target_procs: [ ]string;
	remaps      : [ ]Enum_Arg_Remap;
}

Enum_Arg_Remap :: struct
{
	arg_name : string;
	enum_name: string;
}

/*
// @NOTE: Not in use because I can't figure out how to modify a struct declaration in
//        proc raylib_visitor to insert the strings defined in 
//        Struct_Modification.insert_lines
Struct_Modification :: struct 
{
	type_name: string;
	insert_lines: []string;
}


STRUCT_MODIFICATIONS :: Struct_Modification.[
	.{ type_name = "Rectangle", insert_lines = .[
		"#place x;     position: Vector2;",
		"#place width; size: Vector2;",
	]},
];
*/

PROC_RETURN_TYPE_REMAP :: Modify_Proc_Decl_Return_Info.[
	.{ proc_name = "GetKeyPressed",           enum_return_type_name = "KeyboardKey"}, 
	.{ proc_name = "GetGamepadButtonPressed", enum_return_type_name = "GamepadButton"}
];

// @NOTE,vim: I have macro @l to do the auto conversions of proc decl to string and @k for remaps given the format name, enum_name. Useful for automating the setting target_proc
PROC_ARGS_TYPE_REMAP :: Modify_Proc_Decl_Info.[
	// Window-related functions
	.{
		target_procs = string.[
			"IsWindowState",
			"SetWindowState",
			"ClearWindowState",
		],
		remaps = Enum_Arg_Remap.[
			.{ arg_name = "flag",  enum_name = "ConfigFlags" },
			.{ arg_name = "flags", enum_name = "ConfigFlags" },
		]
	},

	// Drawing-related functions
	.{
		target_procs = string.[
			"BeginBlendMode",
		],
		remaps = Enum_Arg_Remap.[
			.{ arg_name = "mode", enum_name = "BlendMode" },
		]
	},

	// Input-related functions: keyboard
	.{
		target_procs = string.[
			"IsKeyPressed",
			"IsKeyPressedRepeat",
			"IsKeyDown",
			"IsKeyReleased",
			"IsKeyUp",
			"GetKeyPressed",
			"GetCharPressed",
			"GetKeyName",
			"SetExitKey",
		],
		remaps = Enum_Arg_Remap.[
			.{ arg_name = "key", enum_name = "KeyboardKey" },
		]
	},

	// Input-related functions: gamepads
	.{
		target_procs = string.[
			"IsGamepadButtonPressed",
			"IsGamepadButtonDown",
			"IsGamepadButtonReleased",
			"IsGamepadButtonUp",
			"GetGamepadAxisMovement",
		],
		remaps = Enum_Arg_Remap.[
			.{ arg_name = "button", enum_name = "GamepadButton" },
			.{ arg_name = "axis",   enum_name = "GamepadAxis"   },
		]
	},

	// Input-related functions: mouse
	.{
		target_procs = string.[
			"IsMouseButtonPressed",
			"IsMouseButtonDown",
			"IsMouseButtonReleased",
			"IsMouseButtonUp",
		],
		remaps = Enum_Arg_Remap.[
			.{ arg_name = "button", enum_name = "MouseButton" },
		]
	},

	// Camera System Functions (Module: rcamera)
	.{
		target_procs = string.[
			"UpdateCamera",
		],
		remaps = Enum_Arg_Remap.[
			.{ arg_name = "mode", enum_name = "CameraMode" },
		]
	},

	/*
	.{
		target_procs = string.[
		],
		remaps = Enum_Arg_Remap.[
		]
	},
	*/
];
