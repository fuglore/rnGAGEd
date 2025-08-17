function TeamAIDamage:init(unit)
	self._unit = unit
	self._char_tweak = tweak_data.character[unit:base()._tweak_table]
	local damage_tweak = self._char_tweak.damage
	self._HEALTH_INIT = damage_tweak.HEALTH_INIT
	self._HEALTH_BLEEDOUT_INIT = damage_tweak.BLEED_OUT_HEALTH_INIT
	self._HEALTH_TOTAL = self._HEALTH_INIT + self._HEALTH_BLEEDOUT_INIT
	self._HEALTH_TOTAL_PERCENT = self._HEALTH_TOTAL / 100
	self._health = self._HEALTH_INIT
	self._health_ratio = self._health / self._HEALTH_INIT
	self._invulnerable = false
	self._char_dmg_tweak = damage_tweak
	self._focus_delay_mul = 1
	self._listener_holder = EventListenerHolder:new()
	self._bleed_out_paused_count = 0
	self._dmg_interval = tweak_data.player.damage.MIN_DAMAGE_INTERVAL
	self._next_allowed_dmg_t = Application:digest_value(-100, true)
	self._last_received_dmg = 0
	self._spine2_obj = unit:get_object(Idstring("Spine2"))
	self._tase_effect_table = {
		effect = Idstring("effects/payday2/particles/character/taser_hittarget"),
		parent = self._unit:get_object(Idstring("e_taser"))
	}
end

function TeamAIDamage:damage_melee(attack_data)
	if self._invulnerable or self._dead or self._fatal or self._arrested_timer then
		return
	end

	if self:_chk_dmg_too_soon(attack_data.damage) then
		return
	end

	if PlayerDamage.is_friendly_fire(self, attack_data.attacker_unit) then
		return
	end

	local result = {
		variant = "melee"
	}
	local damage_percent, health_subtracted = self:_apply_damage(attack_data, result)
	local t = TimerManager:game():time()
	self._next_allowed_dmg_t = Application:digest_value(t + self._dmg_interval, true)
	self._last_received_dmg = attack_data.damage
	self._last_received_dmg_t = t

	if health_subtracted > 0 then
		self:_send_damage_drama(attack_data, health_subtracted)
	end

	if self._dead then
		self:_unregister_unit()
	end

	self:_call_listeners(attack_data)
	self:_send_melee_attack_result(attack_data)

	return result
end

function TeamAIDamage:force_bleedout()
	local attack_data = {
		damage = 100000,
		pos = Vector3(),
		col_ray = {
			position = Vector3()
		}
	}
	local result = {
		type = "none",
		variant = "bullet"
	}
	attack_data.result = result
	local damage_percent, health_subtracted = self:_apply_damage(attack_data, result)
	
	local t = TimerManager:game():time()
	self._next_allowed_dmg_t = Application:digest_value(t + self._dmg_interval, true)
	self._last_received_dmg = health_subtracted

	if health_subtracted > 0 then
		self:_send_damage_drama(attack_data, health_subtracted)
	end

	if self._dead then
		self:_unregister_unit()
	end

	self:_call_listeners(attack_data)
	self:_send_bullet_attack_result(attack_data)
end

function TeamAIDamage:damage_bullet(attack_data)
	local result = {
		type = "none",
		variant = "bullet"
	}
	attack_data.result = result

	if self:_cannot_take_damage() then
		self:_call_listeners(attack_data)

		return
	elseif self:_chk_dmg_too_soon(attack_data.damage) then
		self:_call_listeners(attack_data)

		return
	elseif PlayerDamage.is_friendly_fire(self, attack_data.attacker_unit) then
		self:friendly_fire_hit()

		return
	end

	local damage_percent, health_subtracted = self:_apply_damage(attack_data, result)
	local t = TimerManager:game():time()
	self._next_allowed_dmg_t = Application:digest_value(t + self._dmg_interval, true)
	self._last_received_dmg_t = t
	self._last_received_dmg = attack_data.damage

	if health_subtracted > 0 then
		self:_send_damage_drama(attack_data, health_subtracted)
	end

	if self._dead then
		self:_unregister_unit()
	end

	self:_call_listeners(attack_data)
	self:_send_bullet_attack_result(attack_data)

	return result
end

