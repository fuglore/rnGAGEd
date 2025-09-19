local PICKUP = {
	AR_LOW_CAPACITY = 7,
	SHOTGUN_HIGH_CAPACITY = 4,
	OTHER = 1,
	LMG_CAPACITY = 9,
	AR_MED_CAPACITY = 3,
	SNIPER_HIGH_DAMAGE = 6,
	AR_HIGH_CAPACITY = 2,
	SNIPER_LOW_DAMAGE = 5,
	AR_DMR_CAPACITY = 8
}
local FALLOFF_TEMPLATE = WeaponFalloffTemplate.setup_weapon_falloff_templates()

local wtd_init_new_weapons = WeaponTweakData._init_new_weapons

function WeaponTweakData:_init_new_weapons(weapon_data)
	if RNGAGED.settings.disable_balance_changes then
		return wtd_init_new_weapons(self, weapon_data)
	end
	
	weapon_data.autohit_rifle_default = {
		INIT_RATIO = 0,
		MAX_RATIO = 1,
		far_angle = 3,
		far_dis = 3000,
		MIN_RATIO = 0.3,
		near_angle = 6
	}
	weapon_data.autohit_pistol_default = {
		INIT_RATIO = 0,
		MAX_RATIO = 1,
		far_angle = 3,
		far_dis = 2000,
		MIN_RATIO = 0.1,
		near_angle = 6
	}
	weapon_data.autohit_shotgun_default = {
		INIT_RATIO = 0,
		MAX_RATIO = 0.4,
		far_angle = 8,
		far_dis = 5000,
		MIN_RATIO = 0.3,
		near_angle = 3
	}
	weapon_data.autohit_lmg_default = {
		INIT_RATIO = 0,
		MAX_RATIO = 0.4,
		far_angle = 3,
		far_dis = 2000,
		MIN_RATIO = 0.2,
		near_angle = 6
	}
	weapon_data.autohit_snp_default = {
		INIT_RATIO = 0,
		MAX_RATIO = 1,
		far_angle = 3,
		far_dis = 4000,
		MIN_RATIO = 0.1,
		near_angle = 6
	}
	weapon_data.autohit_smg_default = {
		INIT_RATIO = 0,
		MAX_RATIO = 1,
		far_angle = 3,
		far_dis = 3000,
		MIN_RATIO = 0.3,
		near_angle = 6
	}
	weapon_data.autohit_minigun_default = {
		INIT_RATIO = 0,
		MAX_RATIO = 1,
		far_angle = 3,
		far_dis = 2000,
		MIN_RATIO = 1,
		near_angle = 3
	}

	wtd_init_new_weapons(self, weapon_data)
end

function WeaponTweakData:_init_rengaged_stat_changes()
	if RNGAGED.settings.disable_balance_changes then
		return
	end
	
	self.stats.spread = {
		2.08,
		2,
		1.92,
		1.84,
		1.76,
		1.68,
		1.60,
		1.52,
		1.44,
		1.36,
		1.28,
		1.2,
		1.12,
		1.04,
		0.96,
		0.88,
		0.8,
		0.72,
		0.64,
		0.56,
		0.48,
		0.4,
		0.32,
		0.24,
		0.16,
		0.08
	}

	self.stats.suppression = {
		5.2,
		5,
		4.8,
		4.6,
		4.4,
		4.2,
		4,
		3.8,
		3.6,
		3.4,
		3.2,
		3,
		2.8,
		2.6,
		2.4,
		2.2,
		2,
		1.8,
		1.6,
		1.4,
		1.2,
		1,
		0.8,
		0.6,
		0.4,
		0
	}
	
	self.stats.concealment_reload_mul = {}
	
	for i = 1, 15 do
		self.stats.concealment_reload_mul[i] = math.lerp(0.85, 1, i / 15)
	end
	
	for i = #self.stats.concealment_reload_mul + 1, #self.stats.concealment do
		self.stats.concealment_reload_mul[i] = 1
	end
	
	self.stats.threat_ammo_mul = {
		1.5,
		1.48,
		1.44,
		1.4,
		1.38,
		1.34,
		1.3,
		1.28,
		1.24,
		1.2,
		1.16,
		1.12,
		1.08,
		1.04,
		1,
		1,
		1,
		1,
		1,
		1,
		1,
		1,
		1,
		1,
		1,
		1
	}
