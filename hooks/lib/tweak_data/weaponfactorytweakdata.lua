if RNGAGED.settings.disable_balance_changes then
	return
end

Hooks:PostHook(WeaponFactoryTweakData, "init", "regunz_weaponmods", function(self)
	local saw_parts = {
		wpn_fps_saw_b_normal = true,
		wpn_fps_saw_body_standard = true,
		wpn_fps_saw_m_blade = true,
		wpn_fps_saw_body_silent = true,
		wpn_fps_saw_body_speed = true,
		wpn_fps_saw_m_blade_durable = true,
		wpn_fps_saw_m_blade_sharp = true,
	}
	
	self.parts.wpn_fps_upg_fl_ass_smg_sho_peqbox.stats = {value = 5}
	self.parts.wpn_fps_upg_fl_ass_smg_sho_surefire.stats = {value = 3}
	self.parts.wpn_fps_upg_fl_pis_laser.stats = {value = 5}
	self.parts.wpn_fps_upg_fl_pis_tlr1.stats = {value = 2}
	self.parts.wpn_fps_upg_fl_ass_utg.stats.concealment = -3
	
	--optics
	self.parts.wpn_fps_upg_o_fc1.stats = {
		zoom = 3,
		recoil = 1,
		concealment = -2,
		value = 3,
		spread_moving = -2
	}
	
	--ammo pouches/racks
	self.parts.wpn_fps_shot_b682_s_ammopouch.stats.total_ammo_mod = 5
	self.parts.wpn_fps_sho_ultima_body_rack.stats.total_ammo_mod = 5

	--m308 abraham body downside
	self.parts.wpn_fps_ass_m14_body_ebr.stats.spread = -1
	
	--m308 b-team body concealment nerf
	self.parts.wpn_fps_ass_m14_body_ruger.stats.concealment = 10
	
	--ak5 cqb barrel
	self.parts.wpn_fps_ass_ak5_b_short.stats.spread = -1
	self.parts.wpn_fps_ass_ak5_b_short.stats.concealment = 1
	self.parts.wpn_fps_ass_ak5_b_short.stats.recoil = 1

	for k, v in pairs(self.parts) do
		if not saw_parts[k] and v.stats and not v.regunned then
			for stat_name, value in pairs(v.stats) do
				if v.stats[stat_name] == 0 then
					v.stats[stat_name] = nil
				end
			end
			
			if v.type ~= "ammo" and v.type ~= "sight" then
				local perfect = v.stats.recoil and v.stats.recoil > 0 or v.stats.spread and v.stats.spread > 0
				local downsides = v.stats.recoil and v.stats.recoil < 0 or v.stats.spread and v.stats.spread < 0
				
				if downsides then
					perfect = nil
				end
				
				local perfect_concealment = not v.stats.concealment or v.stats.concealment > 0
				
				if perfect and perfect_concealment then
					local highest_stat = not v.stats.spread and v.stats.recoil or not v.stats.recoil and v.stats.spread or math.max(v.stats.spread, v.stats.recoil)
				
					v.stats.concealment = -highest_stat
					
					perfect_concealment = nil
				end
				
				if not downsides then
					if v.stats.extra_ammo and v.stats.extra_ammo > 0 and perfect_concealment or v.stats.total_ammo_mod and v.stats.total_ammo_mod > 0 and perfect_concealment then
						v.stats.concealment = -1
					end
				end
			end
		end
	end
	
	for k, v in pairs(self.parts) do
		if not saw_parts[k] and v.stats and not v.regunned then
			if v.stats.concealment then
				local concealment = v.stats.concealment
				
				if concealment < 0 then
					concealment = math.ceil(math.abs(concealment) / 2)
					v.stats.suppression = v.stats.suppression and v.stats.suppression - concealment or -concealment
				elseif concealment > 0 then
					concealment = math.ceil(math.abs(concealment) / 2)
					v.stats.suppression = v.stats.suppression and v.stats.suppression + concealment or concealment
				end
			end

			if v.stats.zoom and v.stats.zoom > 4 then
				v.stats.spread = 1
			elseif v.type == "sight" and v.stats.concealment and v.stats.concealment < -1 then
				v.stats.concealment = -1
				v.stats.suppression = -1
			end
			
			if not v.custom_stats then
				v.custom_stats = {}
			end
			
			v.regunned = true
		end
	end
	
	--magazine tweaks, m4 family
	self.parts.wpn_fps_m4_uupg_m_std.stats.spread = 2
	self.parts.wpn_fps_m4_uupg_m_std.custom_stats.CLIP_AMMO_MAX = 30
	self.parts.wpn_fps_upg_m4_m_straight.custom_stats.CLIP_AMMO_MAX = 20
	self.parts.wpn_fps_upg_m4_m_pmag.custom_stats.CLIP_AMMO_MAX = 30
	self.parts.wpn_fps_upg_m4_m_pmag.stats.spread = 1
	self.parts.wpn_fps_upg_m4_m_quad.custom_stats.CLIP_AMMO_MAX = 60
	
	self.parts.wpn_fps_ass_l85a2_m_emag.custom_stats.CLIP_AMMO_MAX = 30
	self.parts.wpn_fps_upg_m4_m_l5.custom_stats.CLIP_AMMO_MAX = 30
	self.parts.wpn_fps_m4_upg_m_quick.custom_stats.CLIP_AMMO_MAX = 30 --this is the milspec mag with a tiny little sling on it
	self.parts.wpn_fps_m4_uupg_m_strike.custom_stats.CLIP_AMMO_MAX = 30
	
	--magazine tweaks, ak family
	self.parts.wpn_fps_upg_ak_m_quad.custom_stats.CLIP_AMMO_MAX = 60
	self.parts.wpn_fps_upg_ak_m_uspalm.custom_stats.CLIP_AMMO_MAX = 30
	self.parts.wpn_fps_upg_ak_m_quick.custom_stats.CLIP_AMMO_MAX = 30
	
	for k, v in pairs(self.parts) do
		if not saw_parts[k] and v.stats and v.regunned then
			if v.custom_stats and v.custom_stats.CLIP_AMMO_MAX then
				v.stats.extra_ammo = nil
			end
		end
	end
	
	self.parts.wpn_fps_upg_a_custom.custom_stats.rays_add = -2
	self.parts.wpn_fps_upg_a_custom_free.custom_stats.rays_add = -2
	
	self.parts.wpn_fps_upg_a_piercing.stats.damage = -15
	
	self.parts.wpn_fps_upg_m4_g_hgrip.stats.concealment = -2
	self.parts.wpn_fps_upg_m4_g_hgrip.stats.suppression = -1
	
	--Pro Grip
	self.parts.wpn_fps_upg_m4_g_sniper.stats.recoil = 2 
	self.parts.wpn_fps_upg_m4_g_sniper.stats.concealment = -3	
	
	self.parts.wpn_fps_snp_victor_s_mod0.stats.recoil = nil --ursa minor stock
	
	--barrel exts for rifles and smgs
	
	--ported
	self.parts.wpn_fps_upg_ass_ns_battle.stats.concealment = nil
	self.parts.wpn_fps_upg_ass_ns_battle.stats.recoil = nil
	self.parts.wpn_fps_upg_ass_ns_battle.stats.damage = 1
	self.parts.wpn_fps_upg_ass_ns_battle.stats.spread = 2
	self.parts.wpn_fps_upg_ass_ns_battle.stats.suppression = 1
	
	--stubby
	self.parts.wpn_fps_upg_ns_ass_smg_stubby.stats.concealment = nil
	self.parts.wpn_fps_upg_ns_ass_smg_stubby.stats.recoil = 2
	self.parts.wpn_fps_upg_ns_ass_smg_stubby.stats.suppression = 1
	
	--the tank
	self.parts.wpn_fps_upg_ns_ass_smg_tank.stats.suppression = self.parts.wpn_fps_upg_ns_ass_smg_firepig.stats.suppression
	self.parts.wpn_fps_upg_ns_ass_smg_tank.stats.concealment = -2
	self.parts.wpn_fps_upg_ns_ass_smg_tank.stats.damage = 3
	self.parts.wpn_fps_upg_ns_ass_smg_tank.stats.spread = 1
	self.parts.wpn_fps_upg_ns_ass_smg_tank.stats.recoil = nil
	
	--funnel of fun
	self.parts.wpn_fps_upg_ass_ns_linear.stats.suppression = -8
	
	--competitor's compensator
	self.parts.wpn_fps_upg_ass_ns_jprifles.stats.concealment = -3
	self.parts.wpn_fps_upg_ass_ns_jprifles.stats.recoil = 2
	self.parts.wpn_fps_upg_ass_ns_jprifles.stats.damage = 1
	
	--marmon compensator
	self.parts.wpn_fps_upg_ns_ass_smg_v6.stats.suppression = self.parts.wpn_fps_upg_ass_ns_jprifles.stats.suppression
	
	--ks12-a burst muzzle
	self.parts.wpn_fps_ass_shak12_ns_muzzle.stats.recoil = 3
	self.parts.wpn_fps_ass_shak12_ns_muzzle.stats.spread = -1
	self.parts.wpn_fps_ass_shak12_ns_muzzle.stats.concealment = -2
	self.parts.wpn_fps_ass_shak12_ns_muzzle.stats.damage = 1
	self.parts.wpn_fps_ass_shak12_ns_muzzle.stats.suppression = -1
	
	--verdunkeln muzzle brake
	self.parts.wpn_fps_lmg_hk51b_ns_jcomp.stats.recoil = -2
	self.parts.wpn_fps_lmg_hk51b_ns_jcomp.stats.spread = nil
	self.parts.wpn_fps_lmg_hk51b_ns_jcomp.stats.concealment = -2
	self.parts.wpn_fps_lmg_hk51b_ns_jcomp.stats.damage = 4
	self.parts.wpn_fps_lmg_hk51b_ns_jcomp.stats.suppression = -8
	
	--dourif muzzle
	self.parts.wpn_fps_lmg_kacchainsaw_ns_muzzle.stats.spread = 4
	self.parts.wpn_fps_lmg_kacchainsaw_ns_muzzle.stats.recoil = -4
	self.parts.wpn_fps_lmg_kacchainsaw_ns_muzzle.stats.damage = nil
	
	--r870 muldon stock buff
	self.parts.wpn_fps_shot_r870_s_folding.stats.concealment = 2
	self.parts.wpn_fps_shot_r870_s_folding.stats.suppression = -2
		
	--shotgun muzzle buffs
	self.parts.wpn_fps_upg_ns_duck.stats.suppression = 4
	self.parts.wpn_fps_upg_shot_ns_king.stats.concealment = nil
	self.parts.wpn_fps_upg_shot_ns_king.stats.suppression = nil
	
	--slug buff
	self.parts.wpn_fps_upg_a_slug.stats.spread = 8
	self.parts.wpn_fps_upg_a_slug.stats.moving_spread = 8
	
	--Speedpull nerf
	self.parts.wpn_fps_m4_upg_m_quick.stats.suppression = 4
	self.parts.wpn_fps_m4_upg_m_quick.stats.reload = 3
	
	self.parts.wpn_fps_upg_ak_m_quick.stats.suppression = 4
	self.parts.wpn_fps_upg_ak_m_quick.stats.reload = 3
	
	self.parts.wpn_fps_ass_g36_m_quick.stats.suppression = 4
	self.parts.wpn_fps_ass_g36_m_quick.stats.reload = 3
	
	self.parts.wpn_fps_smg_p90_m_strap.stats.suppression = 4
	self.parts.wpn_fps_smg_p90_m_strap.stats.reload = 3
	
	self.parts.wpn_fps_smg_mac10_m_quick.stats.suppression = 4
	self.parts.wpn_fps_smg_mac10_m_quick.stats.extra_ammo = nil
	self.parts.wpn_fps_smg_mac10_m_quick.stats.reload = 3

	self.parts.wpn_fps_ass_aug_m_quick.stats.suppression = 4
	self.parts.wpn_fps_ass_aug_m_quick.stats.reload = 3
	
	self.parts.wpn_fps_smg_fmg9_m_speed.stats.suppression = 4
	self.parts.wpn_fps_smg_fmg9_m_speed.stats.reload = 3
	
	self.parts.wpn_fps_smg_sr2_m_quick.stats.suppression = 4
	self.parts.wpn_fps_smg_sr2_m_quick.stats.reload = 3
	
	self.parts.wpn_fps_smg_pm9_m_quick.stats.suppression = 4
	self.parts.wpn_fps_smg_pm9_m_quick.stats.reload = 3
	
	self.wpn_fps_smg_x_mac10.override.wpn_fps_smg_mac10_m_quick.stats.suppression = 4
	self.wpn_fps_smg_x_mac10.override.wpn_fps_smg_mac10_m_quick.stats.extra_ammo = nil
	self.wpn_fps_smg_x_mac10.override.wpn_fps_smg_mac10_m_quick.stats.reload = 3
	
	--grips
	self.parts.wpn_fps_upg_m4_g_ergo.stats.suppression = -1
	
	self.parts.wpn_fps_snp_tti_g_grippy.stats.recoil = nil
	self.parts.wpn_fps_snp_tti_g_grippy.stats.spread = 1
	self.parts.wpn_fps_snp_tti_g_grippy.stats.suppression = -1
	
	self.parts.wpn_fps_sho_sko12_body_grip.stats.recoil = 1
	self.parts.wpn_fps_sho_sko12_body_grip.stats.spread = nil
	
	--stocks
	self.parts.wpn_fps_snp_tti_s_vltor.stats.concealment = 1
	self.parts.wpn_fps_snp_tti_s_vltor.stats.spread = 1
	self.parts.wpn_fps_snp_tti_s_vltor.stats.suppression = 1
	self.parts.wpn_fps_snp_tti_s_vltor.stats.recoil = nil
	
	self.parts.wpn_fps_sho_sko12_stock.stats.concealment = -1
	self.parts.wpn_fps_sho_sko12_stock.stats.suppression = -1
	
	
	--gun specific mods
	
	--m4 upper receiver
	self.parts.wpn_fps_m4_uupg_upper_radian.stats.concealment = -2
	self.parts.wpn_fps_m4_uupg_upper_radian.stats.spread = -1
	
	--m4 lower receiver
	self.parts.wpn_fps_upg_ass_m4_lower_reciever_core.stats.recoil = 1
	self.parts.wpn_fps_upg_ass_m4_lower_reciever_core.stats.concealment = -1
	self.parts.wpn_fps_upg_ass_m4_lower_reciever_core.stats.spread = -1
	self.parts.wpn_fps_upg_ass_m4_lower_reciever_core.stats.suppression = -1
	self.parts.wpn_fps_m4_uupg_lower_radian.stats.recoil = -1
	
	--m4 foregrips
	self.parts.wpn_fps_upg_fg_jp.stats.concealment = 1
	self.parts.wpn_fps_upg_fg_jp.stats.spread = 1
	self.parts.wpn_fps_upg_fg_jp.stats.recoil = nil
	self.parts.wpn_fps_upg_fg_jp.stats.damage = nil

	self.parts.wpn_fps_uupg_fg_radian.stats.damage = nil
	self.parts.wpn_fps_uupg_fg_radian.stats.recoil = -2
	
	self.parts.wpn_fps_upg_ass_m4_fg_lvoa.stats.damage = nil
	self.parts.wpn_fps_upg_ass_m4_fg_lvoa.stats.recoil = 3
	self.parts.wpn_fps_upg_ass_m4_fg_lvoa.stats.concealment = -2
	self.parts.wpn_fps_upg_ass_m4_fg_lvoa.stats.suppression = -1

	self.parts.wpn_fps_upg_fg_smr.stats.spread = nil
	self.parts.wpn_fps_upg_fg_smr.stats.concealment = -4
	self.parts.wpn_fps_upg_fg_smr.stats.suppression = -4

	self.parts.wpn_fps_upg_ass_m4_fg_moe.stats.recoil = -1
	
	self.parts.wpn_fps_upg_ass_m16_fg_stag.stats.spread = 1
	self.parts.wpn_fps_upg_ass_m16_fg_stag.stats.recoil = 1
	
	--m4 mags	
	self.parts.wpn_fps_m4_uupg_m_std.stats.concealment = -2
	self.parts.wpn_fps_upg_m4_m_pmag.stats.suppression = -1
	
	self.parts.wpn_fps_upg_m4_m_l5.stats.recoil = nil
	self.parts.wpn_fps_upg_m4_m_l5.stats.spread = 1
	
	self.parts.wpn_fps_m4_uupg_m_strike.stats.recoil = -1
	self.parts.wpn_fps_m4_uupg_m_strike.stats.spread = -1
	
	--ak barrels
	self.parts.wpn_fps_upg_ak_b_ak105.stats.recoil = -2
	
	--ak barrel exts
	self.parts.wpn_fps_upg_ak_ns_zenitco.damage = -4
	self.parts.wpn_fps_upg_ak_ns_zenitco.spread = 2
	self.parts.wpn_fps_upg_ak_ns_zenitco.recoil = nil
	self.parts.wpn_fps_upg_ak_ns_zenitco.concealment = 2
	self.parts.wpn_fps_upg_ak_ns_zenitco.suppression = 5
	
	self.parts.wpn_fps_upg_ak_ns_jmac.damage = -4
	self.parts.wpn_fps_upg_ak_ns_jmac.spread = nil
	self.parts.wpn_fps_upg_ak_ns_jmac.recoil = 2
	self.parts.wpn_fps_upg_ak_ns_jmac.concealment = 2
	self.parts.wpn_fps_upg_ak_ns_jmac.suppression = 5
	
	--ak foregrips
	self.parts.wpn_upg_ak_fg_combo2.stats.spread = 1
	self.parts.wpn_upg_ak_fg_combo2.stats.recoil = nil
	self.parts.wpn_upg_ak_fg_combo2.stats.concealment = -1
	self.parts.wpn_upg_ak_fg_combo2.stats.suppression = -1
	
	self.parts.wpn_upg_ak_fg_combo3.stats.spread = nil
	self.parts.wpn_upg_ak_fg_combo3.stats.recoil = 1
	self.parts.wpn_upg_ak_fg_combo3.stats.concealment = -1
	self.parts.wpn_upg_ak_fg_combo3.stats.suppression = -1
	
	self.parts.wpn_fps_upg_ak_fg_tapco.stats.recoil = 1
	self.parts.wpn_fps_upg_ak_fg_tapco.stats.spread = nil
	
	self.parts.wpn_fps_upg_ak_fg_krebs.stats.spread = 1
	
	self.parts.wpn_fps_upg_fg_midwest.stats.concealment = -3
	self.parts.wpn_fps_upg_fg_midwest.stats.recoil = 2
	
	self.parts.wpn_fps_upg_ak_fg_trax.stats.recoil = 1
	
	self.parts.wpn_fps_upg_ak_fg_zenitco.stats.recoil = -1
	self.parts.wpn_fps_upg_ak_fg_zenitco.stats.concealment = nil
	self.parts.wpn_fps_upg_ak_fg_zenitco.stats.suppression = -2	
	
	--ak grips
	self.parts.wpn_fps_upg_ak_g_hgrip.stats.suppression = nil
	self.parts.wpn_fps_upg_ak_g_hgrip.stats.concealment = nil
	self.parts.wpn_fps_upg_ak_g_hgrip.stats.spread = -2
	
	self.parts.wpn_fps_upg_ak_g_wgrip.stats.spread = -1
	
	self.parts.wpn_fps_upg_ak_g_gradus.stats.spread = nil
	self.parts.wpn_fps_upg_ak_g_gradus.stats.recoil = 1
	
	self.parts.wpn_fps_upg_ak_g_edg.stats.concealment = -4
	self.parts.wpn_fps_upg_ak_g_edg.stats.suppression = -2
	
	self.parts.wpn_fps_upg_ak_g_rk9.stats.concealment = -2
	self.parts.wpn_fps_upg_ak_g_rk9.stats.suppression = -1
	
	--cobra submachine gun
	self.parts.wpn_fps_smg_scorpion_s_unfolded.stats.spread = 1
	self.parts.wpn_fps_smg_scorpion_m_extended.stats.extra_ammo = nil
	self.parts.wpn_fps_smg_scorpion_m_extended.stats.total_ammo_mod = 5
	
	--falcon rifles
	self.parts.wpn_fps_ass_fal_fg_04.stats.spread = 2 --marksman foregrip
	
	--extended magazine
	self.parts.wpn_fps_ass_fal_m_01.stats.extra_ammo = 5
	self.parts.wpn_fps_ass_fal_m_01.stats.concealment = -1
	self.parts.wpn_fps_ass_fal_m_01.stats.spread = nil
	self.parts.wpn_fps_ass_fal_m_01.stats.recoil = nil
	self.parts.wpn_fps_ass_fal_m_01.stats.spread_moving = nil
	
	--optics
	self.parts.wpn_fps_upg_o_health.stats = {
		value = 5,
		zoom = 2,
		spread = -1
	}
	
	--weapon specific override
	self.parts.wpn_fps_upg_o_mbus_pro.has_description = true
	
	self.wpn_fps_snp_sbl.override.wpn_fps_upg_o_mbus_pro = self.wpn_fps_snp_sbl.override.wpn_fps_upg_o_mbus_pro or {}
	self.wpn_fps_snp_sbl.override.wpn_fps_upg_o_mbus_pro.desc_id = "bm_wp_wtf_sbl_sights"
	self.wpn_fps_snp_sbl.override.wpn_fps_upg_o_mbus_pro.stats = {
		concealment = -4,
		spread = -4,
		recoil = -4,
		suppression = 10
	}
	
	self.wpn_fps_snp_tti.override = self.wpn_fps_snp_tti.override or {}
	self.wpn_fps_snp_tti.override.wpn_fps_upg_o_mbus_pro = self.wpn_fps_snp_tti.override.wpn_fps_upg_o_mbus_pro or {}
	self.wpn_fps_snp_tti.override.wpn_fps_upg_o_mbus_pro.desc_id = "bm_wp_wtf_sbl_sights"
	self.wpn_fps_snp_tti.override.wpn_fps_upg_o_mbus_pro.stats = {
		concealment = -4,
		spread = -4,
		recoil = -4,
		suppression = 10
	}
end)