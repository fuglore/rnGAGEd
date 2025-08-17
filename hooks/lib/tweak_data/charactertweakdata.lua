if RNGAGED.settings.disable_balance_changes then
	return
end

Hooks:PostHook(CharacterTweakData, "init", "rngaged_body_health", function(self, tweak_data)
	self.cop.HEALTH_INIT = 8
	self.cop_female.HEALTH_INIT = 8
	self.gensec.HEALTH_INIT = 8
	
	self.fbi.HEALTH_INIT = 4
	self.fbi.headshot_dmg_mul = 8
	self.fbi_female.HEALTH_INIT = 4
	self.fbi_female.headshot_dmg_mul = 8

	self.swat.HEALTH_INIT = 6
	self.swat.headshot_dmg_mul = self.swat.HEALTH_INIT / 1.5
	self.zeal_swat.HEALTH_INIT = 6
	self.zeal_swat.headshot_dmg_mul = self.zeal_swat.HEALTH_INIT / 1.5	
	self.fbi_swat.HEALTH_INIT = 6
	self.fbi_swat.headshot_dmg_mul = self.fbi_swat.HEALTH_INIT / 1.5
	self.city_swat.HEALTH_INIT = 6
	self.city_swat.headshot_dmg_mul = self.city_swat.HEALTH_INIT / 1.5
	
	self.heavy_swat.HEALTH_INIT = 12
	self.heavy_swat.headshot_dmg_mul = self.heavy_swat.HEALTH_INIT / 8 
	self.zeal_heavy_swat.HEALTH_INIT = 12
	self.zeal_heavy_swat.headshot_dmg_mul = self.zeal_heavy_swat.HEALTH_INIT / 8
	self.heavy_swat_sniper.HEALTH_INIT = 12
	self.heavy_swat_sniper.headshot_dmg_mul = self.heavy_swat_sniper.HEALTH_INIT / 8
	self.fbi_heavy_swat.HEALTH_INIT = 12
	self.fbi_heavy_swat.headshot_dmg_mul = self.fbi_heavy_swat.HEALTH_INIT / 8
	
	self.medic.HEALTH_INIT = 12
	self.medic.headshot_dmg_mul = self.medic.HEALTH_INIT / 8
	
	self.marshal_marksman.HEALTH_INIT = 6
	self.marshal_marksman.headshot_dmg_mul = self.marshal_marksman.HEALTH_INIT / 1.25
end)

