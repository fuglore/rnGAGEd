PlayerManager._style_data = {}
PlayerManager._style_points = 0
PlayerManager._style_tier = 0
PlayerManager._style_pause = nil

function PlayerManager:add_style(event)
	if managers.groupai:state():whisper_mode() then
		return
	end

	local style_tweak = tweak_data.style_meter_events[event]
	
	if not style_tweak then
		log("you're a bingus")
		return
	end
	
	local t = Application:time()
	local event_data = self._style_data[event]
	local amount = style_tweak.amount

	if event_data then
		if event_data.expire_t < t then
			event_data.stale_value = 1 
			event_data.expire_t = t
		end
	
		if style_tweak.amount_min_mul and event_data.stale_value == style_tweak.stale_max then
			amount = style_tweak.amount_min_mul
		else
			amount = amount / event_data.stale_value
			
			if style_tweak.style_pause_t then
				if self._style_pause then
					self._style_pause = self._style_pause + style_tweak.style_pause_t
				else
					self._style_pause = style_tweak.style_pause_t
				end
			end
		end
		
		local stale_factor = style_tweak.stale_add
		local stale_expire_t = style_tweak.stale_expire_t
		
		if event_data.stale_value < style_tweak.stale_max then
			event_data.stale_value = self._style_data[event].stale_value + stale_factor
		end
		
		event_data.expire_t = event_data.expire_t + stale_expire_t
	else
		local stale_factor = style_tweak.stale_add
		local stale_expire_t = style_tweak.stale_expire_t
		
		self._style_data[event] = {stale_value = stale_factor, expire_t = t + stale_expire_t}
		
		if style_tweak.style_pause_t then
			if self._style_pause then
				self._style_pause = self._style_pause + style_tweak.style_pause_t
			else
				self._style_pause = style_tweak.style_pause_t
			end
		end
	end

	self._style_points = self._style_points + amount
	self._style_points = math.clamp(self._style_points, 0, 6.99)
	self._style_tier = math.ceil(self._style_points)
end

function PlayerManager:upd_style(t, dt)
	if not self:player_unit() then
		self._style_data = {}
		self._style_points = 0
		self._style_tier = 0
		self._style_pause = nil
		
		return
	end

	if self._style_pause then
		self._style_pause = self._style_pause - dt
		
		if self._style_pause > 0 then
			return
		end
	end
	
	self._style_pause = nil

	if self._style_tier > 0 then
		local player_unit = self:player_unit()
		local player_mov_ext = player_unit:movement()
		local player_dmg_ext = player_unit:character_damage()
		
		local tier_mul = 0.5 + self._style_tier / 2
		local drain = 0.016
		
		if not player_mov_ext._attackers or not next(player_mov_ext._attackers) then
			drain = drain * 2
		end

		if player_dmg_ext._supperssion_data.value then
			drain = drain * 0.75
		end
		
		drain = drain * tier_mul
		
		self._style_points = self._style_points - drain * dt
		
		if self._style_points <= 0 then
			self._style_points = 0
			self._style_tier = 0
		else
			self._style_points = math.clamp(self._style_points, 0, 6.99)
			self._style_tier = math.ceil(self._style_points)
		end
	end
end

function PlayerManager:pause_style(time)
	if managers.groupai:state():whisper_mode() then
		return
	end

	if self._style_pause then
		self._style_pause = self._style_pause + time
	else
		self._style_pause = time
	end
end

function PlayerManager:on_enter_custody(_player, already_dead)
	local player = _player or self:player_unit()

	if not player then
		Application:error("[PlayerManager:on_enter_custody] Unable to get player")

		return
	end

	if player == self:player_unit() then
		local equipped_grenade = managers.blackmarket:equipped_grenade()

		if equipped_grenade and tweak_data.blackmarket.projectiles[equipped_grenade] and tweak_data.blackmarket.projectiles[equipped_grenade].base_cooldown then
			self:reset_ability_hud()
		end

		self:set_property("copr_risen_cooldown_added", nil)
		
		self._style_data = {}
		self._style_points = 0
		self._style_tier = 0
		self._style_pause = nil
	end

	managers.mission:call_global_event("player_in_custody")

	local peer_id = managers.network:session():local_peer():id()

	if self._super_syndrome_count and self._super_syndrome_count > 0 and not self._action_mgr:is_running("stockholm_syndrome_trade") then
		self._action_mgr:add_action("stockholm_syndrome_trade", StockholmSyndromeTradeAction:new(player:position(), peer_id))
	end

	self:force_drop_carry()
	managers.statistics:downed({
		death = true
	})

	if not already_dead then
		player:network():send("sync_player_movement_state", "dead", player:character_damage():down_time(), player:id())
		managers.groupai:state():on_player_criminal_death(peer_id)
	end

	self._listener_holder:call(self._custody_state, player)
	game_state_machine:change_state_by_name("ingame_waiting_for_respawn")
	player:character_damage():set_invulnerable(true)
	player:character_damage():set_health(0)
	player:base():_unregister()
	World:delete_unit(player)
	managers.hud:remove_interact()
