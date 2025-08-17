PlayerCarry._update_check_actions = PlayerStandard._update_check_actions

function PlayerCarry:enter(state_data, enter_data)
	PlayerCarry.super.enter(self, state_data, enter_data)
	self._unit:camera():camera_unit():base():set_target_tilt(0)
end

function PlayerCarry:_check_action_run(t, input)
	if tweak_data.carry.types[self._tweak_data_name].can_run or managers.player:has_category_upgrade("carry", "can_sprint_with_any_bag") then
		PlayerCarry.super._check_action_run(self, t, input)
	elseif input.btn_run_press then
		self:_start_action_dash(t)
	end
end