function CharacterTweakData:_set_normal()
	self:_multiply_all_hp(1, 1)
	self:_multiply_all_speeds(1.05, 1.1)

	self.marshal_marksman.weapon.is_rifle.FALLOFF[1].dmg_mul = 0.17
	self.marshal_marksman.weapon.is_rifle.FALLOFF[2].dmg_mul = 0.35
	self.marshal_marksman.weapon.is_rifle.FALLOFF[3].dmg_mul = 0.5
	self.marshal_marksman.weapon.is_rifle.FALLOFF[4].dmg_mul = 0.7
	self.marshal_marksman.weapon.is_rifle.FALLOFF[5].dmg_mul = 0.5
	self.marshal_marksman.HEALTH_INIT = 6
	self.marshal_marksman.headshot_dmg_mul = self.marshal_marksman.HEALTH_INIT / 1.25
	self.marshal_shield.HEALTH_INIT = 8
	self.marshal_shield.weapon.is_pistol.FALLOFF[1].dmg_mul = 1
	self.marshal_shield.weapon.is_pistol.FALLOFF[2].dmg_mul = 0.5
	self.marshal_shield.weapon.is_pistol.FALLOFF[3].dmg_mul = 0.3
	self.marshal_shield.weapon.is_pistol.FALLOFF[4].dmg_mul = 0.25
	self.marshal_shield.weapon.is_pistol.FALLOFF[5].dmg_mul = 0.1
	self.marshal_shield_break.HEALTH_INIT = 32
	self.marshal_shield_break.weapon.is_shotgun_mag.FALLOFF[1].dmg_mul = 1
	self.marshal_shield_break.weapon.is_shotgun_mag.FALLOFF[2].dmg_mul = 0.75
	self.marshal_shield_break.weapon.is_shotgun_mag.FALLOFF[3].dmg_mul = 0.5
	self.marshal_shield_break.weapon.is_shotgun_mag.FALLOFF[4].dmg_mul = 0.25
	self.marshal_shield_break.weapon.is_shotgun_mag.FALLOFF[5].dmg_mul = 0.1
	self.shield.melee_weapon_dmg_multiplier = 0.1
	self.swat.melee_weapon_dmg_multiplier = 0.1
	self.zeal_swat.melee_weapon_dmg_multiplier = 0.1
	self.cop.melee_weapon_dmg_multiplier = 0.1

	self:_multiply_weapon_delay(self.presets.weapon.normal, 0)
	self:_multiply_weapon_delay(self.presets.weapon.good, 0)
	self:_multiply_weapon_delay(self.presets.weapon.expert, 0)
	self:_multiply_weapon_delay(self.presets.weapon.sniper, 3)
	self:_multiply_weapon_delay(self.presets.weapon.gang_member, 0)

	self.swat.weapon.is_rifle.FALLOFF = {
		{
			dmg_mul = 1,
			r = 100,
			acc = {
				0.6,
				0.9
			},
			recoil = {
				0.4,
				0.8
			},
			mode = {
				0,
				3,
				3,
				1
			}
		},
		{
			dmg_mul = 0.5,
			r = 500,
			acc = {
				0.4,
				0.9
			},
			recoil = {
				0.45,
				0.8
			},
			mode = {
				0,
				3,
				3,
				1
			}
		},
		{
			dmg_mul = 0.5,
			r = 1000,
			acc = {
				0.2,
				0.8
			},
			recoil = {
				0.35,
				0.75
			},
			mode = {
				1,
				2,
				2,
				0
			}
		},
		{
			dmg_mul = 0.25,
			r = 2000,
			acc = {
				0.2,
				0.5
			},
			recoil = {
				0.4,
				1.2
			},
			mode = {
				3,
				2,
				2,
				0
			}
		},
		{
			dmg_mul = 0.1,
			r = 3000,
			acc = {
				0.01,
				0.35
			},
			recoil = {
				1.5,
				3
			},
			mode = {
				3,
				1,
				1,
				0
			}
		}
	}
	self.swat.weapon.is_shotgun_pump.FALLOFF = {
		{
			dmg_mul = 1.5,
			r = 100,
			acc = {
				0.6,
				0.9
			},
			recoil = {
				1.5,
				2
			},
			mode = {
				1,
				0,
				0,
				0
			}
		},
		{
			dmg_mul = 0.5,
			r = 500,
			acc = {
				0.4,
				0.9
			},
			recoil = {
				1.5,
				2
			},
			mode = {
				1,
				0,
				0,
				0
			}
		},
		{
			dmg_mul = 0.25,
			r = 1000,
			acc = {
				0.2,
				0.75
			},
			recoil = {
				1.5,
				2
			},
			mode = {
				1,
				0,
				0,
				0
			}
		},
		{
			dmg_mul = 0.25,
			r = 2000,
			acc = {
				0.01,
				0.25
			},
			recoil = {
				1.5,
				2
			},
			mode = {
				1,
				0,
				0,
				0
			}
		},
		{
			dmg_mul = 0.1,
			r = 3000,
			acc = {
				0.05,
				0.35
			},
			recoil = {
				1.5,
				2
			},
			mode = {
				1,
				0,
				0,
				0
			}
		}
	}
	self.zeal_swat.weapon.is_rifle.FALLOFF = {
		{
			dmg_mul = 1,
			r = 100,
			acc = {
				0.6,
				0.9
			},
			recoil = {
				0.4,
				0.8
			},
			mode = {
				0,
				3,
				3,
				1
			}
		},
		{
			dmg_mul = 0.5,
			r = 500,
			acc = {
				0.4,
				0.9
			},
			recoil = {
				0.45,
				0.8
			},
			mode = {
				0,
				3,
				3,
				1
			}
		},
		{
			dmg_mul = 0.5,
			r = 1000,
			acc = {
				0.2,
				0.8
			},
			recoil = {
				0.35,
				0.75
			},
			mode = {
				1,
				2,
				2,
				0
			}
		},
		{
			dmg_mul = 0.25,
			r = 2000,
			acc = {
				0.2,
				0.5
			},
			recoil = {
				0.4,
				1.2
			},
			mode = {
				3,
				2,
				2,
				0
			}
		},
		{
			dmg_mul = 0.1,
			r = 3000,
			acc = {
				0.01,
				0.35
			},
			recoil = {
				1.5,
				3
			},
			mode = {
				3,
				1,
				1,
				0
			}
		}
	}
	self.zeal_swat.weapon.is_shotgun_pump.FALLOFF = {
		{
			dmg_mul = 1.5,
			r = 100,
			acc = {
				0.6,
				0.9
			},
			recoil = {
				1.5,
				2
			},
			mode = {
				1,
				0,
				0,
				0
			}
		},
		{
			dmg_mul = 0.5,
			r = 500,
			acc = {
				0.4,
				0.9
			},
			recoil = {
				1.5,
				2
			},
			mode = {
				1,
				0,
				0,
				0
			}
		},
		{
			dmg_mul = 0.25,
			r = 1000,
			acc = {
				0.2,
				0.75
			},
			recoil = {
				1.5,
				2
			},
			mode = {
				1,
				0,
				0,
				0
			}
		},
		{
			dmg_mul = 0.25,
			r = 2000,
			acc = {
				0.01,
				0.25
			},
			recoil = {
				1.5,
				2
			},
			mode = {
				1,
				0,
				0,
				0
			}
		},
		{
			dmg_mul = 0.1,
			r = 3000,
			acc = {
				0.05,
				0.35
			},
			recoil = {
				1.5,
				2
			},
			mode = {
				1,
				0,
				0,
				0
			}
		}
	}
	self.heavy_swat.weapon.is_rifle.FALLOFF = {
		{
			dmg_mul = 1,
			r = 100,
			acc = {
				0.6,
				0.9
			},
			recoil = {
				0.4,
				0.8
			},
			mode = {
				0,
				3,
				3,
				1
			}
		},
		{
			dmg_mul = 0.5,
			r = 500,
			acc = {
				0.4,
				0.9
			},
			recoil = {
				0.45,
				0.8
			},
			mode = {
				0,
				3,
				3,
				1
			}
		},
		{
			dmg_mul = 0.5,
			r = 1000,
			acc = {
				0.2,
				0.8
			},
			recoil = {
				0.35,
				0.75
			},
			mode = {
				1,
				2,
				2,
				0
			}
		},
		{
			dmg_mul = 0.25,
			r = 2000,
			acc = {
				0.2,
				0.5
			},
			recoil = {
				0.4,
				1.2
			},
			mode = {
				3,
				2,
				2,
				0
			}
		},
		{
			dmg_mul = 0.1,
			r = 3000,
			acc = {
				0.01,
				0.35
			},
			recoil = {
				1.5,
				3
			},
			mode = {
				3,
				1,
				1,
				0
			}
		}
	}
	self.heavy_swat.weapon.is_shotgun_pump.FALLOFF = {
		{
			dmg_mul = 1.5,
			r = 100,
			acc = {
				0.6,
				0.9
			},
			recoil = {
				1.5,
				2
			},
			mode = {
				1,
				0,
				0,
				0
			}
		},
		{
			dmg_mul = 0.5,
			r = 500,
			acc = {
				0.4,
				0.9
			},
			recoil = {
				1.5,
				2
			},
			mode = {
				1,
				0,
				0,
				0
			}
		},
		{
			dmg_mul = 0.25,
			r = 1000,
			acc = {
				0.2,
				0.75
			},
			recoil = {
				1.5,
				2
			},
			mode = {
				1,
				0,
				0,
				0
			}
		},
		{
			dmg_mul = 0.25,
			r = 2000,
			acc = {
				0.01,
				0.25
			},
			recoil = {
				1.5,
				2
			},
			mode = {
				1,
				0,
				0,
				0
			}
		},
		{
			dmg_mul = 0.1,
			r = 3000,
			acc = {
				0.05,
				0.35
			},
			recoil = {
				1.5,
				2
			},
			mode = {
				1,
				0,
				0,
				0
			}
		}
	}
	self.zeal_heavy_swat.weapon.is_rifle.FALLOFF = {
		{
			dmg_mul = 1,
			r = 100,
			acc = {
				0.6,
				0.9
			},
			recoil = {
				0.4,
				0.8
			},
			mode = {
				0,
				3,
				3,
				1
			}
		},
		{
			dmg_mul = 0.5,
			r = 500,
			acc = {
				0.4,
				0.9
			},
			recoil = {
				0.45,
				0.8
			},
			mode = {
				0,
				3,
				3,
				1
			}
		},
		{
			dmg_mul = 0.5,
			r = 1000,
			acc = {
				0.2,
				0.8
			},
			recoil = {
				0.35,
				0.75
			},
			mode = {
				1,
				2,
				2,
				0
			}
		},
		{
			dmg_mul = 0.25,
			r = 2000,
			acc = {
				0.2,
				0.5
			},
			recoil = {
				0.4,
				1.2
			},
			mode = {
				3,
				2,
				2,
				0
			}
		},
		{
			dmg_mul = 0.1,
			r = 3000,
			acc = {
				0.01,
				0.35
			},
			recoil = {
				1.5,
				3
			},
			mode = {
				3,
				1,
				1,
				0
			}
		}
	}
	self.zeal_heavy_swat.weapon.is_shotgun_pump.FALLOFF = {
		{
			dmg_mul = 1.5,
			r = 100,
			acc = {
				0.6,
				0.9
			},
			recoil = {
				1.5,
				2
			},
			mode = {
				1,
				0,
				0,
				0
			}
		},
		{
			dmg_mul = 0.5,
			r = 500,
			acc = {
				0.4,
				0.9
			},
			recoil = {
				1.5,
				2
			},
			mode = {
				1,
				0,
				0,
				0
			}
		},
		{
			dmg_mul = 0.25,
			r = 1000,
			acc = {
				0.2,
				0.75
			},
			recoil = {
				1.5,
				2
			},
			mode = {
				1,
				0,
				0,
				0
			}
		},
		{
			dmg_mul = 0.25,
			r = 2000,
			acc = {
				0.01,
				0.25
			},
			recoil = {
				1.5,
				2
			},
			mode = {
				1,
				0,
				0,
				0
			}
		},
		{
			dmg_mul = 0.1,
			r = 3000,
			acc = {
				0.05,
				0.35
			},
			recoil = {
				1.5,
				2
			},
			mode = {
				1,
				0,
				0,
				0
			}
		}
	}
	self.hector_boss.weapon.is_shotgun_mag.FALLOFF = {
		{
			dmg_mul = 0.22,
			r = 200,
			acc = {
				0.6,
				0.9
			},
			recoil = {
				0.4,
				0.7
			},
			mode = {
				0,
				1,
				2,
				1
			}
		},
		{
			dmg_mul = 0.18,
			r = 500,
			acc = {
				0.6,
				0.9
			},
			recoil = {
				0.4,
				0.7
			},
			mode = {
				0,
				3,
				3,
				1
			}
		},
		{
			dmg_mul = 0.15,
			r = 1000,
			acc = {
				0.4,
				0.8
			},
			recoil = {
				0.45,
				0.8
			},
			mode = {
				1,
				2,
				2,
				0
			}
		},
		{
			dmg_mul = 0.13,
			r = 2000,
			acc = {
				0.4,
				0.55
			},
			recoil = {
				0.45,
				0.8
			},
			mode = {
				3,
				2,
				2,
				0
			}
		},
		{
			dmg_mul = 0.1,
			r = 3000,
			acc = {
				0.1,
				0.35
			},
			recoil = {
				1,
				1.2
			},
			mode = {
				3,
				1,
				1,
				0
			}
		}
	}
	self.hector_boss.HEALTH_INIT = 50
	self.mobster_boss.HEALTH_INIT = 50
	self.biker_boss.HEALTH_INIT = 100
	self.chavez_boss.HEALTH_INIT = 100
	self.triad_boss.player_health_scaling_mul = nil
	self.triad_boss.weapon.is_flamethrower.FALLOFF[1].dmg_mul = 0.6
	self.triad_boss.weapon.is_flamethrower.FALLOFF[2].dmg_mul = 0.5
	self.triad_boss.weapon.is_flamethrower.FALLOFF[3].dmg_mul = 0.4
	self.triad_boss.weapon.is_flamethrower.FALLOFF[4].dmg_mul = 0.2
	self.triad_boss.weapon.is_flamethrower.FALLOFF[5].dmg_mul = 0.1
	self.snowman_boss.player_health_scaling_mul = nil
	self.snowman_boss.weapon.is_flamethrower.FALLOFF[1].dmg_mul = 0.6
	self.snowman_boss.weapon.is_flamethrower.FALLOFF[2].dmg_mul = 0.5
	self.snowman_boss.weapon.is_flamethrower.FALLOFF[3].dmg_mul = 0.4
	self.snowman_boss.weapon.is_flamethrower.FALLOFF[4].dmg_mul = 0.2
	self.snowman_boss.weapon.is_flamethrower.FALLOFF[5].dmg_mul = 0.1
	self.piggydozer.player_health_scaling_mul = nil
	self.piggydozer.weapon.is_flamethrower.FALLOFF[1].dmg_mul = 0.6
	self.piggydozer.weapon.is_flamethrower.FALLOFF[2].dmg_mul = 0.5
	self.piggydozer.weapon.is_flamethrower.FALLOFF[3].dmg_mul = 0.4
	self.piggydozer.weapon.is_flamethrower.FALLOFF[4].dmg_mul = 0.2
	self.piggydozer.weapon.is_flamethrower.FALLOFF[5].dmg_mul = 0.1
	self.presets.gang_member_damage.REGENERATE_TIME = 1.5
	self.presets.gang_member_damage.REGENERATE_TIME_AWAY = 0.2
	self.presets.gang_member_damage.HEALTH_INIT = 200
	self.presets.gang_member_damage.BLEED_OUT_HEALTH_INIT = self.presets.gang_member_damage.HEALTH_INIT * 0.1

	self:_set_characters_weapon_preset("normal")

	self.presets.weapon.gang_member.is_pistol.FALLOFF[1].dmg_mul = 2
	self.presets.weapon.gang_member.is_pistol.FALLOFF[2].dmg_mul = 1
	self.presets.weapon.gang_member.is_revolver.FALLOFF[1].dmg_mul = 2
	self.presets.weapon.gang_member.is_revolver.FALLOFF[2].dmg_mul = 1
	self.presets.weapon.gang_member.is_rifle.FALLOFF[1].dmg_mul = 2
	self.presets.weapon.gang_member.is_rifle.FALLOFF[2].dmg_mul = 1
	self.presets.weapon.gang_member.is_sniper.FALLOFF[1].dmg_mul = 4
	self.presets.weapon.gang_member.is_sniper.FALLOFF[2].dmg_mul = 4
	self.presets.weapon.gang_member.is_sniper.FALLOFF[3].dmg_mul = 4
	self.presets.weapon.gang_member.is_sniper.FALLOFF[4].dmg_mul = 2
	self.presets.weapon.gang_member.is_sniper.FALLOFF[5].dmg_mul = 2
	self.presets.weapon.gang_member.is_lmg.FALLOFF[1].dmg_mul = 2
	self.presets.weapon.gang_member.is_lmg.FALLOFF[2].dmg_mul = 1.5
	self.presets.weapon.gang_member.is_lmg.FALLOFF[3].dmg_mul = 1
	self.presets.weapon.gang_member.is_lmg.FALLOFF[4].dmg_mul = 0.5
	self.presets.weapon.gang_member.is_lmg.FALLOFF[5].dmg_mul = 0.3
	self.presets.weapon.gang_member.is_lmg.FALLOFF[6].dmg_mul = 0.1
	self.presets.weapon.gang_member.is_shotgun_pump.FALLOFF[1].dmg_mul = 2
	self.presets.weapon.gang_member.is_shotgun_pump.FALLOFF[2].dmg_mul = 1
	self.presets.weapon.gang_member.is_shotgun_mag.FALLOFF[1].dmg_mul = 2
	self.presets.weapon.gang_member.is_shotgun_mag.FALLOFF[2].dmg_mul = 2
	self.presets.weapon.gang_member.is_shotgun_mag.FALLOFF[3].dmg_mul = 1
	self.presets.weapon.gang_member.is_shotgun_mag.FALLOFF[4].dmg_mul = 0.75
	self.presets.weapon.gang_member.is_shotgun_mag.FALLOFF[5].dmg_mul = 0.25
	self.presets.weapon.gang_member.is_shotgun_mag.FALLOFF[6].dmg_mul = 0.1
	self.presets.weapon.gang_member.is_smg = self.presets.weapon.gang_member.is_rifle
	self.presets.weapon.gang_member.mac11 = self.presets.weapon.gang_member.is_smg
	self.presets.weapon.gang_member.rifle = deep_clone(self.presets.weapon.gang_member.is_rifle)
	self.presets.weapon.gang_member.rifle.autofire_rounds = nil
	self.presets.weapon.gang_member.akimbo_pistol = self.presets.weapon.gang_member.is_pistol
	self.flashbang_multiplier = 1
	self.concussion_multiplier = 1

	self:_process_weapon_usage_table()
