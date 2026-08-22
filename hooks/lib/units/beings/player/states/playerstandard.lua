local mvec3_dis_sq = mvector3.distance_sq
local mvec3_set = mvector3.set
local mvec3_set_z = mvector3.set_z
local mvec3_sub = mvector3.subtract
local mvec3_add = mvector3.add
local mvec3_mul = mvector3.multiply
local mvec3_norm = mvector3.normalize
local mvec3_dot = mvector3.dot
local mvec3_dir = mvector3.direction

function PlayerStandard:enter(state_data, enter_data)
	PlayerMovementState.enter(self, state_data, enter_data)
	tweak_data:add_reload_callback(self, self.tweak_data_clbk_reload)

	self._state_data = state_data
	self._state_data.using_bipod = managers.player:current_state() == "bipod"
	self._equipped_unit = self._ext_inventory:equipped_unit()
	self._weapon_hold = self:get_weapon_hold_str()

	self:inventory_clbk_listener(self._unit, "equip")
	self:_enter(enter_data)
	self:_update_ground_ray()

	self._controller = self._unit:base():controller()

	if not self._unit:mover() then
		self:_activate_mover(PlayerStandard.MOVER_STAND)
	end

	if not _G.IS_VR and (enter_data and enter_data.wants_crouch or not self:_can_stand(nil, true)) and not self._state_data.ducking then
		self:_start_action_ducking(managers.player:player_timer():time())
	end

	self._ext_camera:clbk_fp_enter(self._unit:rotation():y())

	if self._ext_movement:nav_tracker() then
		self._pos_reservation = {
			radius = 100,
			position = self._ext_movement:m_pos(),
			filter = self._ext_movement:pos_rsrv_id()
		}
		self._pos_reservation_slow = {
			radius = 100,
			position = mvector3.copy(self._ext_movement:m_pos()),
			filter = self._ext_movement:pos_rsrv_id()
		}

		managers.navigation:add_pos_reservation(self._pos_reservation)
		managers.navigation:add_pos_reservation(self._pos_reservation_slow)
	end

	for _, data in ipairs(self._ext_inventory._available_selections) do
		local unit = data.unit

		managers.hud:set_ammo_amount(unit:base():selection_index(), unit:base():ammo_info())
	end

	if enter_data and enter_data.equip_weapon then
		self:_start_action_unequip_weapon(managers.player:player_timer():time(), {
			selection_wanted = enter_data.equip_weapon
		})
	end

	if enter_data then
		self._change_weapon_data = enter_data.change_weapon_data or self._change_weapon_data
		self._unequip_weapon_expire_t = enter_data.unequip_weapon_expire_t or self._unequip_weapon_expire_t
		self._equip_weapon_expire_t = enter_data.equip_weapon_expire_t or self._equip_weapon_expire_t
	end

	self:_reset_delay_action()

	self._last_velocity_xy = Vector3()
	self._last_sent_pos_t = enter_data and enter_data.last_sent_pos_t or managers.player:player_timer():time()
	self._last_sent_pos = enter_data and enter_data.last_sent_pos or mvector3.copy(self._pos)
	--self._gnd_ray = true
	local slow_mul, prevents_running = self._ext_damage:get_current_slowdown()
	self._slowdown_mul = slow_mul ~= 1 and slow_mul or nil
	self._slowdown_run_prevent = slow_mul and prevents_running or false
end

function PlayerStandard:_enter(enter_data)
	self._unit:base():set_slot(self._unit, 2)

	if Network:is_server() and self._ext_movement:nav_tracker() then
		managers.groupai:state():on_player_weapons_hot()
	end

	if self._ext_movement:nav_tracker() then
		managers.groupai:state():on_criminal_recovered(self._unit)
	end

	self._equipping_mask = nil
	local skip_equip = enter_data and enter_data.skip_equip
	local skip_mask_anim = enter_data and enter_data.skip_mask_anim

	if not self:_changing_weapon() and not skip_equip then
		if not self._state_data.mask_equipped then
			self._state_data.mask_equipped = true

			if not skip_mask_anim then
				self._equipping_mask = true
				local equipped_mask = managers.blackmarket:equipped_mask()
				local peer_id = managers.network:session() and managers.network:session():local_peer():id()
				local mask_id = managers.blackmarket:get_real_mask_id(equipped_mask.mask_id, peer_id)
				local equipped_mask_type = tweak_data.blackmarket.masks[mask_id].type

				self._camera_unit:anim_state_machine():set_global((equipped_mask_type or "mask") .. "_equip", 1)
				self:_start_action_equip(self:get_animation("mask_equip"), 1.6)
			end
		else
			self:_start_action_equip(self:get_animation("equip"))
			self._ext_inventory:show_equipped_unit()
		end
	end

	self._ext_camera:camera_unit():base():set_target_tilt(0)

	if self._ext_movement:nav_tracker() then
		self._standing_nav_seg_id = self._ext_movement:nav_tracker():nav_segment()
		local metadata = managers.navigation:get_nav_seg_metadata(self._standing_nav_seg_id)
		local location_id = metadata.location_id

		managers.hud:set_player_location(location_id)
		self._unit:base():set_suspicion_multiplier("area", metadata.suspicion_mul)
		self._unit:base():set_detection_multiplier("area", metadata.detection_mul and 1 / metadata.detection_mul or nil)
	end

	self._ext_inventory:set_mask_visibility(true)
	self:_upd_attention()
	self._ext_network:send("set_stance", 2, false, false)
end

function PlayerStandard:_update_check_actions(t, dt, paused)
	local input = self:_get_input(t, dt, paused)

	self:_determine_move_direction()

	local cur_state = self._ext_movement:current_state_name()
	local new_action = self:_update_interaction_timers(t)

	if cur_state ~= self._ext_movement:current_state_name() then
		return
	end

	self:_update_throw_projectile_timers(t, input)
	self:_update_reload_timers(t, dt, input)

	self:_update_melee_timers(t, input)
	
	self:_update_charging_weapon_timers(t, input)

	new_action = self:_update_use_item_timers(t, input) or new_action

	if cur_state ~= self._ext_movement:current_state_name() then
		return
	end

	self:_update_equip_weapon_timers(t, input)
	self:_update_running_timers(t)
	self:_update_zipline_timers(t, dt)

	if self._change_item_expire_t and self._change_item_expire_t <= t then
		self._change_item_expire_t = nil
	end

	if self._change_weapon_pressed_expire_t and self._change_weapon_pressed_expire_t <= t then
		self._change_weapon_pressed_expire_t = nil
	end

	self:_update_steelsight_timers(t, dt)

	if input.btn_stats_screen_press then
		self._unit:base():set_stats_screen_visible(true)
	elseif input.btn_stats_screen_release then
		self._unit:base():set_stats_screen_visible(false)
	end

	self:_update_foley(t, input)

	local anim_data = self._ext_anim
	self:_check_action_weapon_gadget(t, input)

	if _G.IS_VR then
		new_action = new_action or self:_check_action_deploy_underbarrel(t, input)
	end

	self:_check_action_weapon_firemode(t, input)
	new_action = new_action or self:_check_action_melee(t, input)	
	new_action = new_action or self:_check_action_reload(t, input)
	new_action = new_action or self:_check_change_weapon(t, input)

	if not new_action then
		new_action = self:_check_action_primary_attack(t, input)
		
		if new_action then
			if self._equipped_unit then
				self._equipped_unit:base()._last_saved_reload_prog = nil
			end
		end
		
		if not _G.IS_VR and not new_action then
			self:_check_stop_shooting()
		end
	end

	new_action = new_action or self:_check_action_equip(t, input)

	if not new_action then
		new_action = self:_check_use_item(t, input)

		if cur_state ~= self._ext_movement:current_state_name() then
			return
		end
	end

	if self:_check_action_throw_projectile(t, input) then
		new_action = true
	end

	if not new_action then
		new_action = self:_check_action_interact(t, input)

		if cur_state ~= self._ext_movement:current_state_name() then
			return
		end
	end

	self:_check_action_jump(t, input)
	self:_check_action_run(t, input)
	self:_check_action_ladder(t, input)
	self:_check_action_zipline(t, input)
	self:_check_action_cash_inspect(t, input)

	if not new_action then
		new_action = self:_check_action_deploy_bipod(t, input)
		new_action = new_action or self:_check_action_deploy_underbarrel(t, input)
	end

	self:_check_action_change_equipment(t, input)
	self:_check_action_duck(t, input)
	self:_check_action_steelsight(t, input)
	self:_check_action_night_vision(t, input)
	self:_find_pickups(t)
	
	self:_can_stand(nil, true)
end

function PlayerStandard:_check_action_throw_grenade(t, input)
	local action_wanted = input.btn_throw_grenade_press

	if not action_wanted then
		return
	end

	if not managers.player:can_throw_grenade() then
		return
	end

	local action_forbidden = not PlayerBase.USE_GRENADES or self:chk_action_forbidden("interact") or self._unit:base():stats_screen_visible() or self:_is_throwing_grenade() or self:_interacting() or self:is_deploying() or self:_changing_weapon() or self:_is_meleeing() or self:_is_using_bipod()

	if action_forbidden then
		return
	end

	self:_start_action_throw_grenade(t, input)

	return action_wanted
end

function PlayerStandard:_check_action_throw_projectile(t, input)
	local projectile_entry = managers.blackmarket:equipped_projectile()
	local projectile_tweak = tweak_data.blackmarket.projectiles[projectile_entry]

	if not self._primary_attack_input_cache and not input.btn_primary_attack_state and not input.btn_primary_attack_press and projectile_tweak.is_a_grenade then
		return self:_check_action_throw_grenade(t, input)
	elseif projectile_tweak.ability then
		self:_check_action_use_ability(t, input)
		
		return
	end

	if self._state_data.projectile_throw_wanted then
		if not self._state_data.projectile_throw_allowed_t then
			self._state_data.projectile_throw_wanted = nil

			self:_do_action_throw_projectile(t, input)
		end

		return
	end

	local action_wanted = input.btn_projectile_press or input.btn_projectile_release or self._state_data.projectile_idle_wanted

	if not action_wanted then
		return
	end

	if not managers.player:can_throw_grenade() then
		self._state_data.projectile_throw_wanted = nil
		self._state_data.projectile_idle_wanted = nil

		return
	end

	if input.btn_projectile_release then
		if self._state_data.throwing_projectile then
			if self._state_data.projectile_throw_allowed_t then
				self._state_data.projectile_throw_wanted = true

				return
			end

			self:_do_action_throw_projectile(t, input)
		end

		return
	end

	local action_forbidden = not PlayerBase.USE_GRENADES or not self:_projectile_repeat_allowed() or self:chk_action_forbidden("interact") or self:_interacting() or self:is_deploying() or self:_changing_weapon() or self:_is_meleeing() or self:_is_using_bipod() or self._primary_attack_input_cache or input.btn_primary_attack_state

	if action_forbidden then
		return
	end

	self:_start_action_throw_projectile(t, input)

	return true
end

function PlayerStandard:_check_stop_shooting()
	if self._shooting then
		self._equipped_unit:base():stop_shooting()
		self._camera_unit:base():stop_shooting(self._equipped_unit:base():recoil_wait())

		local weap_base = self._equipped_unit:base()
		local fire_mode = weap_base:fire_mode()
		local is_auto_fire_mode = fire_mode == "auto"

		if is_auto_fire_mode and (not weap_base.akimbo or weap_base:weapon_tweak_data().allow_akimbo_autofire) then
			self._ext_network:send("sync_stop_auto_fire_sound", 0)
		end

		if is_auto_fire_mode and not self:_is_reloading() and not self:_is_meleeing() and not self:_is_throwing_grenade() then
			self._unit:camera():play_redirect(self:get_animation("recoil_exit"))
		end

		self._shooting = false
		self._shooting_t = nil
	end
end

local melee_vars = {
	"player_melee",
	"player_melee_var2"
}

