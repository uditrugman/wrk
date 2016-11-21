-- example script that demonstrates adding a random
-- 10-50ms delay before each request

local thread_id = 0;
setup = function(thread)
	thread_id = thread_id + 1
 	thread:set("thread_id", thread_id)
	-- io.write("Thread start ".. thread_id .."\n");
end

local counter = 0;
request = function()
 	counter = counter + 1
 	local request_id = wrk.thread:get("thread_id") .. ":" .. counter
 	io.write("request ".. request_id .." \n")
	return wrk.format(nil, "/?"..request_id), request_id
end

response = function(status, headers, body, userdata)
	io.write("response ".. userdata .."\n")
end

-- function delay()
--    return math.random(1000, 1500)
-- end
