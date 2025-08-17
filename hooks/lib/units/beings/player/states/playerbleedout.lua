Hooks:PostHook(PlayerBleedOut, "_update_check_actions", "regunz_stop_headbob", function(self, state_data, new_state_name)
	--self._unit:camera():set_shaker_parameter_soft("headbob_run", "amplitude", 0, 0.5)
	--self._unit:camera():set_shaker_parameter_soft("headbob_crouch", "amplitude", 0, 0.9)
end)