end

function CharacterTweakData:_set_hard()
	self:_multiply_all_hp(1, 1)
	self:_multiply_all_speeds(2.05, 2.1)

	self.marshal_marksman.weapon.is_rifle.FALLOFF[1].dmg_mul = 0.45
	self.marshal_marksman.weapon.is_rifle.FALLOFF[2].dmg_mul = 0.67
	self.marshal_marksman.weapon.is_rifle.FALLOFF[3].dmg_mul = 1
	self.marshal_marksman.weapon.is_rifle.FALLOFF[4].dmg_mul = 1.35
	self.marshal_marksman.weapon.is_rifle.FALLOFF[5].dmg_mul = 1
	self.marshal_marksman.HEALTH_INIT = 6
	self.marshal_marksman.headshot_dmg_mul = self.marshal_marksman.HEALTH_INIT / 1.25
	self.marshal_shield.weapon.is_pistol.FALLOFF[1].dmg_mul = 2
	self.marshal_shield.weapon.is_pistol.FALLOFF[2].dmg_mul = 1
	self.marshal_shield.weapon.is_pistol.FALLOFF[3].dmg_mul = 0.5
	self.marshal_shield.weapon.is_pistol.FALLOFF[4].dmg_mul = 0.25
	self.marshal_shield.weapon.is_pistol.FALLOFF[5].dmg_mul = 0.1
	self.marshal_shield_break.weapon.is_shotgun_mag.FALLOFF[1].dmg_mul = 3
	self.marshal_shield_break.weapon.is_shotgun_mag.FALLOFF[2].dmg_mul = 2
	self.marshal_shield_break.weapon.is_shotgun_mag.FALLOFF[3].dmg_mul = 1
	self.marshal_shield_break.weapon.is_shotgun_mag.FALLOFF[4].dmg_mul = 0.5
	self.marshal_shield_break.weapon.is_shotgun_mag.FALLOFF[5].dmg_mul = 0.25
	self.shield.melee_weapon_dmg_multiplier = 0.1
	self.swat.melee_weapon_dmg_multiplier = 0.1
	self.cop.melee_weapon_dmg_multiplier = 0.1

	self:_multiply_weapon_delay(self.presets.weapon.normal, 0)
	self:_multiply_weapon_delay(self.presets.weapon.good, 0)
	self:_multiply_weapon_delay(self.presets.weapon.expert, 0)
	self:_multiply_weapon_delay(self.presets.weapon.sniper, 3)
	self:_multiply_weapon_delay(self.presets.weapon.gang_member, 0)

	self.hector_boss.weapon.is_shotgun_mag.FALLOFF = {
		{
			dmg_mul = 0.44,
			r = 200,
			acc = {
				0.6,
				0.9
			},
			recoil = {
				0.4,
				0.7
			},
			mode = {
				0,
				1,
				2,
				1
			}
		},
		{
			dmg_mul = 0.35,
			r = 500,
			acc = {
				0.6,
				0.9
			},
			recoil = {
				0.4,
				0.7
			},
			mode = {
				0,
				3,
				3,
				1
			}
		},
		{
			dmg_mul = 0.3,
			r = 1000,
			acc = {
				0.4,
				0.8
			},
			recoil = {
				0.45,
				0.8
			},
			mode = {
				1,
				2,
				2,
				0
			}
		},
		{
			dmg_mul = 0.25,
			r = 2000,
			acc = {
				0.4,
				0.55
			},
			recoil = {
				0.45,
				0.8
			},
			mode = {
				3,
				2,
				2,
				0
			}
		},
		{
			dmg_mul = 0.2,
			r = 3000,
			acc = {
				0.1,
				0.35
			},
			recoil = {
				1,
				1.2
			},
			mode = {
				3,
				1,
				1,
				0
			}
		}
	}
	self.hector_boss.HEALTH_INIT = 100
	self.mobster_boss.HEALTH_INIT = 100
	self.biker_boss.HEALTH_INIT = 100
	self.chavez_boss.HEALTH_INIT = 100
	self.triad_boss.weapon.is_flamethrower.FALLOFF[1].dmg_mul = 1
	self.triad_boss.weapon.is_flamethrower.FALLOFF[2].dmg_mul = 0.6
	self.triad_boss.weapon.is_flamethrower.FALLOFF[3].dmg_mul = 0.4
	self.triad_boss.weapon.is_flamethrower.FALLOFF[4].dmg_mul = 0.2
	self.triad_boss.weapon.is_flamethrower.FALLOFF[5].dmg_mul = 0.1
	self.snowman_boss.weapon.is_flamethrower.FALLOFF[1].dmg_mul = 1
	self.snowman_boss.weapon.is_flamethrower.FALLOFF[2].dmg_mul = 0.6
	self.snowman_boss.weapon.is_flamethrower.FALLOFF[3].dmg_mul = 0.4
	self.snowman_boss.weapon.is_flamethrower.FALLOFF[4].dmg_mul = 0.2
	self.snowman_boss.weapon.is_flamethrower.FALLOFF[5].dmg_mul = 0.1
	self.piggydozer.weapon.is_flamethrower.FALLOFF[1].dmg_mul = 1
	self.piggydozer.weapon.is_flamethrower.FALLOFF[2].dmg_mul = 0.6
	self.piggydozer.weapon.is_flamethrower.FALLOFF[3].dmg_mul = 0.4
	self.piggydozer.weapon.is_flamethrower.FALLOFF[4].dmg_mul = 0.2
	self.piggydozer.weapon.is_flamethrower.FALLOFF[5].dmg_mul = 0.1
	self.presets.gang_member_damage.REGENERATE_TIME = 2
	self.presets.gang_member_damage.REGENERATE_TIME_AWAY = 0.4

	self:_set_characters_weapon_preset("normal")

	self.presets.gang_member_damage.HEALTH_INIT = 200
	self.presets.gang_member_damage.BLEED_OUT_HEALTH_INIT = self.presets.gang_member_damage.HEALTH_INIT * 0.1
	self.presets.weapon.gang_member.is_pistol.FALLOFF[1].dmg_mul = 2
	self.presets.weapon.gang_member.is_pistol.FALLOFF[2].dmg_mul = 1
	self.presets.weapon.gang_member.is_revolver.FALLOFF[1].dmg_mul = 2
	self.presets.weapon.gang_member.is_revolver.FALLOFF[2].dmg_mul = 1
	self.presets.weapon.gang_member.is_rifle.FALLOFF[1].dmg_mul = 2
	self.presets.weapon.gang_member.is_rifle.FALLOFF[2].dmg_mul = 1
	self.presets.weapon.gang_member.is_sniper.FALLOFF[1].dmg_mul = 4
	self.presets.weapon.gang_member.is_sniper.FALLOFF[2].dmg_mul = 4
	self.presets.weapon.gang_member.is_sniper.FALLOFF[3].dmg_mul = 4
	self.presets.weapon.gang_member.is_sniper.FALLOFF[4].dmg_mul = 2
	self.presets.weapon.gang_member.is_sniper.FALLOFF[5].dmg_mul = 2
	self.presets.weapon.gang_member.is_lmg.FALLOFF[1].dmg_mul = 2
	self.presets.weapon.gang_member.is_lmg.FALLOFF[2].dmg_mul = 1.5
	self.presets.weapon.gang_member.is_lmg.FALLOFF[3].dmg_mul = 1
	self.presets.weapon.gang_member.is_lmg.FALLOFF[4].dmg_mul = 0.5
	self.presets.weapon.gang_member.is_lmg.FALLOFF[5].dmg_mul = 0.3
	self.presets.weapon.gang_member.is_lmg.FALLOFF[6].dmg_mul = 0.1
	self.presets.weapon.gang_member.is_shotgun_pump.FALLOFF[1].dmg_mul = 2
	self.presets.weapon.gang_member.is_shotgun_pump.FALLOFF[2].dmg_mul = 1
	self.presets.weapon.gang_member.is_shotgun_mag.FALLOFF[1].dmg_mul = 2
	self.presets.weapon.gang_member.is_shotgun_mag.FALLOFF[2].dmg_mul = 2
	self.presets.weapon.gang_member.is_shotgun_mag.FALLOFF[3].dmg_mul = 1
	self.presets.weapon.gang_member.is_shotgun_mag.FALLOFF[4].dmg_mul = 0.75
	self.presets.weapon.gang_member.is_shotgun_mag.FALLOFF[5].dmg_mul = 0.25
	self.presets.weapon.gang_member.is_shotgun_mag.FALLOFF[6].dmg_mul = 0.1
	self.presets.weapon.gang_member.is_smg = self.presets.weapon.gang_member.is_rifle
	self.presets.weapon.gang_member.mac11 = self.presets.weapon.gang_member.is_smg
	self.presets.weapon.gang_member.rifle = deep_clone(self.presets.weapon.gang_member.is_rifle)
	self.presets.weapon.gang_member.rifle.autofire_rounds = nil
	self.presets.weapon.gang_member.akimbo_pistol = self.presets.weapon.gang_member.is_pistol
	self.flashbang_multiplier = 1.25
	self.concussion_multiplier = 1
	self.shadow_spooc.shadow_spooc_attack_timeout = {
		8,
		10
	}
	self.spooc.spooc_attack_timeout = {
		8,
		10
	}
	self.sniper.weapon.is_rifle.FALLOFF = {
		{
			dmg_mul = 7,
			r = 700,
			acc = {
				0.6,
				1
			},
			recoil = {
				3,
				5
			},
			mode = {
				1,
				0,
				0,
				0
			}
		},
		{
			dmg_mul = 6,
			r = 4000,
			acc = {
				0.5,
				0.9
			},
			recoil = {
				4,
				5
			},
			mode = {
				1,
				0,
				0,
				0
			}
		},
		{
			dmg_mul = 3,
			r = 10000,
			acc = {
				0,
				0.3
			},
			recoil = {
				4,
				6
			},
			mode = {
				1,
				0,
				0,
				0
			}
		}
	}

	self:_process_weapon_usage_table()
