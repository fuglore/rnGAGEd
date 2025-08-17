Hooks:PostHook(SkillTreeTweakData, "init", "reengage_skilltree", function(self)
	local sandydeck2 = {
		cost = 0,
		desc_id = "menu_deckall_2_desc",
		name_id = "menu_deckall_2",
		upgrades = {
			"weapon_passive_headshot_damage_multiplier"
		},
		icon_xy = {
			1,
			0
		}
	}
	local sandydeck4 = {
		cost = 0,
		desc_id = "menu_deckall_4_desc",
		name_id = "menu_deckall_4",
		upgrades = {
			"passive_player_xp_multiplier",
			"player_passive_suspicion_bonus",
			"player_passive_armor_movement_penalty_multiplier"
		},
		icon_xy = {
			3,
			0
		}
	}
	local sandydeck6 = {
		cost = 0,
		desc_id = "menu_deckall_6_desc",
		name_id = "menu_deckall_6",
		upgrades = {
			"armor_kit",
			"player_pick_up_ammo_multiplier"
		},
		icon_xy = {
			5,
			0
		}
	}
	local sandydeck8 = {
		cost = 0,
		desc_id = "menu_deckall_8_desc",
		name_id = "menu_deckall_8",
		upgrades = {
			"weapon_passive_damage_multiplier",
			"passive_doctor_bag_interaction_speed_multiplier"
		},
		icon_xy = {
			7,
			0
		}
	}

	local sandy = {
		name_id = "menu_deck_sandy_name",
		desc_id = "menu_deck_sandy_desc",
		category = "offensive",
		{
			upgrades = {
				"sandy_tuner",
				"temporary_sandy_tuner"
			},
			cost = 0,
			texture_bundle_folder = "pd2_mod_rgg",
			icon_xy = {
				0,
				0
			},
			name_id = "menu_deck_sandy_1",
			desc_id = "menu_deck_sandy_1_desc"
		},
		sandydeck2,
		{
			upgrades = {
				"player_sandy_armor_to_health"
			},
			cost = 0,
			texture_bundle_folder = "pd2_mod_rgg",
			icon_xy = {
				1,
				0
			},
			name_id = "menu_deck_sandy_3",
			desc_id = "menu_deck_sandy_3_desc"
		},
		sandydeck4,
		{
			upgrades = {
				"player_sandy_reload_speed_mul",
				"player_sandy_swap_speed_mul"
			},
			cost = 0,
			texture_bundle_folder = "pd2_mod_rgg",
			icon_xy = {
				2,
				0
			},
			name_id = "menu_deck_sandy_5",
			desc_id = "menu_deck_sandy_5_desc"
		},
		sandydeck6,
		{
			upgrades = {
				"player_sandy_dmg_resist_tuner"
			},
			cost = 0,
			texture_bundle_folder = "pd2_mod_rgg",
			icon_xy = {
				3,
				0
			},
			name_id = "menu_deck_sandy_7",
			desc_id = "menu_deck_sandy_7_desc"
		},
		sandydeck8,
		{
			upgrades = {
				"player_sandy_on_kill_health"
			},
			cost = 0,
			texture_bundle_folder = "pd2_mod_rgg",
			icon_xy = {
				0,
				1
			},
			name_id = "menu_deck_sandy_9",
			desc_id = "menu_deck_sandy_9_desc"
		}
	}
	
	table.insert(self.specializations, sandy)
	
	if RNGAGED.settings.disable_balance_changes then
		return
	end
	
	for i = 1, #self.specializations do
		local deck = self.specializations[i]
		
		if deck[2] then
			if deck[2].upgrades then
				table.insert(deck[2].upgrades, "player_movement_speed_multiplier")
				table.insert(deck[2].upgrades, "player_climb_speed_multiplier_1")
				table.insert(deck[2].upgrades, "player_run_speed_multiplier")
			end
		end
		
		if deck[6] then
			if deck[6].upgrades then
				table.remove(deck[6].upgrades, 2)
				table.insert(deck[6].upgrades, "saw_secondary")
				table.insert(deck[6].upgrades, "player_saw_speed_multiplier_2")
				table.insert(deck[6].upgrades, "saw_lock_damage_multiplier_2")
			end
		end
		
		if deck[8] then
			if deck[8].upgrades then
				table.insert(deck[8].upgrades, "player_buy_bodybags_asset")
				table.insert(deck[8].upgrades, "player_additional_assets")
				table.insert(deck[8].upgrades, "player_cleaner_cost_multiplier")
				table.insert(deck[8].upgrades, "player_buy_spotter_asset")
			end
		end
	end
	
	self.specializations[9][1].upgrades = {"player_damage_dampener_outnumbered_strong"} --remove overdog effect
	self.specializations[15][1].upgrades = {"player_armor_grinding_1"}
	table.insert(self.specializations[15][3].upgrades, "player_grind_stamina_on_kill")
	table.insert(self.specializations[15][5].upgrades, "player_grind_armor_on_pickup")
	table.insert(self.specializations[15][7].upgrades, "player_grind_armor_on_kill")

	self.default_upgrades = {
		"player_fall_damage_multiplier",
		"player_fall_health_damage_multiplier",
		"player_silent_kill",
		"player_primary_weapon_when_downed",
		"player_intimidate_enemies",
		"player_special_enemy_highlight",
		"player_hostage_trade",
		"player_sec_camera_highlight",
		"player_corpse_dispose",
		"player_corpse_dispose_amount_1",
		"player_civ_harmless_melee",
		"player_walk_speed_multiplier",
		"player_steelsight_when_downed",
		"player_crouch_speed_multiplier",
		"carry_interact_speed_multiplier_1",
		"carry_interact_speed_multiplier_2",
		"carry_movement_speed_multiplier",
		"trip_mine_sensor_toggle",
		"trip_mine_sensor_highlight",
		"trip_mine_can_switch_on_off",
		"ecm_jammer_can_activate_feedback",
		"ecm_jammer_interaction_speed_multiplier",
		"ecm_jammer_can_retrigger",
		"ecm_jammer_affects_cameras",
		"striker_reload_speed_default",
		"temporary_first_aid_damage_reduction",
		"temporary_passive_revive_damage_reduction_2",
		"akimbo_recoil_index_addend_1",
		"doctor_bag",
		"ammo_bag",
		"trip_mine",
		"ecm_jammer",
		"first_aid_kit",
		"sentry_gun",
		"bodybags_bag",
		"saw",
		"cable_tie",
		"jowi",
		"x_1911",
		"x_b92fs",
		"x_deagle",
		"x_g22c",
		"x_g17",
		"x_usp",
		"x_sr2",
		"x_mp5",
		"x_akmsu",
		"x_packrat",
		"x_p226",
		"x_m45",
		"x_mp7",
		"x_ppk"
	}
	--table.insert(self.default_upgrades, "player_can_free_run")
	
	self.skills.spotter_teamwork = {
		{
			upgrades = {
				"temporary_dmg_resist_on_unsafe_reload_1"
			},
			cost = self.costs.hightier
		},
		{
			upgrades = {
				"player_tase_on_unsafe_reload"
			},
			cost = self.costs.hightierpro
		},
		name_id = "menu_single_shot_ammo_return_beta",
		desc_id = "menu_single_shot_ammo_return_beta_desc",
		icon_xy = {
			8,
			4
		}
	}
	
	self.skills.shotgun_impact = {
		{
			upgrades = {
				"shotgun_damage_multiplier_1",
				"shotgun_damage_multiplier_2"
			},
			cost = self.costs.default
		},
		{
			upgrades = {
				"shotgun_recoil_index_addend"
			},
			cost = self.costs.pro
		},
		name_id = "menu_shotgun_impact_beta",
		desc_id = "menu_shotgun_impact_beta_desc",
		icon_xy = {
			4,
			1
		}
	}
	
	self.skills.far_away = {
		{
			upgrades = {
				"shotgun_steelsight_range_inc_1"
			},
			cost = self.costs.hightier
		},
		{
			upgrades = {
				"shotgun_steelsight_range_inc_2"
			},
			cost = self.costs.hightierpro
		},
		name_id = "menu_far_away_beta",
		desc_id = "menu_far_away_beta_desc",
		icon_xy = {
			8,
			5
		}
	}
	
	self.skills.close_by = {
		{
			upgrades = {
				"shotgun_extra_pellets"
			},
			cost = self.costs.hightier
		},
		{
			upgrades = {
				"shotgun_consume_no_ammo_chance_1",
				"shotgun_consume_no_ammo_chance_2"
			},
			cost = self.costs.hightierpro
		},
		name_id = "menu_close_by_beta",
		desc_id = "menu_close_by_beta_desc",
		icon_xy = {
			8,
			6
		}
	}
	
	self.skills.overkill = {
		{
			upgrades = {
				"player_overkill_damage_multiplier",
				"player_overkill_all_weapons"
			},
			cost = self.costs.hightier
		},
		{
			upgrades = {
				"player_shield_knock"
			},
			cost = self.costs.hightierpro
		},
		name_id = "menu_overkill_beta",
		desc_id = "menu_overkill_beta_desc",
		icon_xy = {
			8,
			10
		}
	}
	
	self.skills.oppressor = {
		{
			upgrades = {
				"player_flashbang_multiplier_1",
				"player_flashbang_multiplier_2"
			},
			cost = self.costs.default
		},
		{
			upgrades = {
				"player_health_dmg_resist_1"
			},
			cost = self.costs.pro
		},
		name_id = "menu_oppressor_beta",
		desc_id = "menu_oppressor_beta_desc",
		icon_xy = {
			5.9625,
			1
		}
	}
	
	self.skills.show_of_force = {
		{
			upgrades = {
				"player_armor_piercing_dmg_resist"
			},
			cost = self.costs.default
		},
		{
			upgrades = {
				"player_interacting_damage_multiplier"
			},
			cost = self.costs.pro
		},
		name_id = "menu_show_of_force_beta",
		desc_id = "menu_show_of_force_beta_desc",
		icon_xy = {
			8,
			9
		}
	}
	
	self.skills.pack_mule = {
		{
			upgrades = {
				"carry_throw_distance_multiplier"
			},
			cost = self.costs.default
		},
		{
			upgrades = {
				"player_armor_carry_bonus_1",
				"carry_can_sprint_with_any_bag"
			},
			cost = self.costs.pro
		},
		name_id = "menu_pack_mule_beta",
		desc_id = "menu_pack_mule_beta_desc",
		icon_xy = {
			8,
			8
		}
	}
	
	self.skills.iron_man = {
		{
			upgrades = {
				"player_armor_regen_time_mul_1"
			},
			cost = self.costs.hightier
		},
		{
			upgrades = {
				"player_armor_regen_time_mul_2"
			},
			cost = self.costs.hightierpro
		},
		name_id = "menu_iron_man_beta",
		desc_id = "menu_iron_man_beta_desc",
		icon_xy = {
			6,
			4
		}
	}

	self.skills.prison_wife = {
		{
			upgrades = {
				"player_headshot_relieve_suppression"
			},
			cost = self.costs.hightier
		},
		{
			upgrades = {
				"player_headshot_regen_armor_bonus_1",
				"player_headshot_regen_armor_bonus_2"
			},
			cost = self.costs.hightierpro
		},
		name_id = "menu_prison_wife_beta",
		desc_id = "menu_prison_wife_beta_desc",
		icon_xy = {
			6,
			11
		}
	}
	
	self.skills.juggernaut = {
		{
			upgrades = {
				"body_armor6"
			},
			cost = self.costs.hightier
		},
		{
			upgrades = {
				"player_add_armor_stat_skill_ammo_mul"
			},
			cost = self.costs.hightierpro
		},
		name_id = "menu_juggernaut_beta",
		desc_id = "menu_juggernaut_beta_desc",
		icon_xy = {
			3,
			1
		}
	}
	
	self.skills.portable_saw = {
		{
			upgrades = {
				"saw_grant_dmg_resist"
			},
			cost = self.costs.hightier
		},
		{
			upgrades = {
				"saw_extra_ammo_multiplier",
			},
			cost = self.costs.hightierpro
		},
		name_id = "menu_portable_saw_beta",
		desc_id = "menu_portable_saw_beta_desc",
		icon_xy = {
			0,
			1
		}
	}
	
	self.skills.carbon_blade = {
		{
			upgrades = {
				"saw_enemy_slicer",
				"saw_reload_speed_multiplier"
			},
			cost = self.costs.hightier
		},
		{
			upgrades = {
				"saw_ignore_shields_1",
				"saw_swap_speed_multiplier"
				
			},
			cost = self.costs.hightierpro
		},
		name_id = "menu_carbon_blade_beta",
		desc_id = "menu_carbon_blade_beta_desc",
		icon_xy = {
			0,
			2
		}
	}
	
	self.skills.steady_grip = {
		{
			upgrades = {
				"player_passive_suppression_bonus_1"
			},
			cost = self.costs.hightier
		},
		{
			upgrades = {
				"player_passive_suppression_bonus_2"
			},
			cost = self.costs.hightierpro
		},
		name_id = "menu_steady_grip_beta",
		desc_id = "menu_steady_grip_beta_desc",
		icon_xy = {
			7,
			0
		}
	}
	
	self.skills.fire_control = {
		{
			upgrades = {
				"player_weapon_accuracy_increase_1"
			},
			cost = self.costs.hightier
		},
		{
			upgrades = {
				"player_weapon_accuracy_increase_2"
			},
			cost = self.costs.hightierpro
		},
		name_id = "menu_fire_control_beta",
		desc_id = "menu_fire_control_beta_desc",
		icon_xy = {
			9,
			10
		}
	}
	
	self.skills.heavy_impact = {
		{
			upgrades = {
				"weapon_knock_down_1"
			},
			cost = self.costs.hightier
		},
		{
			upgrades = {
				"weapon_knock_down_2",
				"weapon_increase_stagger_dmg"
			},
			cost = self.costs.hightierpro
		},
		name_id = "menu_heavy_impact_beta",
		desc_id = "menu_heavy_impact_beta_desc",
		icon_xy = {
			10,
			1
		}
	}
	
	self.skills.shock_and_awe = {
		{
			upgrades = {
				"weapon_passive_recoil_multiplier_1"
			},
			cost = self.costs.hightier
		},
		{
			upgrades = {
				"weapon_passive_recoil_multiplier_2"
			},
			cost = self.costs.hightierpro
		},
		name_id = "menu_shock_and_awe_beta",
		desc_id = "menu_shock_and_awe_beta_desc",
		icon_xy = {
			7,
			7
		}
	}
	
	self.skills.fast_fire = {
		{
			upgrades = {
				"weapon_automatic_heat_chance_1"
			},
			cost = self.costs.hightier
		},
		{
			upgrades = {
				"weapon_automatic_heat_last_shot"
			},
			cost = self.costs.hightierpro
		},
		name_id = "menu_fast_fire_beta",
		desc_id = "menu_fast_fire_beta_desc",
		icon_xy = {
			10,
			2
		}
	}
	
	self.skills.body_expertise = {
		{
			upgrades = {
				"player_automatic_faster_reload_1"
			},
			cost = self.costs.hightier
		},
		{
			upgrades = {
				"player_automatic_faster_reload_2"
			},
			cost = self.costs.hightierpro
		},
		name_id = "menu_body_expertise_beta",
		desc_id = "menu_body_expertise_beta_desc",
		icon_xy = {
			7,
			10
		}
	}
	
	self.skills.chameleon = {
		{
			upgrades = {
				"player_standstill_omniscience"
			},
			cost = self.costs.default
		},
		{
			upgrades = {
				"player_standstill_omniscience_loud"
			},
			cost = self.costs.pro
		},
		name_id = "menu_chameleon_beta",
		desc_id = "menu_chameleon_beta_desc",
		icon_xy = {
			6,
			10
		}
	}
	
	self.skills.thick_skin = {
		{
			upgrades = {
				"player_hh_weapon_swap_speed_mul"
			},
			cost = self.costs.default
		},
		{
			upgrades = {
				"player_hh_armor_movement_penalty_multiplier"
			},
			cost = self.costs.pro
		},
		name_id = "menu_thick_skin_beta",
		desc_id = "menu_thick_skin_beta_desc",
		icon_xy = {
			10,
			7
		}
	}
	
	self.skills.sprinter = {
		{
			upgrades = {
				"player_stamina_regen_timer_multiplier",
				"player_stamina_regen_multiplier"
			},
			cost = self.costs.default
		},
		{
			upgrades = {
				"player_run_dodge_chance",
				"player_on_zipline_dodge_chance"
			},
			cost = self.costs.pro
		},
		name_id = "menu_sprinter_beta",
		desc_id = "menu_sprinter_beta_desc",
		icon_xy = {
			10,
			5
		}
	}
	
	self.skills.awareness = {
		{
			upgrades = {
				"player_run_and_reload"
			},
			cost = self.costs.default
		},
		{
			upgrades = {
				"player_run_and_shoot_1"
			},
			cost = self.costs.pro
		},
		name_id = "menu_awareness_beta",
		desc_id = "menu_awareness_beta_desc",
		icon_xy = {
			10,
			6
		}
	}
	
	self.skills.insulation = {
		{
			upgrades = {
				"player_move_while_tased"
			},
			cost = self.costs.hightier
		},
		{
			upgrades = {
				"player_resist_firing_tased"
			},
			cost = self.costs.hightierpro
		},
		name_id = "menu_insulation_beta",
		desc_id = "menu_insulation_beta_desc",
		icon_xy = {
			3,
			5
		}
	}
	
	self.skills.jail_diet = {
		{
			upgrades = {
				"player_hh_dodge_add_1",
				"player_dodge_reroll"
			},
			cost = self.costs.hightier
		},
		{
			upgrades = {
				"player_hh_dodge_add_2"
			},
			cost = self.costs.hightierpro
		},
		name_id = "menu_jail_diet_beta",
		desc_id = "menu_jail_diet_beta_desc",
		icon_xy = {
			1,
			12
		}
	}
	
	self.skills.scavenger = {
		{
			upgrades = {
				"weapon_silencer_recoil_index_addend",
				"weapon_silencer_enter_steelsight_speed_multiplier"
			},
			cost = self.costs.default
		},
		{
			upgrades = {
				"weapon_silencer_spread_index_addend"
			},
			cost = self.costs.pro
		},
		name_id = "menu_silence_expert_beta",
		desc_id = "menu_silence_expert_beta_desc",
		icon_xy = {
			4,
			4
		}
	}
	
	self.skills.optic_illusions = {
		{
			upgrades = {
				"player_marked_enemy_extra_damage"
			},
			cost = self.costs.hightier
		},
		{
			upgrades = {
				"player_marked_inc_dmg_distance_1",
				"weapon_steelsight_highlight_specials",
				"player_mark_enemy_time_multiplier"
			},
			cost = self.costs.hightierpro
		},
		name_id = "menu_spotter_teamwork_beta",
		desc_id = "menu_spotter_teamwork_beta_desc",
		icon_xy = {
			8,
			2
		}
	}
	
	self.skills.silence_expert = {
		{
			upgrades = {
				"weapon_silencer_damage_falloff_extend"
			},
			cost = self.costs.hightier
		},
		{
			upgrades = {
				"weapon_silencer_damage_falloff_penalty_reduction"
			},
			cost = self.costs.hightierpro
		},
		name_id = "menu_silencer_falloff",
		desc_id = "menu_silencer_falloff_desc",
		icon_xy = {
			5,
			9
		}
	}
	
	self.skills.hitman = {
		{
			upgrades = {
				"weapon_special_damage_taken_multiplier"
			},
			cost = self.costs.hightier
		},
		{
			upgrades = {
				"player_silencer_concealment_penalty_decrease_1",
				"player_silencer_concealment_increase_1"
			},
			cost = self.costs.hightierpro
		},
		name_id = "menu_optic_illusions",
		desc_id = "menu_optic_illusions_desc",
		icon_xy = {
			10,
			10
		}
	}
	
	self.skills.backstab = {
		{
			upgrades = {
				"player_critical_hit_chance_1",
				"player_crit_far"
			},
			cost = self.costs.hightier
		},
		{
			upgrades = {
				"player_critical_hit_chance_2",
				"player_crit_backstab"
			},
			cost = self.costs.hightierpro
		},
		name_id = "menu_backstab_beta",
		desc_id = "menu_backstab_beta_desc",
		icon_xy = {
			0,
			12
		}
	}
	
	self.skills.dance_instructor = {
		{
			upgrades = {
				"pistol_passive_suppression_multiplier",
				"pistol_fire_rate_multiplier_1"
			},
			cost = self.costs.hightier
		},
		{
			upgrades = {
				"pistol_fire_rate_multiplier_2"
			},
			cost = self.costs.hightierpro
		},
		name_id = "menu_dance_instructor",
		desc_id = "menu_dance_instructor_desc",
		icon_xy = {
			11,
			0
		}
	}
	
	self.skills.nine_lives = {
		{
			upgrades = {
				"player_bleed_out_health_multiplier"
			},
			cost = self.costs.hightier
		},
		{
			upgrades = {
				"player_bleedout_invulnerability"
			},
			cost = self.costs.hightierpro
		},
		name_id = "menu_nine_lives_beta",
		desc_id = "menu_nine_lives_beta_desc",
		icon_xy = {
			5,
			2
		}
	}
	
	self.skills.running_from_death = {
		{
			upgrades = {
				"player_reload_on_revive",
				"player_temp_swap_weapon_faster_1"
			},
			cost = self.costs.hightier
		},
		{
			upgrades = {
				"player_temp_increased_movement_speed_1",
				
			},
			cost = self.costs.hightierpro
		},
		name_id = "menu_running_from_death_beta",
		desc_id = "menu_running_from_death_beta_desc",
		icon_xy = {
			11,
			3
		}
	}
	self.skills.up_you_go = {
		{
			upgrades = {
				"player_revived_damage_resist_1",
				"player_revived_health_regain_1"
			},
			cost = self.costs.hightier
		},
		{
			upgrades = {
				"temporary_revive_invulnerabilty"
			},
			cost = self.costs.hightierpro
		},
		name_id = "menu_up_you_go_beta",
		desc_id = "menu_up_you_go_beta_desc",
		icon_xy = {
			11,
			4
		}
	}
	
	self.skills.perseverance = {
		{
			upgrades = {
				"temporary_berserker_damage_multiplier_1"
			},
			cost = self.costs.hightier
		},
		{
			upgrades = {
				"temporary_berserker_damage_multiplier_2"
			},
			cost = self.costs.hightierpro
		},
		name_id = "menu_perseverance_beta",
		desc_id = "menu_perseverance_beta_desc",
		icon_xy = {
			5,
			12
		}
	}
	
	self.skills.messiah = {
		{
			upgrades = {
				"player_messiah_revive_from_bleed_out_1"
			},
			cost = self.costs.hightier
		},
		{
			upgrades = {
				"player_additional_lives_1"
			},
			cost = self.costs.hightierpro
		},
		name_id = "menu_pistol_beta_messiah",
		desc_id = "menu_pistol_beta_messiah_desc",
		icon_xy = {
			2,
			9
		}
	}
	
	self.skills.steroids = {
		{
			upgrades = {
				"player_melee_swing_speed_mul"
			},
			cost = self.costs.default
		},
		{
			upgrades = {
				"player_faster_melee_charge"
			},
			cost = self.costs.pro
		},
		name_id = "menu_steroids_beta",
		desc_id = "menu_steroids_beta_desc",
		icon_xy = {
			1,
			3
		}
	}
	
	self.skills.drop_soap = {
		{
			upgrades = {
				"player_counter_strike_no_dot"
			},
			cost = self.costs.hightier
		},
		{
			upgrades = {
				"player_counter_strike_spooc"
			},
			cost = self.costs.hightierpro
		},
		name_id = "menu_drop_soap_beta",
		desc_id = "menu_drop_soap_beta_desc",
		icon_xy = {
			4,
			12
		}
	}
	
	self.skills.wolverine = {
		{
			upgrades = {
				"player_melee_damage_health_ratio_multiplier",
				"player_melee_damage_health_ratio_threshold_multiplier"
			},
			cost = self.costs.hightier
		},
		{
			upgrades = {
				"player_damage_health_ratio_multiplier",
				"player_damage_damage_health_ratio_threshold_multiplier"
			},
			cost = self.costs.hightierpro
		},
		name_id = "menu_wolverine_beta",
		desc_id = "menu_wolverine_beta_desc",
		icon_xy = {
			2,
			2
		}
	}
	
	self.skills.frenzy = {
		{
			upgrades = {
				"player_healing_reduction_1",
				"player_reclaim_health",
				"player_max_health_reduction_1",
				"player_max_armor_reduction_1"
			},
			cost = self.costs.hightier
		},
		{
			upgrades = {
				"player_reclaim_pickups"
			},
			cost = self.costs.hightierpro
		},
		name_id = "menu_frenzy",
		desc_id = "menu_frenzy_desc",
		icon_xy = {
			0,
			6
		}
	}
end)