function TeamAIDamage:damage_explosion(attack_data)
	if self:_cannot_take_damage() then
		return
	end
	
	if self:_chk_dmg_too_soon(attack_data.damage) then
		return
	end

	local attacker_unit = attack_data.attacker_unit

	if attacker_unit and attacker_unit:base() and attacker_unit:base().thrower_unit then
		attacker_unit = attacker_unit:base():thrower_unit()
	end

	if PlayerDamage.is_friendly_fire(self, attacker_unit) then
		self:friendly_fire_hit()

		return
	end

	local result = {
		variant = attack_data.variant
	}
	local damage_percent, health_subtracted = self:_apply_damage(attack_data, result)

	if health_subtracted > 0 then
		self:_send_damage_drama(attack_data, health_subtracted)
	end

	if self._dead then
		self:_unregister_unit()
	end

	self:_call_listeners(attack_data)
	self:_send_explosion_attack_result(attack_data)

	return result
end

function TeamAIDamage:damage_fire(attack_data)
	if self:_cannot_take_damage() then
		return
	elseif self:_chk_dmg_too_soon(attack_data.damage) then
		attack_data.result = {
			variant = attack_data.variant
		}

		self:_call_listeners(attack_data)

		return
	end

	local attacker_unit = attack_data.attacker_unit

	if attacker_unit and alive(attacker_unit) and attacker_unit:base() and attacker_unit:base().thrower_unit then
		attacker_unit = attacker_unit:base():thrower_unit()
	end

	if attacker_unit and not alive(attacker_unit) then
		return
	end

	if attacker_unit and alive(attacker_unit) and PlayerDamage.is_friendly_fire(self, attacker_unit) then
		self:friendly_fire_hit()

		return
	end

	local result = {
		variant = attack_data.variant
	}
	local damage_percent, health_subtracted = self:_apply_damage(attack_data, result)
	local t = TimerManager:game():time()
	self._next_allowed_dmg_t = Application:digest_value(t + self._dmg_interval, true)
	self._last_received_dmg_t = t
	self._last_received_dmg = attack_data.damage

	if health_subtracted > 0 then
		self:_send_damage_drama(attack_data, health_subtracted)
	end

	if self._dead then
		self:_unregister_unit()
	end

	self:_call_listeners(attack_data)
	self:_send_fire_attack_result(attack_data)

	return result
end

function TeamAIDamage:damage_mission(attack_data)
	if self._dead or self._invulnerable and not attack_data.forced then
		return
	end

	local result = nil
	local damage_percent = self._HEALTH_GRANULARITY
	attack_data.damage = self._health
	attack_data.variant = "explosion"
	local result = {
		variant = attack_data.variant
	}
	local damage_percent, health_subtracted = self:_apply_damage(attack_data, result)

	if health_subtracted > 0 then
		self:_send_damage_drama(attack_data, health_subtracted)
	end

	if self._dead then
		self:_unregister_unit()
	end

	self:_call_listeners(attack_data)
	self:_send_explosion_attack_result(attack_data)

	return result
end

function TeamAIDamage:damage_tase(attack_data)
	if not self:can_be_tased() then
		return
	end

	if attack_data ~= nil and PlayerDamage.is_friendly_fire(self, attack_data.attacker_unit) then
		self:friendly_fire_hit()

		return
	end

	self._regenerate_t = nil
	local damage_info = {
		variant = "tase",
		result = {
			type = "hurt"
		}
	}

	if self._tase_effect then
		World:effect_manager():fade_kill(self._tase_effect)
	end

	self._tase_effect = World:effect_manager():spawn(self._tase_effect_table)

	if Network:is_server() then
		if math.random() < 0.25 then
			self._unit:sound():say("s07x_sin", true)
		end

		if not self._to_incapacitated_clbk_id then
			self._to_incapacitated_clbk_id = "TeamAIDamage_to_incapacitated" .. tostring(self._unit:key())

			managers.enemy:add_delayed_clbk(self._to_incapacitated_clbk_id, callback(self, self, "clbk_exit_to_incapacitated"), TimerManager:game():time() + self._char_dmg_tweak.TASED_TIME)
		end
	end

	self:_call_listeners(damage_info)

	if Network:is_server() then
		self:_send_tase_attack_result()
	end

	return damage_info
end

function TeamAIDamage:_chk_dmg_too_soon(damage, armor_piercing)
	local next_allowed_dmg_t = Application:digest_value(self._next_allowed_dmg_t, false)
	
	return TimerManager:game():time() < next_allowed_dmg_t
end
