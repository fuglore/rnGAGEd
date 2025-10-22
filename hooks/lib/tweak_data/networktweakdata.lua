function NetworkTweakData:init(tweak_data)
	self.player_path_interpolation = 2
	self.player_tick_rate = 30
	self.player_husk_path_threshold = 10
	self.player_path_history = 30
	self.look_direction_smooth_step = 16
	self.camera = {
		network_sync_delta_t = 1 / 12 --12 updates per second
	}
	self.stealth_speed_boost = 1.005
end