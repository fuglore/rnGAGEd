function Setup:exec(context)
	if managers.network then
		if SystemInfo:platform() == Idstring("PS4") then
			PSN:set_matchmaking_callback("session_destroyed", function ()
			end)
		end

		log("SETTING BLACK LOADING SCREEN")

		self._black_loading_screen = true

		if Network.set_loading_state then
			Network:set_loading_state(true)
		end
	end

	--if SystemInfo:platform() == Idstring("WIN32") then
		--self:set_fps_cap(30)
	--end

	managers.music:stop()
	managers.vote:stop()
	SoundDevice:stop()

	if not managers.system_menu:is_active() then
		self:set_main_thread_loading_screen_visible(true)
	end

	CoreSetup.CoreSetup.exec(self, context)
end

local bingus = true

function Setup:block_exec()
	if not self._stuck_in_limbo_t then
		self._stuck_in_limbo_t = TimerManager:wall_running():time()
	end

	if not self._main_thread_loading_screen_gui_visible then
		self:set_main_thread_loading_screen_visible(true)

		return true
	end

	local result = false

	if self._packages_to_unload then
		if self._loading_block ~= "package" then
			self._loading_block = "package" 
			log("UNLOADING PACKAGES")
		end

		result = true
	elseif not self._packages_to_unload_gathered then
		self._packages_to_unload_gathered = true

		self:gather_packages_to_unload()
		
		if self._loading_block ~= "gatherpackage" then
			self._loading_block = "gatherpackage" 
			log("GATHERING PACKAGES TO UNLOAD")
		end

		result = true
	end
	
	if result == true then
		return result
	end

	if not managers.network:is_ready_to_load() then
		if self._loading_block ~= "network" then
			self._loading_block = "network" 
			log("STOPPING NETWORK")
			result = true
		elseif bingus then
			local t = Application:time()
			
			if self._streaming_paused then
				Application:unpause_streaming()
				self._next_streaming_fuck_attempt_t = nil
				self._streaming_paused = nil
				log("UNPAAAAAAAAAAUSE")
				--result = false
			elseif not self._next_streaming_fuck_attempt_t then			
				self._next_streaming_fuck_attempt_t = t + 5
				
				result = true
			end
			
			if self._streaming_paused or self._next_streaming_fuck_attempt_t then
				result = true
			end
			
			if not self._streaming_paused and self._next_streaming_fuck_attempt_t and self._next_streaming_fuck_attempt_t < t then
				Application:pause_streaming()
				self._streaming_paused = true
				log("PAAAAAAAAAAUSE")
				result = true
			end
		end		
	else		
		self._next_streaming_fuck_attempt_t = nil
		self._streaming_paused = nil
	end
	
	if result == true then
		return result
	end

	if not managers.dyn_resource:is_ready_to_close() then
		if self._loading_block ~= "dynresource" then
			self._loading_block = "dynresource" 
			log("CLOSING DYNAMIC RESOURCE MANAGER")
		end
		
		--managers.dyn_resource:set_file_streaming_chunk_size_mul(1, 1)

		result = true
	end
	
	if result == true then
		return result
	end

	if managers.system_menu:block_exec() then
		if self._loading_block ~= "system_menu" then
			self._loading_block = "system_menu" 
			log("CLOSING SYSTEM MENU MANAGER")
		end
		
		result = true
	end
	
	if result == true then
		return result
	end

	if managers.savefile:is_active() then
		if self._loading_block ~= "savefile" then
			self._loading_block = "savefile" 
			log("SAVING")
		end
		result = true
	end
	
	if result == true then
		return result
	end

	if _G.IS_VR and managers.vr:block_exec() then
		if self._loading_block ~= "vr" then
			self._loading_block = "vr" 
			log("CLOSING VR MANAGER")
		end
		result = true
	end
	
	if result == true then
		return result
	end
	
	if result ~= true and self._stuck_in_limbo_t then
		local t = TimerManager:wall_running():time()
		
		log("stuck in limbo for: " .. tostring(t - self._stuck_in_limbo_t) .. " seconds!")
	end

	return result
end