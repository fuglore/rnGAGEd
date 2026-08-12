local old_anim_clbk_play_sound = CopSound.anim_clbk_play_sound

function CopSound:anim_clbk_play_sound(unit, queue_name)
	old_anim_clbk_play_sound(self, unit, queue_name)

	if queue_name ~= "clk_kick_impact" and queue_name ~= "clk_punch_3p" and queue_name ~= "clk_baton_enter" then
		return
	end

	if self._unit:movement()._get_spooc_attack_action then
		local spooc_action = self._unit:movement():_get_spooc_attack_action()
		
		if spooc_action and spooc_action._strike_unit and spooc_action._stroke_t then
			if self._unit:anim_data().spooc_enter then
				spooc_action:anim_clbk_melee_strike()
			end
		end
	end
end

--Hooks:PostHook(CopSound, "anim_clbk_play_sound", "reeg_cloaker_hit_enter", function(self, unit, queue_name)