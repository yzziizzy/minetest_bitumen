



bitumen.burners = {}



local function grab_fuel(inv)
	
	local list = inv:get_list("fuel")
	for i,st in ipairs(list) do
	print(st:get_name())
		local fuel, remains
		fuel, remains = minetest.get_craft_result({
			method = "fuel", 
			width = 1, 
			items = {
				ItemStack(st:get_name())
			},
		})

		if fuel.time > 0 then
			-- Take fuel from fuel list
			st:take_item()
			inv:set_stack("fuel", i, st)
			
			return fuel.time
		end
	end
	
	return 0 -- no fuel found
end


bitumen.register_burner = function(nodes, callbacks) 
	local default_callbacks = {
		grab_fuel = grab_fuel, -- needs to return the fuel time
		start_cook = function() end, -- needs to return the cook time
		finish_cook = function() end,
		abort_cook = function() end,
		get_formspec_on = bitumen.get_melter_active_formspec,
		turn_on = function() end,
		turn_off = function() end,
	}
	
	for k,v in pairs(callbacks) do
		default_callbacks[k] = v
	end
	
	for _,n in ipairs(nodes) do
		print("setting burner: "..n)
		bitumen.burners[n] = default_callbacks
	end
end



bitumen.burner_on_timer = function(pos, elapsed)

	local posnode = minetest.get_node(pos)
	local fns = bitumen.burners[posnode.name]
	if fns == nil then
		return false
	end
	
	
	local meta = minetest.get_meta(pos)
	local fuel_time = meta:get_float("fuel_time") or 0
	local fuel_burned = meta:get_float("fuel_burned") or 0
	local cook_time = meta:get_float("cook_time") or 0
	local cook_burned = meta:get_float("cook_burned") or 0
	
	local inv = meta:get_inventory()
	
	local burned = elapsed
	local turn_off = false
	
	
--	print("\n\naf timer")
--/	print("fuel_burned: " .. fuel_burned)
--	print("fuel_time: " .. fuel_time)
	
	
	if fuel_time > 0 and fuel_burned + elapsed < fuel_time then
		-- still good on fuel
		fuel_burned = fuel_burned + elapsed
		meta:set_float("fuel_burned", fuel_burned + elapsed)
	else
		local t = fns.grab_fuel(inv)
		if t <= 0 then -- out of fuel
			--print("out of fuel")
			meta:set_float("fuel_time", 0)
			meta:set_float("fuel_burned", 0)
			
			burned = fuel_time - fuel_burned
			
			turn_off = true
		else
			-- check if the machine is turning on
			if fuel_time == 0 then
				fns.turn_on(pos, meta, inv)
			end
			
			-- roll into the next period
			fuel_burned =  elapsed - (fuel_time - fuel_burned)
			fuel_time = t
			
			meta:set_float("fuel_time", fuel_time)
			meta:set_float("fuel_burned", fuel_burned)
		end
	end
	
	
	--print("cooktime " .. cook_time)
	--print("cookburned " .. cook_burned)
	if cook_time == 0 then -- nothing cooking atm
		--print("fueltime " .. fuel_time)
		--print("turnoff " .. dump(turn_off))
		if fuel_time ~= 0 and turn_off == false then -- should we start to cook?
			cook_time = fns.start_cook(pos, meta, inv)
			meta:set_float("cook_time", cook_time)
			meta:set_float("cook_burned", 0)
		else
			-- no fuel
		end
	else -- continue cooking
		cook_burned = cook_burned + burned
		if cook_burned >= cook_time then -- cooking finished
			fns.finish_cook(pos, met, inv)
			
			local new_cook_time = fns.start_cook(pos, meta, inv)
			meta:set_float("cook_time", new_cook_time)
			cook_burned = cook_burned - cook_time 
		end
		meta:set_float("cook_burned", cook_burned)
	end
	
	
	
	if turn_off then
		fns.turn_off(pos)
		return false
	end
	
	fuel_pct = math.floor((fuel_burned * 100) / fuel_time)
	meta:set_string("formspec", fns.get_formspec_on(fuel_pct, 0))
	meta:set_string("infotext", "Fuel: " ..  fuel_pct)
	
	return true
end