end

function PlayerManager:verify_grenade(peer_id)
	return true
end

local old_move_speed_mul_func = PlayerManager.movement_speed_multiplier

function PlayerManager:movement_speed_multiplier(speed_state, bonus_multiplier, upgrade_level, health_ratio)
	local multiplier = old_move_speed_mul_func(self, speed_state, bonus_multiplier, upgrade_level, health_ratio)
	
	local player_unit = self:player_unit()

	if not player_unit or not alive(player_unit) then
		return multiplier
	end
	
	local current_state = self:get_current_state()

	if not current_state then
		return multiplier
	end
	
	if RNGAGED.settings.disable_balance_changes then
		return multiplier
	end
	
	local current_weapon = current_state:get_equipped_weapon()
	
	if current_weapon then
		local conc_index = current_weapon._current_stats_indices.concealment
		local conc_tweak_data = tweak_data.weapon.stats.concealment
		local lerp = conc_index / #conc_tweak_data
		local weapon_speed_mul = math.lerp(0.9, 1.1, lerp)
		
		multiplier = multiplier * weapon_speed_mul
		
		if current_weapon.regunz_slow_gun then --this implementation sucks, and doesn't feel good, make something better
			if not current_weapon:start_shooting_allowed() then
				local weapon_slow_mul = math.lerp(0.5, 0.75, lerp)
				local slow_lerpd = math.lerp(weapon_slow_mul, 1, current_weapon:regunz_get_slowdown_lerp())
				
				
				multiplier = multiplier * slow_lerpd
			end
		end
	end
	
	if current_state.tased then
		multiplier = multiplier * 0.2
	end
	
	return multiplier
end

function PlayerManager:mod_movement_penalty(movement_penalty)
	local skill_mods = self:upgrade_value("player", "passive_armor_movement_penalty_multiplier", 1)
	skill_mods = skill_mods * self:upgrade_value("team", "crew_reduce_speed_penalty", 1)
	skill_mods = skill_mods * self:upgrade_value("player", "hh_armor_movement_penalty_multiplier", 1)

	if skill_mods < 1 and movement_penalty < 1 then
		local penalty = 1 - movement_penalty
		penalty = penalty * skill_mods
		movement_penalty = 1 - penalty
	end

	return movement_penalty
end

local old_dmg_resist_func = PlayerManager.damage_reduction_skill_multiplier

function PlayerManager:damage_reduction_skill_multiplier(damage_type)
	local multiplier = old_dmg_resist_func(self, damage_type)
	
	multiplier = multiplier * self:temporary_upgrade_value("temporary", "dmg_resist_on_unsafe_reload", 1)
	
	if self:has_activate_temporary_upgrade("temporary", "sandy_tuner") then
		multiplier = multiplier * self:upgrade_value("player", "sandy_dmg_resist_tuner", 1)
	end
	
	return multiplier
end

local old_dodge_add_func = PlayerManager.skill_dodge_chance

function PlayerManager:skill_dodge_chance(running, crouching, on_zipline, override_armor, detection_risk)
	local chance = old_dodge_add_func(self, running, crouching, on_zipline, override_armor, detection_risk)
	
	chance = chance + self:upgrade_value("player", "hh_dodge_add", 0)
	
	return chance
end

Hooks:PostHook(PlayerManager, "check_skills", "reguns_check_skillz", function(self)
	if self:has_category_upgrade("temporary", "dmg_resist_on_unsafe_reload") then
		self._message_system:register(Message.OnPlayerReload, "power_load_event", callback(self, self, "_on_powerload_event"))
	else
		self._message_system:unregister(Message.OnPlayerReload, "power_load_event")
	end
end)

