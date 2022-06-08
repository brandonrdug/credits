credits = credits or {
	config 	= Config(),
	net		= {},
	db 		= {}
}

include_sv( "credits/config/credits_sql.lua" )
include_sh( "credits/config/credits_config.lua" )

include_sv( "credits/main/sv_credits_sql.lua" )
include_sv( "credits/main/sv_credits.lua" )
include_sh( "credits/main/sh_credits.lua" )
include_cl( "credits/vgui/vgui_credits.lua" )
include_cl( "credits/main/cl_credits.lua" )

include_sv( "credits/net/sv_credits_net.lua" )
include_cl( "credits/net/cl_credits_net.lua" )

include_sv( "credits/methods/sv_credits_methods.lua" )
include_cl( "credits/methods/cl_credits_methods.lua" )

include_sv( "credits/meta/sv_credits_meta.lua" )
include_sh( "credits/meta/sh_credits_meta.lua" )
include_cl( "credits/meta/cl_credits_meta.lua" )