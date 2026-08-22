Hooks:PostHook(BlackMarketTweakData, "init", "reengage_bm", function(self, tweak_data)
	self.melee_weapons.weapon.no_cleave = true
	self.melee_weapons.taser.no_cleave = true
	self.melee_weapons.fight.no_cleave = true
	self.melee_weapons.freedom.no_dot_check = true
	self.melee_weapons.pitchfork.no_dot_check = true
	self.melee_weapons.buck.stats.cleave_radius = 25

	if RNGAGED.settings.disable_balance_changes then
		return
	end

	self.melee_weapons.weapon.stats.min_damage = 8
	self.melee_weapons.weapon.stats.max_damage = 8
	self.melee_weapons.taser.stats.charge_time = 1
	self.melee_weapons.grip.type = "sharp"
	self.melee_weapons.grip.melee_damage_delay = 0

	for k, v in pairs(self.melee_weapons) do
		--log(tostring(k))
		if not v.regunned and v.stats and k ~= "weapon" then
			v.stats.concealment = nil
			local expire_add = v.stats.min_damage * v.expire_t
			expire_add = expire_add - v.stats.min_damage
			
			local repeat_t_add
			
			if v.repeat_expire_t then
				repeat_t_add = v.stats.min_damage * math.min(v.repeat_expire_t, v.expire_t)
			else
				repeat_t_add = v.stats.min_damage * v.expire_t
			end
			
			repeat_t_add = repeat_t_add - v.stats.min_damage
			
			if v.melee_damage_delay then
				local dmg_delay_mul = 1 - v.melee_damage_delay
				v.stats.min_damage = 8 / dmg_delay_mul
			else
				v.stats.min_damage = 8
			end
			
			v.stats.min_damage = v.stats.min_damage + repeat_t_add
			
			local charge_mul = 1 + v.stats.charge_time
			
			if not v.tase_data and not v.dot_data_name and v.stats.charge_time <= 2 then
				v.stats.auto_counter = true
			end
			
			v.stats.max_damage = v.stats.min_damage * charge_mul
			v.stats.max_damage = v.stats.max_damage + expire_add
			
			if v.tase_data or v.dot_data_name then
				v.stats.min_damage = v.stats.min_damage * 0.5
				v.stats.max_damage = v.stats.max_damage * 0.5
			elseif v.no_cleave then
				v.stats.max_damage = v.stats.max_damage * 1.25
			end

			
			v.stats.max_damage = math.ceil(v.stats.max_damage)
			v.stats.min_damage = v.stats.max_damage / 4
			v.stats.min_damage = math.ceil(v.stats.min_damage)
			
			
			if v.stats.weapon_type == "blunt" then
				if v.tase_data or v.dot_data and v.dot_data.name then
					v.stats.min_damage_effect = 0
					v.stats.max_damage_effect = 0
				elseif v.stats.charge_time > 2 then
					v.stats.min_damage_effect = 2
					v.stats.max_damage_effect = 2
				else
					v.stats.min_damage_effect = 1.2
					v.stats.max_damage_effect = 1.5
				end
			elseif v.tase_data or v.dot_data and v.dot_data.name then
				v.stats.min_damage_effect = 0
				v.stats.max_damage_effect = 0
			else
				v.stats.min_damage_effect = 1
				v.stats.max_damage_effect = 1
			end
		
			v.regunned = true
		end
	end

end)

Hooks:PostHook(BlackMarketTweakData, "_init_projectiles", "reengaged_grenades", function(self, tweak_data)
	self.projectiles.sandy_tuner = {
		name_id = "bm_grenade_sandy",
		desc_id = "bm_grenade_sandy_desc",
		icon = "guis/dlcs/pd2_mod_rgg/textures/pd2/hud_sandy_tuner_ability",
		texture_bundle_folder = "pd2_mod_rgg",
		ability = "sandy_tuner",
		custom = true,
		ignore_statistics = true,
		based_on = "copr_ability",
		max_amount = 1,
		base_cooldown = 11,
		sounds = {
			--activate = "perkdeck_activate",
			cooldown = "ch_pad_open"
		}
	}
	table.insert(self._projectiles_index, "sandy_tuner")
	
	if RNGAGED.settings.disable_balance_changes then
		return
	end
	
	self.projectiles.frag.base_cooldown = 120
	self.projectiles.frag.sounds = {
		cooldown = "grenade_pull_pin"
	}
	self.projectiles.frag_com.base_cooldown = 120
	self.projectiles.frag_com.sounds = {
		cooldown = "grenade_pull_pin"
	}
	self.projectiles.dada_com.impact_detonation = true
	self.projectiles.dada_com.base_cooldown = 120
	self.projectiles.dada_com.sounds = {
		cooldown = "mtl_throw"
	}
end)