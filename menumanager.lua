
_G.RNGAGED = RNGAGED or {
	mod_path = ModPath,
	loc_path = ModPath .. "loc/",
	save_path = SavePath .. "RNGAGED.txt",
	--default_loc_path = ModPath .. "loc/en.txt",
	balance_loc_file = ModPath .. "loc/en_rnbalance.txt",
	options_path = ModPath .. "menu/options.txt",
	start_up = true,
	version = "V1",
	settings = {
		disable_balance_changes = false,
		disable_no_retention_reloads = false,
		disable_stepped_reloads = false,
		disable_melee_cleave = false,
		disable_enemy_projectiles = false,
		disable_head_height_changes = false,
		headbob_intensity = 1,
	}
}

function RNGAGED:Load()
	RNGAGED.start_up = nil --https://64.media.tumblr.com/d004a008be106f729536532b1180de78/fd61b73ea27c75a9-5c/s500x750/40bdd856f48179a77e5d2002989fee06d708930c.gif
	local file = io.open(RNGAGED.save_path, "r")

	if file then
		for k, v in pairs(json.decode(file:read("*all"))) do
			RNGAGED.settings[k] = v
		end
	else
		RNGAGED:Save()
	end
end

function RNGAGED:Save()
	local file = io.open(RNGAGED.save_path,"w+")

	if file then
		file:write(json.encode(RNGAGED.settings))
		file:close()
	end
end

if RNGAGED.start_up then
	RNGAGED:Load()
end
	
if RequiredScript == "lib/managers/menumanager" then
	Hooks:Add("LocalizationManagerPostInit", "LocalizationManagerPostInit_RNGAGED", function( loc )
		--loc:load_localization_file( RNGAGED.default_loc_path)
		
		if not RNGAGED.settings.disable_balance_changes then
			loc:load_localization_file( RNGAGED.balance_loc_file)
		end
	end)
	
	--add the menu callbacks for when menu options are changed
	Hooks:Add( "MenuManagerInitialize", "MenuManagerInitialize_RNGAGED", function(menu_manager)			
		MenuCallbackHandler.callback_rngaged_disable_balance_changes = function(self, item)
			local on = item:value() == "on"
			RNGAGED.settings.disable_balance_changes = on

			RNGAGED:Save()
		end
		
		MenuCallbackHandler.callback_rngaged_disable_no_retention_reloads = function(self, item)
			local on = item:value() == "on"
			RNGAGED.settings.disable_no_retention_reloads = on

			RNGAGED:Save()
		end
		
		MenuCallbackHandler.callback_rngaged_disable_stepped_reloads = function(self, item)
			local on = item:value() == "on"
			RNGAGED.settings.disable_stepped_reloads = on

			RNGAGED:Save()
		end
		
		MenuCallbackHandler.callback_rngaged_disable_melee_cleave = function(self, item)
			local on = item:value() == "on"
			RNGAGED.settings.disable_melee_cleave = on

			RNGAGED:Save()
		end
		
		MenuCallbackHandler.callback_rngaged_disable_enemy_projectiles = function(self, item)
			local on = item:value() == "on"
			RNGAGED.settings.disable_enemy_projectiles = on

			RNGAGED:Save()
		end
		
		MenuCallbackHandler.callback_rngaged_disable_head_height_changes = function(self, item)
			local on = item:value() == "on"
			RNGAGED.settings.disable_head_height_changes = on

			RNGAGED:Save()
		end
		
		MenuCallbackHandler.callback_rngaged_headbob_intensity = function(self, item)
			local value = item:value()
			RNGAGED.settings.headbob_intensity = value

			RNGAGED:Save()
		end
		
		--called when the menu is closed
		MenuCallbackHandler.callback_rngaged_close = function(self)
		end

		--load settings from user's mod settings txt
		RNGAGED:Load()

		--create menus
		MenuHelper:LoadFromJsonFile(RNGAGED.options_path, RNGAGED, RNGAGED.settings)
	end)
end