function PlayerManager:on_headshot_dealt()
	local player_unit = self:player_unit()

	if not player_unit then
		return
	end

	self._message_system:notify(Message.OnHeadShot, nil, nil)

	local t = Application:time()

	if self._on_headshot_dealt_t and t < self._on_headshot_dealt_t then
		return
	end

	self._on_headshot_dealt_t = t + (tweak_data.upgrades.on_headshot_dealt_cooldown or 0)
	local damage_ext = player_unit:character_damage()
	local regen_armor_bonus = managers.player:upgrade_value("player", "headshot_regen_armor_bonus", 0)

	if damage_ext and regen_armor_bonus > 0 then
		damage_ext:restore_armor(regen_armor_bonus)
	end
	
	local relieve_sup_bonus = managers.player:upgrade_value("player", "headshot_relieve_suppression", 0)

	if damage_ext and relieve_sup_bonus > 0 then
		damage_ext:relieve_suppression(relieve_sup_bonus)
	end

	local regen_health_bonus = managers.player:upgrade_value("player", "headshot_regen_health_bonus", 0)

	if damage_ext and regen_health_bonus > 0 then
		damage_ext:restore_health(regen_health_bonus, true)
	end
end

function PlayerManager:_on_powerload_event(weapon_unit)
	local player_unit = self:local_player()
	
	if not player_unit or not alive(player_unit) then
		return
	end
	
	local t = TimerManager:game():time()
	local powerload_dmg_resist_ready = not self._next_powerload_t or self._next_powerload_t < t
	local powerload_tase_ready = not self._next_electric_reload_t or self._next_electric_reload_t < t
	
	if powerload_dmg_resist_ready or powerload_tase_ready then
		local enemies = World:find_units_quick(player_unit, "sphere", player_unit:position(), 500, managers.slot:get_mask("enemies"))
		local obstruction_slotmask = managers.slot:get_mask("world_geometry", "vehicles")
		local has_enemies
		local head_pos = player_unit:movement():m_head_pos()
		
		for _, enemy in ipairs(enemies) do
			if enemy:character_damage() and enemy:character_damage().is_friendly_fire and not enemy:character_damage():is_friendly_fire(player_unit) or enemy:brain() and enemy:brain().is_hostile and enemy:brain():is_hostile() then
				local enemy_head_pos = enemy:movement():m_head_pos()
				local obstructed = enemy:raycast("ray", head_pos, enemy_head_pos, "slot_mask", obstruction_slotmask, "report")
				
				if not obstructed then
					has_enemies = true
					break
				end
			end
		end
		
		if has_enemies then
			if powerload_dmg_resist_ready then
				self:activate_temporary_upgrade("temporary", "dmg_resist_on_unsafe_reload")
				self._next_powerload_t = t + tweak_data.upgrades.power_load_cooldown
			end
			
			if self:has_category_upgrade("player", "tase_on_unsafe_reload") and powerload_tase_ready then
				self._next_electric_reload_t = t + tweak_data.upgrades.power_load_cooldown * 2
				
				local explosion_pos = player_unit:movement():m_com()
				explosion_pos = explosion_pos + math.UP * 40
				local sound_event = tweak_data.projectiles["wpn_gre_electric"].sound_event
				local custom_params = {
					camera_shake_max_mul = 0,
					effect = "none",
					sound_event = sound_event,
					idstr_decal = false,
					feedback_range = 0
				}
				
				managers.explosion:play_sound_and_effects(explosion_pos, math.UP, 0, custom_params)
				local slot_mask = managers.slot:get_mask("explosion_targets")
				
				managers.explosion:detect_and_tase({
					player_damage = 0,
					tase_strength = "heavy",
					hit_pos = explosion_pos,
					range = 500,
					collision_slotmask = slot_mask,
					curve_pow = 3,
					damage = 0,
					alert_radius = 0,
					user = player_unit,
					verify_callback = callback(self, self, "_volt_clip_check_tase_unit")
				})
			end
		end
	end
end

function PlayerManager:_volt_clip_check_tase_unit(unit)
	local unit_name = nil

	if unit and unit:base() then
		unit_name = unit:base()._tweak_table
	end

	if alive(unit) and unit:brain() and unit:brain().is_hostage and unit:brain():is_hostage() then
		return false
	end
	
	if alive(unit) and unit:brain() and (not unit:brain().is_hostile or not unit:brain():is_hostile()) then
		return false
	end

	if unit_name then
		return tweak_data:get_raw_value("character", unit_name, "damage", "hurt_severity", "tase") ~= false
	else
		return true
	end