end

Hooks:PostHook(WeaponTweakData, "init", "regunz_tweaks", function(self, tweakdata)
	if not RNGAGED.settings.disable_enemy_projectiles then
		self.r870_npc.spread = 2
		self.benelli_npc.spread = 2
		self.mossberg_npc.spread = 2
		self.saiga_npc.spread = 2
		self.sko12_conc_npc.spread = 2
		self.sko12_conc_npc.rays = nil
		
		self.mini_npc.auto.fire_rate = 0.08 --please dont fire that many real dynamic bullets
		self.mini_npc.rays = 4
		self.mini_npc.spread = 3
	end
	
	self.ching.empty_on_reload = true
	self.coach.dont_empty_on_reload = true
	self.flamethrower_mk2.empty_on_reload = true
	self.system.empty_on_reload = true
	self.kacchainsaw_flamethrower.empty_on_reload = true
	self.rota.empty_on_reload = true

	if RNGAGED.settings.disable_balance_changes then
		return
	end
	
	self.r870_npc.suppression = 2.5
	self.benelli_npc.suppression = 2.5
	self.mossberg_npc.suppression = 2.5
	self.saiga_npc.suppression = 2.5
	self.sko12_conc_npc.rays = nil
	self.sko12_conc_npc.suppression = 2.5
	self.sko12_conc_npc.bullet_class = nil
	self.sko12_conc_npc.concussion_data = nil
	self.mini_npc.suppression = 2.5

	--player weapon tweaks
	local static_spread_table = {
		standing = 1,
		crouching = 1,
		steelsight = 1,
		moving_standing = 1,
		moving_crouching = 1,
		moving_steelsight = 1
	}
	local akimbo_spread_table = {
		standing = 1.25,
		crouching = 1.25,
		steelsight = 1.25,
		moving_standing = 1.25,
		moving_crouching = 1.25,
		moving_steelsight = 1.25
	}
	
	local recoil_table = {
		standing = {
			0.6,
			0.8,
			-0.75,
			0.75
		},
		crouching = {
			0.6,
			0.8,
			-0.75,
			0.75
		},
		steelsight = {
			0.4,
			0.6,
			-0.6,
			0.6
		}
	}
	local pistol_recoil_table = {
		standing = {
			0.4,
			0.6,
			-0.6,
			0.6
		},
		crouching = {
			0.4,
			0.6,
			-0.6,
			0.6
		},
		steelsight = {
			0.2,
			0.4,
			-0.3,
			0.3
		}
	}
	local flamethrower_recoil_table = {
		standing = {
			0.05,
			0.1,
			-0.05,
			0.05
		},
		crouching = {
			0.05,
			0.1,
			-0.05,
			0.05
		},
		steelsight = {
			0.025,
			0.05,
			-0.025,
			0.025
		}
	}
	--amcar, accuracy and damage buff, concealment buff
	self.amcar.stats.spread = 12
	self.amcar.stats.spread_moving = 12
	self.amcar.stats.damage = 62
	self.amcar.stats.concealment = 24
	
	--UAR, stability buff, threat buff
	self.aug.stats.recoil = 18
	self.aug.stats.suppression = 12
	
	--Tempest-21, max ammo buff, concealment buff
	self.komodo.stats.concealment = 28
	--self.komodo.NR_CLIPS_MAX = 7
	--self.komodo.AMMO_MAX = self.komodo.CLIP_AMMO_MAX * self.komodo.NR_CLIPS_MAX
	
	--commando 553, accuracy boost
	self.s552.stats.spread = 14

	--queen's wrath, accuracy boost, max ammo buff
	self.l85a2.stats.spread = 19
	self.l85a2.NR_CLIPS_MAX = 6
	--self.l85a2.AMMO_MAX = self.l85a2.CLIP_AMMO_MAX * self.l85a2.NR_CLIPS_MAX
	
	--lion's roar, total ammo nerf, ammo pickup nerf
	self.vhs.NR_CLIPS_MAX = 5
	--self.vhs.AMMO_MAX = self.vhs.CLIP_AMMO_MAX * self.vhs.NR_CLIPS_MAX
	--self.vhs.AMMO_PICKUP = self:_pickup_chance(self.vhs.AMMO_MAX, PICKUP.AR_MED_CAPACITY)
	
	--ak 762, damage nerf, max ammo buff, ammo pickup buff
	self.akm.stats.damage = 80
	self.akm.NR_CLIPS_MAX = 4
	--self.akm.AMMO_MAX = self.akm.CLIP_AMMO_MAX * self.akm.NR_CLIPS_MAX
	--self.akm.AMMO_PICKUP = self:_pickup_chance(self.akm.AMMO_MAX, PICKUP.AR_LOW_CAPACITY)
	self.akm_gold.stats.damage = 80
	self.akm_gold.NR_CLIPS_MAX = 4
	--self.akm_gold.AMMO_MAX = self.akm_gold.CLIP_AMMO_MAX * self.akm_gold.NR_CLIPS_MAX
	--self.akm_gold.AMMO_PICKUP = self:_pickup_chance(self.akm_gold.AMMO_MAX, PICKUP.AR_LOW_CAPACITY)
	
	--ak17, damage nerf, ammo pickup nerf
	self.flint.stats.damage = 94
	--self.flint.AMMO_PICKUP = self.m16.AMMO_PICKUP
	
	--ks12 urban, slight stability buff
	self.shak12.stats.recoil = 9
	
	--galant rifle, stability buff, damage buff, max ammo nerf, shield piercing
	self.ching.NR_CLIPS_MAX = 6
	--self.ching.AMMO_MAX = self.ching.CLIP_AMMO_MAX * self.ching.NR_CLIPS_MAX
	self.ching.can_shoot_through_enemy = true
	self.ching.can_shoot_through_shield = true
	self.ching.can_shoot_through_wall = true
	
	
	--reinfeld 880, pickup buff, firerate buff, slight stability buff, mosconi 12g tac outclasses it too hard in vanilla
	--self.r870.AMMO_PICKUP = {0.5, 1.5}
	self.r870.stats.recoil = 10
	self.r870.fire_mode_data = {
		fire_rate = 0.375
	}
	self.r870.single = {
		fire_rate = 0.375
	}
	
	--mosconi, big damage buff, max ammo and ammo pickup nerf
	self.huntsman.stats_modifiers = {
		damage = 1.5
	}
	--self.huntsman.NR_CLIPS_MAX = 8
	--self.huntsman.AMMO_MAX = self.huntsman.CLIP_AMMO_MAX * self.huntsman.NR_CLIPS_MAX
	--self.huntsman.AMMO_PICKUP = {0.5, 1}
	
	--joceline, big damage buff, accuracy boost, max ammo and ammo pickup nerf
	self.b682.stats.spread = 20
	self.b682.stats_modifiers = {
		damage = 1
	}
	--self.b682.AMMO_MAX = self.b682.CLIP_AMMO_MAX * self.b682.NR_CLIPS_MAX
	--self.b682.AMMO_PICKUP = {0.5, 1}
	
	--reinfeld 88, accuracy boost
	self.m1897.stats.spread = 15
	
	--mosconi 12g tactical, concealment nerf
	self.m590.stats.concealment = 15
	
	--m1014, ammo pickup nerf, accuracy boost
	self.benelli.stats.spread = 14
	self.benelli.stats.spread_moving = 14
	self.benelli.stats.damage = 70
	--self.benelli.AMMO_PICKUP = self:_pickup_chance(self.benelli.AMMO_MAX, PICKUP.OTHER)
	self.benelli.damage_falloff = FALLOFF_TEMPLATE.SHOTGUN_FALL_PRIMARY_MEDIUM
	
	--predator, ammo pickup nerf, accuracy boost 
	--self.spas12.AMMO_PICKUP = self:_pickup_chance(self.spas12.AMMO_MAX, PICKUP.OTHER)
	self.spas12.NR_CLIPS_MAX = 8
	self.spas12.stats.spread = 10
	self.spas12.stats.spread_moving = 10
	self.spas12.stats.damage = 75
	self.spas12.damage_falloff = FALLOFF_TEMPLATE.SHOTGUN_FALL_PRIMARY_MEDIUM
	
	--deimos, slight damage nerf, slight pickup nerf
	self.supernova.stats.damage = 100
	
	--breaker 12g, slight ammo pickup and max ammo increase
	self.boot.CLIP_AMMO_MAX = 5
	self.boot.NR_CLIPS_MAX = 6
	--self.boot.AMMO_MAX = self.boot.CLIP_AMMO_MAX * self.boot.NR_CLIPS_MAX
	--self.boot.AMMO_PICKUP = self:_pickup_chance(self.boot.AMMO_MAX, PICKUP.OTHER)
	self.boot.damage_falloff = FALLOFF_TEMPLATE.SHOTGUN_FALL_PRIMARY_MEDIUM
	
	--izhma, ammo pickup nerf, accuracy boost, damage boost
	self.saiga.stats.damage = 100
	self.saiga.stats.spread = 15
	--self.saiga.NR_CLIPS_MAX = 4
	--self.saiga.AMMO_MAX = self.saiga.CLIP_AMMO_MAX * self.saiga.NR_CLIPS_MAX
	--self.saiga.AMMO_PICKUP = {self.saiga.AMMO_MAX * 0.03, self.saiga.AMMO_MAX * 0.055}
	
	--steakout, ammo pickup nerf, accuracy boost, damage boost
	self.aa12.stats.damage = 100
	self.aa12.stats.spread = 18
	--self.aa12.NR_CLIPS_MAX = 4
	--self.aa12.AMMO_MAX = self.aa12.CLIP_AMMO_MAX * self.aa12.NR_CLIPS_MAX
	--self.aa12.AMMO_PICKUP = {self.aa12.AMMO_MAX * 0.03, self.aa12.AMMO_MAX * 0.055}
	
	--vd-12, ammo pickup nerf, accuracy boost
	self.sko12.stats.damage = 100
	self.sko12.stats.spread = 15
	--self.sko12.AMMO_PICKUP = {self.sko12.AMMO_MAX * 0.03, self.sko12.AMMO_MAX * 0.055}
	
	--rattlesnake, accuracy boost, stability buff
	self.msr.stats.spread = 25
	self.msr.stats.recoil = 10
	
	--grom, damage increase to higher tier
	self.siltstone.stats.damage = 123
	self.siltstone.stats_modifiers = {
		damage = 2
	}
	
	--repeater, stability buff
	self.winchester1874.stats.recoil = 10
	
	--saw, damage buff
	self.saw.stats.damage = 78
	self.saw_secondary.stats.damage = 78
	
	--secondaries
	
	--peacemaker my beloved
	self.peacemaker.stats.recoil = 12 --i love you
	self.peacemaker.damage_falloff = FALLOFF_TEMPLATE.PISTOL_FALL_SUPER
	
	--matever, slight stability buff
	self.mateba.stats.recoil = 5
	
	--castigo, slight stability buff
	self.chinchilla.stats.recoil = 4
	
	--crosskill, max ammo buff, ammo pickup buff, concealment nerf, threat buff, spread nerf
	self.colt_1911.stats.suppression = 14
	self.colt_1911.stats.concealment = 25
	self.colt_1911.stats.spread = 15
	--self.colt_1911.NR_CLIPS_MAX = 10
	--self.colt_1911.AMMO_MAX = self.colt_1911.CLIP_AMMO_MAX * self.colt_1911.NR_CLIPS_MAX
	--self.colt_1911.AMMO_PICKUP = self:_pickup_chance(self.colt_1911.AMMO_MAX, PICKUP.PISTOL_HIGH_CAPACITY)
	
	--crosskill chunky
	self.m1911.stats.recoil = 12
	self.m1911.stats.spread = 20
	self.m1911.stats.concealment = 24
	self.m1911.stats.suppression = 12
	self.m1911.stats.damage = 80
	--self.m1911.AMMO_PICKUP = self:_pickup_chance(self.colt_1911.AMMO_MAX, PICKUP.PISTOL_HIGH_CAPACITY)
	
	--interceptor, threat buff, stability buff, firerate change, concealment nerf, max ammo nerf
	--self.usp.NR_CLIPS_MAX = 10
	--self.usp.NR_CLIPS_MAX = 5
	--self.usp.AMMO_MAX = self.usp.CLIP_AMMO_MAX * self.usp.NR_CLIPS_MAX
	self.usp.stats.recoil = 16
	self.usp.stats.concealment = 26
	self.usp.stats.suppression = 12
	self.usp.fire_mode_data = {
		fire_rate = 0.084
	}
	self.usp.single = {
		fire_rate = 0.084
	}
	
	--chimano custom, stability buff
	self.g22c.stats.recoil = 18
	self.g22c.stats.suppression = 17
	
	--LEO pistol, slight concealment nerf, max ammo nerf, accuracy boost
	self.hs2000.stats.suppression = 15
	self.hs2000.stats.spread = 21
	self.hs2000.stats.concealment = 27
	--self.hs2000.NR_CLIPS_MAX = 4
	--self.hs2000.AMMO_MAX = self.hs2000.CLIP_AMMO_MAX * self.hs2000.NR_CLIPS_MAX
	
	--signature. 40, slight concealment nerf
	self.p226.stats.suppression = 15
	self.p226.stats.concealment = 28
	
	--gecko m2, threat nerf
	self.maxim9.stats.suppression = #self.stats.suppression
	
	--kang arms model 54, damage nerf, underbarrel ammo pickup buff
	self.type54.stats.damage = 80
	self.type54_underbarrel.AMMO_PICKUP[1] = 0.45
	
	--stryk 18c, ammo pickup buff
	--self.glock_18c.NR_CLIPS_MAX = 12
	--self.glock_18c.AMMO_MAX = self.glock_18c.CLIP_AMMO_MAX * self.glock_18c.NR_CLIPS_MAX
	--self.glock_18c.AMMO_PICKUP = self:_pickup_chance(self.glock_18c.AMMO_MAX, PICKUP.OTHER)
	
	--parabellum, damage reduction, ammo pickup increase by a bunch
	self.breech.stats.damage = 59
	--self.breech.AMMO_PICKUP = self:_pickup_chance(self.glock_17.AMMO_MAX, PICKUP.PISTOL_LOW_CAPACITY)
	
	--baby deagle, damage reduction, ammo pickup increase
	self.sparrow.stats.suppression = 13
	self.sparrow.stats.concealment = 27
	self.sparrow.stats.spread = 19
	self.sparrow.stats.damage = self.p226.stats.damage + 8
	--self.sparrow.AMMO_PICKUP = self:_pickup_chance(self.p226.AMMO_MAX, PICKUP.PISTOL_HIGH_CAPACITY)
	
	--compact-5, damage buff
	self.new_mp5.stats.damage = 50
	
	--signature smg, massive stat buffs
	self.shepheard.stats.recoil = 16
	self.shepheard.stats.spread = 19
	
	--CMP, accuracy boost, stability buff, max ammo buff
	--self.mp9.NR_CLIPS_MAX = 9
	--self.mp9.AMMO_MAX = self.mp9.CLIP_AMMO_MAX * self.mp9.NR_CLIPS_MAX
	self.mp9.stats.spread = 10
	self.mp9.stats.recoil = 22
	
	--krinkov, max ammo increase
	--self.akmsu.NR_CLIPS_MAX = 5
	--self.akmsu.AMMO_MAX = self.akmsu.CLIP_AMMO_MAX * self.akmsu.NR_CLIPS_MAX
	
	--para, max ammo increase
	--self.olympic.NR_CLIPS_MAX = 11
	--self.olympic.AMMO_MAX = self.olympic.CLIP_AMMO_MAX * self.olympic.NR_CLIPS_MAX
	
	--cobra submachine gun, accuracy adjustment
	self.scorpion.stats.spread = 14
	
	--blaster 9mm, accuracy adjustment
	self.tec9.stats.spread = 10
	
	--jacket's piece, threat buff, damage buff, accuracy reduced
	self.cobray.stats.damage = 66
	self.cobray.stats.spread = 12
	self.cobray.stats.suppression = 10

	--heather smg, accuracy boost, stability buff, fixed it being a copy of jacket's piece
	self.sr2.stats.spread = 15
	self.sr2.stats.recoil = 20
	self.sr2.CLIP_AMMO_MAX = 30
	--self.sr2.NR_CLIPS_MAX = 6
	--self.sr2.AMMO_MAX = self.sr2.CLIP_AMMO_MAX * self.sr2.NR_CLIPS_MAX
	--self.sr2.AMMO_PICKUP = self:_pickup_chance(self.sr2.AMMO_MAX, PICKUP.AR_MED_CAPACITY)
	
	--cr 805b, slight ammo pickup buff, slight concealment buff
	self.hajk.stats.concealment = 19
	self.hajk.AMMO_PICKUP = {1, 3.4}
	
	--tatonka, damage nerf
	self.coal.stats.damage = 82
	
	--ak gen 21, ammo pickup nerf
	--self.vityaz.AMMO_PICKUP = {1.92, 6.72}
	
	--locomotive, accuracy reduced
	self.serbu.stats.spread = 9
	
	--grimm 12g, damage boost, accuracy boost, threat nerf, max ammo nerf
	self.basset.stats.damage = 30
	self.basset.stats.spread = 8
	self.basset.stats.suppression = 16
	--self.basset.NR_CLIPS_MAX = 10
	--self.basset.AMMO_MAX = self.basset.CLIP_AMMO_MAX * self.basset.NR_CLIPS_MAX
	
	--claire, big damage buff, max ammo nerf, ammo pickup buff
	self.coach.stats_modifiers = {
		damage = 1.5
	}
	--self.coach.NR_CLIPS_MAX = 8
	--self.coach.AMMO_MAX = self.coach.CLIP_AMMO_MAX * self.coach.NR_CLIPS_MAX
	--self.coach.AMMO_PICKUP = {0.5, 1}
	self.coach.damage_falloff = FALLOFF_TEMPLATE.SHOTGUN_FALL_PRIMARY_HIGH
	
	--gsps, stability nerf, ammo pickup increase
	self.m37.stats.spread = 14
	self.m37.stats.recoil = 8
	--self.m37.AMMO_PICKUP = self.boot.AMMO_PICKUP 
	
	--argos, accuracy boost
	self.ultima.stats.spread = 15
	
	--judge, ammo pickup increase, accuracy reduced, fire-rate change
	self.judge.stats.spread = 12
	--self.judge.AMMO_PICKUP = self.boot.AMMO_PICKUP
	self.judge.fire_mode_data = {
		fire_rate = 0.21
	}
	self.judge.single = {
		fire_rate = 0.21
	}
	self.judge.damage_falloff = FALLOFF_TEMPLATE.SHOTGUN_FALL_SECONDARY_MEDIUM
	
	--street sweeper, damage buff
	self.striker.stats.damage = 60
	self.striker.damage_falloff = FALLOFF_TEMPLATE.SHOTGUN_FALL_SECONDARY_HIGH
	
	--miniguns, damage increase, accuracy increase
	self.m134.stats.damage = 61
	self.m134.stats.spread = 12
	self.shuno.stats.damage = 41
	self.shuno.stats.spread = 10
	self.shuno.stats.recoil = 10

	self:_init_rengaged_stat_changes()
	local akimbos = self:get_akimbo_mappings()
	
	for k, v in pairs(self) do
		local continue = true
		local revolver = nil
		
		if not v.regunned and v.stats then
			if v.categories then
				local add_dmr = nil
				local cats = v.categories
				local do_recoil_tweak = true
				
				if cats[3] == "revolver" or cats[2] == "revolver" then
					revolver = true
				end
				
				for i = 1, #cats do
					local category = cats[i]

					if category == "akimbo" or category == "bow" or category == "crossbow" or category == "saw" then
						continue = nil
						
						break
					elseif category == "assault_rifle" then
						if v.stats.damage >= 160 then
							if v.FIRE_MODE == "single" then
								add_dmr = true
								
								v.damage_falloff = FALLOFF_TEMPLATE.ASSAULT_FALL_HIGH

								if not v.CAN_TOGGLE_FIREMODE then
									v.fire_mode_data.fire_rate = v.fire_mode_data.fire_rate / 0.6
								
									if v.single then
										v.single.fire_rate = v.single.fire_rate / 0.6
									end
								end
							end
						elseif v.stats.damage > 60 then
							v.damage_falloff = FALLOFF_TEMPLATE.ASSAULT_FALL_MEDIUM
						else
							v.damage_falloff = FALLOFF_TEMPLATE.ASSAULT_FALL_LOW
							v.stats.concealment = math.min(v.stats.concealment + 4, #self.stats.concealment)
						end
					elseif category == "smg" then
						if v.fire_mode_data then
							if v.fire_mode_data.fire_rate >= 0.08 then
								v.damage_falloff = FALLOFF_TEMPLATE.SMG_FALL_HIGH
							elseif v.fire_mode_data.fire_rate >= 0.063 then
								v.damage_falloff = FALLOFF_TEMPLATE.SMG_FALL_MEDIUM
							else
								v.damage_falloff = FALLOFF_TEMPLATE.SMG_FALL_LOW
							end
						end
					end
					
					if category == "shotgun" then
						if v.has_magazine then
							v.stats.spread = math.min(v.stats.spread + 4, #self.stats.spread)
							
							if v.stats.suppression then
								v.stats.suppression = math.min(v.stats.suppression + 5, #self.stats.suppression)
							end
						elseif not v.use_shotgun_reload and not v.empty_on_reload and not v.dont_empty_on_reload then
							if v.timers then
								if v.timers.shotgun_reload_enter then
									v.use_shotgun_reload = true
								elseif v.CLIP_AMMO_MAX > 2 then
									local reload_empty = v.timers.reload_empty
									local reload_not_empty = v.timers.reload_not_empty
									
									if reload_empty and reload_not_empty then
										if reload_empty ~= reload_not_empty then
											v.use_shotgun_reload = true
											--log(k .. " has shotgun reload")
										end
									else
										v.use_shotgun_reload = true
										--log(k .. " has shotgun reload")
									end
								end
							end
						end
					end
					
					if category == "shotgun" or category == "snp" then	
						do_recoil_tweak = nil
						
						break
					elseif revolver then
						if category == "revolver" or category == "pistol" then
							if v.FIRE_MODE == "single" and not v.CAN_TOGGLE_FIREMODE then 
								v.fire_mode_data.fire_rate = v.fire_mode_data.fire_rate / 0.6
								
								if v.single then
									v.single.fire_rate = v.single.fire_rate / 0.6
								end
							end
						end
					
						do_recoil_tweak = true
						
						break
					elseif category == "pistol" then
						if v.FIRE_MODE == "single" and not v.CAN_TOGGLE_FIREMODE then 
							v.fire_mode_data.fire_rate = v.fire_mode_data.fire_rate / 0.8
							
							if v.single then
								v.single.fire_rate = v.single.fire_rate / 0.8
							end
						end
					
						do_recoil_tweak = category
						
						break
					elseif category == "flamethrower" then
						do_recoil_tweak = category
					end
				end
				
				if continue then
					if do_recoil_tweak == "pistol" then
						v.kick = pistol_recoil_table
					elseif do_recoil_tweak == "flamethrower" then
						v.kick = flamethrower_recoil_table
					elseif do_recoil_tweak then
						v.kick = recoil_table
					end
					
					if add_dmr then
						v.categories[#v.categories + 1] = "regunz_dmr"
					end
				end
			end
			
			if continue then
				if v.NR_CLIPS_MAX and v.AMMO_PICKUP then				
					local empty_on_reload = v.empty_on_reload and not v.dont_empty_on_reload and not v.use_shotgun_reload
					
					if not v.use_shotgun_reload and not v.dont_empty_on_reload and not empty_on_reload and not v.has_magazine and v.timers then
						local timers = v.timers
						empty_on_reload = timers.reload_not_empty == timers.reload_empty
					end
					
					if v.dont_empty_on_reload then
						empty_on_reload = nil
					end
					
					v.empty_on_reload = empty_on_reload
					
					local clips_max_reduction = 2
					
					if v.use_shotgun_reload then
						if v.CLIP_AMMO_MAX > 8 then
							clips_max_reduction = 4
						elseif v.CLIP_AMMO_MAX > 6 then
							clips_max_reduction = 3
						elseif v.CLIP_AMMO_MAX < 5 then
							clips_max_reduction = 0
						end
						
						if v.stats.damage <= 55 then
							clips_max_reduction = clips_max_reduction + 2
						end
					end
					
					local clips_max = math.max(2, v.NR_CLIPS_MAX - clips_max_reduction)
					
					if not v.use_shotgun_reload and v.CLIP_AMMO_MAX >= 5 then
						clips_max = math.min(4, clips_max)
					end
					
					clips_max = math.floor(clips_max)
					
					v.NR_CLIPS_MAX = clips_max
					v.AMMO_MAX = v.CLIP_AMMO_MAX * v.NR_CLIPS_MAX
					
					local damage_sanitized = v.stats.damage
					local damage_mul = v.stats_modifiers and v.stats_modifiers.damage or 0
					
					if damage_mul > 1 then
						damage_sanitized = damage_sanitized * damage_mul
					end
					
					damage_sanitized = math.max(38, v.stats.damage)
					damage_sanitized = math.min(v.stats.damage, 160)

					local pickup_mul = 1 / (damage_sanitized / 160)
					
					local lower_pickup_mul = v.use_data and v.use_data.selection_index > 2
					
					if lower_pickup_mul then
						if v.CLIP_AMMO_MAX < 2 then
							pickup_mul = pickup_mul * 0.75
						else
							pickup_mul = pickup_mul * 0.5
						end
					end
					
					pickup_mul = pickup_mul * 1 + (1 - math.min(v.NR_CLIPS_MAX / 4, 0.75))

					if empty_on_reload then
						pickup_mul = pickup_mul + 0.5
					end
					
					if damage_mul > 1 then
						pickup_mul = pickup_mul - (damage_mul * 0.01)
					end
					
					local lower_ammo_pickup = v.use_data and v.use_data.selection_index > 2 or v.CLIP_AMMO_MAX > 100 or v.use_shotgun_reload		
					local pickup = lower_ammo_pickup and 0.075 or 0.1
					pickup = pickup * pickup_mul
		
					local clip_ammo_controlled = math.min(v.CLIP_AMMO_MAX, 100)
					local true_pickup_value = clip_ammo_controlled * pickup
					
					if true_pickup_value > 1 then
						true_pickup_value = math.floor(true_pickup_value)
					end
					
					if true_pickup_value <= 0 then
						log(k .. " ammo pickup: " .. true_pickup_value)
					end

					v.AMMO_PICKUP = {true_pickup_value, true_pickup_value}
				end
			
				if v.stats.suppression then
					if revolver then
						v.stats.suppression = math.min(v.stats.suppression, #self.stats.suppression)
					else
						v.stats.suppression = math.min(v.stats.suppression + 5, #self.stats.suppression)
					end
				end
				
				if not v.regunned and v.spread and type(v.spread) == "table" then
					v.spread = static_spread_table
				end
				
				if akimbos[k] then
					local akimbo_version = akimbos[k]
					self[akimbo_version].kick = v.kick
					self[akimbo_version].AMMO_MAX = v.AMMO_MAX * 2
					self[akimbo_version].AMMO_PICKUP = v.AMMO_PICKUP
					self[akimbo_version].spread = akimbo_spread_table
					self[akimbo_version].stats = clone(v.stats)
					self[akimbo_version].stats.concealment = math.max(v.stats.concealment - 2, 1)
					self[akimbo_version].stats.recoil = math.max(v.stats.recoil - 4, 1)
					self[akimbo_version].stats.spread = math.max(v.stats.spread - 2, 1)
					self[akimbo_version].stats.zoom = v.stats.zoom
					self[akimbo_version].damage_falloff = v.damage_falloff
					self[akimbo_version].regunned = true
				end
				
				v.regunned = true
			end
		end
	end
end)