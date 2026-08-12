local temp_rot = Rotation()
local velocity = Vector3()
local last_pos = Vector3()

local max_lean_velocity = 575
local max_lean_velocity_z = 350
local max_lean_angle = 1.5
local lean_rate = 10
local zero_vec = Vector3(0, 0, 0)

local current_lean_angle_x = 0
local current_lean_angle_z = 0

local old_update = FPCameraPlayerBase.update

function FPCameraPlayerBase:update(unit, t, dt)
	old_update(self, unit, t, dt)
--Hooks:PostHook(FPCameraPlayerBase, "update", "FPCameraLean", function(self, unit, t, dt)
	local velocity = self._parent_unit:sampled_velocity()
	--unit:m_position(velocity)
	--mvector3.subtract(velocity, last_pos)
	mvector3.rotate_with(velocity, unit:rotation():inverse())
	--mvector3.divide(velocity, dt)

	local lean_target_angle_x = (velocity.x / max_lean_velocity) * max_lean_angle
	current_lean_angle_x = math.lerp(current_lean_angle_x, lean_target_angle_x, lean_rate * dt)
	local lean_target_angle_z = (velocity.z / max_lean_velocity_z) * max_lean_angle
	current_lean_angle_z = math.lerp(current_lean_angle_z, lean_target_angle_z, lean_rate * dt)
	
	--Play a quiet vague foley sound when past a certain turn value, barely audible in most gameplay, but fills in the silence.
	if math.abs(lean_target_angle_x) >= 1.5 then
		if not self._played_lean_foley or self._played_angle < 1.5 then
			self._parent_unit:sound():play("wp_foley_generic_clip_throw")
			--self:play_sound(nil, "wp_foley_generic_clip_take_new") --Too zippy?
		end
		
		self._played_lean_foley = 0.7
		self._played_angle = 1.5
	elseif math.abs(lean_target_angle_x) > 0.5 and not self._played_angle then
		if not self._played_lean_foley then
			self._parent_unit:sound():play("boot_recoil_lift_gun")
		end
		
		self._played_lean_foley = 0.7
		self._played_angle = 0.5
	elseif math.abs(lean_target_angle_x) <= 0.1 and self._played_lean_foley then
		--Put it behind a small cooldown so it doesn't get spammed when the player moves too much.
		self._played_lean_foley = self._played_lean_foley - dt
		
		if self._played_lean_foley < 0 then
			self._played_lean_foley = nil
			self._played_angle = nil
		end
	end
	
	local lean_rotation = Rotation(0, current_lean_angle_z, current_lean_angle_x)

	local data = self._camera_properties
	local look_polar = Polar(1, data.pitch, data.spin)
	local look_vec = look_polar:to_vector()
	mrotation.set_look_at(temp_rot, look_vec, math.UP)

	-- This exists and is always set to no rotation, so i can take advantage of that to avoid replacing a bunch of vanilla logic.
	self._head_stance.rotation = temp_rot * (lean_rotation * temp_rot:inverse())

	--unit:m_position(last_pos)
end

if not RNGAGED.settings.disable_balance_changes then

function FPCameraPlayerBase:recoil_kick(up, down, left, right)
	local max_recoil = 10
	local equipped_weapon = self._parent_unit:inventory():equipped_unit()
	local weapon_base = alive(equipped_weapon) and equipped_weapon:base()
	
	if weapon_base then
		local max_recoil_mul = (weapon_base:recoil() + weapon_base:recoil_addend()) * weapon_base:recoil_multiplier()
		max_recoil = max_recoil * max_recoil_mul
		
		if weapon_base and weapon_base.regunz_zoom_mul and self._parent_unit:movement()._current_state and self._parent_unit:movement()._current_state:in_steelsight() then
			max_recoil = max_recoil * weapon_base.regunz_zoom_mul
		end
	end
	
	self._accrec_wait = 1
	self._recoil_kick.accumulated = self._recoil_kick.accumulated or 0
	
	if math.abs(self._recoil_kick.accumulated) < max_recoil then
		local v = math.lerp(up, down, math.random())
		self._recoil_kick.accumulated = (self._recoil_kick.accumulated or 0) + v
		
		if weapon_base then
			local player_state = managers.player:current_state()

			if player_state ~= "bipod" then
				local add = math.abs(v)
				local max_recoil_mul = (weapon_base:recoil() + weapon_base:recoil_addend()) * weapon_base:recoil_multiplier()
				local max_accrec_penalty = 4 * max_recoil_mul
				
				weapon_base.regunz_accrec = math.min(4 * max_recoil_mul, weapon_base.regunz_accrec and weapon_base.regunz_accrec + add or add)
				weapon_base.regunz_accrec_penalty = weapon_base.regunz_accrec / max_accrec_penalty
			end
		end
	end
	
	self._recoil_kick.h.accumulated = self._recoil_kick.h.accumulated or 0
	
	if math.abs(self._recoil_kick.h.accumulated) < max_recoil then
		local h = math.lerp(left, right, math.random())
		self._recoil_kick.h.accumulated = (self._recoil_kick.h.accumulated or 0) + h
	end
end

function FPCameraPlayerBase:stop_shooting(wait)
	self._recoil_kick.to_reduce = self._recoil_kick.accumulated
	self._recoil_kick.h.to_reduce = self._recoil_kick.h.accumulated
	self._accrec_wait = wait
end

function FPCameraPlayerBase:_vertical_recoil_kick(t, dt)
	local player_state = managers.player:current_state()

	if player_state == "bipod" then
		self:break_recoil()

		return 0
	end

	local r_value = 0
	local equipped_weapon = self._parent_unit:inventory():equipped_unit()
	local weapon_base = alive(equipped_weapon) and equipped_weapon:base()
	local dt_mul = 1
	local dt_with_mul = dt

	if weapon_base then
		dt_mul = dt_mul / (weapon_base:recoil() + weapon_base:recoil_addend()) * weapon_base:recoil_multiplier()
		dt_with_mul = dt_with_mul * dt_mul
	end

	if self._recoil_kick.current and self._episilon < self._recoil_kick.accumulated - self._recoil_kick.current then
		local n = math.step(self._recoil_kick.current, self._recoil_kick.accumulated, 80 * dt)
		r_value = n - self._recoil_kick.current
		self._recoil_kick.current = n
	elseif self._recoil_kick.to_reduce then
		self._recoil_kick.current = nil
		local n = math.lerp(self._recoil_kick.to_reduce, 0, 9 * dt_with_mul)
		r_value = -(self._recoil_kick.to_reduce - n)
		self._recoil_kick.to_reduce = n

		if self._recoil_kick.to_reduce <= 0 then
			self._recoil_kick.to_reduce = nil
		end
	end
	
	if self._accrec_wait then
		self._accrec_wait = self._accrec_wait - dt_with_mul
		
		if self._accrec_wait <= 0 then
			self._accrec_wait = nil
		end
	end
	
	if not self._accrec_wait then
		if weapon_base and weapon_base.regunz_accrec then
			local player_state = managers.player:current_state()

			if player_state == "bipod" then
				weapon_base.regunz_accrec = 0
				weapon_base.regunz_accrec_penalty = 0
			else
				local max_recoil_mul = (weapon_base:recoil() + weapon_base:recoil_addend()) * weapon_base:recoil_multiplier()
				local set_n = 10 * max_recoil_mul
				set_n = set_n * dt_with_mul
			
				weapon_base.regunz_accrec = math.max(0, weapon_base.regunz_accrec - set_n)
				
				local max_accrec_penalty = 4 * max_recoil_mul
				weapon_base.regunz_accrec_penalty = weapon_base.regunz_accrec / max_accrec_penalty
			end
		end
	end

	return r_value
end

function FPCameraPlayerBase:_horizonatal_recoil_kick(t, dt)
	local player_state = managers.player:current_state()

	if player_state == "bipod" then
		return 0
	end

	local r_value = 0
	local equipped_weapon = self._parent_unit:inventory():equipped_unit()
	local dt_mul = 1
	local dt_with_mul = dt

	if alive(equipped_weapon) and equipped_weapon:base() then
		dt_mul = dt_mul / (equipped_weapon:base():recoil() + equipped_weapon:base():recoil_addend()) * equipped_weapon:base():recoil_multiplier()
		dt_with_mul = dt_with_mul * dt_mul
	end

	if self._recoil_kick.h.current and self._episilon < math.abs(self._recoil_kick.h.accumulated - self._recoil_kick.h.current) then
		local n = math.step(self._recoil_kick.h.current, self._recoil_kick.h.accumulated, 80 * dt)
		r_value = n - self._recoil_kick.h.current
		self._recoil_kick.h.current = n
	elseif self._recoil_kick.h.to_reduce then
		self._recoil_kick.h.current = nil
		local n = math.lerp(self._recoil_kick.h.to_reduce, 0, 18 * dt_with_mul)
		r_value = -(self._recoil_kick.h.to_reduce - n)
		self._recoil_kick.h.to_reduce = n

		if self._recoil_kick.h.to_reduce <= 0 then
			self._recoil_kick.h.to_reduce = nil
		end
	end

	return r_value
end

end

local string_find = string.find
local reload_strings = {
	"mag",
	"clip",
	"lever",
	"bolt",
	"box",
	"clip",
	"drum",
	"valve",
	"tube",
	"magin",
	"magout",
	"contact",
	"throw",
	"push",
	"press",
	"up",
	"down",
	"remove",
	"in",
	"out",
	"insert",
	"remove",
	"tube",
	"twist",
	"lock",
	"button",
	"cylinder",
	"grab",
	"take_new",
	"shells",
	"shell"
}
local function has_reload_strings_in_event_string_chk(event)
	for i = 1, #reload_strings do
		local string_check = reload_strings[i]
		if string_find(event, string_check) then
			return true
		end
	end
end

local out_strings = {
	"throw_mag",
	"mag_out",
	"mag_semifull_out",
	"mag_empty_throw",
	"mag_empty_out",
	"mag_slide_out",
	"rota_slide_out",
	"mag_throw",
	"mag_hit_ground",
	"box_out",
	"box_hit_ground",
	"empty_barrel",
	"clip_out",
	"clip_grab_out",
	"clip_slide_out",
	"clip_remove",
	"clip_throw",
	"magout",
	"tank_hit_ground",
	"bottle_hit_ground",
	"shell_out",
	"coach_barrel_open",
	"shell_ground",
	"cylinder_out",
	"shells_out",
	"shell_hit_ground",
	"eject_shells",
	"twist_tube",
	"grab_throw",
	"take_new",
}
local function has_out_strings_in_event_string_chk(event)
	for i = 1, #out_strings do
		local string_check = out_strings[i]
		if string_find(event, string_check) then
			return true
		end
	end
end

function FPCameraPlayerBase:play_sound(unit, event)
	if alive(self._parent_unit) then
		self._parent_unit:sound():play(event)
		--log(event)
		
		local current_state = self._parent_unit:movement()._current_state
	
		if not current_state or not current_state:_is_reloading() then
			return
		end
		
		if current_state._equipped_unit and current_state._equipped_unit:base() and not current_state._equipped_unit:base():use_shotgun_reload() then
			local weapon = current_state._equipped_unit:base()
			local offset = weapon:tweak_data_anim_is_playing("reload_not_empty")			
			offset = offset or weapon:tweak_data_anim_is_playing("reload_empty")
			offset = offset or weapon:tweak_data_anim_is_playing("reload")
			
			if not RNGAGED.settings.disable_no_retention_reloads then
				if offset and has_out_strings_in_event_string_chk(event) then
					--log("hmm")
					local weapon_tweak = weapon:weapon_tweak_data()
					local empty_on_reload = weapon_tweak.empty_on_reload and not weapon_tweak.dont_empty_on_reload
					
					if not weapon_tweak.dont_empty_on_reload and not empty_on_reload and not weapon_tweak.has_magazine and weapon_tweak.timers then
						local timers = weapon_tweak.timers
						empty_on_reload = timers.reload_not_empty == timers.reload_empty
					end
					
					if weapon_tweak.dont_empty_on_reload then
						empty_on_reload = nil
					end
				
					if weapon:tweak_data_anim_is_playing("reload_not_empty") and not empty_on_reload then
						local ammo_remaining_in_clip = weapon:ammo_base():get_ammo_remaining_in_clip()
						weapon:use_ammo(weapon:ammo_base(), ammo_remaining_in_clip - 1)
						weapon:ammo_base():set_ammo_remaining_in_clip(1)
					else
						local ammo_remaining_in_clip = weapon:ammo_base():get_ammo_remaining_in_clip()
						weapon:use_ammo(weapon:ammo_base(), ammo_remaining_in_clip)
						weapon:ammo_base():set_ammo_remaining_in_clip(0)
					end
					
					managers.hud:set_ammo_amount(weapon:selection_index(), weapon:ammo_info())
				end		
			end
			
			if not RNGAGED.settings.disable_stepped_reloads then
				if offset and has_reload_strings_in_event_string_chk(event) then
					current_state._equipped_unit:base()._last_saved_reload_prog = offset
				end
			end
		end
	end
end