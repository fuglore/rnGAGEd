if RNGAGED.settings.disable_balance_changes then
	local max_health_orig = PlayerDamage._max_health
	
	function PlayerDamage:_max_health()
		local max_health = max_health_orig(self)

		if managers.player:has_category_upgrade("player", "sandy_armor_to_health") then
			local max_armor = self:_raw_max_armor()
			local to_add = max_armor - managers.player:upgrade_value("player", "sandy_armor_to_health")
			max_health = max_health + to_add
		end

		return max_health
	end
	

	return
end

function PlayerDamage:_chk_dmg_too_soon(damage, armor_piercing)
	local next_allowed_dmg_t = self._next_allowed_dmg_t and Application:digest_value(self._next_allowed_dmg_t, false)
	
	if not next_allowed_dmg_t then
		return
	end
	
	local current_armor = self.get_real_armor and self:get_real_armor()
	
	if armor_piercing or current_armor and current_armor <= 0 then
		return managers.player:player_timer():time() < next_allowed_dmg_t
	end
	
	if damage <= self._last_received_dmg + 0.01 then
		return managers.player:player_timer():time() < next_allowed_dmg_t
	end
	
	if managers.player:player_timer():time() < next_allowed_dmg_t then
		--log("full damage: " .. damage)
		local old_received_damage = self._last_received_dmg
		self._last_received_dmg = damage
		damage = damage - old_received_damage
		--log("reduced damage: " .. damage)
	end
end

function PlayerDamage:_max_health()
	local max_health = self:_raw_max_health()

	if managers.player:has_category_upgrade("player", "armor_to_health_conversion") then
		local max_armor = self:_raw_max_armor()
		local conversion_factor = managers.player:upgrade_value("player", "armor_to_health_conversion") * 0.01
		max_health = max_health + max_armor * conversion_factor
	end
	
	if managers.player:has_category_upgrade("player", "sandy_armor_to_health") then
		local max_armor = self:_raw_max_armor()
		local to_add = max_armor - managers.player:upgrade_value("player", "sandy_armor_to_health")
		max_health = max_health + to_add
	end

	return max_health
end

function PlayerDamage:_max_armor()
	local max_armor = self:_raw_max_armor()

	if managers.player:has_category_upgrade("player", "armor_to_health_conversion") then
		local conversion_factor = managers.player:upgrade_value("player", "armor_to_health_conversion") * 0.01
		max_armor = max_armor * (1 - conversion_factor)
	end
	
	if managers.player:has_category_upgrade("player", "sandy_armor_to_health") then
		local to_remove = math.max(max_armor - managers.player:upgrade_value("player", "sandy_armor_to_health"), 0)
		max_armor = max_armor - to_remove
	end

	return max_armor
end

function PlayerDamage:set_armor(armor)
	if self._armor_change_blocked then
		return
	end

	self:_check_update_max_armor()
	
	if not self._max_armor_reduction then
		self._max_armor_reduction = managers.player:upgrade_value("player", "max_armor_reduction", 1)
	end
	
	local max_armor = self:_max_armor() * self._max_armor_reduction
	armor = math.min(armor, max_armor)
	armor = math.clamp(armor, 0, max_armor)

	if self._armor then
		local current_armor = self:get_real_armor()

		if current_armor == 0 and armor ~= 0 then
			self:consume_armor_stored_health()
		elseif current_armor ~= 0 and armor == 0 and self._dire_need then
			local function clbk()
				return self:is_regenerating_armor()
			end

			managers.player:add_coroutine(PlayerAction.DireNeed, PlayerAction.DireNeed, clbk, managers.player:upgrade_value("player", "armor_depleted_stagger_shot", 0))
		end
	end

	self._armor = Application:digest_value(armor, true)
end

function PlayerDamage:suppression_ratio()
	return (self._supperssion_data.value or 0) / 3
end

function PlayerDamage:damage_killzone(attack_data)
	local damage_info = {
		result = {
			variant = "killzone",
			type = "hurt"
		}
	}

	if self._god_mode or self._invulnerable or self._mission_damage_blockers.invulnerable then
		self:_call_listeners(damage_info)

		return
	elseif self:incapacitated() then
		return
	elseif self._unit:movement():current_state().immortal then
		return
	end

	self._unit:sound():play("player_hit")

	if attack_data.instant_death then
		self:set_armor(0)
		self:set_health(0)
		self:_send_set_armor()
		self:_send_set_health()
		managers.hud:set_player_health({
			current = self:get_real_health(),
			total = self:_max_health(),
			revives = Application:digest_value(self._revives, false)
		})
		self:_set_health_effect()
		self:_damage_screen()
		self:_check_bleed_out(nil)
	else
		self:_hit_direction(attack_data.col_ray.origin, attack_data.col_ray.ray)
		self:build_suppression(1)
		
		if self._bleed_out then
			return
		end

		attack_data.damage = managers.player:modify_value("damage_taken", attack_data.damage, attack_data)

		self:mutator_update_attack_data(attack_data)
		self:_check_chico_heal(attack_data)

		local armor_reduction_multiplier = 0

		if self:get_real_armor() <= 0 then
			armor_reduction_multiplier = 1
		end

		local health_subtracted = self:_calc_armor_damage(attack_data)
		attack_data.damage = attack_data.damage * armor_reduction_multiplier
		health_subtracted = health_subtracted + self:_calc_health_damage(attack_data)
	end

	self:_call_listeners(damage_info)
