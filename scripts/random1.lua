random = function (from, to)
   return math.random(from, to)
end

-- do
--    local randomtable
--    random = function (from, to)
--       if randomtable == nil then
--          randomtable = {}
--          for i = 1, 97 do
--             randomtable[i] = math.random()
--          end
--       end
--       local x = math.random()
--       local i = 1 + math.floor(97*x)
--       x, randomtable[i] = randomtable[i], x

--       result = math.floor(x * ((to-from + 1) + from))
--       return result
--    end
-- end

local threadCount = 1
local threads = {}

function setup(thread)
   local msg = "setup thread %d"
   print(msg:format(threadCount))
   io.write("here\n")

   thread:set("thread_id", threadCount)
   table.insert(threads, thread)
   threadCount = threadCount + 1
   thread:setConnections(10)
end

local activeShortHead = 0;
local activeLongTail = 0;

function init(args)
   thread_id = wrk.thread:get("thread_id")
   totalShortHead = 0;
   totalLongTail = 0;

   startSeed = os.time() + os.clock() + thread_id

   math.randomseed(startSeed)
   -- math.random(); math.random(); math.random();

   -- partition = random(0,7)

   -- io.write(thread_id .. " startSeed:" .. startSeed .. "\n")
   -- io.write(thread_id .. " partition:" .. partition .. "\n")

   -- local msg = "thread %d created"
   -- print(msg:format(thread_id))
end


request = function()
   local requestType;
   if activeLongTail == 0 or activeLongTail*100 / (activeShortHead + activeLongTail) < 20 then
      requestType = "2"
   else
      requestType = "1"
   end
   -- if activeLongTail < 6 then
   --    requestType = "2"
   -- else
   --    requestType = "1"
   -- end

   -- requestType = "1"
   -- requestType = "2"

   partition = random(0,7)
   l1 = 0
   l2 = 0
   fileno = 0

   if requestType == "1" then
      activeShortHead = activeShortHead + 1

	   -- partition = random(0,6)
	   -- l1 = random(0,15)
	   -- l2 = random(0,255)
      fileno = random(0,100)
   else
      activeLongTail = activeLongTail + 1

	   -- partition = random(0,3)
	   l1 = random(0,15)
	   l2 = random(0,255)
      fileno = random(0,999)
   end

   -- fileno = 0 --random(0,4)
   -- -- partition = random(0,6)
   -- l1 = 0 --random(0,1)
   -- l2 = 0 --random(0,255)

   if (fileno > 1040) then
   	sendfile = 1
   else
   	sendfile = 0
   end

   sendfile = 0

   path = "/file?partition=" .. partition .. "&l1=" .. l1 .. "&l2=" .. l2 .. "&fileno=" .. fileno .. "&sendfile=" .. sendfile

   -- io.write(path .."\n")
   wrk.headers["Connection"] = "Keep-Alive"

   return wrk.format("GET", path), requestType
end

response = function(status, headers, body, requestType)
   if requestType == "1" then
      totalShortHead = totalShortHead + 1
      activeShortHead = activeShortHead - 1
   else
      totalLongTail = totalLongTail + 1
      activeLongTail = activeLongTail - 1
   end
   -- io.write("response ".. userdata .."\n")
end

function done(summary, latency, requests)

   local totalShortHead = 0
   local totalLongTail = 0
   for index, thread in ipairs(threads) do
      local thread_id        = thread:get("thread_id")
      local totalThreadShortHead  = thread:get("totalShortHead")
      local totalThreadLongTail = thread:get("totalLongTail")
      totalShortHead = totalShortHead + totalThreadShortHead
      totalLongTail = totalLongTail + totalThreadLongTail
      -- local msg = "thread %d made %d Short-Head requests and %d Long-Tail"
      -- print(msg:format(thread_id, totalThreadShortHead, totalThreadLongTail))
   end

   local msg = "Short-Head: %d requests\nLong-Tail: %d requests"
   print(msg:format(totalShortHead, totalLongTail))

end
