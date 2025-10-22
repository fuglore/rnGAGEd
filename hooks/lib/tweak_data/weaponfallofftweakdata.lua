if RNGAGED.settings.disable_balance_changes then
	return
end

local old_falloffs = WeaponFalloffTemplate.setup_weapon_falloff_templates

function WeaponFalloffTemplate.setup_weapon_falloff_templates()
	local weapon_falloff_templates = old_falloffs()
	
	weapon_falloff_templates.ASSAULT_FALL_LOW.optimal_distance = 500
	weapon_falloff_templates.ASSAULT_FALL_LOW.optimal_range = 900
	weapon_falloff_templates.ASSAULT_FALL_LOW.near_falloff = 0
	weapon_falloff_templates.ASSAULT_FALL_LOW.far_falloff = 1000
	weapon_falloff_templates.ASSAULT_FALL_LOW.near_multiplier = 1
	weapon_falloff_templates.ASSAULT_FALL_LOW.far_multiplier = 0.7
	weapon_falloff_templates.ASSAULT_FALL_MEDIUM = {
		optimal_distance = 1000,
		optimal_range = 1000,
		near_falloff = 0,
		far_falloff = 1000,
		near_multiplier = 1,
		far_multiplier = 0.8
	}
	weapon_falloff_templates.ASSAULT_FALL_HIGH = {
		optimal_distance = 1000,
		optimal_range = 2000,
		near_falloff = 0,
		far_falloff = 1000,
		near_multiplier = 1,
		far_multiplier = 0.9
	}
	
	weapon_falloff_templates.SHOTGUN_FALL_PRIMARY_LOW = {
		optimal_distance = 1000,
		optimal_range = 1000,
		near_falloff = 0,
		far_falloff = 1000,
		near_multiplier = 1,
		far_multiplier = 0.1
	}
	weapon_falloff_templates.SHOTGUN_FALL_PRIMARY_MEDIUM = {
		optimal_distance = 1000,
		optimal_range = 1000,
		near_falloff = 0,
		far_falloff = 1000,
		near_multiplier = 1,
		far_multiplier = 0.2
	}
	weapon_falloff_templates.SHOTGUN_FALL_PRIMARY_HIGH = {
		optimal_distance = 1000,
		optimal_range = 1000,
		near_falloff = 0,
		far_falloff = 1000,
		near_multiplier = 1.3,
		far_multiplier = 0.3
	}
	
	weapon_falloff_templates.SHOTGUN_FALL_SECONDARY_LOW = {
		optimal_distance = 1000,
		optimal_range = 1000,
		near_falloff = 0,
		far_falloff = 1000,
		near_multiplier = 1,
		far_multiplier = 0.1
	}
	weapon_falloff_templates.SHOTGUN_FALL_SECONDARY_MEDIUM = {
		optimal_distance = 1000,
		optimal_range = 1000,
		near_falloff = 0,
		far_falloff = 1000,
		near_multiplier = 1,
		far_multiplier = 0.2
	}
	weapon_falloff_templates.SHOTGUN_FALL_SECONDARY_HIGH = {
		optimal_distance = 1000,
		optimal_range = 1000,
		near_falloff = 0,
		far_falloff = 1000,
		near_multiplier = 1,
		far_multiplier = 0.1
	}
	weapon_falloff_templates.SHOTGUN_FALL_SECONDARY_VERYHIGH = {
		optimal_distance = 1000,
		optimal_range = 1000,
		near_falloff = 0,
		far_falloff = 1000,
		near_multiplier = 1,
		far_multiplier = 0.3
	}
	
	return weapon_falloff_templates
end