function PlayerStandard:_do_melee_damage(t, bayonet_melee, melee_hit_ray, melee_entry, hand_id)
	melee_entry = melee_entry or managers.blackmarket:equipped_melee_weapon()
	local instant_hit = tweak_data.blackmarket.melee_weapons[melee_entry].instant
	local melee_damage_delay = tweak_data.blackmarket.melee_weapons[melee_entry].melee_damage_delay or 0
	local charge_lerp_value = instant_hit and 0 or self:_get_melee_charge_lerp_value(t, melee_damage_delay)

	self._ext_camera:play_shaker(melee_vars[math.random(#melee_vars)], math.max(0.3, charge_lerp_value))

	local sphere_cast_radius = 20
	local col_ray = nil

	if melee_hit_ray then
		col_ray = melee_hit_ray ~= true and melee_hit_ray or nil
	else
		col_ray = self:_calc_melee_hit_ray(t, sphere_cast_radius)
	end

	if col_ray and alive(col_ray.unit) then
		local damage, damage_effect = managers.blackmarket:equipped_melee_weapon_damage_info(charge_lerp_value)
		local damage_effect_mul = math.max(managers.player:upgrade_value("player", "melee_knockdown_mul", 1), managers.player:upgrade_value(self._equipped_unit:base():weapon_tweak_data().categories and self._equipped_unit:base():weapon_tweak_data().categories[1], "melee_knockdown_mul", 1))
		damage = damage * managers.player:get_melee_dmg_multiplier()
		damage_effect = damage_effect * damage_effect_mul
		col_ray.sphere_cast_radius = sphere_cast_radius
		local hit_unit = col_ray.unit

		if hit_unit:character_damage() then
			if bayonet_melee then
				self._unit:sound():play("fairbairn_hit_body", nil, false)
			else
				local hit_sfx = "hit_body"

				if hit_unit:character_damage() and hit_unit:character_damage().melee_hit_sfx then
					hit_sfx = hit_unit:character_damage():melee_hit_sfx()
				end

				self:_play_melee_sound(melee_entry, hit_sfx, self._melee_attack_var)
			end

			if not hit_unit:character_damage()._no_blood then
				managers.game_play_central:play_impact_flesh({
					col_ray = col_ray
				})
				managers.game_play_central:play_impact_sound_and_effects({
					no_decal = true,
					no_sound = true,
					col_ray = col_ray
				})
			end

			self._camera_unit:base():play_anim_melee_item("hit_body")
		else
			if self._on_melee_restart_drill and hit_unit:base() and (hit_unit:base().is_drill or hit_unit:base().is_saw) then
				hit_unit:base():on_melee_hit(managers.network:session():local_peer():id())
			end

			if bayonet_melee then
				self._unit:sound():play("knife_hit_gen", nil, false)
			else
				self:_play_melee_sound(melee_entry, "hit_gen", self._melee_attack_var)
			end

			self._camera_unit:base():play_anim_melee_item("hit_gen")
			managers.game_play_central:play_impact_sound_and_effects({
				no_decal = true,
				no_sound = true,
				col_ray = col_ray,
				effect = Idstring("effects/payday2/particles/impacts/fallback_impact_pd2")
			})
		end

		local custom_data = nil

		if _G.IS_VR and hand_id then
			custom_data = {
				engine = hand_id == 1 and "right" or "left"
			}
		end

		managers.rumble:play("melee_hit", nil, nil, custom_data)
		managers.game_play_central:physics_push(col_ray)

		local character_unit, shield_knock = nil
		local can_shield_knock = managers.player:has_category_upgrade("player", "shield_knock") and RNGAGED.settings.disable_balance_changes

		if can_shield_knock and hit_unit:in_slot(8) and alive(hit_unit:parent()) and not hit_unit:parent():character_damage():is_immune_to_shield_knockback() then
			shield_knock = true
			character_unit = hit_unit:parent()
		end

		character_unit = character_unit or hit_unit

		if character_unit:character_damage() and character_unit:character_damage().damage_melee then
			local dmg_multiplier = 1

			if not managers.enemy:is_civilian(character_unit) and not managers.groupai:state():is_enemy_special(character_unit) then
				dmg_multiplier = dmg_multiplier * managers.player:upgrade_value("player", "non_special_melee_multiplier", 1)
			else
				dmg_multiplier = dmg_multiplier * managers.player:upgrade_value("player", "melee_damage_multiplier", 1)
			end

			dmg_multiplier = dmg_multiplier * managers.player:upgrade_value("player", "melee_" .. tostring(tweak_data.blackmarket.melee_weapons[melee_entry].stats.weapon_type) .. "_damage_multiplier", 1)

			if character_unit:base() and character_unit:base().char_tweak and character_unit:base():char_tweak().priority_shout then
				dmg_multiplier = dmg_multiplier * (tweak_data.blackmarket.melee_weapons[melee_entry].stats.special_damage_multiplier or 1)
			end

			if managers.player:has_category_upgrade("melee", "stacking_hit_damage_multiplier") then
				self._state_data.stacking_dmg_mul = self._state_data.stacking_dmg_mul or {}
				self._state_data.stacking_dmg_mul.melee = self._state_data.stacking_dmg_mul.melee or {
					nil,
					0
				}
				local stack = self._state_data.stacking_dmg_mul.melee

				if stack[1] and t < stack[1] then
					dmg_multiplier = dmg_multiplier * (1 + managers.player:upgrade_value("melee", "stacking_hit_damage_multiplier", 0) * stack[2])
				else
					stack[2] = 0
				end
			end

			local health_ratio = self._ext_damage:health_ratio()
			local damage_health_ratio = managers.player:get_damage_health_ratio(health_ratio, "melee")

			if damage_health_ratio > 0 then
				dmg_multiplier = dmg_multiplier * (1 + self._damage_health_ratio_mul_melee * damage_health_ratio)
			end

			dmg_multiplier = dmg_multiplier * managers.player:temporary_upgrade_value("temporary", "berserker_damage_multiplier", 1)
			local target_dead = character_unit:character_damage().dead and not character_unit:character_damage():dead()
			local target_hostile = managers.enemy:is_enemy(character_unit) and not tweak_data.character[character_unit:base()._tweak_table].is_escort and character_unit:brain():is_hostile()
			local life_leach_available = managers.player:has_category_upgrade("temporary", "melee_life_leech") and not managers.player:has_activate_temporary_upgrade("temporary", "melee_life_leech")

			if target_dead and target_hostile and life_leach_available then
				managers.player:activate_temporary_upgrade("temporary", "melee_life_leech")
				self._unit:character_damage():restore_health(managers.player:temporary_upgrade_value("temporary", "melee_life_leech", 1))
			end

			local action_data = {
				variant = "melee"
			}

			if _G.IS_VR and melee_entry == "weapon" and not bayonet_melee then
				dmg_multiplier = 0.1
			end

			action_data.damage = shield_knock and 0 or damage * dmg_multiplier
			action_data.damage_effect = damage_effect
			action_data.attacker_unit = self._unit
			action_data.col_ray = col_ray

			if shield_knock then
				action_data.shield_knock = can_shield_knock
			end

			action_data.name_id = melee_entry
			action_data.charge_lerp_value = charge_lerp_value

			if managers.player:has_category_upgrade("melee", "stacking_hit_damage_multiplier") then
				self._state_data.stacking_dmg_mul = self._state_data.stacking_dmg_mul or {}
				self._state_data.stacking_dmg_mul.melee = self._state_data.stacking_dmg_mul.melee or {
					nil,
					0
				}
				local stack = self._state_data.stacking_dmg_mul.melee

				if character_unit:character_damage().dead and not character_unit:character_damage():dead() then
					stack[1] = t + managers.player:upgrade_value("melee", "stacking_hit_expire_t", 1)
					stack[2] = math.min(stack[2] + 1, tweak_data.upgrades.max_melee_weapon_dmg_mul_stacks or 5)
				else
					stack[1] = nil
					stack[2] = 0
				end
			end

			local defense_data = character_unit:character_damage():damage_melee(action_data)

			self:_check_melee_special_damage(col_ray, character_unit, defense_data, melee_entry)
			self:_perform_sync_melee_damage(hit_unit, col_ray, action_data.damage)

			return defense_data
		else
			self:_perform_sync_melee_damage(hit_unit, col_ray, damage)
		end
	end

	if managers.player:has_category_upgrade("melee", "stacking_hit_damage_multiplier") then
		self._state_data.stacking_dmg_mul = self._state_data.stacking_dmg_mul or {}
		self._state_data.stacking_dmg_mul.melee = self._state_data.stacking_dmg_mul.melee or {
			nil,
			0
		}
		local stack = self._state_data.stacking_dmg_mul.melee
		stack[1] = nil
		stack[2] = 0
	end

	return col_ray
end

local mvec_melee_dir = Vector3()

function PlayerStandard:_upd_melee_cleave(t)
	if self._state_data.cleave_melee_start_t and self._state_data.cleave_melee_start_t > t then
		return
	end

	if not self._state_data.cleave_melee_t or self._state_data.cleave_melee_t < t or not self._camera_unit then
		if self._melee_cleave_particles then
			local effect_manager = World:effect_manager()
			
			for u_key, id in pairs(self._melee_cleave_particles) do
				effect_manager:fade_kill(id)
			end
			
			self._melee_cleave_particles = {}
		end
		
		return
	end
	
	local camera_melee_units = self._camera_unit and self._camera_unit:base()._melee_item_units
	local melee_entry = managers.blackmarket:equipped_melee_weapon()

	--log(tostring(melee_entry))

	
	if melee_entry and tweak_data.blackmarket.melee_weapons[melee_entry].type == "fists" then
		self:melee_fist_cleave(t, melee_entry)
	elseif camera_melee_units then
		for i = 1, #camera_melee_units do
			if not camera_melee_units[i] or not alive(camera_melee_units[i]) then
				--log("fail 1")
				return
			end
		end
		
		self:melee_unit_cleave(t, camera_melee_units, melee_entry)
	end
end

local ids_melee_trail = Idstring("effects/pd2_mod_rgg/particles/melee_trail")

function PlayerStandard:melee_unit_cleave(t, camera_melee_units, melee_entry)
	local no_dot = tweak_data.blackmarket.melee_weapons[melee_entry].no_dot_check
	local radius = tweak_data.blackmarket.melee_weapons[melee_entry].stats.cleave_radius or 15
	local vr_offset = tweak_data.vr.melee_offsets.weapons[melee_entry]
	local slotmask = managers.slot:get_mask("bullet_impact_targets")
	local shield_mask = managers.slot:get_mask("enemy_shield_check")
	local line = Draw:brush(Color.blue:with_alpha(0.25), 0.01)
	local line_offset = Draw:brush(Color.red:with_alpha(0.1), 0.01)
	local from_head = self._unit:movement():m_head_pos()
	local cam_fwd = self._cam_fwd:normalized()
	local fwd_offset = cam_fwd * 60
	
	if not self._melee_cleave_particles then
		self._melee_cleave_particles = {}
	end
	
	local effect_manager = World:effect_manager()
	
	for i = 1, #camera_melee_units do		
		local melee_unit = camera_melee_units[i]
		local orig_point = melee_unit:position()
		
		mvector3.direction(mvec_melee_dir, from_head, orig_point)
		local dot_prod
		
		if not no_dot then
			dot_prod = mvector3.dot(mvec_melee_dir, cam_fwd)
			--log(tostring(dot_prod))
		end
		
		if no_dot or dot_prod > 0.05 then
			local hit_point
			orig_point = orig_point - Vector3(0, melee_unit:oobb():distance_to_point(orig_point), 0):rotate_with(melee_unit:rotation())
			
			if vr_offset and vr_offset.hit_point then
				hit_point = melee_unit:position() + Vector3(0, melee_unit:oobb():size().y, 0):rotate_with(melee_unit:rotation())
				hit_point = hit_point + fwd_offset
				
			else
				hit_point = melee_unit:position() + Vector3(0, melee_unit:oobb():size().y, 0):rotate_with(melee_unit:rotation())
				hit_point = hit_point + fwd_offset
				
			end
			
			local shield_test_ray = melee_unit:raycast("ray", orig_point, hit_point, "slot_mask", shield_mask, "sphere_cast_radius", radius)
			
			if shield_test_ray then
				hit_point = shield_test_ray.hit_position
			end
			
			if not self._melee_cleave_particles[melee_unit:key()] then
				self._melee_cleave_particles[melee_unit:key()] = effect_manager:spawn({
					effect = ids_melee_trail,
					position = hit_point,
					rotation = melee_unit:rotation()
				})
			else
				effect_manager:move(self._melee_cleave_particles[melee_unit:key()], hit_point)
			end
			
			if vr_offset and vr_offset.hitpoint then
				--line_offset:cylinder(orig_point, hit_point, radius)
			else
				--line:cylinder(orig_point, hit_point, radius)
			end
			
			local hits = World:raycast_all("ray", orig_point, hit_point, "slot_mask", slotmask, "ignore_unit", self._unit, "sphere_cast_radius", radius, "ray_type", "body melee bullet")
			
			if hits then
				--log("hits: " .. tostring(#hits)) --this logs
				for _, ray in ipairs(hits) do
					--log(tostring(_))
						
					if ray.unit and ray.unit:character_damage() and not ray.unit:character_damage():dead() then
						--log("hit unit")
						local hit_key = ray.unit:key()
						
						if not self._cleave_melee_hits[hit_key] then
							self._cleave_melee_hits[hit_key] = true
							self:_do_melee_damage(t, nil, ray, melee_entry)
						end
					elseif ray.unit then
						if ray.unit and alive(ray.unit) and ray.unit:parent() and alive(ray.unit:parent()) then
							local hit_key = ray.unit:key()
							local parent = ray.unit:parent()
							
							if parent:character_damage() then
								local parent_key = ray.unit:parent():key()
								
								if not self._cleave_melee_hits[parent_key] then
									self._cleave_melee_hits[parent_key] = true
								end
							end
							
							if not self._cleave_melee_hits[hit_key] then
								self._cleave_melee_hits[hit_key] = true
								self:_do_melee_damage(t, nil, ray, melee_entry)
							end
						elseif not self._cleave_melee_hit_terrain then
							self._cleave_melee_hit_terrain = true
							self:_do_melee_damage(t, nil, ray, melee_entry)
						end
					end
				end
			end
		end
	end
end

local align_obj_l_name = Idstring("a_weapon_left")
local align_obj_r_name = Idstring("a_weapon_right")

function PlayerStandard:melee_fist_cleave(t, melee_entry)
	local cam_unit = self._camera_unit
	local range = tweak_data.blackmarket.melee_weapons[melee_entry].stats.range
	local slotmask = managers.slot:get_mask("bullet_impact_targets")
	local shield_mask = managers.slot:get_mask("enemy_shield_check")
	local line = Draw:brush(Color.blue:with_alpha(0.25), 0.01)
	local line_offset = Draw:brush(Color.red:with_alpha(0.1), 0.01)
	local from_head = self._unit:movement():m_head_pos()
	local cam_fwd = self._cam_fwd:normalized()
	local fwd_offset = cam_fwd * 90
	local aligns = {
		cam_unit:get_object(align_obj_l_name),
		cam_unit:get_object(align_obj_r_name)
	}
	
	if not self._melee_cleave_particles then
		self._melee_cleave_particles = {}
	end
	
	local effect_manager = World:effect_manager()
	
	for i = 1, #aligns do		
		local orig_point = aligns[i]:position()
		
		mvector3.direction(mvec_melee_dir, from_head, orig_point)
		local dot_prod = mvector3.dot(mvec_melee_dir, cam_fwd)
		--log(tostring(dot_prod))
		
		if dot_prod > 0.6 then
			local hit_point = orig_point + fwd_offset

			local shield_test_ray = cam_unit:raycast("ray", orig_point, hit_point, "slot_mask", shield_mask, "sphere_cast_radius", 5)
			
			if shield_test_ray then
				hit_point = shield_test_ray.hit_position
			end
			
			if not self._melee_cleave_particles["i" .. tostring(i)] then
				self._melee_cleave_particles["i" .. tostring(i)] = effect_manager:spawn({
					effect = ids_melee_trail,
					position = hit_point,
				})
			else
				effect_manager:move(self._melee_cleave_particles["i" .. tostring(i)], hit_point)
			end
			
			--line:cylinder(orig_point, hit_point, 5)
		
			local hits = World:raycast_all("ray", orig_point, hit_point, "slot_mask", slotmask, "ignore_unit", self._unit, "sphere_cast_radius", 5, "ray_type", "body melee bullet")
			
			if hits then
				--log("hits: " .. tostring(#hits)) --this logs
				for _, ray in ipairs(hits) do
					--log(tostring(_))
						
					if ray.unit and ray.unit:character_damage() and not ray.unit:character_damage():dead() then
						--log("hit unit")
						local hit_key = ray.unit:key()
						
						if not self._cleave_melee_hits[hit_key] then
							self._cleave_melee_hits[hit_key] = true
							self:_do_melee_damage(t, nil, ray, melee_entry)
						end
					elseif ray.unit then
						if ray.unit and alive(ray.unit) and ray.unit:parent() and alive(ray.unit:parent()) then
							local hit_key = ray.unit:key()
							local parent = ray.unit:parent()
							
							if parent:character_damage() then
								local parent_key = ray.unit:parent():key()
								
								if not self._cleave_melee_hits[parent_key] then
									self._cleave_melee_hits[parent_key] = true
								end
							end
							
							if not self._cleave_melee_hits[hit_key] then
								self._cleave_melee_hits[hit_key] = true
								self:_do_melee_damage(t, nil, ray, melee_entry)
							end
						elseif not self._cleave_melee_hit_terrain then
							self._cleave_melee_hit_terrain = true
							self:_do_melee_damage(t, nil, ray, melee_entry)
						end
					end
				end
			end
		end
	end
end

function PlayerStandard:_check_action_melee(t, input)
	if self._state_data.melee_attack_wanted then
		if not self._state_data.melee_attack_allowed_t then
			self._state_data.melee_attack_wanted = nil

			self:_do_action_melee(t, input)
		end

		return
	end

	local action_wanted = input.btn_melee_press or input.btn_melee_release or input.btn_meleet_state

	if not self._state_data.meleeing and not action_wanted then
		return
	end

	if input.btn_melee_release or not input.btn_melee_press and not input.btn_meleet_state then
		if self._state_data.meleeing then
			if self._state_data.melee_attack_allowed_t then
				self._state_data.melee_attack_wanted = true

				return
			end

			self:_do_action_melee(t, input)
		end

		return
	end

	local action_forbidden = not self:_melee_repeat_allowed() or self._use_item_expire_t or self:_changing_weapon() or self:_interacting() or self:_is_throwing_projectile() or self:_is_using_bipod() or self:is_shooting_count()

	if action_forbidden then
		return
	end
	
	if input.btn_melee_press or input.btn_meleet_state then
		local melee_entry = managers.blackmarket:equipped_melee_weapon()
		local instant = tweak_data.blackmarket.melee_weapons[melee_entry].instant

		self:_start_action_melee(t, input, instant)
	end

	return true
end

function PlayerStandard:_get_melee_charge_lerp_value(t, offset)
	offset = offset or 0
	local melee_entry = managers.blackmarket:equipped_melee_weapon()
	local max_charge_time = tweak_data.blackmarket.melee_weapons[melee_entry].stats.charge_time * managers.player:upgrade_value("player", "faster_melee_charge", 1)

	if not self._state_data.melee_start_t then
		return 0
	end

	return math.clamp(t - self._state_data.melee_start_t - offset, 0, max_charge_time) / max_charge_time
end

if not RNGAGED.settings.disable_melee_cleave then

function PlayerStandard:_update_melee_timers(t, input)
	self:_upd_melee_cleave(t)

	if self._state_data.meleeing then
		local lerp_value = self:_get_melee_charge_lerp_value(t)

		self._camera_unit:anim_state_machine():set_parameter(self:get_animation("melee_charge_state"), "charge_lerp", math.bezier({
			0,
			0,
			1,
			1
		}, lerp_value))

		if self._state_data.melee_charge_shake then
			self._ext_camera:shaker():set_parameter(self._state_data.melee_charge_shake, "amplitude", math.bezier({
				0,
				0,
				1,
				1
			}, lerp_value))
		end
		
		self._state_data.preserve_combo_t = t + 1
	end

	if self._state_data.melee_damage_delay_t and self._state_data.melee_damage_delay_t <= t then
		self:_do_melee_damage(t, nil, self._state_data.melee_hit_ray)

		self._state_data.melee_damage_delay_t = nil
		self._state_data.melee_hit_ray = nil
	end

	if self._state_data.melee_attack_allowed_t and self._state_data.melee_attack_allowed_t <= t then
		self._state_data.melee_start_t = t
		local melee_entry = managers.blackmarket:equipped_melee_weapon()
		local melee_charge_shaker = tweak_data.blackmarket.melee_weapons[melee_entry].melee_charge_shaker or "player_melee_charge"
		self._state_data.melee_charge_shake = self._ext_camera:play_shaker(melee_charge_shaker, 0)
		self._state_data.melee_attack_allowed_t = nil
	end

	if self._state_data.melee_repeat_expire_t and self._state_data.melee_repeat_expire_t <= t then
		self._state_data.melee_repeat_expire_t = nil

		if input.btn_melee_press or input.btn_meleet_state then
			local melee_entry = managers.blackmarket:equipped_melee_weapon()
			local instant_hit = tweak_data.blackmarket.melee_weapons[melee_entry].instant
			self._state_data.melee_charge_wanted = not instant_hit and true
		end
	end
	
	if self._state_data.preserve_combo_t and self._state_data.preserve_combo_t <= t and not self._state_data.meleeing then
		self._wanted_melee_anim_i = 1
	end

	if self._state_data.melee_expire_t and self._state_data.melee_expire_t <= t then
		self._state_data.melee_expire_t = nil
		self._state_data.melee_repeat_expire_t = nil

		self:_stance_entered()

		if self._equipped_unit and input.btn_steelsight_state then
			self._steelsight_wanted = true
		end
	end
end

function PlayerStandard:discharge_melee()
	self:_do_action_melee(managers.player:player_timer():time(), nil)
end

function PlayerStandard:_start_action_melee(t, input, instant)
	self._equipped_unit:base():tweak_data_anim_stop("fire")
	self:_interupt_action_reload(t)
	self:_interupt_action_steelsight(t)
	self:_interupt_action_running(t)
	self:_interupt_action_charging_weapon(t)

	self._state_data.melee_charge_wanted = nil
	self._state_data.meleeing = true
	self._state_data.melee_start_t = nil
	local melee_entry = managers.blackmarket:equipped_melee_weapon()
	local primary = managers.blackmarket:equipped_primary()
	local primary_id = primary.weapon_id
	local bayonet_id = managers.blackmarket:equipped_bayonet(primary_id)
	local bayonet_melee = false
	local speed_mul = managers.player:upgrade_value("player", "melee_swing_speed_mul", 1)

	if bayonet_id and melee_entry == "weapon" and self._equipped_unit:base():selection_index() == 2 then
		bayonet_melee = true
	end

	if instant then
		self:_do_action_melee(t, input)

		return
	end

	self:_stance_entered()

	if self._state_data.melee_global_value then
		self._camera_unit:anim_state_machine():set_global(self._state_data.melee_global_value, 0)
	end

	local melee_entry = managers.blackmarket:equipped_melee_weapon()
	self._state_data.melee_global_value = tweak_data.blackmarket.melee_weapons[melee_entry].anim_global_param

	self._camera_unit:anim_state_machine():set_global(self._state_data.melee_global_value, 1)

	local current_state_name = self._camera_unit:anim_state_machine():segment_state(self:get_animation("base"))
	local attack_allowed_expire_t = tweak_data.blackmarket.melee_weapons[melee_entry].attack_allowed_expire_t or 0.15
	attack_allowed_expire_t = attack_allowed_expire_t / speed_mul
	self._state_data.melee_attack_allowed_t = t + (current_state_name ~= self:get_animation("melee_attack_state") and attack_allowed_expire_t or 0)
	local instant_hit = tweak_data.blackmarket.melee_weapons[melee_entry].instant

	if not instant_hit then
		self._ext_network:send("sync_melee_start", 0)
	end

	if current_state_name == self:get_animation("melee_attack_state") then
		self._ext_camera:play_redirect(self:get_animation("melee_charge"), speed_mul)

		return
	end

	local offset = nil

	if current_state_name == self:get_animation("melee_exit_state") then
		local segment_relative_time = self._camera_unit:anim_state_machine():segment_relative_time(self:get_animation("base"))
		offset = (1 - segment_relative_time) * 0.9
	end

	offset = math.max(offset or 0, attack_allowed_expire_t)

	self._ext_camera:play_redirect(self:get_animation("melee_enter"), speed_mul, offset)
end

function PlayerStandard:_do_action_melee(t, input, skip_damage)
	self._state_data.meleeing = nil
	self._cleave_melee_hits = {}
	self._cleave_melee_hit_terrain = nil
	local speed_mul = managers.player:upgrade_value("player", "melee_swing_speed_mul", 1)
	local melee_entry = managers.blackmarket:equipped_melee_weapon()
	local instant_hit = tweak_data.blackmarket.melee_weapons[melee_entry].instant
	local pre_calc_hit_ray = tweak_data.blackmarket.melee_weapons[melee_entry].hit_pre_calculation
	local melee_cleave = tweak_data.blackmarket.melee_weapons[melee_entry].cleave
	local melee_damage_delay = tweak_data.blackmarket.melee_weapons[melee_entry].melee_damage_delay or 0
	melee_damage_delay = math.min(melee_damage_delay, tweak_data.blackmarket.melee_weapons[melee_entry].repeat_expire_t)
	local primary = managers.blackmarket:equipped_primary()
	local primary_id = primary.weapon_id
	local bayonet_id = managers.blackmarket:equipped_bayonet(primary_id)
	local bayonet_melee = false

	if bayonet_id and self._equipped_unit:base():selection_index() == 2 then
		bayonet_melee = true
	end

	self._state_data.melee_expire_t = t + tweak_data.blackmarket.melee_weapons[melee_entry].expire_t / speed_mul
	self._state_data.melee_repeat_expire_t = t + math.min(tweak_data.blackmarket.melee_weapons[melee_entry].repeat_expire_t, tweak_data.blackmarket.melee_weapons[melee_entry].expire_t) / speed_mul
	self._state_data.preserve_combo_t = self._state_data.melee_repeat_expire_t + 0.5
	

	if not instant_hit and not skip_damage then
		self._state_data.melee_damage_delay_t = t + melee_damage_delay / speed_mul

		if pre_calc_hit_ray then
			self._state_data.melee_hit_ray = self:_calc_melee_hit_ray(t, 20) or true
		else
			self._state_data.melee_hit_ray = nil
		end
	end

	local send_redirect = instant_hit and (bayonet_melee and "melee_bayonet" or "melee") or "melee_item"

	if instant_hit then
		managers.network:session():send_to_peers_synched("play_distance_interact_redirect", self._unit, send_redirect)
	else
		self._ext_network:send("sync_melee_discharge")
	end

	if self._state_data.melee_charge_shake then
		self._ext_camera:shaker():stop(self._state_data.melee_charge_shake)

		self._state_data.melee_charge_shake = nil
	end

	self._melee_attack_var = 0
	self._wanted_melee_anim_i = self._wanted_melee_anim_i and self._wanted_melee_anim_i + 1 or 1

	if instant_hit then
		local hit = skip_damage or self:_do_melee_damage(t, bayonet_melee)

		if hit then
			self._ext_camera:play_redirect(bayonet_melee and self:get_animation("melee_bayonet") or self:get_animation("melee"), speed_mul)
		else
			self._ext_camera:play_redirect(bayonet_melee and self:get_animation("melee_miss_bayonet") or self:get_animation("melee_miss"), speed_mul)
		end
	else
		local state = self._ext_camera:play_redirect(self:get_animation("melee_attack"), speed_mul)
		local anim_attack_vars = tweak_data.blackmarket.melee_weapons[melee_entry].anim_attack_vars
		
		if anim_attack_vars then
			if #anim_attack_vars < self._wanted_melee_anim_i then
				self._wanted_melee_anim_i = 1
			end
			
			self._melee_attack_var = self._wanted_melee_anim_i
		end

		if not skip_damage then

			if not tweak_data.blackmarket.melee_weapons[melee_entry].no_cleave then
				self._state_data.melee_damage_delay_t = nil
				self._state_data.melee_hit_ray = nil
				
				if melee_damage_delay then
					self._state_data.cleave_melee_start_t = t + math.min(0.4, melee_damage_delay) / speed_mul
				else
					self._state_data.cleave_melee_start_t = t
				end
				
				local cleave_duration = math.min(tweak_data.blackmarket.melee_weapons[melee_entry].repeat_expire_t, tweak_data.blackmarket.melee_weapons[melee_entry].expire_t) * 0.675
				self._state_data.cleave_melee_t = t + cleave_duration / speed_mul
				--log("damn")
			end
		end
	
		self:_play_melee_sound(melee_entry, "hit_air", self._melee_attack_var)

		local melee_item_tweak_anim = "attack"
		local melee_item_prefix = ""
		local melee_item_suffix = ""
		local anim_attack_param = anim_attack_vars and anim_attack_vars[self._melee_attack_var]

		if anim_attack_param then
			self._camera_unit:anim_state_machine():set_parameter(state, anim_attack_param, 1)

			melee_item_prefix = anim_attack_param .. "_"
		end

		if not tweak_data.blackmarket.melee_weapons[melee_entry].no_cleave and self:_get_melee_charge_lerp_value(t) > 0.5 or self._state_data.melee_hit_ray and self._state_data.melee_hit_ray ~= true then
			self._camera_unit:anim_state_machine():set_parameter(state, "hit", 1)

			melee_item_suffix = "_hit"
		end

		melee_item_tweak_anim = melee_item_prefix .. melee_item_tweak_anim .. melee_item_suffix

		self._camera_unit:base():play_anim_melee_item(melee_item_tweak_anim)
	end
end

end

local old_swap_speed_mul_func = PlayerStandard._get_swap_speed_multiplier

function PlayerStandard:_get_swap_speed_multiplier()
	local multiplier = old_swap_speed_mul_func(self)
	
	multiplier = multiplier * managers.player:upgrade_value("player", "hh_weapon_swap_speed_mul", 1)
	multiplier = multiplier * managers.player:upgrade_value("player", "sandy_swap_speed_mul", 1)

	if self._unit:inventory() then
		local equipped_weapon = self._unit:inventory():equipped_unit()

		if alive(equipped_weapon) and equipped_weapon:base() then
			local weapon_base = alive(equipped_weapon) and equipped_weapon:base()
			
			if weapon_base._current_stats then
				if weapon_base._current_stats.suspicion then
					multiplier = multiplier / weapon_base._current_stats.suspicion
				end

				return multiplier
			end
			
		end
	end

	return multiplier
end

Hooks:PostHook(PlayerStandard, "set_stance_switch_delay", "regunz_stance_switch_enter_stance", function(self, t)
	self:_stance_entered()
	self:_update_crosshair_offset()
	self._equipped_unit:base()._last_saved_reload_prog = nil
end)

Hooks:PostHook(PlayerStandard, "_start_action_equip_weapon", "regunz_clean_spread", function(self, t)
	self._equipped_unit:base().regunz_accrec = 0
	self._equipped_unit:base().regunz_accrec_penalty = 0
end)

function PlayerStandard:_find_pickups(t)
	local pickups = World:find_units_quick("sphere", self._unit:movement():m_pos(), self._pickup_area, self._slotmask_pickups)
	local grenade_tweak = tweak_data.blackmarket.projectiles[managers.blackmarket:equipped_grenade()]
	local may_find_grenade = not grenade_tweak.base_cooldown and managers.player:has_category_upgrade("player", "regain_throwable_from_ammo")

	for _, pickup in ipairs(pickups) do
		if pickup:pickup() and pickup:pickup():pickup(self._unit) then
			if may_find_grenade then
				local data = managers.player:upgrade_value("player", "regain_throwable_from_ammo", nil)

				if data and not managers.player:got_max_grenades() then
					managers.player:add_coroutine("regain_throwable_from_ammo", PlayerAction.FullyLoaded, managers.player, data.chance, data.chance_inc)
				end
			end
			
			managers.player:_on_ammo_pickup()

			for id, weapon in pairs(self._unit:inventory():available_selections()) do
				managers.hud:set_ammo_amount(id, weapon.unit:base():ammo_info())
			end
		end
	end
end

function PlayerStandard:_update_omniscience(t, dt)
	local whisper = managers.groupai:state():whisper_mode()

	local action_forbidden = not managers.player:has_category_upgrade("player", "standstill_omniscience") or managers.player:current_state() == "civilian" or self:_on_zipline() or self._moving or self:running() or self:in_air() or not self._state_data.ducking or not tweak_data.player.omniscience
	
	if not action_forbidden and not whisper and not managers.player:has_category_upgrade("player", "standstill_omniscience_loud") then
		action_forbidden = true
	end
	
	if action_forbidden then
		if self._state_data.omniscience_t then
			self._state_data.omniscience_t = nil
		end

		return
	end

	self._state_data.omniscience_t = self._state_data.omniscience_t or t + tweak_data.player.omniscience.start_t

	if self._state_data.omniscience_t <= t then
		local radius =  not whisper and 1500 or tweak_data.player.omniscience.sense_radius
	
		local sensed_targets = World:find_units_quick("sphere", self._unit:movement():m_pos(), radius, managers.slot:get_mask("trip_mine_targets"))

		for _, unit in ipairs(sensed_targets) do
			if alive(unit) and not unit:base():char_tweak().is_escort and (whisper or unit:base():char_tweak().priority_shout) then
				self._state_data.omniscience_units_detected = self._state_data.omniscience_units_detected or {}

				if not self._state_data.omniscience_units_detected[unit:key()] or self._state_data.omniscience_units_detected[unit:key()] <= t then
					self._state_data.omniscience_units_detected[unit:key()] = t + tweak_data.player.omniscience.target_resense_t

					managers.game_play_central:auto_highlight_enemy(unit, true)

					break
				end
			end
		end

		self._state_data.omniscience_t = t + tweak_data.player.omniscience.interval_t
	end
end

local zero_vec = Vector3(0, 0, 0)

local tmp_ground_from_vec = Vector3()
local tmp_ground_to_vec = Vector3()
local up_offset_vec = math.UP * 30
local down_offset_vec = math.UP * -40

function PlayerStandard:_activate_mover(mover, velocity)
	self._unit:activate_mover(mover, velocity)

	if self._state_data.on_ladder then
		self._unit:mover():set_gravity(zero_vec)
	else
		self._unit:mover():set_gravity(Vector3(0, 0, -982))
	end
	
	self._unit:mover():set_damp_standing(15)
	self._unit:mover():set_damping(tweak_data.player.freefall.gravity / tweak_data.player.freefall.terminal_velocity)

	if self._is_jumping then
		self._unit:mover():jump()
		self._unit:mover():set_velocity(velocity)
	end
end

function PlayerStandard:_update_ground_ray()
	if self._unit:mover() and self._unit:mover():standing() then
		local body_unit = self._unit:mover():standing_body() and self._unit:mover():standing_body():unit()
		
		if body_unit and alive(body_unit) and body_unit:in_slot(managers.slot:get_mask("persons")) then
			self._gnd_normal = self._unit:mover():standing_normal()
			self._gnd_ray = nil
			self._standing_body = nil
		else
			self._gnd_normal = self._unit:mover():standing_normal()
			self._gnd_ray = mvector3.angle(math.UP, self._gnd_normal) <= 80 and true or nil
			self._standing_body = self._unit:mover():standing_body()
		end
		
		self._gnd_ray_chk = true
		
		return
	end
	
	self._standing_body = nil

	local hips_pos = tmp_ground_from_vec
	local down_pos = tmp_ground_to_vec

	mvector3.set(hips_pos, self._pos)
	mvector3.add(hips_pos, up_offset_vec)
	mvector3.set(down_pos, hips_pos)

	if (self._state_data.in_air or self._is_jumping) and not self._unit:movement():ladder_unit() then
		mvector3.add(down_pos, math.UP * -30)
	else
		mvector3.add(down_pos, down_offset_vec)
	end
	
	local ground_raycast
	
	if self._unit:movement():ladder_unit() then
		self._gnd_ray = self._unit:raycast("ray", hips_pos, down_pos, "slot_mask", self._slotmask_gnd_ray, "ignore_unit", self._unit:movement():ladder_unit(), "ray_type", "walk -mover", "sphere_cast_radius", 29, "report")
		self._gnd_ray_chk = true
		self._gnd_normal = nil
		
		return
	else
		ground_raycast = self._unit:raycast("ray", hips_pos, down_pos, "slot_mask", self._slotmask_gnd_ray, "ray_type", "walk -mover", "sphere_cast_radius", 29)
	end
	
	if ground_raycast and ground_raycast.normal then	
		if mvector3.angle(math.UP, ground_raycast.normal) <= 80 then
			self._gnd_ray = ground_raycast

			self._gnd_normal = ground_raycast.normal
		else
			self._gnd_ray = nil
			self._gnd_normal = ground_raycast.normal
		end
	else
		self._gnd_ray = nil
		self._gnd_normal = nil
	end

	self._gnd_ray_chk = true
end

function PlayerStandard:_chk_floor_moving_pos(pos)
	local hips_pos = tmp_ground_from_vec
	local down_pos = tmp_ground_to_vec

	mvector3.set(hips_pos, self._pos)
	mvector3.add(hips_pos, up_offset_vec)
	mvector3.set(down_pos, hips_pos)
	
	if (self._state_data.in_air or self._is_jumping) and not self._unit:movement():ladder_unit() then
		mvector3.add(down_pos, math.UP * -30)
	else
		mvector3.add(down_pos, down_offset_vec)
	end

	local ground_ray = self._unit:raycast("ray", hips_pos, down_pos, "slot_mask", self._slotmask_gnd_ray, "ray_type", "walk -mover", "sphere_cast_radius", 28)

	if ground_ray then
		return ground_ray
	end
end

function PlayerStandard:_get_walk_headbob()
	if self._state_data.using_bipod then
		return 0
	elseif self._state_data.in_steelsight then
		return 0.001
	elseif self._state_data.in_air then
		return 0
	elseif self._state_data.ducking then
		return 0.025
	elseif self._running then
		return 0.1 * (self._equipped_unit:base():run_and_shoot_allowed() and 0.5 or 1)
	end

	return 0.025
end

local mvec_pos_new = Vector3()
local mvec_achieved_walk_vel = Vector3()
local mvec_move_dir_normalized = Vector3()

function PlayerStandard:_update_movement(t, dt)
	local anim_data = self._unit:anim_data()
	local weapon_id = alive(self._equipped_unit) and self._equipped_unit:base() and self._equipped_unit:base():get_name_id()
	local weapon_tweak_data = weapon_id and tweak_data.weapon[weapon_id]
	local pos_new = nil
	self._target_headbob = self._target_headbob or 0
	self._headbob = self._headbob or 0
	self._true_headbob = self._true_headbob or {
		walk = 0,
		run = 0,
		crouch = 0
	}
	self._true_headbob_target = self._true_headbob_target or {
		walk = 0,
		run = 0,
		crouch = 0
	}
	
	local cur_state = self._ext_movement:current_state_name()
	
	local floor_moving_ray = self:_chk_floor_moving_pos()
	local floor_moving_vel
	
	if floor_moving_ray and floor_moving_ray.body and floor_moving_ray.body:unit() and alive(floor_moving_ray.body:unit()) and not floor_moving_ray.body:unit():in_slot(managers.slot:get_mask("persons")) then
		floor_moving_vel = floor_moving_ray.body and math.abs(floor_moving_ray.body:velocity():length()) > 0 and floor_moving_ray.body:velocity() or floor_moving_ray.body and math.abs(floor_moving_ray.body:angular_velocity():length()) > 0 and floor_moving_ray.body:angular_velocity()
	elseif not self._state_data.on_zipline and self._standing_body then
		floor_moving_vel = math.abs(self._standing_body:velocity():length()) > 0 and self._standing_body:velocity() or math.abs(self._standing_body:angular_velocity():length()) > 0 and self._standing_body:angular_velocity()
	end
	
	local can_move = true
	
	if cur_state == "tased" and not self._move_while_tased then
		can_move = nil
	end
	
	if self._state_data.dashing then
		if self._state_data.dash_t and self._state_data.dash_t < t or self._state_data.in_air then
			self._state_data.dashing = nil
			self._state_data.dash_t = nil
		end
	end

	if self._state_data.on_zipline and self._state_data.zipline_data.position then
		local speed = mvector3.length(self._state_data.zipline_data.position - self._pos) / dt / 500
		pos_new = mvec_pos_new

		mvector3.set(pos_new, self._state_data.zipline_data.position)

		if self._state_data.zipline_data.camera_shake then
			self._ext_camera:shaker():set_parameter_soft(self._state_data.zipline_data.camera_shake, "amplitude", speed, 0.9)
		end

		if alive(self._state_data.zipline_data.zipline_unit) then
			local dot = mvector3.dot(self._ext_camera:rotation():x(), self._state_data.zipline_data.zipline_unit:zipline():current_direction())

			self._ext_camera:camera_unit():base():set_target_tilt(dot * 10 * speed)
		end

		self._target_headbob = 0
	elseif self._move_dir and can_move and not self._state_data.dashing then
		local enter_moving = not self._moving
		self._moving = true
	
		if enter_moving then
			self._last_sent_pos_t = t

			self:_update_crosshair_offset()
		end

		local WALK_SPEED_MAX = self:_get_max_walk_speed(t)

		mvector3.set(mvec_move_dir_normalized, self._move_dir)
		mvector3.normalize(mvec_move_dir_normalized)
		local move_len = self._move_dir:length()

		if self._gnd_normal then --god is dead https://media.tenor.com/CowGNQSUsOYAAAAM/confused-math.gif
			local angle = mvector3.angle(math.UP, self._gnd_normal)
			
			if angle > 70 then
				local mul = 1 - (70 / angle)
				move_len = move_len * mul
			end
		end

		local wanted_walk_speed = WALK_SPEED_MAX * math.min(1, move_len)
		local acceleration = self._state_data.in_air and 700 or self._running and 5000 or 3000
		
		local achieved_walk_vel = mvec_achieved_walk_vel

		if self._jump_vel_xy and self._state_data.in_air and mvector3.dot(self._jump_vel_xy, self._last_velocity_xy) > 0 then
			local input_move_vec = wanted_walk_speed * self._move_dir
			local jump_dir = mvector3.copy(self._last_velocity_xy)
			local jump_vel = mvector3.normalize(jump_dir)
			local fwd_dot = jump_dir:dot(input_move_vec)

			if fwd_dot < jump_vel then
				local sustain_dot = (input_move_vec:normalized() * jump_vel):dot(jump_dir)
				local new_move_vec = input_move_vec + jump_dir * (sustain_dot - fwd_dot)

				mvector3.step(achieved_walk_vel, self._last_velocity_xy, new_move_vec, acceleration * dt)
			else
				mvector3.multiply(mvec_move_dir_normalized, wanted_walk_speed)
				mvector3.step(achieved_walk_vel, self._last_velocity_xy, mvec_move_dir_normalized, acceleration * dt)
			end
		elseif mvector3.is_zero(self._last_velocity_xy) then
			local starting_speed = wanted_walk_speed
			mvector3.multiply(mvec_move_dir_normalized, starting_speed)
			achieved_walk_vel = mvector3.copy(mvec_move_dir_normalized)
		else
			mvector3.multiply(mvec_move_dir_normalized, wanted_walk_speed)
			mvector3.step(achieved_walk_vel, self._last_velocity_xy, mvec_move_dir_normalized, acceleration * dt)
		end

		pos_new = mvec_pos_new
		
		mvector3.set(pos_new, achieved_walk_vel)
		mvector3.multiply(pos_new, dt)
		mvector3.add(pos_new, self._pos)
		
		if floor_moving_ray then
			local affected_body = floor_moving_ray.body
			
			if affected_body and affected_body:dynamic() then
				affected_body:push(80, -achieved_walk_vel)
			end
		elseif self._standing_body then
			local affected_body = self._standing_body
			
			if affected_body:dynamic() then
				affected_body:push(80, -achieved_walk_vel)
			end
		end
		
		self._target_headbob = self:_get_walk_headbob()
		self._target_headbob = self._target_headbob * math.abs(achieved_walk_vel:length()) / WALK_SPEED_MAX

		if weapon_tweak_data and weapon_tweak_data.headbob and weapon_tweak_data.headbob.multiplier then
			self._target_headbob = self._target_headbob * weapon_tweak_data.headbob.multiplier
		end
	elseif not mvector3.is_zero(self._last_velocity_xy) then
		local friction_vector = Vector3()
		--log("hmm")
		if self._gnd_normal then
			local angle = mvector3.angle(math.UP, self._gnd_normal)
			
			if angle > 70 then
				friction_vector = self._gnd_normal:with_z(0)
				local fucklen = math.max(0, 1 - (70 / angle))
				
				mvector3.set_length(friction_vector, 982 * fucklen)
			end
		end
		
		local decceleration = self._state_data.dashing and 2000 or self._state_data.in_air and 250 or math.lerp(2000, 1500, math.min(self._last_velocity_xy:length() / tweak_data.player.movement_state.standard.movement.speed.RUNNING_MAX, 1))
		
		local achieved_walk_vel = math.step(self._last_velocity_xy, friction_vector, decceleration * dt)
		
		if floor_moving_vel then
			local highest_speed_vel = floor_moving_vel:length() > achieved_walk_vel:length() and floor_moving_vel or achieved_walk_vel
			local lowest_speed_vel = floor_moving_vel:length() <= achieved_walk_vel:length() and floor_moving_vel or achieved_walk_vel
			
			mvector3.lerp(achieved_walk_vel, highest_speed_vel, lowest_speed_vel, lowest_speed_vel:length() / highest_speed_vel:length())
		end
		
		pos_new = mvec_pos_new

		mvector3.set(pos_new, achieved_walk_vel)
		mvector3.multiply(pos_new, dt)
		mvector3.add(pos_new, self._pos)

		self._target_headbob = 0
	elseif self._moving or floor_moving_vel then
		if floor_moving_vel then
			local achieved_walk_vel = mvec_achieved_walk_vel
			mvector3.set(achieved_walk_vel, floor_moving_vel)
			
			pos_new = mvec_pos_new
			mvector3.set(pos_new, achieved_walk_vel)
			mvector3.multiply(pos_new, dt)
			mvector3.add(pos_new, self._pos)
		end
		
		if self._moving then
			local step_pos = pos_new or self._pos
		
			mvector3.set(self._last_step_pos, self._pos)
			self._unit:base():anim_data_clbk_footstep()
		end

	
		self._target_headbob = 0
		self._moving = false
		self:_update_crosshair_offset()
	end

	if self._target_headbob ~= 0 and RNGAGED.settings.headbob_intensity ~= 0 then
		self._target_headbob = self._target_headbob * RNGAGED.settings.headbob_intensity
	else
		self._target_headbob = 0
	end

	local upd_headbob = nil
	
	if self._running then
		self._true_headbob_target.walk = 0
		self._true_headbob_target.run = self._target_headbob
		self._true_headbob_target.crouch = 0
	elseif self._state_data.ducking or self._state_data.in_steelsight then
		self._true_headbob_target.run = 0
		self._true_headbob_target.crouch = self._target_headbob
		self._true_headbob_target.walk = 0
	else
		self._true_headbob_target.run = 0
		self._true_headbob_target.walk = self._target_headbob
		self._true_headbob_target.crouch = 0
	end

	local ratio = 4

	if weapon_tweak_data and weapon_tweak_data.headbob and weapon_tweak_data.headbob.speed_ratio then
		ratio = weapon_tweak_data.headbob.speed_ratio
	end
	
	self._true_headbob.walk = math.step(self._true_headbob.walk, self._true_headbob_target.walk, dt / ratio)
	self._true_headbob.run = math.step(self._true_headbob.run, self._true_headbob_target.run, dt / ratio)
	self._true_headbob.crouch = math.step(self._true_headbob.crouch, self._true_headbob_target.crouch, dt / ratio)

	self._ext_camera:set_shaker_parameter_soft("headbob_run", "amplitude", self._true_headbob.run, 0.5)
	self._ext_camera:set_shaker_parameter_soft("headbob_crouch", "amplitude", self._true_headbob.crouch, 0.9)
	self._ext_camera:set_shaker_parameter_soft("headbob", "amplitude", self._true_headbob.walk, 0.9)

	if pos_new and not self._is_jumping and not self._state_data.in_air and not self._state_data.on_zipline and not self._unit:movement():ladder_unit() then
		local down_pos = tmp_ground_to_vec
		local dis = mvector3.distance(self._pos, pos_new)
		dis = dis + 15

		mvector3.set(down_pos, pos_new)
		mvector3.add(down_pos, math.UP * -dis)

		local ray = self._unit:raycast("ray", self._pos, down_pos, "slot_mask", self._slotmask_gnd_ray, "ray_type", "walk -mover")
		
		if ray then		
			local up_pos = tmp_ground_from_vec
			mvector3.set(up_pos, ray.position)
			mvector3.add(up_pos, up_offset_vec)

			local norm_ray = self._unit:raycast("ray", up_pos, down_pos, "slot_mask", self._slotmask_gnd_ray, "ray_type", "walk -mover")
			
			if norm_ray and norm_ray.position.z < pos_new.z and mvector3.angle(norm_ray.normal, math.UP) <= 80 then
				mvector3.set_z(pos_new, norm_ray.position.z)
			end
		end
	end

	if pos_new then
		if self._old_pos then
			if self._state_data.in_air and mvector3.distance(self._old_pos, pos_new) > 10 then
				self._state_data.in_air_t = t
			end
		end

		self._unit:movement():set_position(pos_new)
		
		mvector3.set(self._last_velocity_xy, pos_new)
		mvector3.subtract(self._last_velocity_xy, self._pos)
		
		if not self._state_data.on_ladder and not self._state_data.on_zipline then
			mvector3.set_z(self._last_velocity_xy, 0)
		end
		
		mvector3.divide(self._last_velocity_xy, dt)
		self._old_pos = mvector3.copy(self._pos)
	else
		mvector3.set_static(self._last_velocity_xy, 0, 0, 0)
		
		if self._old_pos then
			if self._state_data.in_air and mvector3.distance(self._old_pos, self._pos) > 10 then
				self._state_data.in_air_t = t
			end
		end

		self._old_pos = mvector3.copy(self._pos)
	end

	local cur_pos = pos_new or self._pos

	self:_update_network_jump(cur_pos, false)
	self:_update_network_position(t, dt, cur_pos, pos_new)
end

function PlayerStandard:_update_foley(t, input)
	if self._state_data.on_zipline then
		return
	end

	if not self._gnd_ray and not self._state_data.on_ladder then
		if not self._state_data.in_air then
			self._state_data.in_air = true
			self._state_data.in_air_t = t
			self._state_data.enter_air_pos_z = self._pos.z

			self:_interupt_action_running(t)
			self._unit:set_driving("orientation_object")
		end
		
		if self._unit:sampled_velocity().z < 0 then
			local amp = 0.1 * math.abs(self._unit:sampled_velocity().z) / 982
		
			self._ext_camera:set_shaker_parameter_soft("freefall", "amplitude", amp, 0.9)
		
			if not self._free_fall_sound and self._unit:sampled_velocity().z < -491 and self._state_data.enter_air_pos_z > self._pos.z and math.abs(self._state_data.enter_air_pos_z, self._pos.z) > 300 then
				self._free_fall_sound = self._unit:sound():play("free_falling", nil, false)
			end
		else
			self._ext_camera:set_shaker_parameter("freefall", "amplitude", 0, 0.9)
		end
	elseif self._state_data.in_air then
		self._state_data.in_air_t = nil
		self._unit:set_driving("script")

		self._state_data.in_air = false
		local from = self._pos + math.UP * 10
		local to = self._pos - math.UP * 60
		local material_name, pos, norm = World:pick_decal_material(from, to, self._slotmask_bullet_impact_targets)

		if self._free_fall_sound then
			self._free_fall_sound:stop()
			self._free_fall_sound = nil
		end
		
		self._ext_camera:set_shaker_parameter("freefall", "amplitude", 0, 0.9)
		self._unit:sound():play_land(material_name)
		
		if self._unit:sampled_velocity().z < -491 and self._pos.z < self._state_data.enter_air_pos_z then
			local fall_height_vel = math.abs(self._unit:sampled_velocity().z)
			local fall_height_dis = math.abs(self._state_data.enter_air_pos_z - self._pos.z)
			local fall_z = math.min(fall_height_vel, fall_height_dis)
		
			if self._unit:character_damage():damage_fall({
				height = fall_z
			}) then
				self._running_wanted = false

				managers.rumble:play("hard_land")
				self._ext_camera:play_shaker("player_fall_damage")
				self:_start_action_ducking(t)
			elseif input.btn_run_state then
				self._running_wanted = true
			end
		end

		self._jump_vel_xy = nil

		self._ext_camera:play_shaker("player_land", 0.5)
		managers.rumble:play("land")
	elseif self._jump_vel_xy and t - self._jump_t > 0.3 then
		self._jump_vel_xy = nil

		if input.btn_run_state then
			self._running_wanted = true
		end
	end

	self:_check_step(t)
end

function PlayerStandard:_check_step(t)
	if self._state_data.in_air then
		return
	end

	self._last_step_pos = self._last_step_pos or Vector3()
	local step_length = self._state_data.on_ladder and 50 or self._state_data.in_steelsight and (managers.player:has_category_upgrade("player", "steelsight_normal_movement_speed") and 150 or 100) or self._state_data.ducking and 125 or self._running and 175 or 150

	if mvector3.distance_sq(self._last_step_pos, self._pos) > step_length * step_length then
		mvector3.set(self._last_step_pos, self._pos)
		self._unit:base():anim_data_clbk_footstep()
		
		if not self._state_data.ducking and not self._state_data.in_steelsight then
			local amp = 0.1 * (step_length / 175)
			
			amp = amp * RNGAGED.settings.headbob_intensity
				
			self._ext_camera:play_shaker("player_land", amp, 0.25)
		end
	end
end

Hooks:PostHook(PlayerStandard, "_interupt_action_reload", "forget_reload", function(self)
	self._queue_reload_interupt = nil
end)

Hooks:PostHook(PlayerStandard, "_start_action_unequip_weapon", "play_swap_sound", function(self, t, data)
	self._unit:sound():play("wp_foley_generic_clip_take_new")
	self._unit:sound():play("wp_foley_generic_clip_throw")
	--self._last_saved_reload_prog = nil
end)

Hooks:PostHook(PlayerStandard, "_start_action_jump", "play_jump_sound", function(self, t, data)
	if not self._played_jump_t or t - self._played_jump_t > 0.55 then
		if self._jump_vel_xy and mvector3.length(self._jump_vel_xy) > 440 then
			self._unit:sound():play("wp_foley_generic_clip_throw")
		end
		
		self._unit:sound():play("boot_recoil_lift_gun")
		
		self._played_jump_t = t
	end
end)

Hooks:PostHook(PlayerStandard, "_start_action_ducking", "play_ducking_sound", function(self, t)
	if self:_interacting() or self:_on_zipline() then
		return
	end
	
	if self._state_data.ducking then
		if self._state_data.in_air then
			if self._jump_vel_xy and mvector3.length(self._jump_vel_xy) > 440 then
				self._unit:sound():play("foley_flap_light")
			end
		end
		
		self._unit:sound():play("boot_recoil_lift_gun")
	end
end)

function PlayerStandard:_check_action_jump(t, input)
	local new_action = nil
	local action_wanted = input.btn_jump_press

	if action_wanted then
		local action_forbidden = self._jump_t and t < self._jump_t + 0.55
		action_forbidden = action_forbidden or self._unit:base():stats_screen_visible() or self._state_data.in_air or self:_interacting() or self:_on_zipline() or self:_does_deploying_limit_movement() or self:_is_using_bipod()

		if not action_forbidden then
			if self._state_data.ducking then
				self:_interupt_action_ducking(t)
			else
				if self._state_data.on_ladder then
					self:_interupt_action_ladder(t)
				end

				local action_start_data = {}
				local jump_vel_z = tweak_data.player.movement_state.standard.movement.jump_velocity.z
				action_start_data.jump_vel_z = jump_vel_z

				if self._last_velocity_xy:length() > 0 then
					local jump_vel_xy = self._last_velocity_xy:length()
					action_start_data.jump_vel_xy = jump_vel_xy

					if is_running then
						self._unit:movement():subtract_stamina(tweak_data.player.movement_state.stamina.JUMP_STAMINA_DRAIN)
					end
				end

				new_action = self:_start_action_jump(t, action_start_data)
			end
		end
	end

	return new_action
end

function PlayerStandard:_start_action_jump(t, action_start_data)
	if self._running and not self.RUN_AND_RELOAD and not self._equipped_unit:base():run_and_shoot_allowed() then
		self:_interupt_action_reload(t)
		self._ext_camera:play_redirect(self:get_animation("stop_running"), self._equipped_unit:base():exit_run_speed_multiplier())
	end

	self:_interupt_action_running(t)

	self._jump_t = t
	local jump_normal = math.UP
	local jump_mul = 1

	if self._gnd_normal and not self._state_data.in_air then
		local angle = mvector3.angle(self._gnd_normal, jump_normal)
		if angle > 70 then 
			jump_mul = math.max(0, 1 - (70 / angle))
		end
	end

	local jump_vec = math.UP * (action_start_data.jump_vel_z * jump_mul)

	self._unit:mover():jump()

	if action_start_data.jump_vel_xy then
		local move_dir = self._last_velocity_xy:normalized()
		
		if math.abs(jump_normal.y) > 0 or math.abs(jump_normal.x) > 0 then
			local jump_normal_no_z = jump_normal:with_z(0)
			local dot_punishment = math.clamp(mvector3.dot(move_dir, jump_normal_no_z), 0, 1)
			mvector3.lerp(move_dir, jump_normal_no_z, move_dir, dot_punishment)
		end

		self._last_velocity_xy = move_dir * action_start_data.jump_vel_xy
		self._jump_vel_xy = mvector3.copy(self._last_velocity_xy)
	else
		self._last_velocity_xy = Vector3()
		
		if math.abs(jump_normal.y) > 0 or math.abs(jump_normal.x) > 0 then
			local move_dir = jump_normal:with_z(0)

			self._last_velocity_xy = move_dir * (action_start_data.jump_vel_z - jump_vec:length())
			self._jump_vel_xy = mvector3.copy(self._last_velocity_xy)
		end
	end

	self:_perform_jump(jump_vec)
end

function PlayerStandard:_determine_move_direction()
	self._stick_move = self._controller:get_input_axis("move")

	if self._state_data.on_zipline then
		return
	end

	if self:_interacting() or self:_does_deploying_limit_movement() then
		self._move_dir = nil
		self._normal_move_dir = nil
	else
		local ladder_unit = self._unit:movement():ladder_unit()

		if alive(ladder_unit) then
			local ladder_ext = ladder_unit:ladder()
			self._move_dir = mvector3.copy(self._stick_move)
			self._normal_move_dir = mvector3.copy(self._move_dir)
			local cam_flat_rot = Rotation(self._cam_fwd_flat, math.UP)

			mvector3.rotate_with(self._normal_move_dir, cam_flat_rot)

			local cam_rot = Rotation(self._cam_fwd, self._ext_camera:rotation():z())

			mvector3.rotate_with(self._move_dir, cam_rot)

			local up_dot = math.dot(self._move_dir, ladder_ext:up())
			local w_dir_dot = math.dot(self._move_dir, ladder_ext:w_dir())
			local normal_dot = math.dot(self._move_dir, ladder_ext:normal()) * -1
			local normal_offset = ladder_ext:get_normal_move_offset(self._unit:movement():m_pos())

			mvector3.set(self._move_dir, ladder_ext:up() * (up_dot + normal_dot))
			mvector3.add(self._move_dir, ladder_ext:w_dir() * w_dir_dot)
			mvector3.add(self._move_dir, ladder_ext:normal() * normal_offset)
		else
			self._move_dir = mvector3.copy(self._stick_move)
			local cam_flat_rot = Rotation(self._cam_fwd_flat, math.UP)

			mvector3.rotate_with(self._move_dir, cam_flat_rot)

			self._normal_move_dir = mvector3.copy(self._move_dir)
		end
	end
end

local tmp_interact_vec1 = Vector3()
local tmp_interact_vec2 = Vector3()
local tmp_interact_smoke_vec = Vector3()

function PlayerStandard:_add_unit_to_char_table(char_table, unit, unit_type, interaction_dist, interaction_through_walls, tight_area, priority, my_head_pos, cam_fwd, ray_ignore_units, ray_types)
	if unit:unit_data().disable_shout and not unit:brain():interaction_voice() then
		return
	end

	local u_head_pos = tmp_interact_vec1

	if unit_type == 3 then
		unit:base():get_mark_check_position(u_head_pos)
	else
		mvec3_set(u_head_pos, unit:movement():m_head_pos())
		mvec3_set(tmp_interact_vec2, math.UP)
		mvec3_mul(tmp_interact_vec2, 30)
		mvec3_add(u_head_pos, tmp_interact_vec2)
	end

	local vec = tmp_interact_vec2

	mvec3_set(vec, u_head_pos)
	mvec3_sub(vec, my_head_pos)

	local dis = mvec3_norm(vec)

	if not interaction_dist or dis < interaction_dist then
		local lerp1, lerp2 = nil

		if type(tight_area) == "table" then
			lerp1 = tight_area[1] or 30
			lerp2 = tight_area[2] or 10
		else
			if tight_area then
				lerp1 = 30
			else
				lerp1 = 90
			end

			if tight_area then
				lerp2 = 10
			else
				lerp2 = 30
			end
		end

		local max_angle = math.max(8, math.lerp(lerp1, lerp2, dis / 1200))
		local angle = vec:angle(cam_fwd)

		if angle < max_angle then
			local ing_wgt = dis * dis * (1 - vec:dot(cam_fwd)) / priority

			if interaction_through_walls then
				table.insert(char_table, {
					unit = unit,
					inv_wgt = ing_wgt,
					unit_type = unit_type
				})
			else
				local smoke_grenades = managers.groupai:state()._smoke_grenades
				local smoke_active = managers.groupai:state():is_smoke_grenade_active()
				
				if not RNGAGED.settings.disable_balance_changes then
					if smoke_active and smoke_grenades and #smoke_grenades > 0 then
						local smoke_dir = tmp_interact_smoke_vec
					
						for id, data in pairs(smoke_grenades) do
							local smoke_pos = data.detonate_pos:with_z(data.detonate_pos.z + 140)
							
							if mvec3_dis_sq(my_head_pos, smoke_pos) < 40000 then
								return --we are in the smoke
							end
							
							if mvec3_dis_sq(u_head_pos, smoke_pos) < 40000 then
								return --fully obscured
							else
								local dot_tolerance = mvec3_dis_sq(u_head_pos, smoke_pos) < 40000 and 0 or mvec3_dis_sq(my_head_pos, smoke_pos) < 40000 and 0 or 0.6
								mvec3_dir(smoke_dir, my_head_pos, smoke_pos)
								local dot = mvec3_dot(vec, smoke_dir)

								if dot >= dot_tolerance and mvec3_dis_sq(my_head_pos, smoke_pos) < mvec3_dis_sq(my_head_pos, u_head_pos) then
									return --they're on the other side of the smoke
								end
							end
						end
					end
				end
			
				local ray = World:raycast("ray", my_head_pos, u_head_pos, "slot_mask", self._slotmask_AI_visibility, "ray_type", ray_types or "ai_vision", "ignore_unit", ray_ignore_units or {})

				if not ray or mvec3_dis_sq(ray.position, u_head_pos) < 900 then
					table.insert(char_table, {
						unit = unit,
						inv_wgt = ing_wgt,
						unit_type = unit_type
					})
				end
			end
		end
	end
end

function PlayerStandard:_get_max_dash_speed(t, force_run)
	local speed_tweak = self._tweak_data.movement.speed
	local movement_speed = speed_tweak.RUNNING_MAX
	local speed_state = "run"

	movement_speed = managers.modifiers:modify_value("PlayerStandard:GetMaxWalkSpeed", movement_speed, self._state_data, speed_tweak)
	local morale_boost_bonus = self._ext_movement:morale_boost()
	local multiplier = managers.player:movement_speed_multiplier(speed_state, speed_state and morale_boost_bonus and morale_boost_bonus.move_speed_bonus, nil, self._ext_damage:health_ratio())
	multiplier = multiplier * (self._tweak_data.movement.multiplier[speed_state] or 1)
	local apply_weapon_penalty = true

	if self:_is_meleeing() then
		local melee_entry = managers.blackmarket:equipped_melee_weapon()
		apply_weapon_penalty = not tweak_data.blackmarket.melee_weapons[melee_entry].stats.remove_weapon_movement_penalty
	end

	if alive(self._equipped_unit) and apply_weapon_penalty then
		multiplier = multiplier * self._equipped_unit:base():movement_penalty()
		multiplier = multiplier * managers.player:upgrade_value(self._equipped_unit:base():get_name_id(), "increased_movement_speed", 1)
	end

	if managers.player:has_activate_temporary_upgrade("temporary", "increased_movement_speed") then
		multiplier = multiplier * managers.player:temporary_upgrade_value("temporary", "increased_movement_speed", 1)
	end

	if managers.player:has_activate_temporary_upgrade("temporary", "copr_ability") then
		local out_of_health = self._unit:character_damage():health_ratio() + 0.01 < managers.player:upgrade_value("player", "copr_static_damage_ratio", 0)

		if out_of_health then
			multiplier = multiplier * managers.player:upgrade_value("player", "copr_out_of_health_move_slow", 1)
		end
	end

	if self._slowdown_mul then
		multiplier = multiplier * self._slowdown_mul
	end
	
	if self._tweak_data_name then
		if managers.player:has_category_upgrade("carry", "movement_penalty_nullifier") then
		
		elseif tweak_data.carry.types[self._tweak_data_name].move_speed_modifier then
			local armor_init = tweak_data.player.damage.ARMOR_INIT
			multiplier = multiplier * tweak_data.carry.types[self._tweak_data_name].move_speed_modifier
			multiplier = math.clamp(multiplier * managers.player:upgrade_value("carry", "movement_speed_multiplier", 1), 0, 1)
			multiplier = math.clamp(multiplier * managers.player:upgrade_value("player", "mrwi_carry_speed_multiplier", 1), 0, 1)
			
			if managers.player:has_category_upgrade("player", "armor_carry_bonus") then
				local base_max_armor = armor_init + managers.player:body_armor_value("armor") + managers.player:body_armor_skill_addend()
				local mul = managers.player:upgrade_value("player", "armor_carry_bonus", 1)

				for i = 1, base_max_armor do
					multiplier = multiplier * mul
				end

				multiplier = math.clamp(multiplier, 0, 1)
			end
			
			local mutator = nil

			if managers.mutators:is_mutator_active(MutatorCG22) then
				mutator = managers.mutators:get_mutator(MutatorCG22)
			elseif managers.mutators:is_mutator_active(MutatorPiggyRevenge) then
				mutator = managers.mutators:get_mutator(MutatorPiggyRevenge)
			end

			if mutator and mutator.get_bag_speed_increase_multiplier then
				multiplier = multiplier * mutator:get_bag_speed_increase_multiplier()
			end
		end
	end

	local final_speed = movement_speed * multiplier
	self._cached_final_speed = self._cached_final_speed or 0

	if final_speed ~= self._cached_final_speed then
		self._cached_final_speed = final_speed

		self._ext_network:send("action_change_speed", final_speed)
	end

	return final_speed
end


local tmp_dash_vector = Vector3()

function PlayerStandard:_start_action_dash(t)
	local move_dir = self._move_dir

	if not move_dir or mvector3.length(move_dir) <= 0 or self._state_data.dashing then
		return
	end
	
	if not self._unit:movement():is_above_stamina_threshold() or self._state_data.in_air or self._jump_vel_xy then
		return
	end
	
	local WALK_SPEED_MAX = self:_get_max_dash_speed(t, true) * 1.2
	
	mvec3_set(tmp_dash_vector, move_dir)
	mvec3_norm(tmp_dash_vector)
	mvector3.multiply(tmp_dash_vector, WALK_SPEED_MAX)
	mvec3_set(self._last_velocity_xy, tmp_dash_vector)
	local sampled_velocity_z = self._unit:sampled_velocity().z
	self._unit:mover():set_velocity(self._last_velocity_xy:with_z(sampled_velocity_z))
	
	self._unit:sound():play("wp_foley_generic_clip_take_new")
	self._unit:sound():play("foley_flap_light")
	self._unit:sound():play("wp_foley_generic_clip_throw")
	self._unit:sound():play("m4_melee_attack")
	
	if not self:_is_meleeing() then
		self._unit:sound():play("wp_foley_generic_tilt_soft")
	end
	
	self._unit:movement():subtract_stamina(5)
	self._state_data.dashing = true
	self._state_data.dash_t = t + 0.25
	self._running_wanted = false
	
	return true
end

function PlayerStandard:_check_action_run(t, input)
	if self._setting_hold_to_run and input.btn_run_release or self._running and not self._move_dir then
		self._running_wanted = false

		if self._running then
			self:_end_action_running(t)

			if input.btn_steelsight_state and not self._state_data.in_steelsight then
				self._steelsight_wanted = true
			end
		end
	elseif not self._setting_hold_to_run and input.btn_run_release and not self._move_dir then
		self._running_wanted = false
	elseif input.btn_run_press or self._running_wanted then
		if not self._running or self._end_running_expire_t then
			self:_start_action_running(t)
		elseif self._running and not self._setting_hold_to_run then
			self:_end_action_running(t)

			if input.btn_steelsight_state and not self._state_data.in_steelsight then
				self._steelsight_wanted = true
			end
		end
	end
end

function PlayerStandard:_start_action_running(t)
	if self._slowdown_run_prevent then
		self._running_wanted = false

		return
	end

	if self:on_ladder() or self:_on_zipline() then
		return
	end
	
	if not self._move_dir then		
		return
	end

	if self._shooting and not self._equipped_unit:base():run_and_shoot_allowed() or self:_changing_weapon() or self:_is_meleeing() or self._use_item_expire_t or self._state_data.in_air or self:_is_throwing_projectile() or self:_is_charging_weapon() then
		if self:_is_meleeing() or not self:_can_run_directional() then
			self:_start_action_dash(t)
		end

		return
	end

	if self._state_data.ducking and not self:_can_stand() then
		self._running_wanted = true

		return
	end

	if not self:_can_run_directional() then
		self:_start_action_dash(t)

		return
	end

	self._running_wanted = false

	if managers.player:get_player_rule("no_run") then
		return
	end

	if not self._unit:movement():is_above_stamina_threshold() then
		return
	end

	--if (not self._state_data.shake_player_start_running or not self._ext_camera:shaker():is_playing(self._state_data.shake_player_start_running)) and self._setting_use_headbob then
		--self._state_data.shake_player_start_running = self._ext_camera:play_shaker("player_start_running", 0.75)
	--end

	self:set_running(true)

	self._end_running_expire_t = nil
	self._start_running_t = t
	self._play_stop_running_anim = nil

	if not self:_is_reloading() or not self.RUN_AND_RELOAD then
		if not self._equipped_unit:base():run_and_shoot_allowed() then
			self._ext_camera:play_redirect(self:get_animation("start_running"))
		else
			self._ext_camera:play_redirect(self:get_animation("idle"))
		end
	end

	if not self.RUN_AND_RELOAD then
		self:_interupt_action_reload(t)
	end

	self:_interupt_action_steelsight(t)
	self:_interupt_action_ducking(t)
end

function PlayerStandard:_end_action_steelsight(t)
	self._state_data.in_steelsight = false
	self._state_data.reticle_obj = nil

	self:_stance_entered()
	self:_update_crosshair_offset()
	self._camera_unit:base():clbk_stop_aim_assist()

	local weap_base = self._equipped_unit:base()

	weap_base:play_tweak_data_sound("leave_steelsight")

	if weap_base:weapon_tweak_data().animations.has_steelsight_stance then
		self:_need_to_play_idle_redirect()

		self._state_data.steelsight_weight_target = 0

		self._camera_unit:base():set_steelsight_anim_enabled(true)
	end

	self._ext_network:send("set_stance", 2, false, false)
end

function PlayerStandard:is_dashing()
	return self._state_data.dashing
end

function PlayerStandard:_start_action_steelsight(t, gadget_state)
	if self:_changing_weapon() or self:_is_reloading() or self:_interacting() or self:_is_meleeing() or self._use_item_expire_t or self:_is_throwing_projectile() or self:_on_zipline() then
		self._steelsight_wanted = true

		return
	end

	if self._running and not self._end_running_expire_t then
		self:_interupt_action_running(t)

		self._steelsight_wanted = true

		return
	end

	self:_break_intimidate_redirect(t)

	self._steelsight_wanted = false
	self._state_data.in_steelsight = true
	self._state_data.reload_steelsight_expire_t = nil

	self:_update_crosshair_offset()
	self:_stance_entered(nil, "steelsight")
	self:_interupt_action_running(t)
	self:_interupt_action_cash_inspect(t)

	local weap_base = self._equipped_unit:base()

	if gadget_state ~= nil then
		weap_base:play_sound("gadget_steelsight_" .. (gadget_state and "enter" or "exit"))
	else
		weap_base:play_tweak_data_sound("enter_steelsight")
	end

	if weap_base:weapon_tweak_data().animations.has_steelsight_stance then
		self:_need_to_play_idle_redirect()

		self._state_data.steelsight_weight_target = 1

		self._camera_unit:base():set_steelsight_anim_enabled(true)
	end

	self._state_data.reticle_obj = weap_base.get_reticle_obj and weap_base:get_reticle_obj()

	if managers.controller:get_default_wrapper_type() ~= "pc" and self._setting_aim_assist then
		local closest_ray = self._equipped_unit:base():check_autoaim(self:get_fire_weapon_position(), self:get_fire_weapon_direction(), nil, true)

		self._camera_unit:base():clbk_aim_assist(closest_ray)
	end

	self._ext_network:send("set_stance", 3, false, false)
	managers.job:set_memory("cac_4", true)
end

function PlayerStandard:_can_stand(ignored_bodies, skip_hint)
	local offset = 50
	local radius = 30
	local hips_pos = self._obj_com:position() + math.UP * offset
	local up_pos = math.UP * (160 - offset)

	mvector3.add(up_pos, hips_pos)

	local ray_table = {
		"ray",
		hips_pos,
		up_pos,
		"slot_mask",
		self._slotmask_gnd_ray,
		"ray_type",
		"body mover",
		"sphere_cast_radius",
		radius,
		"bundle",
		20
	}

	if ignored_bodies then
		table.insert(ray_table, "ignore_body")
		table.insert(ray_table, ignored_bodies)
	end

	local ray = World:raycast(unpack(ray_table))

	if ray then
		if alive(ray.body) and not ray.body:collides_with_mover() then
			ignored_bodies = ignored_bodies or {}

			table.insert(ignored_bodies, ray.body)

			return self:_can_stand(ignored_bodies)
		end
		
		if not skip_hint then
			managers.hint:show_hint("cant_stand_up", 2)
		end
		
		if not self._state_data.cant_stand_here then
			self._state_data.cant_stand_here = true
			self:_stance_entered()
		end
		
		return false
	end
	
	if self._state_data.cant_stand_here then
		self._state_data.cant_stand_here = nil
		self:_stance_entered()
	end

	return true
end

local fwd_ray_to = Vector3()

local cook_states = {
	carry = true,
	standard = true,
	mask_off = true,
	civilian = true,
	tased = true
}

function PlayerStandard:_update_fwd_ray()
	local weap_base = alive(self._equipped_unit) and self._equipped_unit:base()
	local from = self._unit:movement():m_head_pos()
	local camera_unit_base = self._camera_unit:base()
	local range = weap_base and weap_base.needs_extended_fwd_ray_range and weap_base:needs_extended_fwd_ray_range(self._state_data.in_steelsight) and 20000 or 4000

	mvec3_set(fwd_ray_to, self._cam_fwd)
	mvec3_mul(fwd_ray_to, range)
	mvec3_add(fwd_ray_to, from)

	local fwd_ray = World:raycast("ray", from, fwd_ray_to, "slot_mask", self._slotmask_fwd_ray)
	self._fwd_ray = fwd_ray
	
	local cur_state = self._ext_movement:current_state_name()
	local saw = weap_base and weap_base:is_category("saw")
	
	if not RNGAGED.settings.disable_head_height_changes and self._state_data.ducking and self._state_data.in_steelsight and not self._state_data.cant_stand_here and cook_states[cur_state] and not saw then
		local old_peek_from_cover = self._peek_from_cover
		local m_pos = self._unit:movement():m_pos()
		local peek_pos = from:with_z(m_pos.z + 65)
			
		mvec3_set(fwd_ray_to, self._cam_fwd:with_z(0))
		mvec3_mul(fwd_ray_to, 75)
		mvec3_add(fwd_ray_to, peek_pos)
		--local line = Draw:brush(Color.blue:with_alpha(0.25), 0.01)
		--line:cylinder(peek_pos, fwd_ray_to, 1)
		
		local peek_ray = World:raycast("ray", peek_pos, fwd_ray_to, "slot_mask", managers.slot:get_mask("contour_ray_check"), "report")
		
		self._peek_from_cover = peek_ray
		
		if old_peek_from_cover ~= self._peek_from_cover then
			if self._peek_from_cover then
				self._ext_network:send("action_change_pose", 1, self._unit:position()) --stand up
				self._unit:sound():play("wp_foley_generic_clip_throw")
			else
				self._ext_network:send("action_change_pose", 2, self._unit:position()) --sit down
				self._unit:sound():play("boot_recoil_lift_gun")
			end
		
			self:_stance_entered()
		end
	elseif self._peek_from_cover and not self._state_data.cant_stand_here then
		self._peek_from_cover = nil
		
		if self._state_data.ducking then
			self._ext_network:send("action_change_pose", 2, self._unit:position()) --sit down
			self._unit:sound():play("boot_recoil_lift_gun")
		else
			self._ext_network:send("action_change_pose", 1, self._unit:position()) --stand up
			self._unit:sound():play("wp_foley_generic_clip_throw")
		end
		
		self:_stance_entered()
	end

	managers.environment_controller:set_dof_distance(math.max(0, math.min(fwd_ray and fwd_ray.distance or 4000, 4000) - 200), self._state_data.in_steelsight)

	if weap_base then
		if fwd_ray and self._state_data.in_steelsight and weap_base.check_highlight_unit then
			weap_base:check_highlight_unit(fwd_ray.unit)
		end

		if weap_base.set_unit_health_display then
			weap_base:set_unit_health_display(fwd_ray and fwd_ray.unit or nil)
		end

		if weap_base.set_scope_range_distance then
			weap_base:set_scope_range_distance(fwd_ray and fwd_ray.distance / 100 or false)
		end
	end
end

function PlayerStandard:_stance_entered(unequipped, reason)
	local stance_standard = tweak_data.player.stances.default[managers.player:current_state()] or tweak_data.player.stances.default.standard
	local head_stance
	
	if self._state_data.ducking then
		if not RNGAGED.settings.disable_head_height_changes and self._peek_from_cover and self._state_data.in_steelsight and not self._state_data.cant_stand_here then
			head_stance = tweak_data.player.stances.default.crouched_peeking.head
		else
			head_stance = tweak_data.player.stances.default.crouched.head
		end
	end
	
	head_stance = head_stance or stance_standard.head
	
	local stance_id = nil
	local stance_mod = {
		translation = Vector3(0, 0, 0)
	}

	if not unequipped then
		stance_id = self._equipped_unit:base():get_stance_id()

		if self._state_data.in_steelsight and self._equipped_unit:base().stance_mod then
			stance_mod = self._equipped_unit:base():stance_mod() or stance_mod
		end
	end

	local stances = nil
	stances = (self:_is_meleeing() or self:_is_throwing_projectile()) and tweak_data.player.stances.default or tweak_data.player.stances[stance_id] or tweak_data.player.stances.default
	local misc_attribs = stances.standard
	misc_attribs = (not self:_is_using_bipod() or self:_is_throwing_projectile() or stances.bipod) and (self._state_data.in_steelsight and stances.steelsight or self._state_data.ducking and stances.crouched or stances.standard)
	local head_duration = tweak_data.player.TRANSITION_DURATION
	local head_duration_multiplier = 1
	local duration = head_duration + (self._equipped_unit:base():transition_duration() or 0)
	local duration_multiplier = reason == "steelsight" and self._state_data.in_steelsight and 1 / self._equipped_unit:base():enter_steelsight_speed_multiplier() or 1

	if self._instant_stance_transition then
		self._instant_stance_transition = nil
		duration_multiplier = 0
	end

	local new_fov = self:get_zoom_fov(misc_attribs) + 0

	self._camera_unit:base():clbk_stance_entered(misc_attribs.shoulders, head_stance, misc_attribs.vel_overshot, new_fov, misc_attribs.shakers, stance_mod, duration_multiplier, duration, head_duration_multiplier, head_duration)
	managers.menu:set_mouse_sensitivity(self:in_steelsight())
end

function PlayerStandard:_check_action_primary_attack(t, input, params)
	local new_action, action_wanted = nil
	action_wanted = (not params or params.action_wanted == nil or params.action_wanted) and (input.btn_primary_attack_state or input.btn_primary_attack_release or self:is_shooting_count() or self:_is_charging_weapon())

	if action_wanted then
		local action_forbidden = nil

		if params and params.action_forbidden ~= nil then
			action_forbidden = params.action_forbidden
		elseif self:_is_reloading() or self:_changing_weapon() or self:_is_meleeing() or self._use_item_expire_t or self:_interacting() or self:_is_throwing_projectile() or self:_is_deploying_bipod() or self._menu_closed_fire_cooldown > 0 or self:is_switching_stances() then
			action_forbidden = true
		else
			action_forbidden = false
		end

		if not action_forbidden then
			self._queue_reload_interupt = nil
			local start_shooting = false

			self._ext_inventory:equip_selected_primary(false)

			local weap_unit = self._equipped_unit

			if weap_unit then
				local weap_base = weap_unit:base()
				local fire_mode = weap_base:fire_mode()
				local fire_on_release = weap_base:fire_on_release()

				if weap_base:out_of_ammo() then
					if input.btn_primary_attack_press then
						weap_base:dryfire()
					end
				elseif weap_base.clip_empty and weap_base:clip_empty() then
					if params and params.no_reload or self:_is_using_bipod() then
						if input.btn_primary_attack_press then
							weap_base:dryfire()
						end

						weap_base:tweak_data_anim_stop("fire")
					else
						local fire_mode_func = self._primary_action_funcs.clip_empty[fire_mode]

						if not fire_mode_func or not fire_mode_func(self, t, input, params, weap_unit, weap_base) then
							fire_mode_func = self._primary_action_funcs.clip_empty.default

							if fire_mode_func then
								fire_mode_func(self, t, input, params, weap_unit, weap_base)
							end
						end

						new_action = self:_is_reloading()
					end
				elseif params and params.block_fire then
					-- Nothing
				elseif self._running and (params and params.no_running or weap_base.run_and_shoot_allowed and not weap_base:run_and_shoot_allowed()) then
					self:_interupt_action_running(t)
				else
					if not self._shooting then
						if weap_base:start_shooting_allowed() then
							local start = nil
							local start_fire_func = self._primary_action_get_value.chk_start_fire[fire_mode]

							if start_fire_func then
								start = start_fire_func(self, t, input, params, weap_unit, weap_base)
							else
								start_fire_func = self._primary_action_get_value.chk_start_fire.default

								if start_fire_func then
									start = start_fire_func(self, t, input, params, weap_unit, weap_base)
								end
							end

							if not params or not params.no_start_fire_on_release then
								start = start and not fire_on_release
								start = start or fire_on_release and input.btn_primary_attack_release
							end

							if start then
								weap_base:start_shooting()
								self._camera_unit:base():start_shooting()

								self._shooting = true
								self._shooting_t = t
								start_shooting = true
								local fire_mode_func = self._primary_action_funcs.start_fire[fire_mode]

								if not fire_mode_func or not fire_mode_func(self, t, input, params, weap_unit, weap_base) then
									fire_mode_func = self._primary_action_funcs.start_fire.default

									if fire_mode_func then
										fire_mode_func(self, t, input, params, weap_unit, weap_base)
									end
								end
							end
						elseif not params or not params.no_check_stop_shooting_early then
							self:_check_stop_shooting()

							return false
						end
					end

					local suppression_ratio = self._unit:character_damage():effective_suppression_ratio()
					local spread_mul = math.lerp(1, tweak_data.player.suppression.spread_mul, suppression_ratio)
					local autohit_mul = math.lerp(1, tweak_data.player.suppression.autohit_chance_mul, suppression_ratio)
					local weapon_tweak_data = weap_base:weapon_tweak_data()
					local suppression_mul = managers.blackmarket:threat_multiplier(weap_base:get_name_id(), weapon_tweak_data.categories)
					local dmg_mul = 1
					
					local primary_category = weapon_tweak_data.categories[1]

					if not weapon_tweak_data.ignore_damage_multipliers then
						dmg_mul = dmg_mul * managers.player:temporary_upgrade_value("temporary", "dmg_multiplier_outnumbered", 1)

						if self._overkill_all_weapons or weap_base:is_category("shotgun", "saw") then
							dmg_mul = dmg_mul * managers.player:temporary_upgrade_value("temporary", "overkill_damage_multiplier", 1)
						end

						local health_ratio = self._ext_damage:health_ratio()
						local damage_health_ratio = managers.player:get_damage_health_ratio(health_ratio, primary_category)

						if damage_health_ratio > 0 then
							local upgrade = weap_base:is_category("saw") and self._damage_health_ratio_mul_melee or self._damage_health_ratio_mul
							dmg_mul = dmg_mul * (1 + upgrade * damage_health_ratio)
						end

						dmg_mul = dmg_mul * managers.player:temporary_upgrade_value("temporary", "berserker_damage_multiplier", 1)
						dmg_mul = dmg_mul * managers.player:get_property("trigger_happy", 1)
					end

					local fired = nil
					local fired_func = self._primary_action_get_value.fired[fire_mode]

					if fired_func then
						fired = fired_func(self, t, input, params, weap_unit, weap_base, start_shooting, fire_on_release, dmg_mul, nil, spread_mul, autohit_mul, suppression_mul)
					else
						fired_func = self._primary_action_get_value.fired.default

						if fired_func then
							fired = fired_func(self, t, input, params, weap_unit, weap_base, start_shooting, fire_on_release, dmg_mul, nil, spread_mul, autohit_mul, suppression_mul)
						end
					end

					if (not params or not params.no_steelsight) and weap_base.manages_steelsight and weap_base:manages_steelsight() then
						if weap_base:wants_steelsight() and not self._state_data.in_steelsight then
							self:_start_action_steelsight(t)
						elseif not weap_base:wants_steelsight() and self._state_data.in_steelsight then
							self:_end_action_steelsight(t)
						end
					end

					local charging_weapon = weap_base:charging()

					if not self._state_data.charging_weapon and charging_weapon then
						self:_start_action_charging_weapon(t)
					elseif self._state_data.charging_weapon and not charging_weapon then
						self:_end_action_charging_weapon(t)
					end

					new_action = true

					if fired then
						if not params or not params.no_rumble then
							managers.rumble:play("weapon_fire")
						end

						local weap_tweak_data = weap_base.weapon_tweak_data and weap_base:weapon_tweak_data() or tweak_data.weapon[weap_base:get_name_id()]

						if not params or not params.no_shake then
							local shake_tweak_data = weap_tweak_data.shake[fire_mode] or weap_tweak_data.shake
							local shake_multiplier = shake_tweak_data[self._state_data.in_steelsight and "fire_steelsight_multiplier" or "fire_multiplier"]

							self._ext_camera:play_shaker("fire_weapon_rot", 1 * shake_multiplier)
							self._ext_camera:play_shaker("fire_weapon_kick", 1 * shake_multiplier, 1, 0.15)
						end

						weap_base:tweak_data_anim_stop("unequip")
						weap_base:tweak_data_anim_stop("equip")

						if (not params or not params.no_steelsight) and (not self._state_data.in_steelsight or not weap_base:tweak_data_anim_play("fire_steelsight", weap_base:fire_rate_multiplier())) then
							weap_base:tweak_data_anim_play("fire", weap_base:fire_rate_multiplier())
						end

						if (not params or not params.no_recoil_anim_redirect) and not weap_tweak_data.no_recoil_anim_redirect then
							local fire_mode_func = self._primary_action_funcs.recoil_anim_redirect[fire_mode]

							if not fire_mode_func or not fire_mode_func(self, t, input, params, weap_unit, weap_base) then
								fire_mode_func = self._primary_action_funcs.recoil_anim_redirect.default

								if fire_mode_func then
									fire_mode_func(self, t, input, params, weap_unit, weap_base)
								end
							end
						end

						local recoil_multiplier = (weap_base:recoil() + weap_base:recoil_addend()) * weap_base:recoil_multiplier()
						local kick_tweak_data = weap_tweak_data.kick[fire_mode] or weap_tweak_data.kick
						local up, down, left, right = unpack(kick_tweak_data[self._state_data.in_steelsight and "steelsight" or self._state_data.ducking and "crouching" or "standing"])

						self._camera_unit:base():recoil_kick(up * recoil_multiplier, down * recoil_multiplier, left * recoil_multiplier, right * recoil_multiplier)

						if self._shooting_t then
							local time_shooting = t - self._shooting_t
							local achievement_data = tweak_data.achievement.never_let_you_go

							if achievement_data and weap_base:get_name_id() == achievement_data.weapon_id and achievement_data.timer <= time_shooting then
								managers.achievment:award(achievement_data.award)

								self._shooting_t = nil
							end
						end

						if managers.player:has_category_upgrade(primary_category, "stacking_hit_damage_multiplier") then
							self._state_data.stacking_dmg_mul = self._state_data.stacking_dmg_mul or {}
							self._state_data.stacking_dmg_mul[primary_category] = self._state_data.stacking_dmg_mul[primary_category] or {
								nil,
								0
							}
							local stack = self._state_data.stacking_dmg_mul[primary_category]

							if fired.hit_enemy then
								stack[1] = t + managers.player:upgrade_value(primary_category, "stacking_hit_expire_t", 1)
								stack[2] = math.min(stack[2] + 1, tweak_data.upgrades.max_weapon_dmg_mul_stacks or 5)
							else
								stack[1] = nil
								stack[2] = 0
							end
						end

						if (not params or not params.no_recharge_clbk) and weap_base.set_recharge_clbk then
							weap_base:set_recharge_clbk(callback(self, self, "weapon_recharge_clbk_listener"))
						end

						managers.hud:set_ammo_amount(weap_base:selection_index(), weap_base:ammo_info())

						if self._ext_network then
							local impact = not fired.hit_enemy
							local sync_blank_func = self._primary_action_funcs.sync_blank[fire_mode]

							if not sync_blank_func or not sync_blank_func(self, t, input, params, weap_unit, weap_base, impact) then
								sync_blank_func = self._primary_action_funcs.sync_blank.default

								if sync_blank_func then
									sync_blank_func(self, t, input, params, weap_unit, weap_base, impact)
								end
							end
						end

						local stop_volley_func = self._primary_action_get_value.check_stop_shooting_volley[fire_mode]

						if stop_volley_func then
							new_action = stop_volley_func(self, t, input, params, weap_unit, weap_base)
						else
							stop_volley_func = self._primary_action_get_value.check_stop_shooting_volley.default

							if stop_volley_func then
								new_action = stop_volley_func(self, t, input, params, weap_unit, weap_base)
							end
						end
					else
						local not_fired_func = self._primary_action_get_value.not_fired[fire_mode]

						if not_fired_func then
							new_action = not_fired_func(self, t, input, params, weap_unit, weap_base)
						else
							not_fired_func = self._primary_action_get_value.not_fired.default

							if not_fired_func then
								new_action = not_fired_func(self, t, input, params, weap_unit, weap_base)
							end
						end
					end
				end
			end
		elseif self:_is_reloading() and self._equipped_unit and self._equipped_unit:base():reload_interuptable() and input.btn_primary_attack_press then
			self._queue_reload_interupt = true
		end
	end

	self:_chk_action_stop_shooting(new_action)

	return new_action
end

function PlayerStandard:get_fire_weapon_position()
	return self._ext_camera:position_with_shake()
end