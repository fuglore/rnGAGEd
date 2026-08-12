function CopActionTurn:on_exit()
	--boopboopboooopbibibibibi
end

local tmp_vec = Vector3()
local tmp_rot = Rotation()
local mrot_set_ypr = mrotation.set_yaw_pitch_roll

function CopActionTurn:update(t)
	do
		local vis_state = self._ext_base:lod_stage() or 4

		if vis_state == 1 then
			-- Nothing
		elseif vis_state > self._skipped_frames then
			self._skipped_frames = self._skipped_frames + 1

			return
		else
			self._skipped_frames = 1
		end
	end

	local dt = t - self._last_upd_t

	self._last_upd_t = self._timer:time()

	local new_rot = tmp_rot

	self._unit:m_rotation(new_rot)
	mrotation.slerp(new_rot, new_rot, self._end_rot, math.min(1, dt * 5 * self.turn_dt_mul))

	local new_fwd = tmp_vec

	mrotation.y(new_rot, tmp_vec)

	if new_fwd:dot(self._end_dir) < 0.98 then
		self._ext_movement:set_rotation(new_rot)

		if not self._ext_anim.turn and self._ext_anim.idle_full_blend then
			self:_play_turn_anim(new_fwd)
		end
	else
		self._ext_movement:set_rotation(self._end_rot)

		if self._ext_anim.turn then
			--self._ext_movement:play_redirect("idle")
		end

		self._expired = true
	end

	if self._ext_anim.base_need_upd then
		self._ext_movement:upd_m_head_pos()
	end
end

ShieldActionTurn.update = CopActionTurn.update

if RNGAGED.settings.disable_enemy_projectiles then
	return
end

ShieldActionTurn.turn_dt_mul = 1
CopActionTurn.turn_dt_mul = 1