end

function CharacterTweakData:_set_overkill()
	self:_multiply_all_hp(3, 3)
	self:_multiply_all_speeds(2.05, 2.1)
	self:_multiply_weapon_delay(self.presets.weapon.normal, 0)
	self:_multiply_weapon_delay(self.presets.weapon.good, 0)
	self:_multiply_weapon_delay(self.presets.weapon.expert, 0)
	self:_multiply_weapon_delay(self.presets.weapon.sniper, 3)
	self:_multiply_weapon_delay(self.presets.weapon.gang_member, 0)

	self.marshal_marksman.weapon.is_rifle.FALLOFF[1].dmg_mul = 0.5
	self.marshal_marksman.weapon.is_rifle.FALLOFF[2].dmg_mul = 1
	self.marshal_marksman.weapon.is_rifle.FALLOFF[3].dmg_mul = 1.5
	self.marshal_marksman.weapon.is_rifle.FALLOFF[4].dmg_mul = 2
	self.marshal_marksman.weapon.is_rifle.FALLOFF[5].dmg_mul = 1.5
	self.marshal_marksman.HEALTH_INIT = 12
	self.marshal_marksman.headshot_dmg_mul = self.marshal_marksman.HEALTH_INIT / 1.25
	self.marshal_shield.weapon.is_pistol.FALLOFF[1].dmg_mul = 3
	self.marshal_shield.weapon.is_pistol.FALLOFF[2].dmg_mul = 2
	self.marshal_shield.weapon.is_pistol.FALLOFF[3].dmg_mul = 1.5
	self.marshal_shield.weapon.is_pistol.FALLOFF[4].dmg_mul = 1
	self.marshal_shield.weapon.is_pistol.FALLOFF[5].dmg_mul = 0.5
	self.marshal_shield_break.weapon.is_shotgun_mag.FALLOFF[1].dmg_mul = 5
	self.marshal_shield_break.weapon.is_shotgun_mag.FALLOFF[2].dmg_mul = 4.25
	self.marshal_shield_break.weapon.is_shotgun_mag.FALLOFF[3].dmg_mul = 3.5
	self.marshal_shield_break.weapon.is_shotgun_mag.FALLOFF[4].dmg_mul = 1
	self.marshal_shield_break.weapon.is_shotgun_mag.FALLOFF[5].dmg_mul = 0.5
	self.hector_boss.weapon.is_shotgun_mag.FALLOFF = {
		{
			dmg_mul = 1.1,
			r = 200,
			acc = {
				0.6,
				0.9
			},
			recoil = {
				0.4,
				0.7
			},
			mode = {
				0,
				1,
				2,
				1
			}
		},
		{
			dmg_mul = 0.88,
			r = 500,
			acc = {
				0.6,
				0.9
			},
			recoil = {
				0.4,
				0.7
			},
			mode = {
				0,
				3,
				3,
				1
			}
		},
		{
			dmg_mul = 0.75,
			r = 1000,
			acc = {
				0.4,
				0.8
			},
			recoil = {
				0.45,
				0.8
			},
			mode = {
				1,
				2,
				2,
				0
			}
		},
		{
			dmg_mul = 0.63,
			r = 2000,
			acc = {
				0.4,
				0.55
			},
			recoil = {
				0.45,
				0.8
			},
			mode = {
				3,
				2,
				2,
				0
			}
		},
		{
			dmg_mul = 0.5,
			r = 3000,
			acc = {
				0.1,
				0.35
			},
			recoil = {
				1,
				1.2
			},
			mode = {
				3,
				1,
				1,
				0
			}
		}
	}
	self.hector_boss.HEALTH_INIT = 300
	self.mobster_boss.HEALTH_INIT = 300
	self.biker_boss.HEALTH_INIT = 300
	self.chavez_boss.HEALTH_INIT = 300
	self.triad_boss.weapon.is_flamethrower.FALLOFF[1].dmg_mul = 1.8
	self.triad_boss.weapon.is_flamethrower.FALLOFF[2].dmg_mul = 1.6
	self.triad_boss.weapon.is_flamethrower.FALLOFF[3].dmg_mul = 1.4
	self.triad_boss.weapon.is_flamethrower.FALLOFF[4].dmg_mul = 1.2
	self.triad_boss.weapon.is_flamethrower.FALLOFF[5].dmg_mul = 1.1
	self.snowman_boss.weapon.is_flamethrower.FALLOFF[1].dmg_mul = 1.8
	self.snowman_boss.weapon.is_flamethrower.FALLOFF[2].dmg_mul = 1.6
	self.snowman_boss.weapon.is_flamethrower.FALLOFF[3].dmg_mul = 1.4
	self.snowman_boss.weapon.is_flamethrower.FALLOFF[4].dmg_mul = 1.2
	self.snowman_boss.weapon.is_flamethrower.FALLOFF[5].dmg_mul = 1.1
	self.piggydozer.weapon.is_flamethrower.FALLOFF[1].dmg_mul = 1.8
	self.piggydozer.weapon.is_flamethrower.FALLOFF[2].dmg_mul = 1.6
	self.piggydozer.weapon.is_flamethrower.FALLOFF[3].dmg_mul = 1.4
	self.piggydozer.weapon.is_flamethrower.FALLOFF[4].dmg_mul = 1.2
	self.piggydozer.weapon.is_flamethrower.FALLOFF[5].dmg_mul = 1.1
	self.phalanx_minion.HEALTH_INIT = 150
	self.phalanx_minion.DAMAGE_CLAMP_BULLET = 15
	self.phalanx_minion.DAMAGE_CLAMP_EXPLOSION = self.phalanx_minion.DAMAGE_CLAMP_BULLET
	self.phalanx_vip.HEALTH_INIT = 300
	self.phalanx_vip.DAMAGE_CLAMP_BULLET = 30
	self.phalanx_vip.DAMAGE_CLAMP_EXPLOSION = self.phalanx_vip.DAMAGE_CLAMP_BULLET
	self.presets.gang_member_damage.REGENERATE_TIME = 2
	self.presets.gang_member_damage.REGENERATE_TIME_AWAY = 0.6
	self.presets.gang_member_damage.HEALTH_INIT = 300
	self.presets.gang_member_damage.BLEED_OUT_HEALTH_INIT = self.presets.gang_member_damage.HEALTH_INIT * 0.1
	self.presets.weapon.gang_member.is_pistol.FALLOFF[1].dmg_mul = 1.6
	self.presets.weapon.gang_member.is_pistol.FALLOFF[2].dmg_mul = 3.5
	self.presets.weapon.gang_member.is_revolver.FALLOFF[1].dmg_mul = 3.5
	self.presets.weapon.gang_member.is_revolver.FALLOFF[2].dmg_mul = 1.6
	self.presets.weapon.gang_member.is_rifle.FALLOFF[1].dmg_mul = 3.5
	self.presets.weapon.gang_member.is_rifle.FALLOFF[2].dmg_mul = 1.6
	self.presets.weapon.gang_member.is_sniper.FALLOFF[1].dmg_mul = 7
	self.presets.weapon.gang_member.is_sniper.FALLOFF[2].dmg_mul = 7
	self.presets.weapon.gang_member.is_sniper.FALLOFF[3].dmg_mul = 7
	self.presets.weapon.gang_member.is_sniper.FALLOFF[4].dmg_mul = 3.5
	self.presets.weapon.gang_member.is_sniper.FALLOFF[5].dmg_mul = 3.5
	self.presets.weapon.gang_member.is_lmg.FALLOFF[1].dmg_mul = 3
	self.presets.weapon.gang_member.is_lmg.FALLOFF[2].dmg_mul = 2
	self.presets.weapon.gang_member.is_lmg.FALLOFF[3].dmg_mul = 1.5
	self.presets.weapon.gang_member.is_lmg.FALLOFF[4].dmg_mul = 1
	self.presets.weapon.gang_member.is_lmg.FALLOFF[5].dmg_mul = 0.66
	self.presets.weapon.gang_member.is_lmg.FALLOFF[6].dmg_mul = 0.2
	self.presets.weapon.gang_member.is_shotgun_pump.FALLOFF[1].dmg_mul = 3.5
	self.presets.weapon.gang_member.is_shotgun_pump.FALLOFF[2].dmg_mul = 1.6
	self.presets.weapon.gang_member.is_shotgun_mag.FALLOFF[1].dmg_mul = 3.5
	self.presets.weapon.gang_member.is_shotgun_mag.FALLOFF[2].dmg_mul = 3.5
	self.presets.weapon.gang_member.is_shotgun_mag.FALLOFF[3].dmg_mul = 1.5
	self.presets.weapon.gang_member.is_shotgun_mag.FALLOFF[4].dmg_mul = 1
	self.presets.weapon.gang_member.is_shotgun_mag.FALLOFF[5].dmg_mul = 0.5
	self.presets.weapon.gang_member.is_shotgun_mag.FALLOFF[6].dmg_mul = 0.2
	self.presets.weapon.gang_member.is_smg = self.presets.weapon.gang_member.is_rifle
	self.presets.weapon.gang_member.mac11 = self.presets.weapon.gang_member.is_smg
	self.presets.weapon.gang_member.rifle = deep_clone(self.presets.weapon.gang_member.is_rifle)
	self.presets.weapon.gang_member.rifle.autofire_rounds = nil
	self.presets.weapon.gang_member.akimbo_pistol = self.presets.weapon.gang_member.is_pistol

	self:_set_characters_weapon_preset("good")

	self.shadow_spooc.shadow_spooc_attack_timeout = {
		6,
		8
	}
	self.spooc.spooc_attack_timeout = {
		6,
		8
	}
	self.sniper.weapon.is_rifle.FALLOFF = {
		{
			dmg_mul = 8,
			r = 700,
			acc = {
				0.7,
				1
			},
			recoil = {
				3,
				6
			},
			mode = {
				1,
				0,
				0,
				0
			}
		},
		{
			dmg_mul = 6,
			r = 4000,
			acc = {
				0.5,
				0.95
			},
			recoil = {
				4,
				6
			},
			mode = {
				1,
				0,
				0,
				0
			}
		},
		{
			dmg_mul = 3.5,
			r = 10000,
			acc = {
				0,
				0.3
			},
			recoil = {
				4,
				6
			},
			mode = {
				1,
				0,
				0,
				0
			}
		}
	}
	self.flashbang_multiplier = 1.5
	self.concussion_multiplier = 1

	self:_process_weapon_usage_table()