end

function PlayerDamage:damage_bullet(attack_data)
	--log(attack_data.damage)
	if not self:_chk_can_take_dmg() then
		return
	end

	local damage_info = {
		result = {
			variant = "bullet",
			type = "hurt"
		},
		attacker_unit = attack_data.attacker_unit,
		attack_dir = attack_data.attacker_unit and attack_data.attacker_unit:movement():m_pos() - self._unit:movement():m_pos() or Vector3(1, 0, 0),
		pos = mvector3.copy(self._unit:movement():m_head_pos())
	}

	self:copr_update_attack_data(attack_data)

	if self._god_mode then
		self:play_whizby(attack_data.col_ray.position)
	
		if attack_data.damage > 0 then
			self:_send_damage_drama(attack_data, attack_data.damage)
		end

		self:_call_listeners(damage_info)

		return
	elseif self._invulnerable or self._mission_damage_blockers.invulnerable then
		self:play_whizby(attack_data.col_ray.position)
	
		self:_call_listeners(damage_info)

		return
	elseif self:incapacitated() then
		return
	elseif self:is_friendly_fire(attack_data.attacker_unit) then
		self:play_whizby(attack_data.col_ray.position)
	
		return
	elseif self:_chk_dmg_too_soon(attack_data.damage) then
		self:play_whizby(attack_data.col_ray.position)
	
		return
	elseif self._unit:movement():current_state().immortal then
		return
	elseif self._revive_miss and math.random() < self._revive_miss then
		self:play_whizby(attack_data.col_ray.position)

		return
	end

	local pm = managers.player
	local dmg_mul = pm:damage_reduction_skill_multiplier("bullet")
	self._last_received_dmg = attack_data.damage
	self._next_allowed_dmg_t = Application:digest_value(pm:player_timer():time() + self._dmg_interval, true)
	
	attack_data.damage = attack_data.damage * dmg_mul	
	attack_data.damage = managers.mutators:modify_value("PlayerDamage:TakeDamageBullet", attack_data.damage)
	attack_data.damage = managers.modifiers:modify_value("PlayerDamage:TakeDamageBullet", attack_data.damage, attack_data.attacker_unit:base()._tweak_table)
	local charging_melee = self._unit:movement():current_state().in_melee and self._unit:movement():current_state():in_melee() 
	local in_melee = charging_melee or self._unit:movement():current_state()._state_data.melee_expire_t
	
	if in_melee then
		local melee_entry = managers.blackmarket:equipped_melee_weapon()
		local tase_or_dot = tweak_data.blackmarket.melee_weapons[melee_entry].tase_data or tweak_data.blackmarket.melee_weapons[melee_entry].dot_data_name
		local auto_counter = tweak_data.blackmarket.melee_weapons[melee_entry].stats.auto_counter
		
		if auto_counter or tase_or_dot then
			attack_data.damage = attack_data.damage * 0.75
		else
			attack_data.damage = attack_data.damage * 0.5
		end
	elseif pm:get_current_state() and pm:get_current_state()._equipped_unit then
		local equipped_unit = pm:get_current_state()._equipped_unit
		
		if equipped_unit and equipped_unit:base() and equipped_unit:base().has_dmg_resist and equipped_unit:base():has_dmg_resist() then
			attack_data.damage = attack_data.damage * 0.75
		end
	end
	
	
	if _G.IS_VR then
		local distance = mvector3.distance(self._unit:position(), attack_data.attacker_unit:position())

		if tweak_data.vr.long_range_damage_reduction_distance[1] < distance then
			local step = math.clamp(distance / tweak_data.vr.long_range_damage_reduction_distance[2], 0, 1)
			local mul = 1 - math.step(tweak_data.vr.long_range_damage_reduction[1], tweak_data.vr.long_range_damage_reduction[2], step)
			attack_data.damage = attack_data.damage * mul
		end
	end

	local damage_absorption = pm:damage_absorption()

	if damage_absorption > 0 then
		attack_data.damage = math.max(0, attack_data.damage - damage_absorption)
	end
	
	local dodge_roll = math.random()
	local dodge_value = tweak_data.player.damage.DODGE_INIT or 0
	local armor_dodge_chance = pm:body_armor_value("dodge")
	local skill_dodge_chance = pm:skill_dodge_chance(self._unit:movement():running(), self._unit:movement():crouching(), self._unit:movement():zipline_unit())
	dodge_value = dodge_value + armor_dodge_chance + skill_dodge_chance

	if self._temporary_dodge_t and TimerManager:game():time() < self._temporary_dodge_t then
		dodge_value = dodge_value + self._temporary_dodge
	end

	local smoke_dodge = 0

	for _, smoke_screen in ipairs(managers.player._smoke_screen_effects or {}) do
		if smoke_screen:is_in_smoke(self._unit) then
			smoke_dodge = tweak_data.projectiles.smoke_screen_grenade.dodge_chance

			break
		end
	end

	dodge_value = 1 - (1 - dodge_value) * (1 - smoke_dodge)

	if dodge_roll < dodge_value then
		self:_call_listeners(damage_info)
		self:play_whizby(attack_data.col_ray.position)
		self:_hit_direction(attack_data.attacker_unit:position(), attack_data.col_ray and attack_data.col_ray.ray or damage_info.attacK_dir)

		managers.player:send_message(Message.OnPlayerDodge, nil, attack_data)

		return
	elseif managers.player:has_category_upgrade("player", "dodge_reroll") then
		local new_roll = math.random()
		
		if new_roll < dodge_value then
			attack_data.damage = attack_data.damage * 0.5
		end
	end

	if attack_data.attacker_unit:base()._tweak_table == "tank" then
		managers.achievment:set_script_data("dodge_this_fail", true)
	end

	if self:get_real_armor() > 0 then
		self._unit:sound():play("player_hit")
	else
		self._unit:sound():play("player_hit_permadamage")
	end

	local shake_armor_multiplier = pm:body_armor_value("damage_shake") * pm:upgrade_value("player", "damage_shake_multiplier", 1)
	local gui_shake_number = tweak_data.gui.armor_damage_shake_base / shake_armor_multiplier
	gui_shake_number = gui_shake_number + pm:upgrade_value("player", "damage_shake_addend", 0)
	shake_armor_multiplier = tweak_data.gui.armor_damage_shake_base / gui_shake_number
	local shake_multiplier = math.clamp(attack_data.damage, 0.2, 2) * shake_armor_multiplier

	self._unit:camera():play_shaker("player_bullet_damage", 1 * shake_multiplier)

	if not _G.IS_VR then
		managers.rumble:play("damage_bullet")
	end

	self:_hit_direction(attack_data.attacker_unit:position(), attack_data.col_ray and attack_data.col_ray.ray or damage_info.attacK_dir)
	pm:check_damage_carry(attack_data)

	attack_data.damage = managers.player:modify_value("damage_taken", attack_data.damage, attack_data)

	if self._bleed_out then
		self:_bleed_out_damage(attack_data)

		return
	end

	self:mutator_update_attack_data(attack_data)
	self:_check_chico_heal(attack_data)

	local armor_reduction_multiplier = 0

	if self:get_real_armor() <= 0 then
		armor_reduction_multiplier = 1
	end

	local can_pierce = self:get_real_armor() > 0
	local health_subtracted = self:_calc_armor_damage(attack_data)

	if attack_data.armor_piercing then
		attack_data.damage = attack_data.damage - health_subtracted
		local pierced = can_pierce and self:get_real_armor() <= 0 and attack_data.damage > 0
		
		if pierced then
			attack_data.damage = attack_data.damage * pm:upgrade_value("player", "armor_piercing_dmg_resist", 1)
		end
	else
		if self:get_real_armor() <= 0 and armor_reduction_multiplier == 0 then
			managers.player:add_style("gate")
		end
	
		attack_data.damage = attack_data.damage * armor_reduction_multiplier
	end

	health_subtracted = health_subtracted + self:_calc_health_damage(attack_data)

	if not self._bleed_out and health_subtracted > 0 then
		self:_send_damage_drama(attack_data, health_subtracted)
	elseif self._bleed_out then
		self:chk_queue_taunt_line(attack_data)
	end

	pm:send_message(Message.OnPlayerDamage, nil, attack_data)
	self:_call_listeners(damage_info)