end

Hooks:PostHook(PlayerManager, "on_damage_dealt", "regunz_reclaim", function(self, unit, damage_info)
	local player_unit = self:player_unit()

	if not player_unit then
		return
	end
	
	if not alive(unit) or not unit:character_damage() then
		return
	end
	
	if self:has_category_upgrade("weapon", "automatic_heat_chance") then
		local flame_on = nil
		local equipped_unit = self:get_current_state()._equipped_unit
		local gun_base = alive(equipped_unit) and equipped_unit:base()
		
		if gun_base and damage_info and damage_info.weapon_unit then
			if damage_info.weapon_unit == equipped_unit then
				local bad_gun = gun_base:is_category("grenade_launcher", "shotgun", "bow", "flamethrower")
				
				if not bad_gun and gun_base:fire_mode() == "auto" then
					if self:has_category_upgrade("weapon", "automatic_heat_last_shot") and gun_base.get_ammo_remaining_in_clip then
						if gun_base:get_ammo_remaining_in_clip() <= 0 then
							flame_on = true
						elseif math.random() < self:upgrade_value("weapon", "automatic_heat_chance", 0) then							
							flame_on = true
						end						
					elseif math.random() < self:upgrade_value("weapon", "automatic_heat_chance", 0) then
						flame_on = true
					end
				end
			end
		end
		
		if flame_on then
			local weapon_id = gun_base and gun_base.get_name_id and gun_base:get_name_id()
			local dot_data = tweak_data.dot:get_dot_data("weapon_kacchainsaw_flamethrower")
			local data = {
				unit = unit,
				dot_data = dot_data,
				weapon_id = weapon_id,
				weapon_unit = equipped_unit,
				attacker_unit = player_unit
			}

			managers.fire:add_doted_enemy(data)
		end
	end

	if self._current_state == "bleedout" or self._current_state == "fatal" then
		return
	end
	
	if self:has_category_upgrade("player", "reclaim_health") and not unit:in_slot(16) then
		if damage_info.damage and damage_info.damage > 0 then
			if mvector3.distance_sq(unit:position(), player_unit:position()) < 250000 then
				local to_heal = damage_info.damage * 0.25
				
				local character_damage = self:local_player():character_damage()
				
				character_damage:restore_health(to_heal, true, nil, true)
			end
		end
	end	
end)

function PlayerManager:_on_ammo_pickup()
	local player_unit = self:player_unit()

	if not player_unit then
		return
	end

	if not self:has_category_upgrade("player", "reclaim_pickups") and not self:has_category_upgrade("player", "grind_armor_on_pickup") then
		return
	end
	
	if self._current_state == "bleedout" or self._current_state == "fatal" then
		return
	end
	
	local character_damage = self:local_player():character_damage()
	
	if self:has_category_upgrade("player", "reclaim_pickups") then
		character_damage:restore_health(0.01, nil, nil, true)
	end
	
	local t = TimerManager:game():time()
	
	if self:has_category_upgrade("player", "grind_armor_on_pickup") then
		if not self._armor_grinding_ammo_t or self._armor_grinding_ammo_t < t then
			self._armor_grinding_ammo_t = t + 2
			character_damage:restore_armor(1, true)
		end
	end
end

Hooks:PostHook(PlayerManager, "on_killshot", "regunz_killshot", function(self, killed_unit, variant, headshot, weapon_id)
	local player_unit = self:player_unit()

	if not player_unit then
		return
	end

	if CopDamage.is_civilian(killed_unit:base()._tweak_table) then
		return
	end
	
	self:add_style("kill")
	
	local character_damage = self:local_player():character_damage()
	
	if self:has_category_upgrade("player", "sandy_on_kill_health") then
		character_damage:restore_health(self:upgrade_value("player", "sandy_on_kill_health", 0), true)
	end
	
	local t = TimerManager:game():time()
	
	if self:has_category_upgrade("player", "grind_stamina_on_kill") then
		if not self._armor_grinding_kill_t or self._armor_grinding_kill_t < t then
			local stamina_regen = player_unit:movement():_max_stamina() * self:upgrade_value("player", "grind_stamina_on_kill", 0)
			player_unit:movement():add_stamina(stamina_regen)
		
			if self:has_category_upgrade("player", "grind_armor_on_kill") then
				character_damage:restore_armor(1, true)
			end
			
			self._armor_grinding_kill_t = t + 2
		end
	end
	
	
end)