end

function CharacterTweakData:_set_overkill_145()
	if SystemInfo:platform() == Idstring("PS3") then
		self:_multiply_all_hp(3, 3)
	else
		self:_multiply_all_hp(3, 3)
	end

	self.marshal_marksman.HEALTH_INIT = 18
	self.marshal_marksman.headshot_dmg_mul = self.marshal_marksman.HEALTH_INIT / 1.25
	self.hector_boss.weapon.is_shotgun_mag.FALLOFF = {
		{
			dmg_mul = 2.2,
			r = 200,
			acc = {
				0.6,
				0.9
			},
			recoil = {
				0.4,
				0.7
			},
			mode = {
				0,
				1,
				2,
				1
			}
		},
		{
			dmg_mul = 1.75,
			r = 500,
			acc = {
				0.6,
				0.9
			},
			recoil = {
				0.4,
				0.7
			},
			mode = {
				0,
				3,
				3,
				1
			}
		},
		{
			dmg_mul = 1.5,
			r = 1000,
			acc = {
				0.4,
				0.8
			},
			recoil = {
				0.45,
				0.8
			},
			mode = {
				1,
				2,
				2,
				0
			}
		},
		{
			dmg_mul = 1.25,
			r = 2000,
			acc = {
				0.4,
				0.55
			},
			recoil = {
				0.45,
				0.8
			},
			mode = {
				3,
				2,
				2,
				0
			}
		},
		{
			dmg_mul = 1,
			r = 3000,
			acc = {
				0.1,
				0.35
			},
			recoil = {
				1,
				1.2
			},
			mode = {
				3,
				1,
				1,
				0
			}
		}
	}
	self.hector_boss.HEALTH_INIT = 600
	self.mobster_boss.HEALTH_INIT = 600
	self.biker_boss.HEALTH_INIT = 1800
	self.chavez_boss.HEALTH_INIT = 600
	self.phalanx_minion.HEALTH_INIT = 300
	self.phalanx_minion.DAMAGE_CLAMP_BULLET = 30
	self.phalanx_minion.DAMAGE_CLAMP_EXPLOSION = self.phalanx_minion.DAMAGE_CLAMP_BULLET
	self.phalanx_vip.HEALTH_INIT = 600
	self.phalanx_vip.DAMAGE_CLAMP_BULLET = 60
	self.phalanx_vip.DAMAGE_CLAMP_EXPLOSION = self.phalanx_vip.DAMAGE_CLAMP_BULLET

	self:_multiply_all_speeds(1.05, 1.05)
	self:_multiply_weapon_delay(self.presets.weapon.normal, 0)
	self:_multiply_weapon_delay(self.presets.weapon.good, 0)
	self:_multiply_weapon_delay(self.presets.weapon.expert, 0)
	self:_multiply_weapon_delay(self.presets.weapon.sniper, 3)
	self:_multiply_weapon_delay(self.presets.weapon.gang_member, 0)

	self.marshal_marksman.weapon.is_rifle.focus_delay = 3
	self.presets.gang_member_damage.REGENERATE_TIME = 2
	self.presets.gang_member_damage.REGENERATE_TIME_AWAY = 0.6
	self.presets.gang_member_damage.HEALTH_INIT = 400
	self.presets.gang_member_damage.BLEED_OUT_HEALTH_INIT = self.presets.gang_member_damage.HEALTH_INIT * 0.1

	self:_set_characters_weapon_preset("expert")

	self.shadow_spooc.shadow_spooc_attack_timeout = {
		3.5,
		5
	}
	self.spooc.spooc_attack_timeout = {
		3.5,
		5
	}
	self.sniper.weapon.is_rifle.FALLOFF = {
		{
			dmg_mul = 10,
			r = 700,
			acc = {
				0.7,
				1
			},
			recoil = {
				3,
				5
			},
			mode = {
				1,
				0,
				0,
				0
			}
		},
		{
			dmg_mul = 10,
			r = 4000,
			acc = {
				0.6,
				0.95
			},
			recoil = {
				3,
				5
			},
			mode = {
				1,
				0,
				0,
				0
			}
		},
		{
			dmg_mul = 6,
			r = 10000,
			acc = {
				0.2,
				0.5
			},
			recoil = {
				3,
				5
			},
			mode = {
				1,
				0,
				0,
				0
			}
		}
	}
	self.flashbang_multiplier = 1.75
	self.concussion_multiplier = 1

	self:_process_weapon_usage_table()
end

function CharacterTweakData:_set_easy_wish()
	if SystemInfo:platform() == Idstring("PS3") then
		self:_multiply_all_hp(6, 2)
	else
		self:_multiply_all_hp(6, 2)
	end

	self.marshal_marksman.weapon.is_rifle.FALLOFF[1].dmg_mul = 1.55
	self.marshal_marksman.weapon.is_rifle.FALLOFF[2].dmg_mul = 2.5
	self.marshal_marksman.weapon.is_rifle.FALLOFF[3].dmg_mul = 3.75
	self.marshal_marksman.weapon.is_rifle.FALLOFF[4].dmg_mul = 5
	self.marshal_marksman.weapon.is_rifle.FALLOFF[5].dmg_mul = 3.75
	self.marshal_marksman.HEALTH_INIT = 36
	self.marshal_marksman.headshot_dmg_mul = 12 / 1.25
	self.marshal_shield.weapon.is_pistol.FALLOFF[1].dmg_mul = 5
	self.marshal_shield.weapon.is_pistol.FALLOFF[2].dmg_mul = 4
	self.marshal_shield.weapon.is_pistol.FALLOFF[3].dmg_mul = 3
	self.marshal_shield.weapon.is_pistol.FALLOFF[4].dmg_mul = 2
	self.marshal_shield.weapon.is_pistol.FALLOFF[5].dmg_mul = 1.25
	self.marshal_shield_break.weapon.is_shotgun_mag.FALLOFF[1].dmg_mul = 7
	self.marshal_shield_break.weapon.is_shotgun_mag.FALLOFF[2].dmg_mul = 6.5
	self.marshal_shield_break.weapon.is_shotgun_mag.FALLOFF[3].dmg_mul = 5.5
	self.marshal_shield_break.weapon.is_shotgun_mag.FALLOFF[4].dmg_mul = 2
	self.marshal_shield_break.weapon.is_shotgun_mag.FALLOFF[5].dmg_mul = 1.5
	self.hector_boss.HEALTH_INIT = 900
	self.mobster_boss.HEALTH_INIT = 900
	self.biker_boss.HEALTH_INIT = 3000
	self.chavez_boss.HEALTH_INIT = 900

	self:_multiply_all_speeds(2.05, 2.1)
	self:_multiply_weapon_delay(self.presets.weapon.normal, 0)
	self:_multiply_weapon_delay(self.presets.weapon.good, 0)
	self:_multiply_weapon_delay(self.presets.weapon.expert, 0)
	self:_multiply_weapon_delay(self.presets.weapon.sniper, 3)
	self:_multiply_weapon_delay(self.presets.weapon.gang_member, 0)

	self.presets.gang_member_damage.REGENERATE_TIME = 1.8
	self.presets.gang_member_damage.REGENERATE_TIME_AWAY = 0.6
	self.presets.gang_member_damage.HEALTH_INIT = 400
	self.presets.gang_member_damage.BLEED_OUT_HEALTH_INIT = self.presets.gang_member_damage.HEALTH_INIT * 0.1
	self.presets.weapon.gang_member.is_pistol.FALLOFF[1].dmg_mul = 10
	self.presets.weapon.gang_member.is_pistol.FALLOFF[2].dmg_mul = 5
	self.presets.weapon.gang_member.is_revolver.FALLOFF[1].dmg_mul = 10
	self.presets.weapon.gang_member.is_revolver.FALLOFF[2].dmg_mul = 5
	self.presets.weapon.gang_member.is_rifle.FALLOFF[1].dmg_mul = 10
	self.presets.weapon.gang_member.is_rifle.FALLOFF[2].dmg_mul = 5
	self.presets.weapon.gang_member.is_sniper.FALLOFF[1].dmg_mul = 20
	self.presets.weapon.gang_member.is_sniper.FALLOFF[2].dmg_mul = 20
	self.presets.weapon.gang_member.is_sniper.FALLOFF[3].dmg_mul = 20
	self.presets.weapon.gang_member.is_sniper.FALLOFF[4].dmg_mul = 10
	self.presets.weapon.gang_member.is_sniper.FALLOFF[5].dmg_mul = 10
	self.presets.weapon.gang_member.is_lmg.FALLOFF[1].dmg_mul = 10
	self.presets.weapon.gang_member.is_lmg.FALLOFF[2].dmg_mul = 7.5
	self.presets.weapon.gang_member.is_lmg.FALLOFF[3].dmg_mul = 5
	self.presets.weapon.gang_member.is_lmg.FALLOFF[4].dmg_mul = 3
	self.presets.weapon.gang_member.is_lmg.FALLOFF[5].dmg_mul = 2
	self.presets.weapon.gang_member.is_lmg.FALLOFF[6].dmg_mul = 0.5
	self.presets.weapon.gang_member.is_shotgun_pump.FALLOFF[1].dmg_mul = 10
	self.presets.weapon.gang_member.is_shotgun_pump.FALLOFF[2].dmg_mul = 5
	self.presets.weapon.gang_member.is_shotgun_mag.FALLOFF[1].dmg_mul = 10
	self.presets.weapon.gang_member.is_shotgun_mag.FALLOFF[2].dmg_mul = 8
	self.presets.weapon.gang_member.is_shotgun_mag.FALLOFF[3].dmg_mul = 7
	self.presets.weapon.gang_member.is_shotgun_mag.FALLOFF[4].dmg_mul = 5
	self.presets.weapon.gang_member.is_shotgun_mag.FALLOFF[5].dmg_mul = 2
	self.presets.weapon.gang_member.is_shotgun_mag.FALLOFF[6].dmg_mul = 0.4
	self.presets.weapon.gang_member.is_smg = self.presets.weapon.gang_member.is_rifle
	self.presets.weapon.gang_member.is_rifle = self.presets.weapon.gang_member.is_rifle
	self.presets.weapon.gang_member.mac11 = self.presets.weapon.gang_member.is_smg
	self.presets.weapon.gang_member.rifle = deep_clone(self.presets.weapon.gang_member.is_rifle)
	self.presets.weapon.gang_member.rifle.autofire_rounds = nil
	self.presets.weapon.gang_member.akimbo_pistol = self.presets.weapon.gang_member.is_pistol

	self:_set_characters_weapon_preset("expert")

	self.shadow_spooc.shadow_spooc_attack_timeout = {
		3,
		4
	}
	self.spooc.spooc_attack_timeout = {
		3,
		4
	}
	self.sniper.weapon.is_rifle.FALLOFF = {
		{
			dmg_mul = 10,
			r = 700,
			acc = {
				0.7,
				1
			},
			recoil = {
				3,
				5
			},
			mode = {
				1,
				0,
				0,
				0
			}
		},
		{
			dmg_mul = 10,
			r = 4000,
			acc = {
				0.6,
				0.95
			},
			recoil = {
				3,
				5
			},
			mode = {
				1,
				0,
				0,
				0
			}
		},
		{
			dmg_mul = 5,
			r = 10000,
			acc = {
				0.2,
				0.8
			},
			recoil = {
				3,
				5
			},
			mode = {
				1,
				0,
				0,
				0
			}
		}
	}
	self.tank.weapon.is_lmg.aim_delay = {
		0,
		0
	}
	self.tank.weapon.is_lmg.focus_delay = 0
	self.tank_mini.weapon.mini.aim_delay = {
		0,
		0
	}
	self.tank_mini.weapon.mini.focus_delay = 0
	self.shield.weapon.is_smg.aim_delay = {
		0,
		0
	}
	self.shield.weapon.is_smg.focus_delay = 0
	self.shield.weapon.is_pistol.aim_delay = {
		0,
		0
	}
	self.shield.weapon.is_pistol.focus_delay = 0
	self.city_swat.damage.explosion_damage_mul = 1
	self.phalanx_minion.HEALTH_INIT = 400
	self.phalanx_minion.DAMAGE_CLAMP_BULLET = 40
	self.phalanx_minion.DAMAGE_CLAMP_EXPLOSION = self.phalanx_minion.DAMAGE_CLAMP_BULLET
	self.phalanx_vip.HEALTH_INIT = 800
	self.phalanx_vip.DAMAGE_CLAMP_BULLET = 80
	self.phalanx_vip.DAMAGE_CLAMP_EXPLOSION = self.phalanx_vip.DAMAGE_CLAMP_BULLET
	self.flashbang_multiplier = 2
	self.concussion_multiplier = 1

	self:_process_weapon_usage_table()