end

function PlayerDamage:damage_explosion(attack_data)
	if not self:_chk_can_take_dmg() then
		return
	end

	local damage_info = {
		result = {
			variant = "explosion",
			type = "hurt"
		}
	}

	if self._god_mode or self._invulnerable or self._mission_damage_blockers.invulnerable then
		self:_call_listeners(damage_info)

		return
	elseif self._unit:movement():current_state().immortal then
		return
	elseif self:incapacitated() then
		return
	end

	local distance = mvector3.distance(attack_data.position, self._unit:position())

	if attack_data.range < distance then
		return
	end

	local damage = (attack_data.damage or 1) * (1 - distance / attack_data.range)

	if self._bleed_out then
		return
	end

	local dmg_mul = managers.player:damage_reduction_skill_multiplier("explosion")
	attack_data.damage = damage * dmg_mul
	attack_data.damage = managers.modifiers:modify_value("PlayerDamage:OnTakeExplosionDamage", attack_data.damage)
	attack_data.damage = managers.player:modify_value("damage_taken", attack_data.damage, attack_data)

	self:copr_update_attack_data(attack_data)
	self:mutator_update_attack_data(attack_data)
	self:_check_chico_heal(attack_data)

	local armor_subtracted = self:_calc_armor_damage(attack_data)
	attack_data.damage = attack_data.damage - (armor_subtracted or 0)
	local health_subtracted = self:_calc_health_damage(attack_data)
	
	self:build_suppression(5)

	managers.player:send_message(Message.OnPlayerDamage, nil, attack_data)
	self:_call_listeners(damage_info)
