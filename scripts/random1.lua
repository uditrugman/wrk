
random = function (from, to)
   return math.random(from, to)
end

local threadCount = 1
local threads = {}

function setup(thread)
   thread_id = threadCount
   threadCount = threadCount + 1

   thread:set("thread_id", thread_id)
   table.insert(threads, thread)
   if thread_id == 1 then
      thread:setConnections(1)
   end

end

local activeShortHead = 0;
local activeLongTail = 0;

function init(args)
   thread_id = wrk.thread:get("thread_id")
   totalShortHead = 0;
   totalLongTail = 0;

   startSeed = os.time() + os.clock() + thread_id
   math.randomseed(startSeed)

   -- local msg = "thread %d created"
   -- print(msg:format(thread_id))

   if thread_id == 1 then
      delay = echoDelay
      request = echoRequest
      response = echoHandleResponse
   else
      request = fileRequest
      response = fileHandleResponse
   end

end

echoDelay = function ()
   return 1000
end

echoRequest = function()

   wrk.headers["Connection"] = "Keep-Alive"

   now = wrk.gettimeofday() --os.clock()
--    io.write("inside echo request " .. tostring(now) .."\n")

   return wrk.format("GET", path), tostring(now)
end

echoHandleResponse = function(status, headers, body, startTime)
--    io.write("inside echo reply" .. thread_id .. "\n")
   now = wrk.gettimeofday() --os.clock()
   diff = math.floor(now - tonumber(startTime))

   io.write(os.date("%Y-%m-%d %X") .. " echo reply " .. diff .. " ms\n")
end

-- delayFile = function ()
--    return 0
-- end

fileRequest = function()
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

   -- fileno = 1030 --random(0,4)
   -- -- partition = random(0,6)
   -- l1 = 0 --random(0,1)
   -- l2 = 0 --random(0,255)

   if (fileno > 1040) then
      sendfile = 1
   else
      sendfile = 0
   end

   sendfile = 0
   verify = 0

   path = "/f/" .. partition .. "/" .. l1 .. "/" .. l2 .. "/" .. fileno .. "/" .. sendfile .. "/" .. verify

   -- io.write(path .."\n")
   wrk.headers["Connection"] = "Keep-Alive"

   return wrk.format("GET", path), requestType
end

cfileRequest = function()
   local requestType;
   if activeLongTail == 0 or activeLongTail*100 / (activeShortHead + activeLongTail) < 10 then
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
   fileno = 0
   slot = 0

   if requestType == "1" then
      activeShortHead = activeShortHead + 1

      -- partition = random(0,6)
      -- l1 = random(0,15)
      -- l2 = random(0,255)
      fileno = random(0,7)
      slot = random(0,1000)
   else
      activeLongTail = activeLongTail + 1

      -- partition = random(0,3)
      l1 = random(0,15)
      fileno = random(0,7)
      slot = random(0,1000)
   end

   -- fileno = 0 --random(0,4)
   -- -- partition = random(0,6)
   -- l1 = 0 --random(0,1)
   -- l2 = 0 --random(0,255)

   sendfile = 0
   verify = 0

   path = "/cfile?partition=" .. partition .. "&l1=" .. l1 .. "&fileno=" .. fileno .. "&slot=" .. slot .. "&sendfile=" .. sendfile .. "&verify=" .. verify

   -- io.write(path .."\n")
   wrk.headers["Connection"] = "Keep-Alive"

   return wrk.format("GET", path), requestType
end

fileHandleResponse = function(status, headers, body, requestType)
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