function PlayerManager:_on_messiah_event()
	if self._messiah_charges > 0 and self._current_state == "bleed_out" and not self._coroutine_mgr:is_running("get_up_messiah") and not self._coroutine_mgr:is_running("feign_death_up") then
		self._coroutine_mgr:add_coroutine("get_up_messiah", PlayerAction.MessiahGetUp, self)
	end
end

function PlayerManager:_on_feign_death_event()
	if self._current_state == "bleed_out" and not self._coroutine_mgr:is_running("feign_death_up") then
		self._coroutine_mgr:add_coroutine("feign_death_up", PlayerAction.FeignDeathGetUp, self)
	end
end

function PlayerManager:attempt_ability(ability)
	if not self:player_unit() then
		return false
	end

	local local_peer_id = managers.network:session():local_peer():id()
	local has_no_grenades = self:get_grenade_amount(local_peer_id) == 0
	local is_downed = game_state_machine:verify_game_state(GameStateFilters.downed)
	local swan_song_active = managers.player:has_activate_temporary_upgrade("temporary", "berserker_damage_multiplier")
	is_downed = is_downed and not self:has_category_upgrade("player", "activate_ability_downed")
	
	if not self:has_activate_temporary_upgrade("temporary", "sandy_tuner") then
		if has_no_grenades or is_downed or swan_song_active then
			return false
		end
	end

	local attempt_func = self["_attempt_" .. ability]

	if attempt_func and not attempt_func(self) then
		return false
	end

	local tweak = tweak_data.blackmarket.projectiles[ability]

	if tweak and tweak.sounds and tweak.sounds.activate then
		self:player_unit():sound():play(tweak.sounds.activate)
	end

	self:add_grenade_amount(-1)
	self._message_system:notify("ability_activated", nil, ability)

	return true
end

function PlayerManager:_attempt_sandy_tuner()
	if self:has_activate_temporary_upgrade("temporary", "sandy_tuner") then
		managers.time_speed:stop_effect(self._sandy_effect_world, 0.0125)
		--self:player_unit():sound():play("perkdeck_activate")
		if self._sandy_looping_sound_wind or self._sandy_looping_sound_clock then
			if self._sandy_looping_sound_wind then
				self._sandy_looping_sound_wind:stop()
			end
			
			if self._sandy_looping_sound_clock then
				self._sandy_looping_sound_clock:stop()
			end
			
			self:player_unit():sound():play("emitter_electric_fence_hum_stop")
			self:player_unit():sound():play("tag_reader_scan_beep")
			self._sandy_looping_sound_clock = nil
			self._sandy_looping_sound_wind = nil
			
			if self._sandy_trail_vfx then
				World:effect_manager():fade_kill(self._sandy_trail_vfx)
			end
		end
		
		return false
	end
	
	local pausable = {
		sustain = 10,
		timer = "pausable",
		speed = 0.1,
		fade_in = 0.0125,
		fade_out = 0.0125
	}
	
	self._sandy_effect_world = "world_sandy_Peer" .. tostring(managers.network:session():local_peer():id())

	managers.time_speed:play_effect(self._sandy_effect_world, pausable)

	self:activate_temporary_upgrade("temporary", "sandy_tuner")
	
	local expire_time = self:get_activate_temporary_expire_time("temporary", "sandy_tuner")

	managers.enemy:add_delayed_clbk("sandy_tuner_active", callback(self, self, "clbk_sandy_tuner_end"), expire_time)

	self:player_unit():sound():play("repel_end")
	self:player_unit():sound():play("c4_explode_under_water")
	
	if not self._sandy_looping_sound_wind and not self._sandy_looping_sound_clock then
		--self._sandy_looping_sound_clock = self:player_unit():sound():play("emitter_clock_01")
		self._sandy_looping_sound_wind = self:player_unit():sound():play("emitter_cargo_bay_wind_01")
	end
	
	managers.environment_controller:set_buff_effect(0.5)

	return true
end

function PlayerManager:clbk_sandy_tuner_end()
	if self._sandy_looping_sound_wind or self._sandy_looping_sound_clock then
		--log("yay")
		if self._sandy_looping_sound_wind then
			self._sandy_looping_sound_wind:stop()
		end
		
		if self._sandy_looping_sound_clock then
			self._sandy_looping_sound_clock:stop()
		end
		
		self:player_unit():sound():play("emitter_electric_fence_hum_stop")
		self:player_unit():sound():play("tag_reader_scan_beep")
		self._sandy_looping_sound_clock = nil
		self._sandy_looping_sound_wind = nil
	end
