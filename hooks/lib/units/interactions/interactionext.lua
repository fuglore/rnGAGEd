if RNGAGED.settings.disable_head_height_changes then
	return
end

function BaseInteractionExt:interact_distance()
	local distance = self._tweak_data.interact_distance or tweak_data.interaction.INTERACT_DISTANCE
	local cur_state = managers.player:get_current_state()
	
	if not cur_state or not cur_state._state_data or not cur_state._state_data.ducking then
		distance = distance + 25
	end

	return distance
end