function CopMovement:_get_spooc_attack_action()
	for body_part, action in pairs(self._active_actions) do
		if action and action:type() == "spooc" then
			return action
		end
	end
end

function CopMovement:_exit_hurt_clbk(unit, wanted_pose)
	if self._ext_damage:dead() then
		return
	end
	
	if self._anim_global ~= "shield" and wanted_pose then
		self:play_redirect(tostring(wanted_pose))
	else
		self:play_redirect("crouch")
	end
end

function CopMovement:_play_weapon_reload_animation_sfx(unit, event)
	local equipped_weapon = self._unit:inventory():equipped_unit()

	if alive(equipped_weapon) then
		if not self._reload_sound_source then
			self._reload_sound_source = SoundDevice:create_source("reload")
		end

		self._reload_sound_source:set_position(equipped_weapon:position())
		self._reload_sound_source:post_event(event)
	end
end