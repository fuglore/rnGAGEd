if not RNGAGED.settings.disable_balance_changes then

function NewRaycastWeaponBase:recoil_wait()
	local tweak_is_auto = tweak_data.weapon[self._name_id].FIRE_MODE == "auto"
	local weapon_is_auto = self:fire_mode() == "auto"
	local multiplier = tweak_is_auto == weapon_is_auto and 1 or 1.05

	return self:weapon_fire_rate() * multiplier
end

function RaycastWeaponBase:regunz_get_slowdown_lerp() --this implementation sucks and doesn't feel good, make something better eventually
	if self._shooting then
		return 0
	elseif self._next_fire_allowed > self._unit:timer():time() then
		return self._unit:timer():time() / self._next_fire_allowed
	else
		return 1
	end
end

function NewRaycastWeaponBase:_get_spread(user_unit)
	local current_state = user_unit:movement():current_state()
	local current_state_name = user_unit:movement():current_state_name()

	if not current_state then
		return 0, 0
	end

	local spread_values = self:weapon_tweak_data().spread

	if not spread_values then
		return 0, 0
	end

	local current_spread_value = spread_values["standing"]
	local spread_x, spread_y = nil

	if type(current_spread_value) == "number" then
		spread_x = self:_get_spread_from_number(user_unit, current_state, current_spread_value)
		spread_y = spread_x
	else
		spread_x, spread_y = self:_get_spread_from_table(user_unit, current_state, current_spread_value)
	end
	
	if not self._is_saw and current_state_name ~= "bipod" then
		local accrec_spread_add = 0
		local mov_spread_add = 0
		
		if self.regunz_accrec_mul and self.regunz_accrec_mul > 0 then
			local accrec = self.regunz_accrec_penalty or 0
			local recoil_index = managers.blackmarket:recoil_index(self._name_id, self:weapon_tweak_data().categories, self._current_stats_indices and self._current_stats_indices.recoil, self._silencer, self._blueprint, current_state, self:is_single_shot())
			local spread = tweak_data.weapon.stats.spread[recoil_index] * self.regunz_accrec_mul
			
			if self.regunz_accrec_inverse then
				accrec_spread_add = spread * (1 - accrec)
			else
				accrec_spread_add = spread * accrec
			end
		end
		
		if self.regunz_movepen_mul and self.regunz_movepen_mul > 0 then
			local movepen = self.regunz_movement_penalty or 0
			
			if movepen > 0 then
				local concealment_index = math.clamp(self._current_stats_indices.concealment, 1, #tweak_data.weapon.stats.spread)
				local spread = tweak_data.weapon.stats.spread[concealment_index] * self.regunz_movepen_mul
				
				mov_spread_add = spread * movepen
			end
		end
		
		spread_x = spread_x + accrec_spread_add
		spread_x = spread_x + mov_spread_add
		spread_y = spread_y + accrec_spread_add
		spread_y = spread_y + mov_spread_add
	
		if current_state:in_steelsight() and not self._is_saw and self.regunz_zoom_mul then
			local zoom_mul = self.regunz_zoom_mul
				
			spread_x = spread_x * zoom_mul
			spread_y = spread_y * zoom_mul
		end
	end

	if self._spread_multiplier then
		spread_x = spread_x * self._spread_multiplier[1]
		spread_y = spread_y * self._spread_multiplier[2]
	end

	return spread_x, spread_y
end

local old_steelsight_speed = NewRaycastWeaponBase.enter_steelsight_speed_multiplier

function NewRaycastWeaponBase:enter_steelsight_speed_multiplier()
	local speed_mul = old_steelsight_speed(self)
	
	if self._current_stats.suspicion then
		speed_mul = speed_mul / self._current_stats.suspicion
		
		--log(tostring(speed_mul))
	end

	return speed_mul
end

end

local old_reload_speed = NewRaycastWeaponBase.reload_speed_multiplier

function NewRaycastWeaponBase:reload_speed_multiplier()
	if self._current_reload_speed_multiplier then
		return self._current_reload_speed_multiplier
	end

	local speed_mul = old_reload_speed(self)
	
	if self._regunz_reload_speed_mul then
		speed_mul = speed_mul * self._regunz_reload_speed_mul
	end
	
	speed_mul = speed_mul / managers.player:upgrade_value("player", "sandy_reload_speed_mul", 1)
	--log(tostring(self._regunz_reload_speed_mul))

	return speed_mul
end

local gunmuls = {
	snp = {
		1,
		0
	},
	shotgun = {
		0,
		1
	},
	revolver = {
		1,
		1
	},
	pistol = {
		1,
		1
	},
	lmg = {
		1,
		2,
	},
	akimbo = {
		1,
		1
	},
	assault_rifle = {
		1,
		1
	},
	smg = {
		1,
		1
	},
	minigun = {
		1,
		2
	},
	regunz_dmr = {
		1,
		1
	}
}

local slow_guns = {
	shotgun = true,
	assault_rifle = true,
	lmg = true,
	revolver = true,
	snp = true,
	regunz_dmr = true
}

local upd_stats_values = NewRaycastWeaponBase._update_stats_values

function NewRaycastWeaponBase:_update_stats_values(disallow_replenish, ammo_data)	
	upd_stats_values(self, disallow_replenish, ammo_data)
--Hooks:PostHook(NewRaycastWeaponBase, "_update_stats_values", "regunz_accfalloff", function(self, disallow_replenish, ammo_data)
	if self:is_npc() or self:_third_person() then
		return
	end

	if RNGAGED.settings.disable_balance_changes then
		return
	end
	
	local categories = self:weapon_tweak_data().categories
	
	for i = 1, #categories do
		local cat = categories[i]
		
		if cat == "saw" then
			self._is_saw = true
			return
		end
	end

	if self._current_stats then
		local falloff_mul = math.clamp(math.lerp(0, 2, self._current_stats_indices.spread / 26), 0.1, 2)
		
		if self._silencer then
			falloff_mul = falloff_mul * managers.player:upgrade_value("weapon", "silencer_damage_falloff_extend", 1)
		end
		
		self._optimal_distance = self._optimal_distance * falloff_mul
		self._optimal_range = self._optimal_range * falloff_mul
		self._near_falloff = self._near_falloff * falloff_mul
		self._far_falloff = self._far_falloff * falloff_mul
		
		if managers.player:has_category_upgrade("weapon", "silencer_damage_falloff_penalty_reduction") then
			if self._far_multiplier < 1 then
				if self._silencer then
					local penalty = 1 - self._far_multiplier
					penalty = penalty * managers.player:upgrade_value("weapon", "silencer_damage_falloff_penalty_reduction", 1)
					
					self._far_multiplier = 1 - penalty
				end
			end
		end
		
		local stats_tweak_data = tweak_data.weapon.stats
		local ammo_mul = stats_tweak_data.threat_ammo_mul[self._current_stats_indices.suppression]
		
		self._ammo_data.ammo_pickup_min_mul = self._ammo_data.ammo_pickup_min_mul and self._ammo_data.ammo_pickup_min_mul * ammo_mul or ammo_mul
		self._ammo_data.ammo_pickup_max_mul = self._ammo_data.ammo_pickup_max_mul and self._ammo_data.ammo_pickup_max_mul * ammo_mul or ammo_mul

		self.regunz_zoom_mul = self._current_stats.zoom / 120
		
		self._regunz_reload_speed_mul = stats_tweak_data.concealment_reload_mul[self._current_stats_indices.concealment]
		self._regunz_minigun_knock_chance = self:weapon_tweak_data().regunz_shield_knock_chance
		
		if self:weapon_tweak_data().weapon_movement_penalty then
			self._movement_penalty = self._movement_penalty == 1 and self:weapon_tweak_data().weapon_movement_penalty or self._movement_penalty * self:weapon_tweak_data().weapon_movement_penalty
		end
	end

	if not disallow_replenish and self:weapon_tweak_data().categories then
		local cats = self:weapon_tweak_data().categories
		local apply_akimbo_modifier = nil

		for i = 1, #cats do
			local cat = cats[i]
			
			if cat == "saw" then
				break
			end

			--if slow_guns[cat] then
				--self.regunz_slow_gun = true
			--end
			
			if not self.regunz_accrec_inverse then
				if cat == "lmg" or cat == "minigun" then
					self.regunz_accrec_inverse = true
				end
			end
			
			
			if cat == "akimbo" then
				apply_akimbo_modifier = true
			elseif gunmuls[cat] then
				if not self.regunz_movepen_mul or self.regunz_movepen_mul < gunmuls[cat][1] then
					self.regunz_movepen_mul = gunmuls[cat][1]
				end
				
				if not self.regunz_accrec_mul or self.regunz_accrec_mul < gunmuls[cat][2] then
					self.regunz_accrec_mul = gunmuls[cat][2]
				end
			end
		end
		
		if apply_akimbo_modifier then
			self.regunz_movepen_mul = self.regunz_movepen_mul and self.regunz_movepen_mul * gunmuls["akimbo"][1] or gunmuls["akimbo"][1]
			self.regunz_accrec_mul = self.regunz_accrec_mul and self.regunz_accrec_mul * gunmuls["akimbo"][2] or gunmuls["akimbo"][2]
		end
	end
	
	self._hurt_dmg_increase = managers.player:upgrade_value("weapon", "increase_stagger_dmg", 1)
end

function NewRaycastWeaponBase:has_dmg_resist()
	return self._weapon_dmg_resist
end

function NewRaycastWeaponBase:calculate_ammo_max_per_clip()
	local added = 0
	local weapon_tweak_data = self:weapon_tweak_data()

	if self:is_category("shotgun") and tweak_data.weapon[self._name_id].has_magazine then
		added = managers.player:upgrade_value("shotgun", "magazine_capacity_inc", 0)

		if self:is_category("akimbo") then
			added = added * 2
		end
	elseif self:is_category("pistol") and not self:is_category("revolver") and managers.player:has_category_upgrade("pistol", "magazine_capacity_inc") then
		added = managers.player:upgrade_value("pistol", "magazine_capacity_inc", 0)

		if self:is_category("akimbo") then
			added = added * 2
		end
	elseif self:is_category("smg", "assault_rifle", "lmg") then
		added = managers.player:upgrade_value("player", "automatic_mag_increase", 0)

		if self:is_category("akimbo") then
			added = added * 2
		end
	end

	local ammo = self:_get_magazine_size_from_parts() + added
	ammo = ammo + managers.player:upgrade_value(self._name_id, "clip_ammo_increase")

	if not self:upgrade_blocked("weapon", "clip_ammo_increase") then
		ammo = ammo + managers.player:upgrade_value("weapon", "clip_ammo_increase", 0)
	end

	for _, category in ipairs(tweak_data.weapon[self._name_id].categories) do
		if not self:upgrade_blocked(category, "clip_ammo_increase") then
			ammo = ammo + managers.player:upgrade_value(category, "clip_ammo_increase", 0)
		end
	end

	ammo = ammo + (self._extra_ammo or 0)

	return ammo
end

function NewRaycastWeaponBase:_get_magazine_size_from_parts()
	if self:is_npc() or self:_third_person() or not self._assembly_complete then
		return tweak_data.weapon[self._name_id].CLIP_AMMO_MAX
	end

	local custom_stats = managers.weapon_factory:get_custom_stats_from_weapon(self._factory_id, self._blueprint)
	local part_data = nil
	local is_underbarrel = self.is_underbarrel and self:is_underbarrel()
	local weap_factory_parts = tweak_data.weapon.factory.parts

	for part_id, stats in pairs(custom_stats) do
		part_data = weap_factory_parts[part_id]
		local can_apply = part_data.type == "magazine"

		if can_apply and stats.CLIP_AMMO_MAX then
			return stats.CLIP_AMMO_MAX 
		end
	end
	
	return tweak_data.weapon[self._name_id].CLIP_AMMO_MAX
end

local on_reload_old = NewRaycastWeaponBase.on_reload

function NewRaycastWeaponBase:on_reload(...)
	on_reload_old(self, ...)
--Hooks:PostHook(NewRaycastWeaponBase, "on_reload", "regunz_forget_reload_progress", function(self)
	if self:is_npc() or self:_third_person() or not self._assembly_complete then
		return
	end
	
	self._last_saved_reload_prog = nil
end

function NewRaycastWeaponBase:tweak_data_anim_is_playing(anim)
	local orig_anim = anim
	local unit_anim = self:_get_tweak_data_weapon_animation(orig_anim)
	local data = tweak_data.weapon.factory[self._factory_id]

	if data.animations and data.animations[unit_anim] then
		local anim_name = data.animations[unit_anim]

		if self._unit:anim_is_playing(Idstring(anim_name)) then
			return self._unit:anim_time(Idstring(anim_name))
		end
	end

	for part_id, data in pairs(self._parts) do
		if data.unit and data.animations and data.animations[unit_anim] then
			local anim_name = data.animations[unit_anim]

			if data.unit:anim_is_playing(Idstring(anim_name)) then
				return data.unit:anim_time(Idstring(unit_anim))
			end
		end
	end

	return self._unit:anim_is_playing(Idstring(unit_anim)) and self._unit:anim_time(Idstring(unit_anim))
end

function NewRaycastWeaponBase:_get_anim_start_offset(anim)
	if anim ~= "reload" and anim ~= "reload_not_empty" then
		return false
	end
	
	if self:use_shotgun_reload() then
		return
	end

	local player_unit = managers.player:player_unit()
	
	if not player_unit then
		return false
	end

	local is_player = self._setup.user_unit == managers.player:player_unit()
	
	if not is_player then
		return false
	end
	
	local current_state = player_unit:movement()._current_state
	
	if not current_state then
		return false
	end

	return self._last_saved_reload_prog
end