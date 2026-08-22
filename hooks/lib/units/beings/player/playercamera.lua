function PlayerCamera:init(unit)
	self._unit = unit
	self._m_cam_rot = unit:rotation()
	self._m_cam_pos = unit:position() + math.UP * 145
	self._m_cam_fwd = self._m_cam_rot:y()
	self._m_cam_right = self._m_cam_rot:x()
	self._camera_object = World:create_camera()

	self._camera_object:set_near_range(3)
	self._camera_object:set_far_range(500000)
	self._camera_object:set_fov(75)
	self:spawn_camera_unit()
	self:_setup_sound_listener()

	self._sync_dir = {
		pitch = 0,
		yaw = unit:rotation():yaw()
	}
	self._last_sync_t = 0

	self:setup_viewport(managers.player:viewport_config())

	if _G.IS_VR then
		self._scope_camera = ScopeCamera:new(self)
	end
end

Hooks:PostHook(PlayerCamera, "setup_viewport", "regunz_freefall", function(self)
	self._shakers.freefall = self._shaker:play("player_freefall", 0, 0.01)
	local freq = 95 / 140
	self._shakers.headbob_crouch = self._shaker:play("headbob", 0, freq)
	local run_freq = 175 / 150
	self._shakers.headbob_run = self._shaker:play("headbob", 0, run_freq)
end)

function PlayerCamera:set_shaker_parameter_soft(effect, parameter, value, rate)
	if not self._shakers then
		return
	end

	if self._shakers[effect] then
		self._shaker:set_parameter_soft(self._shakers[effect], parameter, value, rate)
	end
end

local mvec1 = Vector3()

function PlayerCamera:set_rotation(rot)
	if _G.IS_VR then
		self._camera_object:set_rotation(rot)
	end

	mrotation.y(rot, mvec1)
	mvector3.multiply(mvec1, 100000)
	mvector3.add(mvec1, self._m_cam_pos)

	if not _G.IS_VR then
		self._camera_controller:set_target(mvec1)
	end

	mrotation.z(rot, mvec1)

	if not _G.IS_VR then
		self._camera_controller:set_default_up(mvec1)
	end

	mrotation.set_yaw_pitch_roll(self._m_cam_rot, rot:yaw(), rot:pitch(), rot:roll())
	mrotation.y(self._m_cam_rot, self._m_cam_fwd)
	mrotation.x(self._m_cam_rot, self._m_cam_right)

	local t = TimerManager:game():time()
	local sync_dt = t - self._last_sync_t
	local sync_yaw = rot:yaw()
	sync_yaw = sync_yaw % 360

	if sync_yaw < 0 then
		sync_yaw = 360 - sync_yaw
	end

	sync_yaw = math.floor(255 * sync_yaw / 360)
	local sync_pitch = nil

	if _G.IS_VR then
		sync_pitch = math.clamp(rot:pitch(), -30, 60) + 85
	else
		sync_pitch = math.clamp(rot:pitch(), -85, 85) + 85
	end

	sync_pitch = math.floor(127 * sync_pitch / 170)
	sync_yaw = math.round(sync_yaw)
	sync_pitch = math.round(sync_pitch)
	
	local angle_delta = math.abs(self._sync_dir.yaw - sync_yaw) + math.abs(self._sync_dir.pitch - sync_pitch)
	
	if not managers.menu:active_menu() then
		
	else
		return
	end
	
	if tweak_data.network then
		if angle_delta <= 0 then
			self._last_sync_t = t
		elseif tweak_data.network.camera.network_sync_delta_t <= sync_dt or angle_delta > 30 then --if we're turning really fast and hard or we passed the sync delta
			--log("angle_delta: " .. angle_delta)
		
			local locked_look_dir = self._locked_look_dir_t and t < self._locked_look_dir_t
			
			if _G.IS_VR then
				if locked_look_dir then
					if self._unit:hand():arm_simulation_enabled() then
						self._unit:hand():send_filtered("set_look_dir", sync_yaw, sync_pitch)
						self._unit:hand():send_inv_filtered("set_look_dir", self._locked_yaw, self._locked_pitch)
					else
						self._unit:network():send("set_look_dir", self._locked_yaw, self._locked_pitch)
					end
				else
					self._unit:network():send("set_look_dir", sync_yaw, sync_pitch)
				end
			else
				self._unit:network():send("set_look_dir", sync_yaw, sync_pitch)
			end

			self._sync_dir.yaw = sync_yaw
			self._sync_dir.pitch = sync_pitch
			self._last_sync_t = t
		end
	end
end

local function _get_reload_from_vanilla(player_state)
	local weapon = player_state._equipped_unit:base()
	local is_reload_not_empty = weapon:clip_not_empty()
	local tweak_data = weapon:weapon_tweak_data()
	local reload_anim = "reload"
	local reload_prefix = weapon:reload_prefix() or ""
	local reload_name_id = tweak_data.animations.reload_name_id or weapon.name_id
	
	if is_reload_not_empty then
		reload_anim = "reload_not_empty"
	end
	
	local reload_ids = Idstring(string.format("%s%s_%s", reload_prefix, reload_anim, reload_name_id))
	
	return reload_ids
end

local function _get_reload_from_weaponlib(player_state)
	local weapon = player_state._equipped_unit:base()
	local should_do_empty_reload = weapon:should_do_empty_reload()
	local reload_anim = "reload_not_empty"
	local reload_bipod_prefix = player_state:_is_using_bipod() and "bipod_" or ""
	local reload_prefix = reload_bipod_prefix .. (weapon:reload_prefix() or "")
	local reload_name_id = weapon:reload_name_id()
	
	if should_do_empty_reload then
		reload_anim = "reload"
	end
	
	local reload_ids = Idstring(string.format("%s%s_%s", reload_prefix, reload_anim, reload_name_id))
	
	return reload_ids
end

function PlayerCamera:play_redirect(redirect_name, speed, offset_time)
	local current_state = self._unit:movement():current_state()
	if current_state and current_state._state_data then
		local reload_ids
		local weapon = current_state._equipped_unit:base()
		
		if weapon.should_do_empty_reload then
			reload_ids = _get_reload_from_weaponlib(current_state)
		else
			reload_ids = _get_reload_from_vanilla(current_state)
		end
		
		if reload_ids == redirect_name then
			offset_time = weapon._last_saved_reload_prog
		end
	end

	local result = self._camera_unit:base():play_redirect(redirect_name, speed, offset_time)

	return result ~= PlayerCamera.IDS_NOTHING and result
end