end

local mvec1 = Vector3()

function PlayerDamage:damage_melee(attack_data)
	if not self:_chk_can_take_dmg() then
		return
	end

	local pm = managers.player
	local melee_entry = managers.blackmarket:equipped_melee_weapon()
	local tase_or_dot = tweak_data.blackmarket.melee_weapons[melee_entry].tase_data or tweak_data.blackmarket.melee_weapons[melee_entry].dot_data_name
	local auto_counter = tweak_data.blackmarket.melee_weapons[melee_entry].stats.auto_counter
	
	local can_counter_strike = auto_counter and pm:has_category_upgrade("player", "counter_strike_no_dot")
	local charging_melee = self._unit:movement():current_state().in_melee and self._unit:movement():current_state():in_melee() 
	local in_melee = charging_melee or self._unit:movement():current_state()._state_data.melee_expire_t
	local no_push = in_melee
	
	if auto_counter and not can_counter_strike then
		local dot = mvector3.dot(-self._unit:camera():forward(), attack_data.col_ray.ray)
		--log(tostring(dot))
		can_counter_strike = dot > 0.8
	end
	
	if can_counter_strike and in_melee then
		if charging_melee then
			self._unit:movement():current_state():discharge_melee()
		end

		return "countered"
	end

	local blood_effect = attack_data.melee_weapon and attack_data.melee_weapon == "weapon"
	blood_effect = blood_effect or attack_data.melee_weapon and tweak_data.weapon.npc_melee[attack_data.melee_weapon] and tweak_data.weapon.npc_melee[attack_data.melee_weapon].player_blood_effect or false

	if blood_effect then
		local pos = mvec1

		mvector3.set(pos, self._unit:camera():forward())
		mvector3.multiply(pos, 20)
		mvector3.add(pos, self._unit:camera():position())

		local rot = self._unit:camera():rotation():z()

		World:effect_manager():spawn({
			effect = Idstring("effects/payday2/particles/impacts/blood/blood_impact_a"),
			position = pos,
			normal = rot
		})
	end

	local dmg_mul = pm:damage_reduction_skill_multiplier("melee")
	attack_data.damage = attack_data.damage * dmg_mul

	if in_melee then
		if auto_counter or tase_or_dot then
			attack_data.damage = attack_data.damage * 0.5
		else
			attack_data.damage = attack_data.damage * 0.25
		end
	elseif pm:get_current_state() and pm:get_current_state()._equipped_unit then
		local equipped_unit = pm:get_current_state()._equipped_unit
		
		if equipped_unit and equipped_unit:base() and equipped_unit:base().has_dmg_resist and equipped_unit:base():has_dmg_resist() then
			attack_data.damage = attack_data.damage * 0.5
			no_push = true
		end
	end
	
	self:copr_update_attack_data(attack_data)
	self._unit:sound():play("melee_hit_body", nil, nil)
	
	self:build_suppression(2.5)
	local result = self:damage_bullet(attack_data)
	local vars = {
		"melee_hit",
		"melee_hit_var2"
	}

	self._unit:camera():play_shaker(vars[math.random(#vars)], 1)

	if pm:current_state() == "bipod" then
		self._unit:movement()._current_state:exit(nil, "standard")
		pm:set_player_state("standard")
	end
	
	if not no_push then
		self._unit:movement():push(attack_data.push_vel)
	end

	return result
end

function PlayerDamage:_update_regenerate_timer(t, dt)
	local next_allowed_dmg_t = type(self._next_allowed_dmg_t) == "number" and self._next_allowed_dmg_t or Application:digest_value(self._next_allowed_dmg_t, false)
	
	if managers.player:player_timer():time() > next_allowed_dmg_t and managers.player:player_timer():time() > self._next_allowed_sup_t and (not self._start_armor_regen_t or managers.player:player_timer():time() > self._start_armor_regen_t) then
		dt = dt * (1 - self:suppression_ratio())
		
		if self:full_armor() then
			self._regenerate_timer = 0
			self:_regenerate_armor()
		else
			local to_regen = 4 * self._regenerate_speed
			to_regen = to_regen / self:get_armor_regen_speed()
			to_regen = to_regen * dt
			local real_armor = self:get_real_armor()
			local armor = real_armor + to_regen
			
			self:set_armor(armor)
		end
	end
end

function PlayerDamage:full_armor()
	local diff = math.abs(self:get_real_armor() - self:_max_armor() * self._max_armor_reduction)

	return diff < 0.001
end

function PlayerDamage:get_armor_regen_speed()
	local mul = managers.player:body_armor_regen_multiplier(alive(self._unit) and self._unit:movement():current_state()._moving, self:health_ratio())
	mul = mul * managers.player:upgrade_value("player", "armor_regen_time_mul", 1)
	
	return mul
end

function PlayerDamage:set_regenerate_timer_to_max()
	local mul = managers.player:body_armor_regen_multiplier(alive(self._unit) and self._unit:movement():current_state()._moving, self:health_ratio())
	self._regenerate_timer = tweak_data.player.damage.REGENERATE_TIME * mul
	self._regenerate_timer = self._regenerate_timer * managers.player:upgrade_value("player", "armor_regen_time_mul", 1)
	self._regenerate_speed = self._regenerate_speed or 1
	self._start_armor_regen_t = managers.player:player_timer():time() + 2
	self._current_state = self._update_regenerate_timer
end

function PlayerDamage:is_suppressed()
	return true
end

function PlayerDamage:build_suppression(amount)
	local data = self._supperssion_data
	amount = amount * managers.player:upgrade_value("player", "suppressed_multiplier", 1)
	local morale_boost_bonus = self._unit:movement():morale_boost()

	if morale_boost_bonus then
		amount = amount * morale_boost_bonus.suppression_resistance
	end

	data.value = math.min(3, (data.value or 0) + amount)
	self._last_received_sup = amount
	self._next_allowed_sup_t = managers.player:player_timer():time() + self._dmg_interval
	data.decay_start_t = managers.player:player_timer():time() + 2
end

function PlayerDamage:relieve_suppression(amount)
	local data = self._supperssion_data
	
	if data.value and data.value > 0 then
		data.value = math.max(0, data.value - amount)
		data.decay_start_t = 0
		
		if data.value <= 0 then
			data.value = nil

			managers.environment_controller:set_suppression_value(0, 0)
		end
	end
end

function PlayerDamage:restore_health(health_restored, is_static, chk_health_ratio, ignore_healing_reduction)
	if self:need_revive() then
		return false
	end

	if chk_health_ratio and managers.player:is_damage_health_ratio_active(self:health_ratio()) then
		return false
	end
	
	if not ignore_healing_reduction then
		health_restored = health_restored * self._healing_reduction
	end

	if is_static then
		return self:change_health(health_restored * self._healing_reduction)
	else
		local max_health = self:_max_health()

		return self:change_health(max_health * health_restored * self._healing_reduction)
	end
end

function PlayerDamage:_bleed_out_damage(attack_data)
	if managers.player:has_category_upgrade("player", "bleedout_invulnerability") then
		return
	end

	local health_subtracted = Application:digest_value(self._bleed_out_health, false)
	self._bleed_out_health = Application:digest_value(math.max(0, health_subtracted - attack_data.damage), true)
	health_subtracted = health_subtracted - Application:digest_value(self._bleed_out_health, false)
	self._next_allowed_dmg_t = Application:digest_value(managers.player:player_timer():time() + self._dmg_interval, true)
	self._last_received_dmg = health_subtracted

	if Application:digest_value(self._bleed_out_health, false) <= 0 then
		managers.player:set_player_state("fatal")
	end

	if health_subtracted > 0 then
		self:_send_damage_drama(attack_data, health_subtracted)
	end
end

Hooks:PostHook(PlayerDamage, "revive", "regunz_revive_skills", function(self, silent)
	if Application:digest_value(self._revives, false) == 0 then
		return
	end

	if managers.player:has_inactivate_temporary_upgrade("temporary", "revive_temporary_invulnerabilty") then
		managers.player:activate_temporary_upgrade("temporary", "revive_temporary_invulnerabilty")
	end
	
	if managers.player:has_category_upgrade("player", "reload_on_revive") then
		local primary_unit = self._unit:inventory():unit_by_selection(2)
		local primary_base = alive(primary_unit) and primary_unit:base()
		local can_reload_primary = primary_base and primary_base.can_reload and primary_base:can_reload()
		
		if can_reload_primary then
			primary_base:on_reload()
			managers.statistics:reloaded()
			managers.hud:set_ammo_amount(primary_base:selection_index(), primary_base:ammo_info())
		end
		
		local secondary_unit = self._unit:inventory():unit_by_selection(1)
		local secondary_base = alive(secondary_unit) and secondary_unit:base()
		local can_reload_secondary = secondary_base and secondary_base.can_reload and secondary_base:can_reload()
		
		if can_reload_secondary then
			secondary_base:on_reload()
			managers.statistics:reloaded()
			managers.hud:set_ammo_amount(secondary_base:selection_index(), secondary_base:ammo_info())
		end
	end
end)

function PlayerDamage:_chk_can_take_dmg()
	if not self._unit:inventory():mask_visibility() then
		return false
	end
	
	if managers.player:has_activate_temporary_upgrade("temporary", "revive_temporary_invulnerabilty") then
		return false
	end

	local can_take_damage = self._can_take_dmg_timer <= 0
	can_take_damage = managers.modifiers:modify_value("PlayerDamage:CheckCanTakeDamage", can_take_damage)

	return can_take_damage
end

function PlayerDamage:update(unit, t, dt)
	if _G.IS_VR and self._heartbeat_t and t < self._heartbeat_t then
		local intensity_mul = 1 - (t - self._heartbeat_start_t) / (self._heartbeat_t - self._heartbeat_start_t)
		local controller = self._unit:base():controller():get_controller("vr")

		for i = 0, 1 do
			local intensity = get_heartbeat_value(t)
			intensity = intensity * (1 - math.clamp(self:health_ratio() / 0.3, 0, 1))
			intensity = intensity * intensity_mul

			controller:trigger_haptic_pulse(i, 0, intensity * 900)
		end
	end

	self:_check_update_max_health()
	self:_check_update_max_armor()
	self:_update_can_take_dmg_timer(dt)
	self:_update_regen_on_the_side(dt)
	self:_update_slowdowns(dt)

	if not self._armor_stored_health_max_set then
		self._armor_stored_health_max_set = true

		self:update_armor_stored_health()
	end

	if managers.player:has_activate_temporary_upgrade("temporary", "chico_injector") then
		self._chico_injector_active = true
		local total_time = managers.player:upgrade_value("temporary", "chico_injector")[2]
		local current_time = managers.player:get_activate_temporary_expire_time("temporary", "chico_injector") - t

		managers.hud:set_player_ability_radial({
			current = current_time,
			total = total_time
		})
	elseif self._chico_injector_active then
		managers.hud:set_player_ability_radial({
			current = 0,
			total = 1
		})

		self._chico_injector_active = nil
	end

	local is_berserker_active = managers.player:has_activate_temporary_upgrade("temporary", "berserker_damage_multiplier")

	if self._check_berserker_done then
		if is_berserker_active then
			if self._unit:movement():tased() then
				self._tased_during_berserker = true
			else
				self._tased_during_berserker = false
			end
		end

		if not is_berserker_active then
			if self._unit:movement():tased() then
				self._bleed_out_blocked_by_tased = true
			else
				self._bleed_out_blocked_by_tased = false
				self._check_berserker_done = nil

				managers.hud:set_teammate_condition(HUDManager.PLAYER_PANEL, "mugshot_normal", "")
				managers.hud:set_player_custom_radial({
					current = 0,
					total = self:_max_health(),
					revives = Application:digest_value(self._revives, false)
				})
				self:force_into_bleedout()

				if not self._bleed_out then
					self._disable_next_swansong = true
				end
			end
		else
			local expire_time = managers.player:get_activate_temporary_expire_time("temporary", "berserker_damage_multiplier")
			local total_time = managers.player:upgrade_value("temporary", "berserker_damage_multiplier")
			total_time = total_time and total_time[2] or 0
			local delta = 0
			local max_health = self:_max_health()

			if total_time ~= 0 then
				delta = math.clamp((expire_time - Application:time()) / total_time, 0, 1)
			end

			managers.hud:set_player_custom_radial({
				current = delta * max_health,
				total = max_health,
				revives = Application:digest_value(self._revives, false)
			})
			managers.network:session():send_to_peers("sync_swansong_timer", self._unit, delta * max_health, max_health, Application:digest_value(self._revives, false), managers.network:session():local_peer():id())
		end
	end

	if self._bleed_out_blocked_by_zipline and not self._unit:movement():zipline_unit() then
		self:force_into_bleedout(true)

		self._bleed_out_blocked_by_zipline = nil
	end

	if self._bleed_out_blocked_by_movement_state and not self._unit:movement():current_state():bleed_out_blocked() then
		self:force_into_bleedout()

		self._bleed_out_blocked_by_movement_state = nil
	end

	if self._bleed_out_blocked_by_tased and not self._tased_during_berserker and not self._unit:movement():tased() then
		self:force_into_bleedout()

		self._bleed_out_blocked_by_tased = nil
	end

	if not self._armor_change_blocked and self._current_state then
		self:_current_state(t, dt)
	end

	self:_update_armor_hud(t, dt)

	if self._tinnitus_data then
		self._tinnitus_data.intensity = (self._tinnitus_data.end_t - t) / self._tinnitus_data.duration

		if self._tinnitus_data.intensity <= 0 then
			SoundDevice:set_rtpc("downed_state_progression", math.max(self._downed_progression or 0, 0))
			self:_stop_tinnitus(true)
		else
			SoundDevice:set_rtpc("downed_state_progression", math.max(self._downed_progression or 0, self._tinnitus_data.intensity * 100))
		end
	end

	if self._concussion_data then
		self._concussion_data.intensity = (self._concussion_data.end_t - t) / self._concussion_data.duration

		if self._concussion_data.intensity <= 0 then
			SoundDevice:set_rtpc("concussion_effect", 0)
			self:_stop_concussion(true)
		else
			SoundDevice:set_rtpc("concussion_effect", self._concussion_data.intensity * 100)
		end
	end

	if not self._downed_timer and self._downed_progression then
		self._downed_progression = math.max(0, self._downed_progression - dt * 50)

		if not _G.IS_VR then
			managers.environment_controller:set_downed_value(self._downed_progression)
		end

		SoundDevice:set_rtpc("downed_state_progression", self._downed_progression)

		if self._downed_progression == 0 then
			self._unit:sound():play("critical_state_heart_stop")

			self._downed_progression = nil
			managers.music:set_volume_multiplier("downed", 1, 1)
		end
	end

	if self._auto_revive_timer then
		if not managers.platform:presence() == "Playing" or not self._bleed_out or self._dead or self:incapacitated() or self:arrested() or self._check_berserker_done then
			self._auto_revive_timer = nil
		else
			self._auto_revive_timer = self._auto_revive_timer - dt

			if self._auto_revive_timer <= 0 then
				managers.player:_on_feign_death_event()
			end
		end
	end

	if self._revive_miss then
		self._revive_miss = self._revive_miss - dt

		if self._revive_miss <= 0 then
			self._revive_miss = nil
		end
	end

	self:_upd_suppression(t, dt)

	if not self._dead and not self._bleed_out and not self._check_berserker_done then
		self:_upd_health_regen(t, dt)
	end

	if not self:is_downed() then
		self:_update_delayed_damage(t, dt)
	end
end

function PlayerDamage:revive(silent)
	if Application:digest_value(self._revives, false) == 0 then
		self._revive_health_multiplier = nil

		return
	end

	local arrested = self:arrested()
	local incapacitated = self:incapacitated()

	managers.player:set_player_state("standard")
	managers.player:remove_copr_risen_cooldown()

	if not silent then
		PlayerStandard.say_line(self, "s05x_sin")
	end

	self._bleed_out = false
	self._hard_incapacitated = nil
	self._incapacitated = nil
	self._downed_timer = nil
	self._downed_start_time = nil

	if not arrested and not incapacitated then
		self:set_health(self:_max_health() * tweak_data.player.damage.REVIVE_HEALTH_STEPS[self._revive_health_i] * (self._revive_health_multiplier or 1) * managers.player:upgrade_value("player", "revived_health_regain", 1))
		self:set_armor(self:_max_armor())

		self._revive_health_i = math.min(#tweak_data.player.damage.REVIVE_HEALTH_STEPS, self._revive_health_i + 1)
		self._revive_miss = 2
	end

	self:_regenerate_armor()
	managers.hud:set_player_health({
		current = self:get_real_health(),
		total = self:_max_health(),
		revives = Application:digest_value(self._revives, false)
	})
	self:_send_set_health()
	self:_set_health_effect()
	managers.hud:pd_stop_progress()

	self._revive_health_multiplier = nil

	self._listener_holder:call("on_revive")

	if managers.player:has_inactivate_temporary_upgrade("temporary", "revived_damage_resist") then
		managers.player:activate_temporary_upgrade("temporary", "revived_damage_resist")
	end

	if managers.player:has_inactivate_temporary_upgrade("temporary", "increased_movement_speed") then
		managers.player:activate_temporary_upgrade("temporary", "increased_movement_speed")
	end

	if managers.player:has_inactivate_temporary_upgrade("temporary", "swap_weapon_faster") then
		managers.player:activate_temporary_upgrade("temporary", "swap_weapon_faster")
	end

	if managers.player:has_inactivate_temporary_upgrade("temporary", "reload_weapon_faster") then
		managers.player:activate_temporary_upgrade("temporary", "reload_weapon_faster")
	end
end

function PlayerDamage:need_revive()
	return self._bleed_out or self._incapacitated or self._hard_incapacitated
end

function PlayerDamage:is_downed()
	return self._bleed_out or self._incapacitated or self._hard_incapacitated
end

function PlayerDamage:recover_health()
	if managers.platform:presence() == "Playing" and (self:arrested() or self:need_revive()) then
		self:revive(true)
	end

	self:set_health(self:_max_health())
	self:_send_set_health()
	self:_set_health_effect()

	self._said_hurt = false
	local max_lives = self._lives_init + managers.player:upgrade_value("player", "additional_lives", 0)
	
	self._revives = Application:digest_value(math.min(Application:digest_value(self._revives, false) + 1, max_lives), true)

	self:_send_set_revives()

	self._revive_health_i = 1

	managers.environment_controller:set_last_life(false)

	self._down_time = tweak_data.player.damage.DOWNED_TIME

	self._messiah_charges = managers.player:upgrade_value("player", "pistol_revive_from_bleed_out", 0)
	
	managers.hud:set_player_health({
		current = self:get_real_health(),
		total = self:_max_health(),
		revives = Application:digest_value(self._revives, false)
	})
	managers.player:set_property("copr_risen", false)
	managers.player:remove_copr_risen_cooldown()
end

function PlayerDamage:_calc_health_damage(attack_data)
	if attack_data.weapon_unit then
		local weap_base = alive(attack_data.weapon_unit) and attack_data.weapon_unit:base()
		local weap_tweak_data = weap_base and weap_base.weapon_tweak_data and weap_base:weapon_tweak_data()

		if weap_tweak_data and weap_tweak_data.slowdown_data then
			self:apply_slowdown(weap_tweak_data.slowdown_data)
		end
	end

	if managers.player:has_activate_temporary_upgrade("temporary", "mrwi_health_invulnerable") then
		return 0
	end

	local health_subtracted = 0
	health_subtracted = self:get_real_health()
	
	local attack_dmg = attack_data.damage
	attack_dmg = attack_dmg * managers.player:upgrade_value("player", "health_dmg_resistance", 1)
	
	self:change_health(-attack_data.damage)
	managers.player:add_style("damage")

	health_subtracted = health_subtracted - self:get_real_health()

	if managers.player:has_activate_temporary_upgrade("temporary", "copr_ability") and health_subtracted > 0 then
		local teammate_heal_level = managers.player:upgrade_level_nil("player", "copr_teammate_heal")

		if teammate_heal_level and self:get_real_health() > 0 then
			self._unit:network():send("copr_teammate_heal", teammate_heal_level)
		end
	end

	if self._has_mrwi_health_invulnerable then
		local health_threshold = self._mrwi_health_invulnerable_threshold or 0.5
		local is_cooling_down = managers.player:get_temporary_property("mrwi_health_invulnerable", false)

		if self:health_ratio() <= health_threshold and not is_cooling_down then
			local cooldown_time = self._mrwi_health_invulnerable_cooldown or 10

			managers.player:activate_temporary_upgrade("temporary", "mrwi_health_invulnerable")
			managers.player:activate_temporary_property("mrwi_health_invulnerable", cooldown_time, true)
		end
	end

	local trigger_skills = table.contains({
		"bullet",
		"explosion",
		"melee",
		"delayed_tick"
	}, attack_data.variant)
	local ignore_reduce_revive = self:check_ignore_reduce_revive()

	if self:get_real_health() == 0 and trigger_skills then
		self:_chk_cheat_death(ignore_reduce_revive)
	end

	self:_damage_screen()
	self:_check_bleed_out(trigger_skills, nil, ignore_reduce_revive)
	managers.hud:set_player_health({
		current = self:get_real_health(),
		total = self:_max_health(),
		revives = Application:digest_value(self._revives, false)
	})
	self:_send_set_health()
	self:_set_health_effect()
	managers.statistics:health_subtracted(health_subtracted)

	return health_subtracted
end