end

function CharacterTweakData:_set_overkill_290()
	if SystemInfo:platform() == Idstring("PS3") then
		self:_multiply_all_hp(6, 1.5)
	else
		self:_multiply_all_hp(6, 1.5)
	end

	self.marshal_marksman.weapon.is_rifle.FALLOFF[1].dmg_mul = 2.5
	self.marshal_marksman.weapon.is_rifle.FALLOFF[2].dmg_mul = 5
	self.marshal_marksman.weapon.is_rifle.FALLOFF[3].dmg_mul = 7.5
	self.marshal_marksman.weapon.is_rifle.FALLOFF[4].dmg_mul = 10
	self.marshal_marksman.weapon.is_rifle.FALLOFF[5].dmg_mul = 7.5
	self.marshal_marksman.HEALTH_INIT = 36
	self.marshal_marksman.headshot_dmg_mul = 9 / 1.25
	self.marshal_shield.weapon.is_pistol.FALLOFF[1].dmg_mul = 6
	self.marshal_shield.weapon.is_pistol.FALLOFF[2].dmg_mul = 5
	self.marshal_shield.weapon.is_pistol.FALLOFF[3].dmg_mul = 4
	self.marshal_shield.weapon.is_pistol.FALLOFF[4].dmg_mul = 3
	self.marshal_shield.weapon.is_pistol.FALLOFF[5].dmg_mul = 2
	self.marshal_shield_break.weapon.is_shotgun_mag.FALLOFF[1].dmg_mul = 8
	self.marshal_shield_break.weapon.is_shotgun_mag.FALLOFF[2].dmg_mul = 7.5
	self.marshal_shield_break.weapon.is_shotgun_mag.FALLOFF[3].dmg_mul = 6.5
	self.marshal_shield_break.weapon.is_shotgun_mag.FALLOFF[4].dmg_mul = 3
	self.marshal_shield_break.weapon.is_shotgun_mag.FALLOFF[5].dmg_mul = 2
	self.tank_mini.HEALTH_INIT = 2400
	self.hector_boss.weapon.is_shotgun_mag.FALLOFF = {
		{
			dmg_mul = 3.14,
			r = 200,
			acc = {
				0.6,
				0.9
			},
			recoil = {
				0.4,
				0.7
			},
			mode = {
				0,
				1,
				2,
				1
			}
		},
		{
			dmg_mul = 2.5,
			r = 500,
			acc = {
				0.6,
				0.9
			},
			recoil = {
				0.4,
				0.7
			},
			mode = {
				0,
				3,
				3,
				1
			}
		},
		{
			dmg_mul = 2.1,
			r = 1000,
			acc = {
				0.4,
				0.8
			},
			recoil = {
				0.45,
				0.8
			},
			mode = {
				1,
				2,
				2,
				0
			}
		},
		{
			dmg_mul = 1.8,
			r = 2000,
			acc = {
				0.4,
				0.55
			},
			recoil = {
				0.45,
				0.8
			},
			mode = {
				3,
				2,
				2,
				0
			}
		},
		{
			dmg_mul = 1.4,
			r = 3000,
			acc = {
				0.1,
				0.35
			},
			recoil = {
				1,
				1.2
			},
			mode = {
				3,
				1,
				1,
				0
			}
		}
	}
	self.hector_boss.HEALTH_INIT = 900
	self.mobster_boss.HEALTH_INIT = 900
	self.biker_boss.HEALTH_INIT = 3000
	self.chavez_boss.HEALTH_INIT = 900

	self:_multiply_all_speeds(2.05, 2.1)
	self:_multiply_weapon_delay(self.presets.weapon.normal, 0)
	self:_multiply_weapon_delay(self.presets.weapon.good, 0)
	self:_multiply_weapon_delay(self.presets.weapon.expert, 0)
	self:_multiply_weapon_delay(self.presets.weapon.sniper, 3)
	self:_multiply_weapon_delay(self.presets.weapon.gang_member, 0)

	self.presets.gang_member_damage.REGENERATE_TIME = 1.8
	self.presets.gang_member_damage.REGENERATE_TIME_AWAY = 0.6
	self.presets.gang_member_damage.HEALTH_INIT = 800
	self.presets.gang_member_damage.BLEED_OUT_HEALTH_INIT = self.presets.gang_member_damage.HEALTH_INIT * 0.1
	self.presets.weapon.gang_member.is_pistol.FALLOFF[1].dmg_mul = 10
	self.presets.weapon.gang_member.is_pistol.FALLOFF[2].dmg_mul = 5
	self.presets.weapon.gang_member.is_revolver.FALLOFF[1].dmg_mul = 10
	self.presets.weapon.gang_member.is_revolver.FALLOFF[2].dmg_mul = 5
	self.presets.weapon.gang_member.is_rifle.FALLOFF[1].dmg_mul = 10
	self.presets.weapon.gang_member.is_rifle.FALLOFF[2].dmg_mul = 5
	self.presets.weapon.gang_member.is_sniper.FALLOFF[1].dmg_mul = 20
	self.presets.weapon.gang_member.is_sniper.FALLOFF[2].dmg_mul = 20
	self.presets.weapon.gang_member.is_sniper.FALLOFF[3].dmg_mul = 20
	self.presets.weapon.gang_member.is_sniper.FALLOFF[4].dmg_mul = 10
	self.presets.weapon.gang_member.is_sniper.FALLOFF[5].dmg_mul = 10
	self.presets.weapon.gang_member.is_lmg.FALLOFF[1].dmg_mul = 10
	self.presets.weapon.gang_member.is_lmg.FALLOFF[2].dmg_mul = 7.5
	self.presets.weapon.gang_member.is_lmg.FALLOFF[3].dmg_mul = 5
	self.presets.weapon.gang_member.is_lmg.FALLOFF[4].dmg_mul = 3
	self.presets.weapon.gang_member.is_lmg.FALLOFF[5].dmg_mul = 2
	self.presets.weapon.gang_member.is_lmg.FALLOFF[6].dmg_mul = 0.5
	self.presets.weapon.gang_member.is_shotgun_pump.FALLOFF[1].dmg_mul = 10
	self.presets.weapon.gang_member.is_shotgun_pump.FALLOFF[2].dmg_mul = 5
	self.presets.weapon.gang_member.is_shotgun_mag.FALLOFF[1].dmg_mul = 10
	self.presets.weapon.gang_member.is_shotgun_mag.FALLOFF[2].dmg_mul = 8
	self.presets.weapon.gang_member.is_shotgun_mag.FALLOFF[3].dmg_mul = 7
	self.presets.weapon.gang_member.is_shotgun_mag.FALLOFF[4].dmg_mul = 5
	self.presets.weapon.gang_member.is_shotgun_mag.FALLOFF[5].dmg_mul = 2
	self.presets.weapon.gang_member.is_shotgun_mag.FALLOFF[6].dmg_mul = 0.4
	self.presets.weapon.gang_member.is_smg = self.presets.weapon.gang_member.is_rifle
	self.presets.weapon.gang_member.is_rifle = self.presets.weapon.gang_member.is_rifle
	self.presets.weapon.gang_member.mac11 = self.presets.weapon.gang_member.is_smg
	self.presets.weapon.gang_member.rifle = deep_clone(self.presets.weapon.gang_member.is_rifle)
	self.presets.weapon.gang_member.rifle.autofire_rounds = nil
	self.presets.weapon.gang_member.akimbo_pistol = self.presets.weapon.gang_member.is_pistol

	self:_set_characters_weapon_preset("deathwish")

	self.shadow_spooc.shadow_spooc_attack_timeout = {
		3,
		4
	}
	self.spooc.spooc_attack_timeout = {
		3,
		4
	}
	self.sniper.weapon.is_rifle.FALLOFF = {
		{
			dmg_mul = 12,
			r = 700,
			acc = {
				0.7,
				1
			},
			recoil = {
				3,
				5
			},
			mode = {
				1,
				0,
				0,
				0
			}
		},
		{
			dmg_mul = 12,
			r = 4000,
			acc = {
				0.6,
				0.95
			},
			recoil = {
				3,
				5
			},
			mode = {
				1,
				0,
				0,
				0
			}
		},
		{
			dmg_mul = 12,
			r = 10000,
			acc = {
				0.2,
				0.8
			},
			recoil = {
				3,
				5
			},
			mode = {
				1,
				0,
				0,
				0
			}
		}
	}
	self.tank.weapon.is_shotgun_mag.aim_delay = {
		0,
		0
	}
	self.tank.weapon.is_shotgun_mag.focus_delay = 0
	self.tank.weapon.is_shotgun_mag.focus_dis = 200
	self.tank.weapon.is_shotgun_mag.FALLOFF = {
		{
			dmg_mul = 8,
			r = 100,
			acc = {
				0.75,
				0.9
			},
			recoil = {
				0.4,
				0.7
			},
			mode = {
				0,
				3,
				3,
				1
			}
		},
		{
			dmg_mul = 7.5,
			r = 500,
			acc = {
				0.75,
				0.9
			},
			recoil = {
				0.4,
				0.7
			},
			mode = {
				0,
				3,
				3,
				1
			}
		},
		{
			dmg_mul = 7,
			r = 1000,
			acc = {
				0.7,
				0.85
			},
			recoil = {
				0.45,
				0.8
			},
			mode = {
				1,
				2,
				2,
				0
			}
		},
		{
			dmg_mul = 5,
			r = 2000,
			acc = {
				0.5,
				0.65
			},
			recoil = {
				0.45,
				0.8
			},
			mode = {
				3,
				2,
				2,
				0
			}
		},
		{
			dmg_mul = 3.5,
			r = 3000,
			acc = {
				0.3,
				0.5
			},
			recoil = {
				1,
				1.2
			},
			mode = {
				3,
				1,
				1,
				0
			}
		}
	}
	self.tank.weapon.is_shotgun_pump.focus_dis = 200
	self.tank.weapon.is_shotgun_pump.FALLOFF[1].dmg_mul = 9
	self.tank.weapon.is_shotgun_pump.FALLOFF[2].dmg_mul = 8
	self.tank.weapon.is_shotgun_pump.FALLOFF[3].dmg_mul = 7
	self.tank.weapon.is_lmg.aim_delay = {
		0,
		0
	}
	self.tank.weapon.is_lmg.focus_delay = 0
	self.tank.weapon.is_lmg.FALLOFF = {
		{
			dmg_mul = 5,
			r = 100,
			acc = {
				0.7,
				0.9
			},
			recoil = {
				0.4,
				0.7
			},
			mode = {
				0,
				0,
				0,
				1
			}
		},
		{
			dmg_mul = 5,
			r = 500,
			acc = {
				0.5,
				0.75
			},
			recoil = {
				0.5,
				0.8
			},
			mode = {
				0,
				0,
				0,
				6
			}
		},
		{
			dmg_mul = 5,
			r = 1000,
			acc = {
				0.3,
				0.6
			},
			recoil = {
				1,
				1
			},
			mode = {
				0,
				0,
				2,
				6
			}
		},
		{
			dmg_mul = 5,
			r = 2000,
			acc = {
				0.25,
				0.55
			},
			recoil = {
				1,
				1
			},
			mode = {
				0,
				0,
				2,
				6
			}
		},
		{
			dmg_mul = 5,
			r = 3000,
			acc = {
				0.15,
				0.5
			},
			recoil = {
				1,
				2
			},
			mode = {
				0,
				0,
				2,
				6
			}
		}
	}
	self.tank_mini.weapon.mini.aim_delay = {
		0,
		0
	}
	self.tank_mini.weapon.mini.focus_delay = 0
	self.tank_mini.weapon.mini.FALLOFF[1].dmg_mul = 5
	self.tank_mini.weapon.mini.FALLOFF[2].dmg_mul = 5
	self.tank_mini.weapon.mini.FALLOFF[3].dmg_mul = 5
	self.tank_mini.weapon.mini.FALLOFF[4].dmg_mul = 5
	self.tank_mini.weapon.mini.FALLOFF[5].dmg_mul = 5
	self.shield.weapon.is_smg.aim_delay = {
		0,
		0
	}
	self.shield.weapon.is_smg.focus_delay = 0
	self.shield.weapon.is_pistol.aim_delay = {
		0,
		0
	}
	self.shield.weapon.is_pistol.focus_delay = 0
	self.city_swat.damage.explosion_damage_mul = 1
	self.phalanx_minion.HEALTH_INIT = 400
	self.phalanx_minion.DAMAGE_CLAMP_BULLET = 40
	self.phalanx_minion.DAMAGE_CLAMP_EXPLOSION = self.phalanx_minion.DAMAGE_CLAMP_BULLET
	self.phalanx_vip.HEALTH_INIT = 800
	self.phalanx_vip.DAMAGE_CLAMP_BULLET = 80
	self.phalanx_vip.DAMAGE_CLAMP_EXPLOSION = self.phalanx_vip.DAMAGE_CLAMP_BULLET
	self.flashbang_multiplier = 2
	self.concussion_multiplier = 1

	self:_process_weapon_usage_table()
