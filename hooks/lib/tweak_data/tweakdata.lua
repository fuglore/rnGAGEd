if not tweak_data then
	return
end

tweak_data.style_meter_events = {
	kill = {
		amount = 0.2,
		stale_add = 1,
		stale_max = 2,
		stale_expire_t = 0.25,
		style_pause_t = 0.048
	},
	dodge = {
		amount = 0.1,
		stale_add = 1,
		stale_max = 8,
		stale_expire_t = 0.5
	},
	gate = {
		amount = 0.5,
		stale_add = 1,
		stale_max = 4,
		stale_expire_t = 4.6,
		style_pause_t = 0.2
	},
	exposure = {
		amount = 0.01,
		amount_min_mul = 0,
		stale_add = 1,
		stale_max = 4,
		stale_expire_t = 1
	},
	damage = {
		amount = -0.1,
		stale_add = 1,
		stale_max = 2,
		stale_expire_t = 0.7
	}
}

if RNGAGED.settings.disable_balance_changes then
	return
end

tweak_data.projectiles.wpn_prj_four.damage = 4 --throwing star
tweak_data.projectiles.wpn_prj_ace.damage = 12 --throwing cards

tweak_data.projectiles.wpn_prj_jav.damage = 110 --javelin
tweak_data.projectiles.wpn_prj_jav.armor_piercing = true

tweak_data.projectiles.wpn_prj_hur.damage = 48 --throwing axe
tweak_data.projectiles.wpn_prj_target.damage = 24 --throwing knives