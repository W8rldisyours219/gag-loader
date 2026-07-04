local K = "https://keys.w8rldisyours.com"
assert(type(loadstring) == "function", "[W8rldisyours219] loadstring is not available in this executor")
local function H()
	local o, i = pcall(function() if gethwid then return tostring(gethwid()) end return tostring(game:GetService("RbxAnalyticsService"):GetClientId()) end)
	return (o and i and tostring(i) ~= "") and i or "unknown-hwid"
end
local function Q(v)
	return tostring(v or ""):gsub("([^%w%-_%.~])", function(c) return string.format("%%%02X", string.byte(c)) end)
end
local function P()
	local o, s = pcall(function() return game:HttpGet("https://raw.githubusercontent.com/GhostDuckyy/UI-Libraries/main/Discord%20Ui%20Lib/source.lua") end)
	if not o or type(s) ~= "string" or #s < 200 then return nil end
	local c = loadstring(s)
	if not c then return nil end
	local lo, l = pcall(c)
	if not lo or not l then return nil end
	local w = l:Window("W8rldisyours219")
	local sv = w:Server("License", "")
	local ch = sv:Channel("enter-key")
	local sk
	ch:Textbox("License Key", "XXXXX-XXXXX-XXXXX-XXXXX", false, function(t)
		t = tostring(t or ""):gsub("^%s+", ""):gsub("%s+$", "")
		if t ~= "" then sk = t end
	end)
	local wt = (task and task.wait) or wait
	while not sk do wt(0.1) end
	pcall(function() local r = game:GetService("CoreGui"):FindFirstChild("Discord") if r then r:Destroy() end end)
	return sk
end
local KF = "w8rldisyours219_key.txt"
local function W(k)
	local hw = H()
	local oe, p = pcall(function() return game:GetService("HttpService"):JSONEncode({ key = k, hwid = hw }) end)
	assert(oe, "[W8rldisyours219] Failed to build the license request")
	local rb, le = nil, "no reachable key server"
	local rf = (syn and syn.request) or (http and http.request) or http_request or request or (fluxus and fluxus.request)
	if rf then
		local o, rs = pcall(function() return rf({ Url = K .. "/script/fetch", Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = p }) end)
		if o and type(rs) == "table" then
			local sc = tonumber(rs.StatusCode or rs.Status or rs.statusCode) or 0
			if sc >= 200 and sc < 300 then
				rb = rs.Body or rs.body
			else
				local dok, dc = pcall(function() return game:GetService("HttpService"):JSONDecode(rs.Body or rs.body or "") end)
				le = (dok and dc and dc.error) or ("HTTP " .. tostring(sc))
			end
		end
	end
	if not rb then
		local u = K .. "/script/fetch?payload=" .. Q(p)
		local o, tx = pcall(function() return game:HttpGet(u) end)
		if o and type(tx) == "string" and tx ~= "" then
			local lk = tx:sub(1, 1) == "{"
			if lk then
				local dok, dc = pcall(function() return game:GetService("HttpService"):JSONDecode(tx) end)
				le = (dok and dc and dc.error) or "invalid response"
			else
				rb = tx
			end
		end
	end
	return rb, le
end
local function F()
	local e = (getgenv and getgenv()) or _G
	local k = tostring(e["key"] or e["W8rldisyours219Key"] or ""):gsub("^%s+", ""):gsub("%s+$", "")
	local cached = false
	if k == "" and isfile and readfile then
		local ok, saved = pcall(function() return isfile(KF) and readfile(KF) or "" end)
		if ok and tostring(saved or "") ~= "" then
			k = tostring(saved):gsub("^%s+", ""):gsub("%s+$", "")
			cached = true
		end
	end
	if k == "" then
		k = P()
		assert(k, "[W8rldisyours219] Set getgenv().key = \"YOUR-KEY\" before running this loader.")
	end
	e["key"] = k
	local rb, le = W(k)
	if not rb and cached then
		if deletefile then pcall(deletefile, KF) end
		k = P()
		assert(k, "[W8rldisyours219] Saved key was rejected (" .. tostring(le) .. "); set getgenv().key = \"YOUR-KEY\" and rerun.")
		e["key"] = k
		rb, le = W(k)
	end
	assert(rb, "[W8rldisyours219] License check failed: " .. tostring(le))
	if writefile then pcall(writefile, KF, k) end
	return rb
end
local ok, source = pcall(F)
assert(ok, tostring(source))
assert(type(source) == "string" and source ~= "", "[W8rldisyours219] Empty script source received")
local chunk, compileError = loadstring(source)
assert(chunk, "[W8rldisyours219] compile failed: " .. tostring(compileError))
return chunk()
