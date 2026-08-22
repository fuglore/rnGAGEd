Hooks:PostHook(UpgradesTweakData, "init", "reengage_skillupgrades", function(self, tweak_data)
	--sandy perkdeck upgrades
	--who is sandy tuner and what is she doing in my code
	self.definitions.sandy_tuner = {
		category = "grenade"
	}
	self.values.temporary.sandy_tuner = {
		{
			11,
			1
		}
	}	
	self.values.player.sandy_armor_to_health = {
		2
	}
	self.values.player.sandy_reload_speed_mul = {
		1.25
	}
	self.values.player.sandy_swap_speed_mul = {
		2
	}
	self.values.player.sandy_dmg_resist_tuner = {
		0.5
	}
	self.values.player.sandy_on_kill_health = {
		1
	}
	
	self.definitions.temporary_sandy_tuner = {
		name_id = "",
		category = "temporary",
		upgrade = {
			value = 1,
			upgrade = "sandy_tuner",
			category = "temporary"
		}
	}
	self.definitions.player_sandy_armor_to_health = {
		name_id = "",
		category = "feature",
		upgrade = {
			value = 1,
			upgrade = "sandy_armor_to_health",
			category = "player"
		}
	}
	self.definitions.player_sandy_reload_speed_mul = {
		name_id = "",
		category = "feature",
		upgrade = {
			value = 1,
			upgrade = "sandy_reload_speed_mul",
			category = "player"
		}
	}
	self.definitions.player_sandy_swap_speed_mul = {
		name_id = "",
		category = "feature",
		upgrade = {
			value = 1,
			upgrade = "sandy_swap_speed_mul",
			category = "player"
		}
	}
	self.definitions.player_sandy_dmg_resist_tuner = {
		name_id = "",
		category = "feature",
		upgrade = {
			value = 1,
			upgrade = "sandy_dmg_resist_tuner",
			category = "player"
		}
	}
	self.definitions.player_sandy_on_kill_health = {
		name_id = "",
		category = "feature",
		upgrade = {
			value = 1,
			upgrade = "sandy_on_kill_health",
			category = "player"
		}
	}
	
	if RNGAGED.settings.disable_balance_changes then
		return
	end
	
	self.values.player.body_armor.armor = {
		0.5,
		3.5,
		5,
		6,
		9.5,
		13,
		20.5
	}
	self.values.player.body_armor.movement = {
		1.05,
		1.025,
		1,
		0.95,
		0.75,
		0.7,
		0.675
	}
	self.values.player.body_armor.stamina = {
		1.025,
		1,
		0.95,
		0.9,
		0.85,
		0.8,
		0.75
	}
	
	self.values.player.shield_knock_bullet = {
		max_damage = 40,
		chance = 0.25
	}

	--perkdeck upgrades
	self.values.player.passive_always_regen_armor = {
		3
	}

	self.values.melee.stacking_hit_damage_multiplier = {
		2.5,
		2.5
	}
	self.values.melee.stacking_hit_expire_t = {
		2
	}
	
	self.values.player.armor_grinding = {
		{
			{
				3,
				3
			},
			{
				3,
				3
			},
			{
				3,
				3
			},
			{
				3,
				3
			},
			{
				3,
				3
			},
			{
				3,
				3
			},
			{
				3,
				3
			}
		}
	}
	
	self.values.player.body_armor.skill_kill_change_regenerate_speed = {
		2.25,
		2.1,
		2,
		1.75,
		1.5,
		1.25,
		1.1
	}
	
	self.values.player.damage_to_armor = {
		{
			{
				2,
				2
			},
			{
				2,
				2
			},
			{
				2,
				2
			},
			{
				2,
				2
			},
			{
				2,
				2
			},
			{
				2,
				2
			},
			{
				2,
				2
			}
		}
	}
	
	self.values.player.grind_stamina_on_kill = {
		0.1
	}
	self.definitions.player_grind_stamina_on_kill = {
		name_id = "",
		category = "feature",
		upgrade = {
			value = 1,
			upgrade = "grind_stamina_on_kill",
			category = "player"
		}
	}
	
	self.values.player.grind_armor_on_pickup = {
		2
	}
	self.definitions.player_grind_armor_on_pickup = {
		name_id = "",
		category = "feature",
		upgrade = {
			value = 1,
			upgrade = "grind_armor_on_pickup",
			category = "player"
		}
	}
	
	self.values.player.grind_armor_on_kill = {
		2
	}
	self.definitions.player_grind_armor_on_kill = {
		name_id = "",
		category = "feature",
		upgrade = {
			value = 1,
			upgrade = "grind_armor_on_kill",
			category = "player"
		}
	}
	
	self.values.player.damage_control_passive = {
		{
			50,
			9
		}
	}
	self.values.player.damage_control_auto_shrug = {
		6
	}
	self.values.player.damage_control_healing = {
		25
	}
	
	self.values.temporary.mrwi_health_invulnerable = {
		{
			0.25,
			2,
			20
		}
	}
	
	--skill upgrades
	self.power_load_cooldown = 10
	
	self.values.temporary.dmg_resist_on_unsafe_reload = {
		{
			0.25,
			3
		}
	}
	
	self.definitions.temporary_dmg_resist_on_unsafe_reload_1 = {
		name_id = "",
		category = "temporary",
		upgrade = {
			value = 1,
			upgrade = "dmg_resist_on_unsafe_reload",
			category = "temporary"
		}
	}
	
	self.values.player.tase_on_unsafe_reload = {
		true
	}
	self.definitions.player_tase_on_unsafe_reload = {
		name_id = "",
		category = "feature",
		upgrade = {
			value = 1,
			upgrade = "tase_on_unsafe_reload",
			category = "player"
		}
	}
	self.values.snp.graze_damage = {
		{
			radius = 100,
			damage_factor = 0.25,
			damage_factor_headshot = 0.25
		},
		{
			radius = 100,
			damage_factor = 0.25,
			damage_factor_headshot = 0.5
		}
	}
	
	self.values.shotgun.steelsight_range_inc = {
		1.25,
		1.5
	}
	
	self.definitions.shotgun_steelsight_range_inc_2 = {
		name_id = "",
		category = "feature",
		upgrade = {
			value = 2,
			upgrade = "steelsight_range_inc",
			category = "shotgun"
		}
	}
	
	self.values.shotgun.extra_pellets = {
		2
	}
	
	self.definitions.shotgun_extra_pellets = {
		name_id = "",
		category = "feature",
		upgrade = {
			value = 1,
			upgrade = "extra_pellets",
			category = "shotgun"
		}
	}
	
	self.values.shotgun.consume_no_ammo_chance[2] = 0.25
	
	self.values.player.flashbang_multiplier = {
		0.75,
		0.75
	}
	
	self.values.player.health_dmg_resist = {
		0.9
	}
	self.definitions.player_health_dmg_resist_1 = {
		name_id = "",
		category = "feature",
		upgrade = {
			value = 1,
			upgrade = "health_dmg_resist",
			category = "player"
		}
	}
	
	self.values.player.armor_piercing_dmg_resist = {
		0.75
	}
	self.definitions.player_armor_piercing_dmg_resist = {
		name_id = "",
		category = "feature",
		upgrade = {
			value = 1,
			upgrade = "armor_piercing_dmg_resist",
			category = "player"
		}
	}
	
	self.values.carry.can_sprint_with_any_bag = {
		true
	}
	self.definitions.carry_can_sprint_with_any_bag = {
		name_id = "",
		category = "feature",
		upgrade = {
			value = 1,
			upgrade = "can_sprint_with_any_bag",
			category = "carry"
		}
	}
	
	self.values.player.armor_regen_time_mul = {
		0.9,
		0.75
	}
	self.definitions.player_armor_regen_time_mul_2 = {
		name_id = "menu_player_armor_regen_time_mul",
		category = "feature",
		upgrade = {
			value = 2,
			upgrade = "armor_regen_time_mul",
			category = "player"
		}
	}
	
	self.values.temporary.overkill_damage_multiplier = {
		{
			1.5,
			7
		}
	}
	
	
	self.values.player.headshot_relieve_suppression = {
		1
	}
	self.definitions.player_headshot_relieve_suppression = {
		name_id = "",
		category = "feature",
		upgrade = {
			value = 1,
			upgrade = "headshot_relieve_suppression",
			category = "player"
		}
	}
	self.on_headshot_dealt_cooldown = 4
	
	self.values.player.body_armor.skill_ammo_mul = {
		1,
		1.025,
		1.05,
		1.1,
		1.15,
		1.2,
		1.25
	}
	
	self.values.saw.grant_dmg_resist = {
		true
	}
	self.definitions.saw_grant_dmg_resist = {
		name_id = "",
		category = "feature",
		upgrade = {
			value = 1,
			upgrade = "grant_dmg_resist",
			category = "saw"
		}
	}
	
	self.values.saw.extra_ammo_multiplier = {
		2
	}
	
	self.values.saw.enemy_slicer = {
		8
	}
	
	self.values.saw.swap_speed_multiplier = {
		1.5
	}
	
	self.values.player.passive_suppression_multiplier = {
		1.05,
		1.15
	}

	self.values.player.weapon_accuracy_increase = {
		1,
		2
	}
	
	self.definitions.player_weapon_accuracy_increase_2 = {
		name_id = "menu_player_weapon_accuracy_increase",
		category = "feature",
		upgrade = {
			value = 2,
			upgrade = "weapon_accuracy_increase",
			category = "player"
		}
	}
	
	self.values.weapon.increase_stagger_dmg = {
		1.15
	}
	
	self.definitions.weapon_increase_stagger_dmg = {
		name_id = "menu_weapon_increase_stagger_dmg",
		category = "feature",
		upgrade = {
			value = 1,
			upgrade = "increase_stagger_dmg",
			category = "weapon"
		}
	}
	
	self.values.weapon.knock_down[1] = 0.15
	self.values.weapon.knock_down[2] = 0.15
	
	self.values.weapon.passive_recoil_multiplier = {
		0.95,
		0.9
	}
	
	self.values.weapon.automatic_heat_chance = {
		0.15
	}
	
	self.definitions.weapon_automatic_heat_chance_1 = {
		name_id = "menu_weapon_increase_stagger_dmg",
		category = "feature",
		upgrade = {
			value = 1,
			upgrade = "automatic_heat_chance",
			category = "weapon"
		}
	}
	
	self.values.weapon.automatic_heat_last_shot = {
		true
	}
	
	self.definitions.weapon_automatic_heat_last_shot = {
		name_id = "menu_weapon_increase_stagger_dmg",
		category = "feature",
		upgrade = {
			value = 1,
			upgrade = "automatic_heat_last_shot",
			category = "weapon"
		}
	}
	
	self.values.player.automatic_faster_reload[1] = {
		min_reload_increase = 1.3,
		penalty = 0.98,
		target_enemies = 2,
		min_bullets = 20,
		max_reload_increase = 2
	}
	self.values.player.automatic_faster_reload[2] = {
		min_reload_increase = 1.6,
		penalty = 0.99,
		target_enemies = 2,
		min_bullets = 50,
		max_reload_increase = 2
	}
	
	self.definitions.player_automatic_faster_reload_2 = {
		name_id = "menu_automatic_faster_reload",
		category = "feature",
		upgrade = {
			value = 2,
			upgrade = "automatic_faster_reload",
			category = "player"
		}
	}
	
	self.values.player.standstill_omniscience_loud = {
		true
	}
	self.definitions.player_standstill_omniscience_loud = {
		name_id = "menu_player_standstill_omniscience",
		category = "feature",
		upgrade = {
			value = 1,
			upgrade = "standstill_omniscience_loud",
			category = "player"
		}
	}
	
	self.values.player.hh_weapon_swap_speed_mul = {
		1.15
	}
	
	self.definitions.player_hh_weapon_swap_speed_mul = {
		name_id = "",
		category = "feature",
		upgrade = {
			value = 1,
			upgrade = "hh_weapon_swap_speed_mul",
			category = "player"
		}
	}
	
	self.values.player.hh_armor_movement_penalty_multiplier = {
		0.9
	}
	
	self.definitions.player_hh_armor_movement_penalty_multiplier = {
		name_id = "",
		category = "feature",
		upgrade = {
			value = 1,
			upgrade = "hh_armor_movement_penalty_multiplier",
			category = "player"
		}
	}
	
	self.values.player.taser_malfunction = {
		{
			interval = 10,
			chance_to_trigger = 0
		}
	}
	
	self.values.player.move_while_tased = {
		true
	}
	self.definitions.player_move_while_tased = {
		name_id = "",
		category = "feature",
		upgrade = {
			value = 1,
			upgrade = "move_while_tased",
			category = "player"
		}
	}
	
	self.values.player.hh_dodge_add = {
		0.05,
		0.15
	}
	self.definitions.player_hh_dodge_add_1 = {
		name_id = "",
		category = "feature",
		upgrade = {
			value = 1,
			upgrade = "hh_dodge_add",
			category = "player"
		}
	}
	self.definitions.player_hh_dodge_add_2 = {
		name_id = "",
		category = "feature",
		upgrade = {
			value = 2,
			upgrade = "hh_dodge_add",
			category = "player"
		}
	}
	
	self.values.weapon.silencer_damage_falloff_extend = {
		1.3
	}
	self.values.weapon.silencer_damage_falloff_penalty_reduction = {
		0.5
	}
	self.definitions.weapon_silencer_damage_falloff_extend = {
		name_id = "",
		category = "feature",
		upgrade = {
			value = 1,
			upgrade = "silencer_damage_falloff_extend",
			category = "weapon"
		}
	}
	self.definitions.weapon_silencer_damage_falloff_penalty_reduction = {
		name_id = "",
		category = "feature",
		upgrade = {
			value = 1,
			upgrade = "silencer_damage_falloff_penalty_reduction",
			category = "weapon"
		}
	}
	
	self.values.player.marked_inc_dmg_distance = {
		{
			700,
			1.15
		}
	}
	
	self.values.weapon.special_damage_taken_multiplier = {
		1.15
	}
	
	self.values.player.critical_hit_chance = {
		0.15,
		0.25
	}
	
	self.definitions.player_critical_hit_chance_1 = {
		name_id = "menu_player_critical_hit_chance",
		category = "feature",
		upgrade = {
			value = 1,
			upgrade = "critical_hit_chance",
			category = "player"
		}
	}
	self.definitions.player_critical_hit_chance_2 = {
		name_id = "menu_player_critical_hit_chance",
		category = "feature",
		upgrade = {
			value = 2,
			upgrade = "critical_hit_chance",
			category = "player"
		}
	}
	
	self.values.player.crit_from_far = {
		true
	}
	self.definitions.player_crit_far = {
		name_id = "menu_player_critical_hit_chance",
		category = "feature",
		upgrade = {
			value = 1,
			upgrade = "crit_from_far",
			category = "player"
		}
	}
	
	self.values.player.crit_backstab = {
		true
	}
	self.definitions.player_crit_backstab = {
		name_id = "menu_player_critical_hit_chance",
		category = "feature",
		upgrade = {
			value = 1,
			upgrade = "crit_backstab",
			category = "player"
		}
	}
	
	self.values.pistol.passive_suppression_multiplier = {
		1.25
	}
	self.values.pistol.fire_rate_multiplier = {
		1.25,
		1.5
	}
	self.definitions.pistol_fire_rate_multiplier_1 = {
		name_id = "menu_pistol_fire_rate_multiplier",
		category = "feature",
		upgrade = {
			value = 1,
			upgrade = "fire_rate_multiplier",
			category = "pistol"
		}
	}
	self.definitions.pistol_fire_rate_multiplier_2 = {
		name_id = "menu_pistol_fire_rate_multiplier",
		category = "feature",
		upgrade = {
			value = 1,
			upgrade = "fire_rate_multiplier",
			category = "pistol"
		}
	}
	
	self.definitions.pistol_passive_suppression_multiplier = {
		name_id = "",
		category = "feature",
		upgrade = {
			value = 1,
			upgrade = "passive_suppression_multiplier",
			category = "pistol"
		}
	}
	
	self.values.akimbo.recoil_index_addend = {
		0,
		1,
		2,
		2,
		2	
	}
	
	self.values.player.bleed_out_health_multiplier = {
		4.6
	}
	
	self.values.player.bleedout_invulnerability = {
		true
	}
	self.definitions.player_bleedout_invulnerability = {
		name_id = "",
		category = "feature",
		upgrade = {
			value = 1,
			upgrade = "bleedout_invulnerability",
			category = "player"
		}
	}
	
	self.values.player.reload_on_revive = {
		true
	}
	self.definitions.player_reload_on_revive = {
		name_id = "",
		category = "feature",
		upgrade = {
			value = 1,
			upgrade = "reload_on_revive",
			category = "player"
		}
	}
	
	self.values.temporary.revive_invulnerabilty = {
		{
			true,
			1.5
		}
	}
	
	self.definitions.temporary_revive_invulnerabilty = {
		name_id = "",
		category = "temporary",
		upgrade = {
			value = 1,
			upgrade = "revive_invulnerabilty",
			category = "temporary"
		}
	}
	
	self.values.player.cheat_death_chance = {
		0.15,
		0.3
	}
	
	self.values.player.melee_damage_stacking = {
		{
			max_multiplier = 4,
			melee_multiplier = 0.25
		}
	}
	
	self.values.player.melee_swing_speed_mul = {
		1.15
	}
	self.definitions.player_melee_swing_speed_mul = {
		name_id = "",
		category = "feature",
		upgrade = {
			value = 1,
			upgrade = "melee_swing_speed_mul",
			category = "player"
		}
	}
	
	self.values.player.faster_melee_charge = {
		0.5
	}
	self.definitions.player_faster_melee_charge = {
		name_id = "",
		category = "feature",
		upgrade = {
			value = 1,
			upgrade = "faster_melee_charge",
			category = "player"
		}
	}
	
	self.values.player.counter_strike_no_dot = {
		true
	}
	
	self.definitions.player_counter_strike_no_dot = {
		name_id = "",
		category = "feature",
		upgrade = {
			value = 1,
			upgrade = "counter_strike_no_dot",
			category = "player"
		}
	}
	
	self.values.player.healing_reduction = {
		0.3,
		1
	}
	
	self.values.player.melee_damage_health_ratio_threshold_multiplier = {
		2
	}
	self.definitions.player_melee_damage_health_ratio_threshold_multiplier = {
		name_id = "",
		category = "feature",
		upgrade = {
			value = 1,
			upgrade = "melee_damage_health_ratio_threshold_multiplier",
			category = "player"
		}
	}
	
	self.values.player.damage_damage_health_ratio_threshold_multiplier = {
		2
	}	
	self.definitions.player_damage_damage_health_ratio_threshold_multiplier = {
		name_id = "",
		category = "feature",
		upgrade = {
			value = 1,
			upgrade = "damage_damage_health_ratio_threshold_multiplier",
			category = "player"
		}
	}
	
	self.values.player.max_health_reduction = {
		0.5
	}
	
	self.values.player.max_armor_reduction = {
		0.5
	}
	self.definitions.player_max_armor_reduction_1 = {
		name_id = "",
		category = "feature",
		upgrade = {
			value = 1,
			upgrade = "max_armor_reduction",
			category = "player"
		}
	}
	
	self.values.player.reclaim_health = {
		true
	}
	
	self.definitions.player_reclaim_health = {
		name_id = "",
		category = "feature",
		upgrade = {
			value = 1,
			upgrade = "reclaim_health",
			category = "player"
		}
	}
	
	self.values.player.reclaim_pickups = {
		true
	}
	
	self.definitions.player_reclaim_pickups = {
		name_id = "",
		category = "feature",
		upgrade = {
			value = 1,
			upgrade = "reclaim_health",
			category = "player"
		}
	}
	
	
end)