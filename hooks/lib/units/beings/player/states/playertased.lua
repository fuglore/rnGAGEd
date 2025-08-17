local tmp_vec1 = Vector3()

Hooks:PostHook(PlayerTased, "init", "regunz_taser_skill", function(self, ...)
	local pm = managers.player
	self._move_while_tased = pm:has_category_upgrade("player", "move_while_tased")
end)

function PlayerTased:enter(state_data, enter_data)
	PlayerTased.super.enter(self, state_data, enter_data)
	--log("hmm")
	local projectile_entry = managers.blackmarket:equipped_projectile()

	if tweak_data.blackmarket.projectiles[projectile_entry].is_a_grenade then
		self:_interupt_action_throw_grenade()
	else
		self:_interupt_action_throw_projectile()
	end

	self:_interupt_action_reload()
	self:_interupt_action_steelsight()

	local t = managers.player:player_timer():time()

	self:_interupt_action_melee(t)
	self:_interupt_action_ladder(t)
	self:_interupt_action_charging_weapon(t)
	self:_start_action_tased(managers.player:player_timer():time(), state_data.non_lethal_electrocution)

	local non_lethal = state_data.non_lethal_electrocution

	if non_lethal then
		state_data.non_lethal_electrocution = nil
		local recover_time = TimerManager:game():time() + tweak_data.player.damage.TASED_TIME * self._non_lethal_tase_time_mul * (state_data.electrocution_duration_multiplier or 1)
		state_data.electrocution_duration_multiplier = nil
		self._recover_delayed_clbk = "PlayerTased_recover_delayed_clbk"

		managers.enemy:add_delayed_clbk(self._recover_delayed_clbk, callback(self, self, "clbk_exit_to_std"), recover_time)
	else
		self._fatal_delayed_clbk = "PlayerTased_fatal_delayed_clbk"
		local tased_time = tweak_data.player.damage.TASED_TIME
		tased_time = managers.modifiers:modify_value("PlayerTased:TasedTime", tased_time)

		managers.enemy:add_delayed_clbk(self._fatal_delayed_clbk, callback(self, self, "clbk_exit_to_fatal"), TimerManager:game():time() + tased_time)

		if Network:is_server() then
			self:_register_revive_SO()
		end
	end

	self._countering_tase = nil
	self._next_shock = 0.5
	self._taser_value = 1
	self._num_shocks = 0

	managers.groupai:state():on_criminal_disabled(self._unit, "electrified")

	if not non_lethal then
		--self._equipped_unit:base():on_reload()
	end

	self._rumble_electrified = managers.rumble:play("electrified")
	self.tased = true
	self._state_data = state_data

	CopDamage.register_listener("on_criminal_tased", {
		"on_criminal_tased"
	}, callback(self, self, "_on_tased_event"))
end

function PlayerTased:_update_movement(t, dt)
	PlayerTased.super._update_movement(self, t, dt)
end

if not RNGAGED.settings.disable_balance_changes then

function PlayerTased:_update_check_actions(t, dt)
	local input = self:_get_input(t, dt)

	local stop_here = self:_check_action_shock(t, input)
	
	if stop_here then
		return
	end

	self._taser_value = math.step(self._taser_value, 0.8, dt / 4)

	managers.environment_controller:set_taser_value(self._taser_value)

	local shooting = self:_check_action_primary_attack(t, input)

	if shooting then
		--=self._camera_unit:base():recoil_kick(-5, 5, -5, 5)
	end

	if self._unequip_weapon_expire_t and self._unequip_weapon_expire_t <= t then
		self._unequip_weapon_expire_t = nil

		self:_start_action_equip_weapon(t)
	end

	if self._equip_weapon_expire_t and self._equip_weapon_expire_t <= t then
		self._equip_weapon_expire_t = nil
	end

	if input.btn_stats_screen_press then
		self._unit:base():set_stats_screen_visible(true)
	elseif input.btn_stats_screen_release then
		self._unit:base():set_stats_screen_visible(false)
	end

	self:_update_foley(t, input)

	local new_action = nil

	self:_check_action_interact(t, input)

	local new_action = nil
	
	self:_determine_move_direction()
end

function PlayerTased:_check_action_shock(t, input)
	self._next_shock = self._next_shock or 0.35

	if self._next_shock < t then
		self._num_shocks = self._num_shocks or 0
		self._num_shocks = self._num_shocks + 1
		self._next_shock = t + 0.35

		self._unit:camera():play_shaker("player_taser_shock", 1, 10)
		--self._unit:camera():camera_unit():base():set_target_tilt((math.random(2) == 1 and -1 or 1) * math.random(10))

		self._taser_value = math.max((self._taser_value or 1) - 0.25, 0)

		self._unit:sound():play("tasered_shock")
		managers.rumble:play("electric_shock")

		if not self._countering_tase then
			self._camera_unit:base():start_shooting()

			self._recoil_t = t + 0.5

			if not self._resist_tase then
				input.btn_primary_attack_state = true
				input.btn_primary_attack_press = true
			end

			self._camera_unit:base():recoil_kick(-2, 2, -2, 2)
			self._unit:camera():play_redirect(self:get_animation("tased_boost"))

			if self._taser_unit then
				local char_damage = self._unit:character_damage()
				
				if char_damage:get_real_health() <= 0 then
					char_damage._revives = Application:digest_value(Application:digest_value(char_damage._revives, false) - 1, true)

					char_damage:_send_set_revives()

					managers.environment_controller:set_last_life(Application:digest_value(char_damage._revives, false) <= 1)

					if Application:digest_value(char_damage._revives, false) <= 0 then
						char_damage._down_time = 0
						char_damage._downed_timer = 0
						char_damage._downed_paused_counter = 0
					end
					
					if self._fatal_delayed_clbk then
						managers.enemy:remove_delayed_clbk(self._fatal_delayed_clbk)

						self._fatal_delayed_clbk = nil
					end
					
					self:clbk_exit_to_fatal()
					
					char_damage._incapacitated = nil
					char_damage._hard_incapacitated = true
					
					return true
				else
					char_damage:change_health(-1)
					
					local target_vec = tmp_vec1

					mvector3.set(target_vec, self._taser_unit:movement():m_head_pos())
					mvector3.subtract(target_vec, self._unit:movement():m_head_pos())
					managers.hud:on_hit_direction(target_vec, HUDHitDirection.DAMAGE_TYPES.HEALTH)
					self._unit:camera():play_shaker("player_bullet_damage", 1)
					self._unit:sound():play("player_hit_permadamage")
					
					if char_damage:get_real_health() <= 0 then
						char_damage._revives = Application:digest_value(Application:digest_value(char_damage._revives, false) - 1, true)

						char_damage:_send_set_revives()

						managers.environment_controller:set_last_life(Application:digest_value(char_damage._revives, false) <= 1)

						if Application:digest_value(char_damage._revives, false) <= 0 then
							char_damage._down_time = 0
							char_damage._downed_timer = 0
							char_damage._downed_paused_counter = 0
						end
						
						if self._fatal_delayed_clbk then
							managers.enemy:remove_delayed_clbk(self._fatal_delayed_clbk)

							self._fatal_delayed_clbk = nil
						end
						
						self:clbk_exit_to_fatal()
						
						char_damage._incapacitated = nil
						char_damage._hard_incapacitated = true
						
						return true
					end
				end
			end
		end
	elseif self._recoil_t then
		if not self._resist_tase then
			input.btn_primary_attack_state = true
		end

		if self._recoil_t < t then
			self._recoil_t = nil

			self._camera_unit:base():stop_shooting()
		end
	end
end

end