end

function CharacterTweakData:_set_sm_wish()
	if SystemInfo:platform() == Idstring("PS3") then
		self:_multiply_all_hp(6, 1.5)
	else
		self:_multiply_all_hp(6, 1.5)
	end

	self.marshal_marksman.weapon.is_rifle.FALLOFF[1].dmg_mul = 3.5
	self.marshal_marksman.weapon.is_rifle.FALLOFF[2].dmg_mul = 7
	self.marshal_marksman.weapon.is_rifle.FALLOFF[3].dmg_mul = 10.5
	self.marshal_marksman.weapon.is_rifle.FALLOFF[4].dmg_mul = 14
	self.marshal_marksman.weapon.is_rifle.FALLOFF[5].dmg_mul = 10.5
	self.marshal_marksman.HEALTH_INIT = 36
	self.marshal_marksman.headshot_dmg_mul = 9 / 1.25
	self.marshal_shield.weapon.is_pistol.FALLOFF[1].dmg_mul = 8
	self.marshal_shield.weapon.is_pistol.FALLOFF[2].dmg_mul = 7
	self.marshal_shield.weapon.is_pistol.FALLOFF[3].dmg_mul = 6
	self.marshal_shield.weapon.is_pistol.FALLOFF[4].dmg_mul = 4
	self.marshal_shield.weapon.is_pistol.FALLOFF[5].dmg_mul = 3
	self.marshal_shield_break.weapon.is_shotgun_mag.FALLOFF[1].dmg_mul = 10
	self.marshal_shield_break.weapon.is_shotgun_mag.FALLOFF[2].dmg_mul = 9
	self.marshal_shield_break.weapon.is_shotgun_mag.FALLOFF[3].dmg_mul = 8
	self.marshal_shield_break.weapon.is_shotgun_mag.FALLOFF[4].dmg_mul = 4
	self.marshal_shield_break.weapon.is_shotgun_mag.FALLOFF[5].dmg_mul = 2.5
	self.tank.HEALTH_INIT = 2400
	self.tank_mini.HEALTH_INIT = 4800
	self.tank_medic.HEALTH_INIT = 2400
	self.hector_boss.weapon.is_shotgun_mag.FALLOFF = {
		{
			dmg_mul = 3.14,
			r = 200,
			acc = {
				0.6,
				0.9
			},
			recoil = {
				0.4,
				0.7
			},
			mode = {
				0,
				1,
				2,
				1
			}
		},
		{
			dmg_mul = 2.5,
			r = 500,
			acc = {
				0.6,
				0.9
			},
			recoil = {
				0.4,
				0.7
			},
			mode = {
				0,
				3,
				3,
				1
			}
		},
		{
			dmg_mul = 2.1,
			r = 1000,
			acc = {
				0.4,
				0.8
			},
			recoil = {
				0.45,
				0.8
			},
			mode = {
				1,
				2,
				2,
				0
			}
		},
		{
			dmg_mul = 1.8,
			r = 2000,
			acc = {
				0.4,
				0.55
			},
			recoil = {
				0.45,
				0.8
			},
			mode = {
				3,
				2,
				2,
				0
			}
		},
		{
			dmg_mul = 1.4,
			r = 3000,
			acc = {
				0.1,
				0.35
			},
			recoil = {
				1,
				1.2
			},
			mode = {
				3,
				1,
				1,
				0
			}
		}
	}
	self.hector_boss.HEALTH_INIT = 900
	self.mobster_boss.HEALTH_INIT = 900
	self.biker_boss.HEALTH_INIT = 3000
	self.chavez_boss.HEALTH_INIT = 900

	self:_multiply_all_speeds(4.05, 4.1)
	self:_multiply_weapon_delay(self.presets.weapon.normal, 0)
	self:_multiply_weapon_delay(self.presets.weapon.good, 0)
	self:_multiply_weapon_delay(self.presets.weapon.expert, 0)
	self:_multiply_weapon_delay(self.presets.weapon.sniper, 3)
	self:_multiply_weapon_delay(self.presets.weapon.gang_member, 0)

	self.presets.gang_member_damage.REGENERATE_TIME = 1.8
	self.presets.gang_member_damage.REGENERATE_TIME_AWAY = 0.6
	self.presets.gang_member_damage.HEALTH_INIT = 800
	self.presets.gang_member_damage.BLEED_OUT_HEALTH_INIT = self.presets.gang_member_damage.HEALTH_INIT * 0.1
	self.presets.weapon.gang_member.is_pistol.FALLOFF[1].dmg_mul = 10
	self.presets.weapon.gang_member.is_pistol.FALLOFF[2].dmg_mul = 5
	self.presets.weapon.gang_member.is_revolver.FALLOFF[1].dmg_mul = 10
	self.presets.weapon.gang_member.is_revolver.FALLOFF[2].dmg_mul = 5
	self.presets.weapon.gang_member.is_rifle.FALLOFF[1].dmg_mul = 10
	self.presets.weapon.gang_member.is_rifle.FALLOFF[2].dmg_mul = 5
	self.presets.weapon.gang_member.is_sniper.FALLOFF[1].dmg_mul = 20
	self.presets.weapon.gang_member.is_sniper.FALLOFF[2].dmg_mul = 20
	self.presets.weapon.gang_member.is_sniper.FALLOFF[3].dmg_mul = 20
	self.presets.weapon.gang_member.is_sniper.FALLOFF[4].dmg_mul = 10
	self.presets.weapon.gang_member.is_sniper.FALLOFF[5].dmg_mul = 10
	self.presets.weapon.gang_member.is_lmg.FALLOFF[1].dmg_mul = 10
	self.presets.weapon.gang_member.is_lmg.FALLOFF[2].dmg_mul = 7.5
	self.presets.weapon.gang_member.is_lmg.FALLOFF[3].dmg_mul = 5
	self.presets.weapon.gang_member.is_lmg.FALLOFF[4].dmg_mul = 3
	self.presets.weapon.gang_member.is_lmg.FALLOFF[5].dmg_mul = 2
	self.presets.weapon.gang_member.is_lmg.FALLOFF[6].dmg_mul = 0.5
	self.presets.weapon.gang_member.is_shotgun_pump.FALLOFF[1].dmg_mul = 10
	self.presets.weapon.gang_member.is_shotgun_pump.FALLOFF[2].dmg_mul = 5
	self.presets.weapon.gang_member.is_shotgun_mag.FALLOFF[1].dmg_mul = 10
	self.presets.weapon.gang_member.is_shotgun_mag.FALLOFF[2].dmg_mul = 8
	self.presets.weapon.gang_member.is_shotgun_mag.FALLOFF[3].dmg_mul = 7
	self.presets.weapon.gang_member.is_shotgun_mag.FALLOFF[4].dmg_mul = 5
	self.presets.weapon.gang_member.is_shotgun_mag.FALLOFF[5].dmg_mul = 2
	self.presets.weapon.gang_member.is_shotgun_mag.FALLOFF[6].dmg_mul = 0.4
	self.presets.weapon.gang_member.is_smg = self.presets.weapon.gang_member.is_rifle
	self.presets.weapon.gang_member.is_rifle = self.presets.weapon.gang_member.is_rifle
	self.presets.weapon.gang_member.mac11 = self.presets.weapon.gang_member.is_smg
	self.presets.weapon.gang_member.rifle = deep_clone(self.presets.weapon.gang_member.is_rifle)
	self.presets.weapon.gang_member.rifle.autofire_rounds = nil
	self.presets.weapon.gang_member.akimbo_pistol = self.presets.weapon.gang_member.is_pistol

	self:_set_characters_weapon_preset("deathwish")

	self.spooc.spooc_attack_timeout = {
		3,
		4
	}
	self.shadow_spooc.shadow_spooc_attack_timeout = {
		3,
		4
	}
	self.sniper.weapon.is_rifle.FALLOFF = {
		{
			dmg_mul = 12,
			r = 700,
			acc = {
				0.7,
				1
			},
			recoil = {
				3,
				5
			},
			mode = {
				1,
				0,
				0,
				0
			}
		},
		{
			dmg_mul = 12,
			r = 4000,
			acc = {
				0.6,
				0.95
			},
			recoil = {
				3,
				5
			},
			mode = {
				1,
				0,
				0,
				0
			}
		},
		{
			dmg_mul = 12,
			r = 10000,
			acc = {
				0.2,
				0.8
			},
			recoil = {
				3,
				5
			},
			mode = {
				1,
				0,
				0,
				0
			}
		}
	}
	self.tank.weapon.is_shotgun_mag.aim_delay = {
		0,
		0
	}
	self.tank.weapon.is_shotgun_mag.focus_delay = 0
	self.tank.weapon.is_shotgun_mag.focus_dis = 200
	self.tank.weapon.is_shotgun_mag.FALLOFF = {
		{
			dmg_mul = 9,
			r = 100,
			acc = {
				0.75,
				0.9
			},
			recoil = {
				0.4,
				0.7
			},
			mode = {
				0,
				3,
				3,
				1
			}
		},
		{
			dmg_mul = 8.5,
			r = 500,
			acc = {
				0.75,
				0.9
			},
			recoil = {
				0.4,
				0.7
			},
			mode = {
				0,
				3,
				3,
				1
			}
		},
		{
			dmg_mul = 8,
			r = 1000,
			acc = {
				0.7,
				0.85
			},
			recoil = {
				0.45,
				0.8
			},
			mode = {
				1,
				2,
				2,
				0
			}
		},
		{
			dmg_mul = 5,
			r = 2000,
			acc = {
				0.5,
				0.65
			},
			recoil = {
				0.45,
				0.8
			},
			mode = {
				3,
				2,
				2,
				0
			}
		},
		{
			dmg_mul = 3.5,
			r = 3000,
			acc = {
				0.3,
				0.5
			},
			recoil = {
				1,
				1.2
			},
			mode = {
				3,
				1,
				1,
				0
			}
		}
	}
	self.tank.weapon.is_shotgun_pump.focus_dis = 200
	self.tank.weapon.is_shotgun_pump.FALLOFF[1].dmg_mul = 9
	self.tank.weapon.is_shotgun_pump.FALLOFF[2].dmg_mul = 8
	self.tank.weapon.is_shotgun_pump.FALLOFF[3].dmg_mul = 7
	self.tank.weapon.is_lmg.aim_delay = {
		0,
		0
	}
	self.tank.weapon.is_lmg.focus_delay = 0
	self.tank.weapon.is_lmg.FALLOFF = {
		{
			dmg_mul = 6,
			r = 100,
			acc = {
				0.7,
				0.9
			},
			recoil = {
				0.4,
				0.7
			},
			mode = {
				0,
				0,
				0,
				1
			}
		},
		{
			dmg_mul = 6,
			r = 500,
			acc = {
				0.5,
				0.75
			},
			recoil = {
				0.5,
				0.8
			},
			mode = {
				0,
				0,
				0,
				6
			}
		},
		{
			dmg_mul = 6,
			r = 1000,
			acc = {
				0.3,
				0.6
			},
			recoil = {
				1,
				1
			},
			mode = {
				0,
				0,
				2,
				6
			}
		},
		{
			dmg_mul = 6,
			r = 2000,
			acc = {
				0.25,
				0.55
			},
			recoil = {
				1,
				1
			},
			mode = {
				0,
				0,
				2,
				6
			}
		},
		{
			dmg_mul = 6,
			r = 3000,
			acc = {
				0.15,
				0.5
			},
			recoil = {
				1,
				2
			},
			mode = {
				0,
				0,
				2,
				6
			}
		}
	}
	self.tank_mini.weapon.mini.aim_delay = {
		0,
		0
	}
	self.tank_mini.weapon.mini.focus_delay = 0
	self.tank_mini.weapon.mini.FALLOFF[1].dmg_mul = 6
	self.tank_mini.weapon.mini.FALLOFF[2].dmg_mul = 6
	self.tank_mini.weapon.mini.FALLOFF[3].dmg_mul = 6
	self.tank_mini.weapon.mini.FALLOFF[4].dmg_mul = 6
	self.tank_mini.weapon.mini.FALLOFF[5].dmg_mul = 6
	self.shield.weapon.is_smg.aim_delay = {
		0,
		0
	}
	self.shield.weapon.is_smg.focus_delay = 0
	self.shield.weapon.is_pistol.aim_delay = {
		0,
		0
	}
	self.shield.weapon.is_pistol.focus_delay = 0
	self.city_swat.damage.explosion_damage_mul = 1
	self.phalanx_minion.HEALTH_INIT = 400
	self.phalanx_minion.DAMAGE_CLAMP_BULLET = 40
	self.phalanx_minion.DAMAGE_CLAMP_EXPLOSION = self.phalanx_minion.DAMAGE_CLAMP_BULLET
	self.phalanx_vip.HEALTH_INIT = 800
	self.phalanx_vip.DAMAGE_CLAMP_BULLET = 80
	self.phalanx_vip.DAMAGE_CLAMP_EXPLOSION = self.phalanx_vip.DAMAGE_CLAMP_BULLET
	self.flashbang_multiplier = 2
	self.concussion_multiplier = 1

	self:_process_weapon_usage_table()
end