end

Hooks:PostHook(PlayerManager, "update", "regunz_upd", function(self, t, dt)
	self:_upd_sandy_vfx(t, dt)
	if managers.groupai and not managers.groupai:state():whisper_mode() then
		self:upd_style(t, dt)
	end
end)

function PlayerManager:_upd_sandy_vfx(t, dt)
	local player_unit = self:player_unit()
	
	if not self:has_category_upgrade("temporary", "sandy_tuner") then
		--log("hmm")
		return
	end
	
	if not player_unit then
		managers.environment_controller:set_base_chromatic_amount(0.15)
	
		return
	end
	
	if not self._sandy_vfx_data then
		self._sandy_vfx_data = {
			target_chrom_vfx = 0
		}
	end
	
	local vfx_data = self._sandy_vfx_data
	
	if self:has_activate_temporary_upgrade("temporary", "sandy_tuner") then
		vfx_data.target_chrom_vfx = math.lerp(-0.75, 0.6, math.random())
	else
		vfx_data.target_chrom_vfx = 0
	end
	
	managers.environment_controller:set_base_chromatic_amount(0.15 + vfx_data.target_chrom_vfx)
end

--networking fixes (to not crash other players) ((MADE BY OFFYERROCKER TYSM))

local function get_as_digested(amount)
	local list = {}

	for i = 1, #amount do
		table.insert(list, Application:digest_value(amount[i], false))
	end

	return list
end

local function make_double_hud_string(a, b)
	return string.format("%01d|%01d", a, b)
end

local function add_hud_item(amount, icon)
	if #amount > 1 then
		managers.hud:add_item_from_string({
			amount_str = make_double_hud_string(amount[1], amount[2]),
			amount = amount,
			icon = icon
		})
	else
		managers.hud:add_item({
			amount = amount[1],
			icon = icon
		})
	end
end

local function set_hud_item_amount(index, amount)
	if #amount > 1 then
		managers.hud:set_item_amount_from_string(index, make_double_hud_string(amount[1], amount[2]), amount)
	else
		managers.hud:set_item_amount(index, amount[1])
	end
end

function PlayerManager:update_grenades_to_peer(peer)
	local peer_id = managers.network:session():local_peer():id()

	if self._global.synced_grenades[peer_id] then
		local grenade = self._global.synced_grenades[peer_id].grenade
		local tweak = tweak_data.blackmarket.projectiles[grenade]
		if tweak.based_on then 
			grenade = tweak.based_on
		end
		local amount = self._global.synced_grenades[peer_id].amount

		peer:send_queued_sync("sync_grenades", grenade, Application:digest_value(amount, false), 0)
	end
end

function PlayerManager:update_grenades_amount_to_peers(grenade, amount, register_peer_id)
	local peer_id = managers.network:session():local_peer():id()
	
		local tweak = tweak_data.blackmarket.projectiles[grenade]
		if tweak.based_on then 
			grenade = tweak.based_on
		end
		
	managers.network:session():send_to_peers_synched("sync_grenades", grenade, amount, register_peer_id or 0)
	self:set_synced_grenades(peer_id, grenade, amount, register_peer_id)
end

--fixes the synced (spoofed) grenade data being used for the actual data- specifically, cooldown
function PlayerManager:add_grenade_amount(amount, sync)
	local peer_id = managers.network:session():local_peer():id()
	local grenade = managers.blackmarket:equipped_grenade() --self._global.synced_grenades[peer_id].grenade
	local tweak = tweak_data.blackmarket.projectiles[grenade]
	local max_amount = self:get_max_grenades_by_peer_id(peer_id)
	local icon = tweak.icon
	local previous_amount = self._global.synced_grenades[peer_id].amount

	if amount > 0 and tweak.base_cooldown then
		managers.hud:animate_grenade_flash(HUDManager.PLAYER_PANEL)
	end

	amount = math.min(Application:digest_value(previous_amount, false) + amount, max_amount)

	if amount < max_amount and tweak.base_cooldown then
		self:replenish_grenades(tweak.base_cooldown)
	end

	managers.hud:set_teammate_grenades_amount(HUDManager.PLAYER_PANEL, {
		icon = icon,
		amount = amount
	})
	self:update_grenades_amount_to_peers(grenade, amount, sync and peer_id)
end
