local Rostruct = (function()
	local a = { _G = {} }
	setmetatable(a, {
		__index = function(self, b)
			if b == "Promise" then
				self.Promise = a.initialize("modules", "Promise")
				return self.Promise
			end
		end,
	})
	local c
	do
		c = {}
		c.__index = c
		function c.new(d)
			local e, f = string.match(d, "([^/]+)(/*)$")
			return setmetatable({ name = e, path = string.sub(d, 1, -#e - (f ~= "" and 2 or 1)) }, c)
		end
		function c:__index(b)
			if b == "Parent" then
				return c.new(self.path)
			end
		end
	end
	local g
	do
		g = {}
		g.__index = g
		function g.new(d, h, i)
			return setmetatable({ path = h ~= "init" and d or c.new(d).path, name = h, func = i, data = nil }, g)
		end
		function g:__index(b)
			if g[b] then
				return g[b]
			elseif b == "Parent" then
				return c.new(self.path)
			elseif b == "Name" then
				return self.path
			end
		end
		function g:require()
			if self.func then
				self.data = self.func()
				self.func = nil
			end
			return self.data
		end
		function g:GetFullName()
			return self.path
		end
	end
	local j
	do
		j = {}
		j.__index = j
		setmetatable(j, {
			__call = function(k, l)
				local self = setmetatable({}, j)
				self.description = "Symbol(" .. (l or "") .. ")"
				return self
			end,
		})
		local m = setmetatable({}, {
			__index = function(self, b)
				self[b] = j(b)
				return self[b]
			end,
		})
		function j:toString()
			return self.description
		end
		j.__tostring = j.toString
		function j.getFor(n)
			return m[n]
		end
		function j.keyFor(o)
			for n, p in pairs(m) do
				if p == o then
					return n
				end
			end
		end
	end
	a.Symbol = j
	a.Symbol_iterator = j("Symbol.iterator")
	local q = {}
	local r = {}
	function a.register(d, h, i)
		local s = g.new(d, h, i)
		q[d] = s
		r[h] = s
		return s
	end
	function a.get(d)
		return q[d]
	end
	function a.initialize(...)
		local p = setmetatable({}, {
			__tostring = function()
				return "root"
			end,
		})
		local t = a.register(p, p)
		return a.import(t, { path = "out/" }, ...)
	end
	function a.getModule(u, v)
		return error("TS.getModule is not supported", 2)
	end
	local w = {}
	local x = {}
	function a.import(t, y, ...)
		local z = y.path .. table.concat({ ... }, "/") .. ".lua"
		local A = y.path .. table.concat({ ... }, "/") .. "/init.lua"
		local s = assert(q[z] or q[A], "No module exists at path '" .. z .. "'")
		w[t] = s
		local B = s
		local C = 0
		while B do
			C = C + 1
			B = w[B]
			if B == s then
				local D = B.name
				for k = 1, C do
					B = w[B]
					D = D .. " => " .. B.name
				end
				error("Failed to import! Detected a circular dependency chain: " .. D, 2)
			end
		end
		if not x[s] then
			if a._G[s] then
				error("Invalid module access! Do you have two TS runtimes trying to import this? " .. s.path, 2)
			end
			a._G[s] = a
			x[s] = true
		end
		local E = s:require()
		if w[t] == s then
			w[t] = nil
		end
		return E
	end
	function a.async(F)
		local G = a.Promise
		return function(...)
			local H = select("#", ...)
			local I = { ... }
			return G.new(function(J, K)
				coroutine.wrap(function()
					local L, M = pcall(F, unpack(I, 1, H))
					if L then
						J(M)
					else
						K(M)
					end
				end)()
			end)
		end
	end
	function a.await(N)
		local G = a.Promise
		if not G.is(N) then
			return N
		end
		local O, P = N:awaitStatus()
		if O == G.Status.Resolved then
			return P
		elseif O == G.Status.Rejected then
			error(P, 2)
		else
			error("The awaited Promise was cancelled", 2)
		end
	end
	function a.opcall(i, ...)
		local Q, R = pcall(i, ...)
		if Q then
			return { success = true, value = R }
		else
			return { success = false, error = R }
		end
	end
	a.register("out/Package.lua", "Package", function()
		local S = a.get("out/Package.lua")
		local a = a._G[S]
		local T = a.import(S, S.Parent, "core")
		local U = T.Session
		local V = T.VirtualScript
		local W = a.import(S, S.Parent, "utils", "file-utils").pathUtils
		local X = a.import(S, S.Parent, "modules", "make")
		local Y
		do
			Y = setmetatable({}, {
				__tostring = function()
					return "Package"
				end,
			})
			Y.__index = Y
			function Y.new(...)
				local self = setmetatable({}, Y)
				self:constructor(...)
				return self
			end
			function Y:constructor(Z, _)
				self.tree = X("Folder", { Name = "Tree" })
				local a0 = type(Z) == "string"
				assert(a0, "(Package) The path must be a string")
				local a1 = isfolder(Z)
				local a2 = "(Package) The path '" .. Z .. "' must be a valid directory"
				assert(a1, a2)
				self.root = W.formatPath(Z)
				self.session = U.new(Z)
				self.fetchInfo = _
			end
			function Y:build(a3, a4)
				if a3 == nil then
					a3 = ""
				end
				local a0 = isfile(self.root .. a3) or isfolder(self.root .. a3)
				local a1 = "(Package.build) The path '" .. self.root .. a3 .. "' must be a file or folder"
				assert(a0, a1)
				local a5 = self.session:build(a3)
				local a2 = a5
				local a6 = "(Package.build) The path '" .. self.root .. a3 .. "' could not be turned into an Instance"
				assert(a2, a6)
				if a4 ~= nil then
					for a7, P in pairs(a4) do
						a5[a7] = P
					end
				end
				a5.Parent = self.tree
				return a5
			end
			function Y:start()
				return self.session:simulate()
			end
			Y.require = a.async(function(self, s)
				local a0 = s
				local a1 = a0.ClassName == "ModuleScript"
				local a2 = "(Package.require) '" .. tostring(s) .. "' must be a module"
				assert(a1, a2)
				local a6 = s:IsDescendantOf(self.tree)
				local a8 = "(Package.require) '" .. tostring(s) .. "' must be a descendant of Package.tree"
				assert(a6, a8)
				return V:requireFromInstance(s)
			end)
			function Y:requireAsync(s)
				return self:require(s):expect()
			end
			Y.fromFetch = function(_)
				return Y.new(_.location, _)
			end
		end
		return { Package = Y }
	end)
	a.register("out/bootstrap.lua", "bootstrap", function()
		local S = a.get("out/bootstrap.lua")
		local a = a._G[S]
		local a9 = a.import(S, S.Parent, "utils", "file-utils").makeUtils
		local aa = {
			ROOT = "rostruct/",
			CACHE = "rostruct/cache/",
			RELEASE_CACHE = "rostruct/cache/releases/",
			RELEASE_TAGS = "rostruct/cache/release_tags.json",
		}
		local ab = function(ac)
			return aa[ac]
		end
		local ad = function()
			return a9.makeFiles({ { "rostruct/cache/releases/", "" }, { "rostruct/cache/release_tags.json", "{}" } })
		end
		return { getRostructPath = ab, bootstrap = ad }
	end)
	a.register("out/init.lua", "init", function()
		local S = a.get("out/init.lua")
		local a = a._G[S]
		local ad = a.import(S, S, "bootstrap").bootstrap
		ad()
		local Y = a.import(S, S, "Package").Package
		local T = a.import(S, S, "utils", "fetch-github-release")
		local ae = T.clearReleaseCache
		local af = T.downloadLatestRelease
		local ag = T.downloadRelease
		local ah = function()
			return ae()
		end
		local ai = function(Z)
			return Y.new(Z)
		end
		local aj = a.async(function(...)
			local I = { ... }
			return Y.fromFetch(a.await(ag(unpack(I))))
		end)
		local ak = function(...)
			local I = { ... }
			return Y.fromFetch(ag(unpack(I)):expect())
		end
		local al = a.async(function(...)
			local I = { ... }
			return Y.fromFetch(a.await(af(unpack(I))))
		end)
		local am = function(...)
			local I = { ... }
			return Y.fromFetch(af(unpack(I)):expect())
		end
		return { clearCache = ah, open = ai, fetch = aj, fetchAsync = ak, fetchLatest = al, fetchLatestAsync = am }
	end)
	a.register("out/api/compatibility.lua", "compatibility", function()
		local S = a.get("out/api/compatibility.lua")
		local T = request
		if not (T ~= 0 and T == T and T ~= "" and T) then
			T = syn.request
			if not (T ~= 0 and T == T and T ~= "" and T) then
				T = http.request
			end
		end
		local an = T
		local a0 = getcustomasset
		if not (a0 ~= 0 and a0 == a0 and a0 ~= "" and a0) then
			a0 = getsynasset
		end
		local ao = a0
		return { httpRequest = an, getContentId = ao }
	end)
	a.register("out/api/init.lua", "init", function()
		local S = a.get("out/api/init.lua")
		local a = a._G[S]
		local ap = {}
		for T, a0 in pairs(a.import(S, S, "compatibility")) do
			ap[T] = a0
		end
		return ap
	end)
	a.register("out/core/Session.lua", "Session", function()
		local S = a.get("out/core/Session.lua")
		local a = a._G[S]
		local aq = a.import(S, S.Parent, "Store").Store
		local ar = a.import(S, S.Parent.Parent, "modules", "services").HttpService
		local as = a.import(S, S.Parent, "build").build
		local U
		do
			U = setmetatable({}, {
				__tostring = function()
					return "Session"
				end,
			})
			U.__index = U
			function U.new(...)
				local self = setmetatable({}, U)
				self:constructor(...)
				return self
			end
			function U:constructor(Z)
				self.root = Z
				self.sessionId = ar:GenerateGUID(false)
				self.virtualScripts = {}
				local T = U.sessions
				local a0 = self.sessionId
				local a1 = self
				T[a0] = a1
			end
			function U:fromSessionId(at)
				local T = self.sessions
				local a0 = at
				return T[a0]
			end
			function U:virtualScriptAdded(au)
				local T = self.virtualScripts
				local a0 = au
				T[#T + 1] = a0
			end
			function U:build(d)
				if d == nil then
					d = ""
				end
				local T = isfile(self.root .. d) or isfolder(self.root .. d)
				local a0 = "The path '" .. self.root .. d .. "' must be a file or folder"
				assert(T, a0)
				return as(self, self.root .. d)
			end
			function U:simulate()
				local av = {}
				local T = #self.virtualScripts > 0
				assert(T, "This session cannot start because no LocalScripts were found.")
				for k, aw in ipairs(self.virtualScripts) do
					if aw.instance:IsA("LocalScript") then
						local a0 = av
						local a1 = aw:deferExecutor():andThenReturn(aw.instance)
						a0[#a0 + 1] = a1
					end
				end
				return a.Promise.all(av):timeout(10)
			end
			U.sessions = aq:getStore("Sessions")
		end
		return { Session = U }
	end)
	a.register("out/core/Store.lua", "Store", function()
		local S = a.get("out/core/Store.lua")
		local T
		if getgenv().RostructStore ~= nil then
			T = getgenv().RostructStore
		else
			local a0 = getgenv()
			a0.RostructStore = {}
			T = a0.RostructStore
		end
		local ax = T
		local aq = {
			getStore = function(self, ay)
				local a0 = ax
				local a1 = ay
				if a0[a1] ~= nil then
					local a2 = ax
					local a6 = ay
					return a2[a6]
				end
				local az = {}
				local a2 = ax
				local a6 = ay
				local a8 = az
				a2[a6] = a8
				return az
			end,
		}
		return { Store = aq }
	end)
	a.register("out/core/VirtualScript.lua", "VirtualScript", function()
		local S = a.get("out/core/VirtualScript.lua")
		local a = a._G[S]
		local aq = a.import(S, S.Parent, "Store").Store
		local ar = a.import(S, S.Parent.Parent, "modules", "services").HttpService
		local w = {}
		local function aA(s)
			local B = s
			local C = 0
			while B do
				C = C + 1
				local T = w
				local a0 = B
				B = T[a0]
				if s == B then
					local aB = s:getChunkName()
					do
						local a1 = 0
						while a1 < C do
							local aC = a1
							local a2 = w
							local a6 = B
							B = a2[a6]
							aB = aB .. "\n\t\t⇒ " .. B:getChunkName()
							a1 = aC
							a1 = a1 + 1
						end
					end
					error(
						"Requested module '"
							.. s:getChunkName()
							.. "' contains a cyclic reference"
							.. "\n\tTraceback: "
							.. aB
					)
				end
			end
		end
		local V
		do
			V = setmetatable({}, {
				__tostring = function()
					return "VirtualScript"
				end,
			})
			V.__index = V
			function V.new(...)
				local self = setmetatable({}, V)
				self:constructor(...)
				return self
			end
			function V:constructor(a5, d, Z, aD)
				if aD == nil then
					aD = readfile(d)
				end
				self.instance = a5
				self.path = d
				self.root = Z
				self.source = aD
				self.id = "VirtualScript-" .. ar:GenerateGUID(false)
				self.jobComplete = false
				self.scriptEnvironment = setmetatable({
					script = a5,
					require = function(aE)
						return V:loadModule(aE, self)
					end,
					_PATH = d,
					_ROOT = Z,
				}, { __index = getfenv(0), __metatable = "This metatable is locked" })
				local T = V.fromInstance
				local a0 = a5
				local a1 = self
				T[a0] = a1
			end
			function V:getFromInstance(aF)
				local T = self.fromInstance
				local a0 = aF
				return T[a0]
			end
			function V:requireFromInstance(aF)
				local s = self:getFromInstance(aF)
				local T = s
				local a0 = "Failed to get VirtualScript for Instance '" .. aF:GetFullName() .. "'"
				assert(T, a0)
				return s:runExecutor()
			end
			function V:loadModule(aF, t)
				local T = self.fromInstance
				local a0 = aF
				local s = T[a0]
				if not s then
					return require(aF)
				end
				local a1 = w
				local a2 = t
				local a6 = s
				a1[a2] = a6
				aA(s)
				local M = s:runExecutor()
				local a8 = w
				local aG = t
				if a8[aG] == s then
					local aH = w
					local aI = t
					aH[aI] = nil
				end
				return M
			end
			function V:getChunkName()
				local T = self.path
				local a0 = #self.root + 1
				local aJ = string.sub(T, a0)
				return "@" .. aJ .. " (" .. self.instance:GetFullName() .. ")"
			end
			function V:setExecutor(aK)
				local T = self.jobComplete == false
				assert(T, "Cannot set executor after script was executed")
				self.executor = aK
			end
			function V:createExecutor()
				local T = self.executor
				if T ~= 0 and T == T and T ~= "" and T then
					return self.executor
				end
				local aL, aM = loadstring(self.source, "=" .. self:getChunkName())
				local a0 = aL
				local a1 = aM
				assert(a0 ~= 0 and a0 == a0 and a0 ~= "" and a0, a1)
				self.executor = setfenv(aL, self.scriptEnvironment)
				return self.executor
			end
			function V:runExecutor()
				if self.jobComplete then
					return self.result
				end
				local M = self:createExecutor()(self.scriptEnvironment)
				if self.instance:IsA("ModuleScript") and M == nil then
					error("Module '" .. self:getChunkName() .. "' did not return any value")
				end
				self.jobComplete = true
				self.result = M
				return self.result
			end
			function V:deferExecutor()
				return a.Promise
					.defer(function(J)
						return J(self:runExecutor())
					end)
					:timeout(
						30,
						"Script "
							.. self:getChunkName()
							.. " reached execution timeout! Try not to yield the main thread in LocalScripts."
					)
			end
			V.fromInstance = aq:getStore("VirtualScriptStore")
		end
		return { VirtualScript = V }
	end)
	a.register("out/core/init.lua", "init", function()
		local S = a.get("out/core/init.lua")
		local a = a._G[S]
		local ap = {}
		ap.build = a.import(S, S, "build").build
		ap.Store = a.import(S, S, "Store").Store
		ap.Session = a.import(S, S, "Session").Session
		ap.VirtualScript = a.import(S, S, "VirtualScript").VirtualScript
		return ap
	end)
	a.register("out/core/types.lua", "types", function()
		local S = a.get("out/core/types.lua")
		return nil
	end)
	a.register("out/core/build/csv.lua", "csv", function()
		local S = a.get("out/core/build/csv.lua")
		local a = a._G[S]
		local X = a.import(S, S.Parent.Parent.Parent, "modules", "make")
		local W = a.import(S, S.Parent.Parent.Parent, "utils", "file-utils").pathUtils
		local aN = a.import(S, S.Parent, "metadata").fileMetadata
		local aO = { "Context", "Example", "Key", "Source" }
		local aP
		do
			aP = setmetatable({}, {
				__tostring = function()
					return "CsvReader"
				end,
			})
			aP.__index = aP
			function aP.new(...)
				local self = setmetatable({}, aP)
				self:constructor(...)
				return self
			end
			function aP:constructor(aQ, aR)
				if aR == nil then
					aR = string.split(aQ, "\n")
				end
				self.raw = aQ
				self.buffer = aR
				self.entries = {}
				self.keys = {}
			end
			function aP:read()
				for aC, aS in ipairs(self.buffer) do
					if aC == 1 then
						self:readHeader(aS)
					else
						self:readEntry(aS)
					end
				end
				return self.entries
			end
			function aP:readHeader(aT)
				self.keys = string.split(aT, ",")
			end
			function aP:validateEntry(aU)
				return aU.Context ~= nil and aU.Key ~= nil and aU.Source ~= nil and aU.Values ~= nil
			end
			function aP:readEntry(aT)
				local aU = { Values = {} }
				for aC, P in ipairs(string.split(aT, ",")) do
					local n = self.keys[aC - 1 + 1]
					local T = aO
					local a0 = n
					if table.find(T, a0) ~= nil then
						aU[n] = P
					else
						local a1 = aU.Values
						local a2 = n
						local a6 = P
						a1[a2] = a6
					end
				end
				if self:validateEntry(aU) then
					local T = self.entries
					local a0 = aU
					T[#T + 1] = a0
				end
			end
		end
		local function aV(d, h)
			local aW = aP.new(readfile(d))
			local aX = X("LocalizationTable", { Name = h })
			aX:SetEntries(aW:read())
			local aY = tostring(W.getParent(d)) .. h .. ".meta.json"
			if isfile(aY) then
				aN(aY, aX)
			end
			return aX
		end
		return { makeLocalizationTable = aV }
	end)
	a.register("out/core/build/dir.lua", "dir", function()
		local S = a.get("out/core/build/dir.lua")
		local a = a._G[S]
		local X = a.import(S, S.Parent.Parent.Parent, "modules", "make")
		local W = a.import(S, S.Parent.Parent.Parent, "utils", "file-utils").pathUtils
		local aZ = a.import(S, S.Parent, "metadata").directoryMetadata
		local function a_(d)
			local aY = d .. "init.meta.json"
			if isfile(aY) then
				return aZ(aY, W.getName(d))
			end
			return X("Folder", { Name = W.getName(d) })
		end
		return { makeDir = a_ }
	end)
	a.register("out/core/build/init.lua", "init", function()
		local S = a.get("out/core/build/init.lua")
		local a = a._G[S]
		local W = a.import(S, S.Parent.Parent, "utils", "file-utils").pathUtils
		local aV = a.import(S, S, "csv").makeLocalizationTable
		local a_ = a.import(S, S, "dir").makeDir
		local b0 = a.import(S, S, "json").makeJsonModule
		local b1 = a.import(S, S, "json-model").makeJsonModel
		local T = a.import(S, S, "lua")
		local b2 = T.makeLua
		local b3 = T.makeLuaInit
		local b4 = a.import(S, S, "rbx-model").makeRobloxModel
		local b5 = a.import(S, S, "txt").makePlainText
		local function b6(b7, d)
			if isfolder(d) then
				local a5
				local b8 = W.locateFiles(d, { "init.lua", "init.server.lua", "init.client.lua" })
				if b8 ~= nil then
					a5 = b3(b7, d .. b8)
				else
					a5 = a_(d)
				end
				for k, b9 in ipairs(listfiles(d)) do
					local ba = b6(b7, W.addTrailingSlash(b9))
					if ba then
						ba.Parent = a5
					end
				end
				return a5
			elseif isfile(d) then
				local h = W.getName(d)
				if string.match(h, "(%.lua)$") ~= nil and string.match(h, "^(init%.)") == nil then
					return b2(b7, d)
				elseif string.match(h, "(%.meta.json)$") ~= nil then
					return nil
				elseif string.match(h, "(%.model.json)$") ~= nil then
					return b1(d, string.match(h, "^(.*)%.model.json$"))
				elseif string.match(h, "(%.project.json)$") ~= nil then
					warn("Project files are not supported (" .. d .. ")")
				elseif string.match(h, "(%.json)$") ~= nil then
					return b0(b7, d, string.match(h, "^(.*)%.json$"))
				elseif string.match(h, "(%.csv)$") ~= nil then
					return aV(d, string.match(h, "^(.*)%.csv$"))
				elseif string.match(h, "(%.txt)$") ~= nil then
					return b5(d, string.match(h, "^(.*)%.txt$"))
				elseif string.match(h, "(%.rbxm)$") ~= nil then
					return b4(b7, d, string.match(h, "^(.*)%.rbxm$"))
				elseif string.match(h, "(%.rbxmx)$") ~= nil then
					return b4(b7, d, string.match(h, "^(.*)%.rbxmx$"))
				end
			end
		end
		return { build = b6 }
	end)
	a.register("out/core/build/json-model.lua", "json-model", function()
		local S = a.get("out/core/build/json-model.lua")
		local a = a._G[S]
		local X = a.import(S, S.Parent.Parent.Parent, "modules", "make")
		local ar = a.import(S, S.Parent.Parent.Parent, "modules", "services").HttpService
		local bb = a.import(S, S.Parent, "EncodedValue")
		local function bc(bd, d, h)
			local T = h
			if T == nil then
				T = bd.Name
			end
			local a0 = "A child in the model file '" .. d .. "' is missing a Name field"
			assert(T ~= "" and T, a0)
			if h ~= nil and bd.Name ~= nil and bd.Name ~= h then
				warn(
					"The name of the model file at '"
						.. d
						.. "' ("
						.. h
						.. ") does not match the Name field '"
						.. bd.Name
						.. "'"
				)
			end
			local a1 = bd.ClassName ~= nil
			local a2 = "An object in the model file '" .. d .. "' is missing a ClassName field"
			assert(a1, a2)
			local a6 = bd.ClassName
			local a8 = {}
			local aG = "Name"
			local aH = h
			if aH == nil then
				aH = bd.Name
			end
			a8[aG] = aH
			local aE = X(a6, a8)
			if bd.Properties then
				bb.setModelProperties(aE, bd.Properties)
			end
			if bd.Children then
				for k, aU in ipairs(bd.Children) do
					local b9 = bc(aU, d)
					b9.Parent = aE
				end
			end
			return aE
		end
		local function b1(d, h)
			return bc(ar:JSONDecode(readfile(d)), d, h)
		end
		return { makeJsonModel = b1 }
	end)
	a.register("out/core/build/json.lua", "json", function()
		local S = a.get("out/core/build/json.lua")
		local a = a._G[S]
		local V = a.import(S, S.Parent.Parent, "VirtualScript").VirtualScript
		local X = a.import(S, S.Parent.Parent.Parent, "modules", "make")
		local ar = a.import(S, S.Parent.Parent.Parent, "modules", "services").HttpService
		local W = a.import(S, S.Parent.Parent.Parent, "utils", "file-utils").pathUtils
		local aN = a.import(S, S.Parent, "metadata").fileMetadata
		local function b0(b7, d, h)
			local a5 = X("ModuleScript", { Name = h })
			local au = V.new(a5, d, b7.root)
			au:setExecutor(function()
				return ar:JSONDecode(au.source)
			end)
			b7:virtualScriptAdded(au)
			local aY = tostring(W.getParent(d)) .. h .. ".meta.json"
			if isfile(aY) then
				aN(aY, a5)
			end
			return a5
		end
		return { makeJsonModule = b0 }
	end)
	a.register("out/core/build/lua.lua", "lua", function()
		local S = a.get("out/core/build/lua.lua")
		local a = a._G[S]
		local V = a.import(S, S.Parent.Parent, "VirtualScript").VirtualScript
		local X = a.import(S, S.Parent.Parent.Parent, "modules", "make")
		local be = a.import(S, S.Parent.Parent.Parent, "utils", "replace").replace
		local W = a.import(S, S.Parent.Parent.Parent, "utils", "file-utils").pathUtils
		local aN = a.import(S, S.Parent, "metadata").fileMetadata
		local bf = { [".server.lua"] = "Script", [".client.lua"] = "LocalScript", [".lua"] = "ModuleScript" }
		local function b2(b7, d, bg)
			local e = W.getName(d)
			local T = be(e, "(%.client%.lua)$", "")
				or be(e, "(%.server%.lua)$", "")
				or be(e, "(%.lua)$", "")
				or error("Invalid Lua file at " .. d)
			local h = T[1]
			local bh = T[2]
			local a0 = bf[bh]
			local a1 = {}
			local a2 = "Name"
			local a6 = bg
			if a6 == nil then
				a6 = h
			end
			a1[a2] = a6
			local a5 = X(a0, a1)
			b7:virtualScriptAdded(V.new(a5, d, b7.root))
			local aY = tostring(W.getParent(d)) .. h .. ".meta.json"
			if isfile(aY) then
				aN(aY, a5)
			end
			return a5
		end
		local function b3(b7, d)
			local bi = W.getParent(d)
			local a5 = b2(b7, d, W.getName(bi))
			return a5
		end
		return { makeLua = b2, makeLuaInit = b3 }
	end)
	a.register("out/core/build/metadata.lua", "metadata", function()
		local S = a.get("out/core/build/metadata.lua")
		local a = a._G[S]
		local X = a.import(S, S.Parent.Parent.Parent, "modules", "make")
		local ar = a.import(S, S.Parent.Parent.Parent, "modules", "services").HttpService
		local bb = a.import(S, S.Parent, "EncodedValue")
		local function aN(aY, a5)
			local bj = ar:JSONDecode(readfile(aY))
			local T = bj.className == nil
			assert(
				T,
				"className can only be specified in init.meta.json files if the parent directory would turn into a Folder!"
			)
			if bj.properties ~= nil then
				bb.setProperties(a5, bj.properties)
			end
		end
		local function aZ(aY, h)
			local bj = ar:JSONDecode(readfile(aY))
			local a5 = X(bj.className, { Name = h })
			if bj.properties ~= nil then
				bb.setProperties(a5, bj.properties)
			end
			return a5
		end
		return { fileMetadata = aN, directoryMetadata = aZ }
	end)
	a.register("out/core/build/rbx-model.lua", "rbx-model", function()
		local S = a.get("out/core/build/rbx-model.lua")
		local a = a._G[S]
		local ao = a.import(S, S.Parent.Parent.Parent, "api").getContentId
		local V = a.import(S, S.Parent.Parent, "VirtualScript").VirtualScript
		local function b4(b7, d, h)
			local T = ao
			local a0 = "'" .. d .. "' could not be loaded; No way to get a content id"
			assert(T ~= 0 and T == T and T ~= "" and T, a0)
			local bk = game:GetObjects(ao(d))
			local a1 = #bk == 1
			local a2 = "'" .. d .. "' could not be loaded; Only one top-level instance is supported"
			assert(a1, a2)
			local bl = bk[1]
			bl.Name = h
			for k, aE in ipairs(bl:GetDescendants()) do
				if aE:IsA("LuaSourceContainer") then
					b7:virtualScriptAdded(V.new(aE, d, b7.root, aE.Source))
				end
			end
			if bl:IsA("LuaSourceContainer") then
				b7:virtualScriptAdded(V.new(bl, d, b7.root, bl.Source))
			end
			return bl
		end
		return { makeRobloxModel = b4 }
	end)
	a.register("out/core/build/txt.lua", "txt", function()
		local S = a.get("out/core/build/txt.lua")
		local a = a._G[S]
		local X = a.import(S, S.Parent.Parent.Parent, "modules", "make")
		local W = a.import(S, S.Parent.Parent.Parent, "utils", "file-utils").pathUtils
		local aN = a.import(S, S.Parent, "metadata").fileMetadata
		local function b5(d, h)
			local bm = X("StringValue", { Name = h, Value = readfile(d) })
			local aY = tostring(W.getParent(d)) .. h .. ".meta.json"
			if isfile(aY) then
				aN(aY, bm)
			end
			return bm
		end
		return { makePlainText = b5 }
	end)
	a.register("out/core/build/EncodedValue/init.lua", "init", function()
		local S = a.get("out/core/build/EncodedValue/init.lua")
		local bn
		do
			local bo = math.floor
			local bp = string.char
			local function bq(D)
				local br = {}
				local bs = 0
				local bt = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
				local bu = #D
				for aC = 1, bu - 2, 3 do
					local bv, bw, bx = D:byte(aC, aC + 3)
					local by = bx + bw * 256 + bv * 256 * 256
					local bz = by % 64 + 1
					by = bo(by / 64)
					local bA = by % 64 + 1
					by = bo(by / 64)
					local bB = by % 64 + 1
					by = bo(by / 64)
					local bC = by % 64 + 1
					br[bs + 1] = bt:sub(bC, bC)
					br[bs + 2] = bt:sub(bB, bB)
					br[bs + 3] = bt:sub(bA, bA)
					br[bs + 4] = bt:sub(bz, bz)
					bs = bs + 4
				end
				local bD = bu % 3
				if bD == 2 then
					local bv, bw = D:byte(-2, -1)
					local by = bw * 4 + bv * 4 * 256
					local bA = by % 64 + 1
					by = bo(by / 64)
					local bB = by % 64 + 1
					by = bo(by / 64)
					local bC = by % 64 + 1
					br[bs + 1] = bt:sub(bC, bC)
					br[bs + 2] = bt:sub(bB, bB)
					br[bs + 3] = bt:sub(bA, bA)
					br[bs + 4] = "="
				elseif bD == 1 then
					local bv = D:byte(-1, -1)
					local by = bv * 16
					local bB = by % 64 + 1
					by = bo(by / 64)
					local bC = by % 64 + 1
					br[bs + 1] = bt:sub(bC, bC)
					br[bs + 2] = bt:sub(bB, bB)
					br[bs + 3] = "="
					br[bs + 4] = "="
				end
				return table.concat(br, "")
			end
			local function bE(D)
				local br = {}
				local bs = 0
				local bt = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
				local bu = #D
				local bF = 0
				local bG = 0
				local bH = {}
				for aC = 1, #bt do
					bH[bt:sub(aC, aC)] = aC - 1
				end
				for aC = 1, bu do
					local bI = D:sub(aC, aC)
					local bJ = bH[bI]
					if bJ then
						bF = bF * 64 + bJ
						bG = bG + 1
					end
					if bG == 4 then
						local bx = bF % 256
						bF = bo(bF / 256)
						local bw = bF % 256
						bF = bo(bF / 256)
						local bv = bF % 256
						br[bs + 1] = bp(bv)
						br[bs + 2] = bp(bw)
						br[bs + 3] = bp(bx)
						bs = bs + 3
						bG = 0
						bF = 0
					end
				end
				if bG == 3 then
					bF = bF * 64
					bF = bo(bF / 256)
					local bw = bF % 256
					bF = bo(bF / 256)
					local bv = bF % 256
					br[bs + 1] = bp(bv)
					br[bs + 2] = bp(bw)
				elseif bG == 2 then
					bF = bF * 64
					bF = bo(bF / 256)
					bF = bF * 64
					bF = bo(bF / 256)
					local bv = bF % 256
					br[bs + 1] = bp(bv)
				elseif bG == 1 then
					error("Base64 has invalid length")
				end
				return table.concat(br, "")
			end
			bn = { decode = bE, encode = bq }
		end
		local function bK(...)
			return ...
		end
		local function bL(aL)
			return function(P)
				return aL(unpack(P))
			end
		end
		local function bM(P)
			if P == math.huge or P == -math.huge then
				return 999999999 * math.sign(P)
			end
			return P
		end
		local bN = { "X", "Y", "Z" }
		local bO = { "Right", "Top", "Back", "Left", "Bottom", "Front" }
		local bP
		bP = {
			boolean = { fromPod = bK, toPod = bK },
			number = { fromPod = bK, toPod = bK },
			string = { fromPod = bK, toPod = bK },
			EnumItem = {
				fromPod = bK,
				toPod = function(bQ)
					if typeof(bQ) == "number" then
						return bQ
					else
						return bQ.Value
					end
				end,
			},
			Axes = {
				fromPod = function(bR)
					local bS = {}
					for bT, bU in ipairs(bR) do
						bS[bT] = Enum.Axis[bU]
					end
					return Axes.new(unpack(bS))
				end,
				toPod = function(bQ)
					local bV = {}
					for k, bW in ipairs(bN) do
						if bQ[bW] then
							table.insert(bV, bW)
						end
					end
					return bV
				end,
			},
			BinaryString = { fromPod = bn.decode, toPod = bn.encode },
			Bool = { fromPod = bK, toPod = bK },
			BrickColor = {
				fromPod = function(bR)
					return BrickColor.new(bR)
				end,
				toPod = function(bQ)
					return bQ.Number
				end,
			},
			CFrame = {
				fromPod = function(bR)
					local bX = bR.Position
					local bY = bR.Orientation
					return CFrame.new(
						bX[1],
						bX[2],
						bX[3],
						bY[1][1],
						bY[1][2],
						bY[1][3],
						bY[2][1],
						bY[2][2],
						bY[2][3],
						bY[3][1],
						bY[3][2],
						bY[3][3]
					)
				end,
				toPod = function(bQ)
					local bZ, b_, c0, c1, c2, c3, c4, c5, c6, c7, c8, c9 = bQ:GetComponents()
					return { Position = { bZ, b_, c0 }, Orientation = { { c1, c2, c3 }, { c4, c5, c6 }, { c7, c8, c9 } } }
				end,
			},
			Color3 = {
				fromPod = bL(Color3.new),
				toPod = function(bQ)
					return { bQ.r, bQ.g, bQ.b }
				end,
			},
			Color3uint8 = {
				fromPod = bL(Color3.fromRGB),
				toPod = function(bQ)
					return { math.round(bQ.R * 255), math.round(bQ.G * 255), math.round(bQ.B * 255) }
				end,
			},
			ColorSequence = {
				fromPod = function(bR)
					local ca = {}
					for bT, cb in ipairs(bR.Keypoints) do
						ca[bT] = ColorSequenceKeypoint.new(cb.Time, bP.Color3.fromPod(cb.Color))
					end
					return ColorSequence.new(ca)
				end,
				toPod = function(bQ)
					local ca = {}
					for bT, cb in ipairs(bQ.Keypoints) do
						ca[bT] = { Time = cb.Time, Color = bP.Color3.toPod(cb.Value) }
					end
					return { Keypoints = ca }
				end,
			},
			Content = { fromPod = bK, toPod = bK },
			Faces = {
				fromPod = function(bR)
					local cc = {}
					for bT, cd in ipairs(bR) do
						cc[bT] = Enum.NormalId[cd]
					end
					return Faces.new(unpack(cc))
				end,
				toPod = function(bQ)
					local bR = {}
					for k, ce in ipairs(bO) do
						if bQ[ce] then
							table.insert(bR, ce)
						end
					end
					return bR
				end,
			},
			Float32 = { fromPod = bK, toPod = bM },
			Float64 = { fromPod = bK, toPod = bM },
			Int32 = { fromPod = bK, toPod = bK },
			Int64 = { fromPod = bK, toPod = bK },
			NumberRange = {
				fromPod = bL(NumberRange.new),
				toPod = function(bQ)
					return { bQ.Min, bQ.Max }
				end,
			},
			NumberSequence = {
				fromPod = function(bR)
					local ca = {}
					for bT, cb in ipairs(bR.Keypoints) do
						ca[bT] = NumberSequenceKeypoint.new(cb.Time, cb.Value, cb.Envelope)
					end
					return NumberSequence.new(ca)
				end,
				toPod = function(bQ)
					local ca = {}
					for bT, cb in ipairs(bQ.Keypoints) do
						ca[bT] = { Time = cb.Time, Value = cb.Value, Envelope = cb.Envelope }
					end
					return { Keypoints = ca }
				end,
			},
			PhysicalProperties = {
				fromPod = function(bR)
					if bR == "Default" then
						return nil
					else
						return PhysicalProperties.new(
							bR.Density,
							bR.Friction,
							bR.Elasticity,
							bR.FrictionWeight,
							bR.ElasticityWeight
						)
					end
				end,
				toPod = function(bQ)
					if bQ == nil then
						return "Default"
					else
						return {
							Density = bQ.Density,
							Friction = bQ.Friction,
							Elasticity = bQ.Elasticity,
							FrictionWeight = bQ.FrictionWeight,
							ElasticityWeight = bQ.ElasticityWeight,
						}
					end
				end,
			},
			Ray = {
				fromPod = function(bR)
					return Ray.new(bP.Vector3.fromPod(bR.Origin), bP.Vector3.fromPod(bR.Direction))
				end,
				toPod = function(bQ)
					return { Origin = bP.Vector3.toPod(bQ.Origin), Direction = bP.Vector3.toPod(bQ.Direction) }
				end,
			},
			Rect = {
				fromPod = function(bR)
					return Rect.new(bP.Vector2.fromPod(bR[1]), bP.Vector2.fromPod(bR[2]))
				end,
				toPod = function(bQ)
					return { bP.Vector2.toPod(bQ.Min), bP.Vector2.toPod(bQ.Max) }
				end,
			},
			Instance = {
				fromPod = function(cf)
					error("Ref cannot be decoded on its own")
				end,
				toPod = function(cg)
					error("Ref can not be encoded on its own")
				end,
			},
			Ref = {
				fromPod = function(cf)
					error("Ref cannot be decoded on its own")
				end,
				toPod = function(cg)
					error("Ref can not be encoded on its own")
				end,
			},
			Region3 = {
				fromPod = function(bR)
					error("Region3 is not implemented")
				end,
				toPod = function(bQ)
					error("Region3 is not implemented")
				end,
			},
			Region3int16 = {
				fromPod = function(bR)
					return Region3int16.new(bP.Vector3int16.fromPod(bR[1]), bP.Vector3int16.fromPod(bR[2]))
				end,
				toPod = function(bQ)
					return { bP.Vector3int16.toPod(bQ.Min), bP.Vector3int16.toPod(bQ.Max) }
				end,
			},
			SharedString = {
				fromPod = function(bR)
					error("SharedString is not supported")
				end,
				toPod = function(bQ)
					error("SharedString is not supported")
				end,
			},
			String = { fromPod = bK, toPod = bK },
			UDim = {
				fromPod = bL(UDim.new),
				toPod = function(bQ)
					return { bQ.Scale, bQ.Offset }
				end,
			},
			UDim2 = {
				fromPod = function(bR)
					return UDim2.new(bP.UDim.fromPod(bR[1]), bP.UDim.fromPod(bR[2]))
				end,
				toPod = function(bQ)
					return { bP.UDim.toPod(bQ.X), bP.UDim.toPod(bQ.Y) }
				end,
			},
			Vector2 = {
				fromPod = bL(Vector2.new),
				toPod = function(bQ)
					return { bM(bQ.X), bM(bQ.Y) }
				end,
			},
			Vector2int16 = {
				fromPod = bL(Vector2int16.new),
				toPod = function(bQ)
					return { bQ.X, bQ.Y }
				end,
			},
			Vector3 = {
				fromPod = bL(Vector3.new),
				toPod = function(bQ)
					return { bM(bQ.X), bM(bQ.Y), bM(bQ.Z) }
				end,
			},
			Vector3int16 = {
				fromPod = bL(Vector3int16.new),
				toPod = function(bQ)
					return { bQ.X, bQ.Y, bQ.Z }
				end,
			},
		}
		local bb = {}
		function bb.decode(ch, ci)
			local cj = bP[ch]
			if cj == nil then
				return false, "Couldn't decode value " .. tostring(ch)
			end
			return true, cj.fromPod(ci)
		end
		function bb.setProperty(aE, a7, ci, ch)
			ch = ch or typeof(aE[a7])
			local Q, M = bb.decode(ch, ci)
			if Q then
				aE[a7] = M
			else
				warn("Could not set property " .. a7 .. " of " .. aE.GetFullName() .. "; " .. M)
			end
		end
		function bb.setProperties(aE, ck)
			for a7, ci in pairs(ck) do
				bb.setProperty(aE, a7, ci)
			end
		end
		function bb.setModelProperties(aE, ck)
			for a7, ci in pairs(ck) do
				bb.setProperty(aE, a7, ci.Value, ci.Type)
			end
		end
		return bb
	end)
	a.register("out/modules/Promise/init.lua", "init", function()
		local S = a.get("out/modules/Promise/init.lua")
		local cl = "Non-promise value passed into %s at index %s"
		local cm = "Please pass a list of promises to %s"
		local cn = "Please pass a handler function to %s!"
		local co = { __mode = "k" }
		local function cp(cq, cr)
			local cs = {}
			for k, ct in ipairs(cr) do
				cs[ct] = ct
			end
			return setmetatable(cs, {
				__index = function(k, b)
					error(string.format("%s is not in %s!", b, cq), 2)
				end,
				__newindex = function()
					error(string.format("Creating new members in %s is not allowed!", cq), 2)
				end,
			})
		end
		local cu
		do
			cu = { Kind = cp(
				"Promise.Error.Kind",
				{ "ExecutionError", "AlreadyCancelled", "NotResolvedInTime", "TimedOut" }
			) }
			cu.__index = cu
			function cu.new(cv, cw)
				cv = cv or {}
				return setmetatable(
					{
						error = tostring(cv.error) or "[This error has no error text.]",
						trace = cv.trace,
						context = cv.context,
						kind = cv.kind,
						parent = cw,
						createdTick = os.clock(),
						createdTrace = debug.traceback(),
					},
					cu
				)
			end
			function cu.is(cx)
				if type(cx) == "table" then
					local cy = getmetatable(cx)
					if type(cy) == "table" then
						return rawget(cx, "error") ~= nil and type(rawget(cy, "extend")) == "function"
					end
				end
				return false
			end
			function cu.isKind(cx, cz)
				assert(cz ~= nil, "Argument #2 to Promise.Error.isKind must not be nil")
				return cu.is(cx) and cx.kind == cz
			end
			function cu:extend(cv)
				cv = cv or {}
				cv.kind = cv.kind or self.kind
				return cu.new(cv, self)
			end
			function cu:getErrorChain()
				local cA = { self }
				while cA[#cA].parent do
					table.insert(cA, cA[#cA].parent)
				end
				return cA
			end
			function cu:__tostring()
				local cB = { string.format("-- Promise.Error(%s) --", self.kind or "?") }
				for k, cC in ipairs(self:getErrorChain()) do
					table.insert(cB, table.concat({ cC.trace or cC.error, cC.context }, "\n"))
				end
				return table.concat(cB, "\n")
			end
		end
		local function cD(...)
			return select("#", ...), { ... }
		end
		local function cE(Q, ...)
			return Q, select("#", ...), { ... }
		end
		local function cF(aB)
			assert(aB ~= nil)
			return function(aM)
				if type(aM) == "table" then
					return aM
				end
				return cu.new({
					error = aM,
					kind = cu.Kind.ExecutionError,
					trace = debug.traceback(tostring(aM), 2),
					context = "Promise created at:\n\n" .. aB,
				})
			end
		end
		local function cG(aB, F, ...)
			return cE(xpcall(F, cF(aB), ...))
		end
		local function cH(aB, F, J, K)
			return function(...)
				local L, cI, M = cG(aB, F, ...)
				if L then
					J(unpack(M, 1, cI))
				else
					K(M[1])
				end
			end
		end
		local function cJ(cK)
			return next(cK) == nil
		end
		local G = {
			Error = cu,
			Status = cp("Promise.Status", { "Started", "Resolved", "Rejected", "Cancelled" }),
			_getTime = os.clock,
			_timeEvent = game:GetService("RunService").Heartbeat,
		}
		G.prototype = {}
		G.__index = G.prototype
		function G._new(aB, F, cw)
			if cw ~= nil and not G.is(cw) then
				error("Argument #2 to Promise.new must be a promise or nil", 2)
			end
			local self = {
				_source = aB,
				_status = G.Status.Started,
				_values = nil,
				_valuesLength = -1,
				_unhandledRejection = true,
				_queuedResolve = {},
				_queuedReject = {},
				_queuedFinally = {},
				_cancellationHook = nil,
				_parent = cw,
				_consumers = setmetatable({}, co),
			}
			if cw and cw._status == G.Status.Started then
				cw._consumers[self] = true
			end
			setmetatable(self, G)
			local function J(...)
				self:_resolve(...)
			end
			local function K(...)
				self:_reject(...)
			end
			local function cL(cM)
				if cM then
					if self._status == G.Status.Cancelled then
						cM()
					else
						self._cancellationHook = cM
					end
				end
				return self._status == G.Status.Cancelled
			end
			coroutine.wrap(function()
				local L, k, M = cG(self._source, F, J, K, cL)
				if not L then
					K(M[1])
				end
			end)()
			return self
		end
		function G.new(cN)
			return G._new(debug.traceback(nil, 2), cN)
		end
		function G:__tostring()
			return string.format("Promise(%s)", self:getStatus())
		end
		function G.defer(F)
			local aB = debug.traceback(nil, 2)
			local N
			N = G._new(aB, function(J, K, cL)
				local cO
				cO = G._timeEvent:Connect(function()
					cO:Disconnect()
					local L, k, M = cG(aB, F, J, K, cL)
					if not L then
						K(M[1])
					end
				end)
			end)
			return N
		end
		G.async = G.defer
		function G.resolve(...)
			local cP, cQ = cD(...)
			return G._new(debug.traceback(nil, 2), function(J)
				J(unpack(cQ, 1, cP))
			end)
		end
		function G.reject(...)
			local cP, cQ = cD(...)
			return G._new(debug.traceback(nil, 2), function(k, K)
				K(unpack(cQ, 1, cP))
			end)
		end
		function G._try(aB, F, ...)
			local cR, cQ = cD(...)
			return G._new(aB, function(J)
				J(F(unpack(cQ, 1, cR)))
			end)
		end
		function G.try(...)
			return G._try(debug.traceback(nil, 2), ...)
		end
		function G._all(aB, cS, cT)
			if type(cS) ~= "table" then
				error(string.format(cm, "Promise.all"), 3)
			end
			for aC, N in pairs(cS) do
				if not G.is(N) then
					error(string.format(cl, "Promise.all", tostring(aC)), 3)
				end
			end
			if #cS == 0 or cT == 0 then
				return G.resolve({})
			end
			return G._new(aB, function(J, K, cL)
				local cU = {}
				local cV = {}
				local cW = 0
				local cX = 0
				local cY = false
				local function cZ()
					for k, N in ipairs(cV) do
						N:cancel()
					end
				end
				local function c_(aC, ...)
					if cY then
						return
					end
					cW = cW + 1
					if cT == nil then
						cU[aC] = ...
					else
						cU[cW] = ...
					end
					if cW >= (cT or #cS) then
						cY = true
						J(cU)
						cZ()
					end
				end
				cL(cZ)
				for aC, N in ipairs(cS) do
					cV[aC] = N:andThen(function(...)
						c_(aC, ...)
					end, function(...)
						cX = cX + 1
						if cT == nil or #cS - cX < cT then
							cZ()
							cY = true
							K(...)
						end
					end)
				end
				if cY then
					cZ()
				end
			end)
		end
		function G.all(cS)
			return G._all(debug.traceback(nil, 2), cS)
		end
		function G.fold(d0, F, d1)
			assert(type(d0) == "table", "Bad argument #1 to Promise.fold: must be a table")
			assert(type(F) == "function", "Bad argument #2 to Promise.fold: must be a function")
			local d2 = G.resolve(d1)
			return G.each(d0, function(d3, aC)
				d2 = d2:andThen(function(d4)
					return F(d4, d3, aC)
				end)
			end):andThenReturn(d2)
		end
		function G.some(cS, cT)
			assert(type(cT) == "number", "Bad argument #2 to Promise.some: must be a number")
			return G._all(debug.traceback(nil, 2), cS, cT)
		end
		function G.any(cS)
			return G._all(debug.traceback(nil, 2), cS, 1):andThen(function(cQ)
				return cQ[1]
			end)
		end
		function G.allSettled(cS)
			if type(cS) ~= "table" then
				error(string.format(cm, "Promise.allSettled"), 2)
			end
			for aC, N in pairs(cS) do
				if not G.is(N) then
					error(string.format(cl, "Promise.allSettled", tostring(aC)), 2)
				end
			end
			if #cS == 0 then
				return G.resolve({})
			end
			return G._new(debug.traceback(nil, 2), function(J, k, cL)
				local d5 = {}
				local cV = {}
				local d6 = 0
				local function c_(aC, ...)
					d6 = d6 + 1
					d5[aC] = ...
					if d6 >= #cS then
						J(d5)
					end
				end
				cL(function()
					for k, N in ipairs(cV) do
						N:cancel()
					end
				end)
				for aC, N in ipairs(cS) do
					cV[aC] = N:finally(function(...)
						c_(aC, ...)
					end)
				end
			end)
		end
		function G.race(cS)
			assert(type(cS) == "table", string.format(cm, "Promise.race"))
			for aC, N in pairs(cS) do
				assert(G.is(N), string.format(cl, "Promise.race", tostring(aC)))
			end
			return G._new(debug.traceback(nil, 2), function(J, K, cL)
				local cV = {}
				local d7 = false
				local function cZ()
					for k, N in ipairs(cV) do
						N:cancel()
					end
				end
				local function d8(F)
					return function(...)
						cZ()
						d7 = true
						return F(...)
					end
				end
				if cL(d8(K)) then
					return
				end
				for aC, N in ipairs(cS) do
					cV[aC] = N:andThen(d8(J), d8(K))
				end
				if d7 then
					cZ()
				end
			end)
		end
		function G.each(d0, d9)
			assert(type(d0) == "table", string.format(cm, "Promise.each"))
			assert(type(d9) == "function", string.format(cn, "Promise.each"))
			return G._new(debug.traceback(nil, 2), function(J, K, cL)
				local da = {}
				local db = {}
				local dc = false
				local function cZ()
					for k, dd in ipairs(db) do
						dd:cancel()
					end
				end
				cL(function()
					dc = true
					cZ()
				end)
				local de = {}
				for bT, P in ipairs(d0) do
					if G.is(P) then
						if P:getStatus() == G.Status.Cancelled then
							cZ()
							return K(
								cu.new({
									error = "Promise is cancelled",
									kind = cu.Kind.AlreadyCancelled,
									context = string.format(
										"The Promise that was part of the array at index %d passed into Promise.each was already cancelled when Promise.each began.\n\nThat Promise was created at:\n\n%s",
										bT,
										P._source
									),
								})
							)
						elseif P:getStatus() == G.Status.Rejected then
							cZ()
							return K(select(2, P:await()))
						end
						local df = P:andThen(function(...)
							return ...
						end)
						table.insert(db, df)
						de[bT] = df
					else
						de[bT] = P
					end
				end
				for bT, P in ipairs(de) do
					if G.is(P) then
						local Q
						Q, P = P:await()
						if not Q then
							cZ()
							return K(P)
						end
					end
					if dc then
						return
					end
					local dg = G.resolve(d9(P, bT))
					table.insert(db, dg)
					local Q, M = dg:await()
					if not Q then
						cZ()
						return K(M)
					end
					da[bT] = M
				end
				J(da)
			end)
		end
		function G.is(aF)
			if type(aF) ~= "table" then
				return false
			end
			local dh = getmetatable(aF)
			if dh == G then
				return true
			elseif dh == nil then
				return type(aF.andThen) == "function"
			elseif
				type(dh) == "table"
				and type(rawget(dh, "__index")) == "table"
				and type(rawget(rawget(dh, "__index"), "andThen")) == "function"
			then
				return true
			end
			return false
		end
		function G.promisify(F)
			return function(...)
				return G._try(debug.traceback(nil, 2), F, ...)
			end
		end
		do
			local di
			local cO
			function G.delay(dj)
				assert(type(dj) == "number", "Bad argument #1 to Promise.delay, must be a number.")
				if not (dj >= 1 / 60) or dj == math.huge then
					dj = 1 / 60
				end
				return G._new(debug.traceback(nil, 2), function(J, k, cL)
					local dk = G._getTime()
					local dl = dk + dj
					local dm = { resolve = J, startTime = dk, endTime = dl }
					if cO == nil then
						di = dm
						cO = G._timeEvent:Connect(function()
							local dn = G._getTime()
							while di ~= nil and di.endTime < dn do
								local dp = di
								di = dp.next
								if di == nil then
									cO:Disconnect()
									cO = nil
								else
									di.previous = nil
								end
								dp.resolve(G._getTime() - dp.startTime)
							end
						end)
					else
						if di.endTime < dl then
							local dp = di
							local next = dp.next
							while next ~= nil and next.endTime < dl do
								dp = next
								next = dp.next
							end
							dp.next = dm
							dm.previous = dp
							if next ~= nil then
								dm.next = next
								next.previous = dm
							end
						else
							dm.next = di
							di.previous = dm
							di = dm
						end
					end
					cL(function()
						local next = dm.next
						if di == dm then
							if next == nil then
								cO:Disconnect()
								cO = nil
							else
								next.previous = nil
							end
							di = next
						else
							local dq = dm.previous
							dq.next = next
							if next ~= nil then
								next.previous = dq
							end
						end
					end)
				end)
			end
		end
		function G.prototype:timeout(dj, dr)
			local aB = debug.traceback(nil, 2)
			return G.race({
				G.delay(dj):andThen(function()
					return G.reject(
						dr == nil
								and cu.new({
									kind = cu.Kind.TimedOut,
									error = "Timed out",
									context = string.format(
										"Timeout of %d seconds exceeded.\n:timeout() called at:\n\n%s",
										dj,
										aB
									),
								})
							or dr
					)
				end),
				self,
			})
		end
		function G.prototype:getStatus()
			return self._status
		end
		function G.prototype:_andThen(aB, ds, dt)
			self._unhandledRejection = false
			return G._new(aB, function(J, K)
				local du = J
				if ds then
					du = cH(aB, ds, J, K)
				end
				local dv = K
				if dt then
					dv = cH(aB, dt, J, K)
				end
				if self._status == G.Status.Started then
					table.insert(self._queuedResolve, du)
					table.insert(self._queuedReject, dv)
				elseif self._status == G.Status.Resolved then
					du(unpack(self._values, 1, self._valuesLength))
				elseif self._status == G.Status.Rejected then
					dv(unpack(self._values, 1, self._valuesLength))
				elseif self._status == G.Status.Cancelled then
					K(
						cu.new({
							error = "Promise is cancelled",
							kind = cu.Kind.AlreadyCancelled,
							context = "Promise created at\n\n" .. aB,
						})
					)
				end
			end, self)
		end
		function G.prototype:andThen(ds, dt)
			assert(ds == nil or type(ds) == "function", string.format(cn, "Promise:andThen"))
			assert(dt == nil or type(dt) == "function", string.format(cn, "Promise:andThen"))
			return self:_andThen(debug.traceback(nil, 2), ds, dt)
		end
		function G.prototype:catch(dv)
			assert(dv == nil or type(dv) == "function", string.format(cn, "Promise:catch"))
			return self:_andThen(debug.traceback(nil, 2), nil, dv)
		end
		function G.prototype:tap(dw)
			assert(type(dw) == "function", string.format(cn, "Promise:tap"))
			return self:_andThen(debug.traceback(nil, 2), function(...)
				local dx = dw(...)
				if G.is(dx) then
					local cP, cQ = cD(...)
					return dx:andThen(function()
						return unpack(cQ, 1, cP)
					end)
				end
				return ...
			end)
		end
		function G.prototype:andThenCall(F, ...)
			assert(type(F) == "function", string.format(cn, "Promise:andThenCall"))
			local cP, cQ = cD(...)
			return self:_andThen(debug.traceback(nil, 2), function()
				return F(unpack(cQ, 1, cP))
			end)
		end
		function G.prototype:andThenReturn(...)
			local cP, cQ = cD(...)
			return self:_andThen(debug.traceback(nil, 2), function()
				return unpack(cQ, 1, cP)
			end)
		end
		function G.prototype:cancel()
			if self._status ~= G.Status.Started then
				return
			end
			self._status = G.Status.Cancelled
			if self._cancellationHook then
				self._cancellationHook()
			end
			if self._parent then
				self._parent:_consumerCancelled(self)
			end
			for b9 in pairs(self._consumers) do
				b9:cancel()
			end
			self:_finalize()
		end
		function G.prototype:_consumerCancelled(dy)
			if self._status ~= G.Status.Started then
				return
			end
			self._consumers[dy] = nil
			if next(self._consumers) == nil then
				self:cancel()
			end
		end
		function G.prototype:_finally(aB, dz, dA)
			if not dA then
				self._unhandledRejection = false
			end
			return G._new(aB, function(J, K)
				local dB = J
				if dz then
					dB = cH(aB, dz, J, K)
				end
				if dA then
					local F = dB
					dB = function(...)
						if self._status == G.Status.Rejected then
							return J(self)
						end
						return F(...)
					end
				end
				if self._status == G.Status.Started then
					table.insert(self._queuedFinally, dB)
				else
					dB(self._status)
				end
			end, self)
		end
		function G.prototype:finally(dz)
			assert(dz == nil or type(dz) == "function", string.format(cn, "Promise:finally"))
			return self:_finally(debug.traceback(nil, 2), dz)
		end
		function G.prototype:finallyCall(F, ...)
			assert(type(F) == "function", string.format(cn, "Promise:finallyCall"))
			local cP, cQ = cD(...)
			return self:_finally(debug.traceback(nil, 2), function()
				return F(unpack(cQ, 1, cP))
			end)
		end
		function G.prototype:finallyReturn(...)
			local cP, cQ = cD(...)
			return self:_finally(debug.traceback(nil, 2), function()
				return unpack(cQ, 1, cP)
			end)
		end
		function G.prototype:done(dz)
			assert(dz == nil or type(dz) == "function", string.format(cn, "Promise:done"))
			return self:_finally(debug.traceback(nil, 2), dz, true)
		end
		function G.prototype:doneCall(F, ...)
			assert(type(F) == "function", string.format(cn, "Promise:doneCall"))
			local cP, cQ = cD(...)
			return self:_finally(debug.traceback(nil, 2), function()
				return F(unpack(cQ, 1, cP))
			end, true)
		end
		function G.prototype:doneReturn(...)
			local cP, cQ = cD(...)
			return self:_finally(debug.traceback(nil, 2), function()
				return unpack(cQ, 1, cP)
			end, true)
		end
		function G.prototype:awaitStatus()
			self._unhandledRejection = false
			if self._status == G.Status.Started then
				local dC = Instance.new("BindableEvent")
				self:finally(function()
					dC:Fire()
				end)
				dC.Event:Wait()
				dC:Destroy()
			end
			if self._status == G.Status.Resolved then
				return self._status, unpack(self._values, 1, self._valuesLength)
			elseif self._status == G.Status.Rejected then
				return self._status, unpack(self._values, 1, self._valuesLength)
			end
			return self._status
		end
		local function dD(O, ...)
			return O == G.Status.Resolved, ...
		end
		function G.prototype:await()
			return dD(self:awaitStatus())
		end
		local function dE(O, ...)
			if O ~= G.Status.Resolved then
				error(... == nil and "Expected Promise rejected with no value." or ..., 3)
			end
			return ...
		end
		function G.prototype:expect()
			return dE(self:awaitStatus())
		end
		G.prototype.awaitValue = G.prototype.expect
		function G.prototype:_unwrap()
			if self._status == G.Status.Started then
				error("Promise has not resolved or rejected.", 2)
			end
			local Q = self._status == G.Status.Resolved
			return Q, unpack(self._values, 1, self._valuesLength)
		end
		function G.prototype:_resolve(...)
			if self._status ~= G.Status.Started then
				if G.is(...) then
					select(1, ...):_consumerCancelled(self)
				end
				return
			end
			if G.is(...) then
				if select("#", ...) > 1 then
					local dF = string.format(
						"When returning a Promise from andThen, extra arguments are " .. "discarded! See:\n\n%s",
						self._source
					)
					warn(dF)
				end
				local dG = ...
				local N = dG:andThen(function(...)
					self:_resolve(...)
				end, function(...)
					local dH = dG._values[1]
					if dG._error then
						dH = cu.new({
							error = dG._error,
							kind = cu.Kind.ExecutionError,
							context = "[No stack trace available as this Promise originated from an older version of the Promise library (< v2)]",
						})
					end
					if cu.isKind(dH, cu.Kind.ExecutionError) then
						return self:_reject(
							dH:extend({
								error = "This Promise was chained to a Promise that errored.",
								trace = "",
								context = string.format(
									"The Promise at:\n\n%s\n...Rejected because it was chained to the following Promise, which encountered an error:\n",
									self._source
								),
							})
						)
					end
					self:_reject(...)
				end)
				if N._status == G.Status.Cancelled then
					self:cancel()
				elseif N._status == G.Status.Started then
					self._parent = N
					N._consumers[self] = true
				end
				return
			end
			self._status = G.Status.Resolved
			self._valuesLength, self._values = cD(...)
			for k, F in ipairs(self._queuedResolve) do
				coroutine.wrap(F)(...)
			end
			self:_finalize()
		end
		function G.prototype:_reject(...)
			if self._status ~= G.Status.Started then
				return
			end
			self._status = G.Status.Rejected
			self._valuesLength, self._values = cD(...)
			if not cJ(self._queuedReject) then
				for k, F in ipairs(self._queuedReject) do
					coroutine.wrap(F)(...)
				end
			else
				local aM = tostring(...)
				coroutine.wrap(function()
					G._timeEvent:Wait()
					if not self._unhandledRejection then
						return
					end
					local dF = string.format("Unhandled Promise rejection:\n\n%s\n\n%s", aM, self._source)
					if G.TEST then
						return
					end
					warn(dF)
				end)()
			end
			self:_finalize()
		end
		function G.prototype:_finalize()
			for k, F in ipairs(self._queuedFinally) do
				coroutine.wrap(F)(self._status)
			end
			self._queuedFinally = nil
			self._queuedReject = nil
			self._queuedResolve = nil
			if not G.TEST then
				self._parent = nil
				self._consumers = nil
			end
		end
		function G.prototype:now(dr)
			local aB = debug.traceback(nil, 2)
			if self:getStatus() == G.Status.Resolved then
				return self:_andThen(aB, function(...)
					return ...
				end)
			else
				return G.reject(
					dr == nil
							and cu.new({
								kind = cu.Kind.NotResolvedInTime,
								error = "This Promise was not resolved in time for :now()",
								context = ":now() was called at:\n\n" .. aB,
							})
						or dr
				)
			end
		end
		function G.retry(F, dI, ...)
			assert(type(F) == "function", "Parameter #1 to Promise.retry must be a function")
			assert(type(dI) == "number", "Parameter #2 to Promise.retry must be a number")
			local I, cP = { ... }, select("#", ...)
			return G.resolve(F(...)):catch(function(...)
				if dI > 0 then
					return G.retry(F, dI - 1, unpack(I, 1, cP))
				else
					return G.reject(...)
				end
			end)
		end
		function G.fromEvent(dJ, d9)
			d9 = d9 or function()
				return true
			end
			return G._new(debug.traceback(nil, 2), function(J, K, cL)
				local cO
				local dK = false
				local function dL()
					cO:Disconnect()
					cO = nil
				end
				cO = dJ:Connect(function(...)
					local dM = d9(...)
					if dM == true then
						J(...)
						if cO then
							dL()
						else
							dK = true
						end
					elseif type(dM) ~= "boolean" then
						error("Promise.fromEvent predicate should always return a boolean")
					end
				end)
				if dK and cO then
					return dL()
				end
				cL(function()
					dL()
				end)
			end)
		end
		return G
	end)
	a.register("out/modules/make/init.lua", "init", function()
		local S = a.get("out/modules/make/init.lua")
		local function X(dN, dO)
			local T = dO
			local dP = T.Children
			local cw = T.Parent
			local a5 = Instance.new(dN)
			for dQ, P in pairs(dO) do
				if dQ ~= "Children" and dQ ~= "Parent" then
					local a0 = a5
					local dR = a0[dQ]
					local a1 = dR
					if typeof(a1) == "RBXScriptSignal" then
						dR:Connect(P)
					else
						a5[dQ] = P
					end
				end
			end
			if dP then
				for k, b9 in ipairs(dP) do
					b9.Parent = a5
				end
			end
			a5.Parent = cw
			return a5
		end
		return X
	end)
	a.register("out/modules/object-utils/init.lua", "init", function()
		local S = a.get("out/modules/object-utils/init.lua")
		local ar = game:GetService("HttpService")
		local dS = {}
		function dS.keys(aF)
			local M = table.create(#aF)
			for n in pairs(aF) do
				M[#M + 1] = n
			end
			return M
		end
		function dS.values(aF)
			local M = table.create(#aF)
			for k, P in pairs(aF) do
				M[#M + 1] = P
			end
			return M
		end
		function dS.entries(aF)
			local M = table.create(#aF)
			for n, P in pairs(aF) do
				M[#M + 1] = { n, P }
			end
			return M
		end
		function dS.assign(dT, ...)
			for aC = 1, select("#", ...) do
				local dU = select(aC, ...)
				if type(dU) == "table" then
					for n, P in pairs(dU) do
						dT[n] = P
					end
				end
			end
			return dT
		end
		function dS.copy(aF)
			local M = table.create(#aF)
			for b, aw in pairs(aF) do
				M[b] = aw
			end
			return M
		end
		local function dV(aF, dW)
			local M = table.create(#aF)
			dW[aF] = M
			for b, aw in pairs(aF) do
				if type(b) == "table" then
					b = dW[b] or dV(b, dW)
				end
				if type(aw) == "table" then
					aw = dW[aw] or dV(aw, dW)
				end
				M[b] = aw
			end
			return M
		end
		function dS.deepCopy(aF)
			return dV(aF, {})
		end
		function dS.deepEquals(dX, dY)
			for b in pairs(dX) do
				local dZ = dX[b]
				local d_ = dY[b]
				if type(dZ) == "table" and type(d_) == "table" then
					local M = dS.deepEquals(dZ, d_)
					if not M then
						return false
					end
				elseif dZ ~= d_ then
					return false
				end
			end
			for b in pairs(dY) do
				if dX[b] == nil then
					return false
				end
			end
			return true
		end
		function dS.toString(E)
			return ar:JSONEncode(E)
		end
		function dS.isEmpty(aF)
			return next(aF) == nil
		end
		function dS.fromEntries(e0)
			local e1 = #e0
			local M = table.create(e1)
			if e0 then
				for aC = 1, e1 do
					local e2 = e0[aC]
					M[e2[1]] = e2[2]
				end
			end
			return M
		end
		return dS
	end)
	a.register("out/modules/services/init.lua", "init", function()
		local S = a.get("out/modules/services/init.lua")
		return setmetatable({}, {
			__index = function(self, e3)
				local e4 = game:GetService(e3)
				self[e3] = e4
				return e4
			end,
		})
	end)
	a.register("out/modules/zzlib/init.lua", "init", function()
		local S = a.get("out/modules/zzlib/init.lua")
		local unpack = unpack
		local M
		local e5
		do
			local e6 = {}
			local e7 = bit32
			e6.band = e7.band
			e6.rshift = e7.rshift
			function e6.bitstream_init(aJ)
				local e8 = { file = aJ, buf = nil, len = nil, pos = 1, b = 0, n = 0 }
				function e8:flushb(H)
					self.n = self.n - H
					self.b = e7.rshift(self.b, H)
				end
				function e8:peekb(H)
					while self.n < H do
						if self.pos > self.len then
							self.buf = self.file:read(4096)
							self.len = self.buf:len()
							self.pos = 1
						end
						self.b = self.b + e7.lshift(self.buf:byte(self.pos), self.n)
						self.pos = self.pos + 1
						self.n = self.n + 8
					end
					return e7.band(self.b, e7.lshift(1, H) - 1)
				end
				function e8:getb(H)
					local e9 = e8:peekb(H)
					self.n = self.n - H
					self.b = e7.rshift(self.b, H)
					return e9
				end
				function e8:getv(ea, H)
					local eb = ea[e8:peekb(H)]
					local ec = e7.band(eb, 15)
					local e9 = e7.rshift(eb, 4)
					self.n = self.n - ec
					self.b = e7.rshift(self.b, ec)
					return e9
				end
				function e8:close()
					if self.file then
						self.file:close()
					end
				end
				if type(aJ) == "string" then
					e8.file = nil
					e8.buf = aJ
				else
					e8.buf = aJ:read(4096)
				end
				e8.len = e8.buf:len()
				return e8
			end
			local function ed(ee)
				local ef = #ee
				local eg = 1
				local eh = {}
				local ei = {}
				for aC = 1, ef do
					local ej = ee[aC]
					if ej > eg then
						eg = ej
					end
					eh[ej] = (eh[ej] or 0) + 1
				end
				local table = {}
				local ek = 0
				eh[0] = 0
				for aC = 1, eg do
					ek = (ek + (eh[aC - 1] or 0)) * 2
					ei[aC] = ek
				end
				for aC = 1, ef do
					local ec = ee[aC] or 0
					if ec > 0 then
						local eb = (aC - 1) * 16 + ec
						local ek = ei[ec]
						local el = 0
						for em = 1, ec do
							el = el + e7.lshift(e7.band(1, e7.rshift(ek, em - 1)), ec - em)
						end
						for em = 0, 2 ^ eg - 1, 2 ^ ec do
							table[em + el] = eb
						end
						ei[ec] = ei[ec] + 1
					end
				end
				return table, eg
			end
			local function en(br, e8, eo, ep, eq, er)
				local es
				repeat
					es = e8:getv(eq, eo)
					if es < 256 then
						table.insert(br, es)
					elseif es > 256 then
						local eg = 0
						local et = 3
						local eu = 1
						if es < 265 then
							et = et + es - 257
						elseif es < 285 then
							eg = e7.rshift(es - 261, 2)
							et = et + e7.lshift(e7.band(es - 261, 3) + 4, eg)
						else
							et = 258
						end
						if eg > 0 then
							et = et + e8:getb(eg)
						end
						local aw = e8:getv(er, ep)
						if aw < 4 then
							eu = eu + aw
						else
							eg = e7.rshift(aw - 2, 1)
							eu = eu + e7.lshift(e7.band(aw, 1) + 2, eg)
							eu = eu + e8:getb(eg)
						end
						local ev = #br - eu + 1
						while et > 0 do
							table.insert(br, br[ev])
							ev = ev + 1
							et = et - 1
						end
					end
				until es == 256
			end
			local function ew(br, e8)
				local ex = { 17, 18, 19, 1, 9, 8, 10, 7, 11, 6, 12, 5, 13, 4, 14, 3, 15, 2, 16 }
				local ey = 257 + e8:getb(5)
				local ez = 1 + e8:getb(5)
				local eA = 4 + e8:getb(4)
				local ee = {}
				for aC = 1, eA do
					local aw = e8:getb(3)
					ee[ex[aC]] = aw
				end
				for aC = eA + 1, 19 do
					ee[ex[aC]] = 0
				end
				local eB, eC = ed(ee)
				local aC = 1
				while aC <= ey + ez do
					local aw = e8:getv(eB, eC)
					if aw < 16 then
						ee[aC] = aw
						aC = aC + 1
					elseif aw < 19 then
						local eD = { 2, 3, 7 }
						local eE = eD[aw - 15]
						local eF = 0
						local H = 3 + e8:getb(eE)
						if aw == 16 then
							eF = ee[aC - 1]
						elseif aw == 18 then
							H = H + 8
						end
						for em = 1, H do
							ee[aC] = eF
							aC = aC + 1
						end
					else
						error("wrong entry in depth table for literal/length alphabet: " .. aw)
					end
				end
				local eG = {}
				for aC = 1, ey do
					table.insert(eG, ee[aC])
				end
				local eq, eo = ed(eG)
				local eH = {}
				for aC = ey + 1, #ee do
					table.insert(eH, ee[aC])
				end
				local er, ep = ed(eH)
				en(br, e8, eo, ep, eq, er)
			end
			local function eI(br, e8)
				local eJ = { 144, 112, 24, 8 }
				local eK = { 8, 9, 7, 8 }
				local ee = {}
				for aC = 1, 4 do
					local ej = eK[aC]
					for em = 1, eJ[aC] do
						table.insert(ee, ej)
					end
				end
				local eq, eo = ed(ee)
				ee = {}
				for aC = 1, 32 do
					ee[aC] = 5
				end
				local er, ep = ed(ee)
				en(br, e8, eo, ep, eq, er)
			end
			local function eL(br, e8)
				e8:flushb(e7.band(e8.n, 7))
				local ec = e8:getb(16)
				if e8.n > 0 then
					error("Unexpected.. should be zero remaining bits in buffer.")
				end
				local eC = e8:getb(16)
				if e7.bxor(ec, eC) ~= 65535 then
					error("LEN and NLEN don't match")
				end
				for aC = e8.pos, e8.pos + ec - 1 do
					table.insert(br, e8.buf:byte(aC, aC))
				end
				e8.pos = e8.pos + ec
			end
			function e6.main(e8)
				local eM, type
				local eN = {}
				repeat
					local eO
					eM = e8:getb(1)
					type = e8:getb(2)
					if type == 0 then
						eL(eN, e8)
					elseif type == 1 then
						eI(eN, e8)
					elseif type == 2 then
						ew(eN, e8)
					else
						error("unsupported block type")
					end
				until eM == 1
				e8:flushb(e7.band(e8.n, 7))
				return eN
			end
			local eP
			function e6.crc32(eQ, eR)
				if not eP then
					eP = {}
					for aC = 0, 255 do
						local eS = aC
						for em = 1, 8 do
							eS = e7.bxor(e7.rshift(eS, 1), e7.band(0xedb88320, e7.bnot(e7.band(eS, 1) - 1)))
						end
						eP[aC] = eS
					end
				end
				eR = e7.bnot(eR or 0)
				for aC = 1, #eQ do
					local eF = eQ:byte(aC)
					eR = e7.bxor(eP[e7.bxor(eF, e7.band(eR, 0xff))], e7.rshift(eR, 8))
				end
				eR = e7.bnot(eR)
				if eR < 0 then
					eR = eR + 4294967296
				end
				return eR
			end
			e5 = e6
		end
		local eT = {}
		local function eU(eV)
			local eW = {}
			local et = #eV
			local bX = 1
			local eX = 1
			while et > 0 do
				local eY = et >= 2048 and 2048 or et
				local eQ = string.char(unpack(eV, bX, bX + eY - 1))
				bX = bX + eY
				et = et - eY
				local aC = 1
				while eW[aC] do
					eQ = eW[aC] .. eQ
					eW[aC] = nil
					aC = aC + 1
				end
				if aC > eX then
					eX = aC
				end
				eW[aC] = eQ
			end
			local D = ""
			for aC = 1, eX do
				if eW[aC] then
					D = eW[aC] .. D
				end
			end
			return D
		end
		local function eZ(e8)
			local e_, f0, f1, f2 = e8.buf:byte(1, 4)
			if e_ ~= 31 or f0 ~= 139 then
				error("invalid gzip header")
			end
			if f1 ~= 8 then
				error("only deflate format is supported")
			end
			e8.pos = 11
			if e5.band(f2, 4) ~= 0 then
				local f3, f4 = e8.buf.byte(e8.pos, e8.pos + 1)
				local f5 = f4 * 256 + f3
				e8.pos = e8.pos + f5 + 2
			end
			if e5.band(f2, 8) ~= 0 then
				local bX = e8.buf:find("\0", e8.pos)
				e8.pos = bX + 1
			end
			if e5.band(f2, 16) ~= 0 then
				local bX = e8.buf:find("\0", e8.pos)
				e8.pos = bX + 1
			end
			if e5.band(f2, 2) ~= 0 then
				e8.pos = e8.pos + 2
			end
			local M = eU(e5.main(e8))
			local eR = e8:getb(8) + 256 * (e8:getb(8) + 256 * (e8:getb(8) + 256 * e8:getb(8)))
			e8:close()
			if eR ~= e5.crc32(M) then
				error("checksum verification failed")
			end
			return M
		end
		local function f6(eQ)
			local f7 = 1
			local f8 = 0
			for aC = 1, #eQ do
				local eF = eQ:byte(aC)
				f7 = (f7 + eF) % 65521
				f8 = (f8 + f7) % 65521
			end
			return f8 * 65536 + f7
		end
		local function f9(e8)
			local fa = e8.buf:byte(1)
			local f2 = e8.buf:byte(2)
			if (fa * 256 + f2) % 31 ~= 0 then
				error("zlib header check bits are incorrect")
			end
			if e5.band(fa, 15) ~= 8 then
				error("only deflate format is supported")
			end
			if e5.rshift(fa, 4) ~= 7 then
				error("unsupported window size")
			end
			if e5.band(f2, 32) ~= 0 then
				error("preset dictionary not implemented")
			end
			e8.pos = 3
			local M = eU(e5.main(e8))
			local fb = ((e8:getb(8) * 256 + e8:getb(8)) * 256 + e8:getb(8)) * 256 + e8:getb(8)
			e8:close()
			if fb ~= f6(M) then
				error("checksum verification failed")
			end
			return M
		end
		function eT.gunzipf(fc)
			local aJ, aM = io.open(fc, "rb")
			if not aJ then
				return nil, aM
			end
			return eZ(e5.bitstream_init(aJ))
		end
		function eT.gunzip(D)
			return eZ(e5.bitstream_init(D))
		end
		function eT.inflate(D)
			return f9(e5.bitstream_init(D))
		end
		local function fd(D, bX)
			local dX, dY = D:byte(bX, bX + 1)
			return dY * 256 + dX
		end
		local function fe(D, bX)
			local dX, dY, eF, ej = D:byte(bX, bX + 3)
			return ((ej * 256 + eF) * 256 + dY) * 256 + dX
		end
		function eT.unzip(ff)
			local ev = #ff - 21 - #"00bd21b8cc3a2e233276f5a70b57ca7347fdf520"
			local fg = false
			local fh = {}
			if fe(ff, ev) ~= 0x06054b50 then
				error(".ZIP file comments not supported")
			end
			local fi = fe(ff, ev + 16)
			local fj = fd(ff, ev + 10)
			ev = fi + 1
			for aC = 1, fj do
				if fe(ff, ev) ~= 0x02014b50 then
					error("invalid central directory header signature")
				end
				local fk = fd(ff, ev + 8)
				local fl = fd(ff, ev + 10)
				local eR = fe(ff, ev + 16)
				local fm = fd(ff, ev + 28)
				local h = ff:sub(ev + 46, ev + 45 + fm)
				if true then
					local fn = fe(ff, ev + 42)
					local ev = 1 + fn
					if fe(ff, ev) ~= 0x04034b50 then
						error("invalid local header signature")
					end
					local fo = fe(ff, ev + 18)
					local fp = fd(ff, ev + 28)
					ev = ev + 30 + fm + fp
					if fl == 0 then
						M = ff:sub(ev, ev + fo - 1)
						fh[h] = M
					else
						local e8 = e5.bitstream_init(ff)
						e8.pos = ev
						M = eU(e5.main(e8))
						fh[h] = M
					end
					if eR ~= e5.crc32(M) then
						error("checksum verification failed")
					end
				end
				ev = ev + 46 + fm + fd(ff, ev + 30) + fd(ff, ev + 32)
			end
			return fh
		end
		return eT
	end)
	a.register("out/utils/JsonStore.lua", "JsonStore", function()
		local S = a.get("out/utils/JsonStore.lua")
		local a = a._G[S]
		local ar = a.import(S, S.Parent.Parent, "modules", "services").HttpService
		local fq
		do
			fq = setmetatable({}, {
				__tostring = function()
					return "JsonStore"
				end,
			})
			fq.__index = fq
			function fq.new(...)
				local self = setmetatable({}, fq)
				self:constructor(...)
				return self
			end
			function fq:constructor(aJ)
				self.file = aJ
				local T = isfile(aJ)
				local a0 = "File '" .. aJ .. "' must be a valid JSON file"
				assert(T, a0)
			end
			function fq:get(n)
				local T = self.state
				assert(T ~= 0 and T == T and T ~= "" and T, "The JsonStore must be open to read from it")
				return self.state[n]
			end
			function fq:set(n, P)
				local T = self.state
				assert(T ~= 0 and T == T and T ~= "" and T, "The JsonStore must be open to write to it")
				self.state[n] = P
			end
			function fq:open()
				local T = self.state == nil
				assert(T, "Attempt to open an active JsonStore")
				local fr = ar:JSONDecode(readfile(self.file))
				a.Promise.defer(function(k, K)
					if self.state == fr then
						self:close()
						K("JsonStore was left open; was the thread blocked before it could close?")
					end
				end)
				self.state = fr
			end
			function fq:close()
				local T = self.state
				assert(T ~= 0 and T == T and T ~= "" and T, "Attempt to close an inactive JsonStore")
				writefile(self.file, ar:JSONEncode(self.state))
				self.state = nil
			end
		end
		return { JsonStore = fq }
	end)
	a.register("out/utils/extract.lua", "extract", function()
		local S = a.get("out/utils/extract.lua")
		local a = a._G[S]
		local eT = a.import(S, S.Parent.Parent, "modules", "zzlib")
		local T = a.import(S, S.Parent, "file-utils")
		local a9 = T.makeUtils
		local W = T.pathUtils
		local function fs(ft, fu, fv)
			local fw = eT.unzip(ft)
			local fx = {}
			for d, fy in pairs(fw) do
				local a0
				if fv then
					local a1 = fx
					local a2 = { W.addTrailingSlash(fu) .. tostring(string.match(d, "^[^/]*/(.*)$")), fy }
					local a6 = #a1
					a1[a6 + 1] = a2
					a0 = a6 + 1
				else
					local a1 = fx
					local a2 = { W.addTrailingSlash(fu) .. d, fy }
					local a6 = #a1
					a1[a6 + 1] = a2
					a0 = a6 + 1
				end
			end
			a9.makeFiles(fx)
		end
		return { extract = fs }
	end)
	a.register("out/utils/http.lua", "http", function()
		local S = a.get("out/utils/http.lua")
		local a = a._G[S]
		local an = a.import(S, S.Parent.Parent, "api").httpRequest
		local fz = a.Promise.promisify(function(fA)
			return game:HttpGetAsync(fA)
		end)
		local fB = a.Promise.promisify(function(fA)
			return game:HttpPostAsync(fA)
		end)
		local request = a.Promise.promisify(an)
		return { get = fz, post = fB, request = request }
	end)
	a.register("out/utils/replace.lua", "replace", function()
		local S = a.get("out/utils/replace.lua")
		local function be(D, fC, fD)
			local T = D
			local a0 = fC
			local a1 = fD
			local eN, fE = string.gsub(T, a0, a1, 1)
			if fE > 0 then
				local a2 = D
				local a6 = fC
				local aC, em = string.find(a2, a6)
				local a8 = D
				local aG = aC
				local aH = em
				return { eN, string.sub(a8, aG, aH), aC, em }
			end
		end
		return { replace = be }
	end)
	a.register("out/utils/fetch-github-release/downloadAsset.lua", "downloadAsset", function()
		local S = a.get("out/utils/fetch-github-release/downloadAsset.lua")
		local a = a._G[S]
		local http = a.import(S, S.Parent.Parent, "http")
		local a9 = a.import(S, S.Parent.Parent, "file-utils").makeUtils
		local fs = a.import(S, S.Parent.Parent, "extract").extract
		local fF = a.async(function(fG, d, fH)
			local fI
			if fH ~= nil then
				local T = fG.assets
				local a0 = function(dX)
					return dX.name == fH
				end
				local a1 = nil
				for a2, a6 in ipairs(T) do
					if a0(a6, a2 - 1, T) == true then
						a1 = a6
						break
					end
				end
				local fJ = a1
				local a2 = fJ
				local a6 = "Release '" .. fG.name .. "' does not have asset '" .. fH .. "'"
				assert(a2, a6)
				fI = fJ.browser_download_url
			else
				fI = fG.zipball_url
			end
			local fK = a.await(http.request({ Url = fI, Headers = { ["User-Agent"] = "rostruct" } }))
			local T = fK.Success
			local a0 = fK.StatusMessage
			assert(T, a0)
			local a1
			if fH ~= nil and string.match(fH, "([^%.]+)$") ~= "zip" then
				a1 = a9.makeFile(d .. fH, fK.Body)
			else
				a1 = fs(fK.Body, d, fH == nil)
			end
		end)
		return { downloadAsset = fF }
	end)
	a.register("out/utils/fetch-github-release/downloadRelease.lua", "downloadRelease", function()
		local S = a.get("out/utils/fetch-github-release/downloadRelease.lua")
		local a = a._G[S]
		local fq = a.import(S, S.Parent.Parent, "JsonStore").JsonStore
		local fF = a.import(S, S.Parent, "downloadAsset").downloadAsset
		local T = a.import(S, S.Parent.Parent.Parent, "bootstrap")
		local ad = T.bootstrap
		local ab = T.getRostructPath
		local fL = a.import(S, S.Parent, "identify").identify
		local a0 = a.import(S, S.Parent, "getReleases")
		local fM = a0.getLatestRelease
		local fN = a0.getRelease
		local fO = fq.new(ab("RELEASE_TAGS"))
		local ag = a.async(function(fP, fQ, fR, fH)
			local a1 = type(fP) == "string"
			assert(a1, "Argument 'owner' must be a string")
			local a2 = type(fQ) == "string"
			assert(a2, "Argument 'repo' must be a string")
			local a6 = type(fR) == "string"
			assert(a6, "Argument 'tag' must be a string")
			local a8 = fH == nil or type(fH) == "string"
			assert(a8, "Argument 'asset' must be a string or nil")
			local fS = fL(fP, fQ, fR, fH)
			local d = ab("RELEASE_CACHE") .. fS .. "/"
			if isfolder(d) then
				local aG = { location = d, owner = fP, repo = fQ, tag = fR }
				local aH = "asset"
				local aI = fH
				if aI == nil then
					aI = "Source code"
				end
				aG[aH] = aI
				aG.updated = false
				return aG
			end
			local fG = a.await(fN(fP, fQ, fR))
			a.await(fF(fG, d, fH))
			local aG = { location = d, owner = fP, repo = fQ, tag = fR }
			local aH = "asset"
			local aI = fH
			if aI == nil then
				aI = "Source code"
			end
			aG[aH] = aI
			aG.updated = true
			return aG
		end)
		local af = a.async(function(fP, fQ, fH)
			local a1 = type(fP) == "string"
			assert(a1, "Argument 'owner' must be a string")
			local a2 = type(fQ) == "string"
			assert(a2, "Argument 'repo' must be a string")
			local a6 = fH == nil or type(fH) == "string"
			assert(a6, "Argument 'asset' must be a string or nil")
			local fS = fL(fP, fQ, nil, fH)
			local d = ab("RELEASE_CACHE") .. fS .. "/"
			local fG = a.await(fM(fP, fQ))
			fO:open()
			if fO:get(fS) == fG.tag_name and isfolder(d) then
				fO:close()
				local a8 = { location = d, owner = fP, repo = fQ, tag = fG.tag_name }
				local aG = "asset"
				local aH = fH
				if aH == nil then
					aH = "Source code"
				end
				a8[aG] = aH
				a8.updated = false
				return a8
			end
			fO:set(fS, fG.tag_name)
			fO:close()
			if isfolder(d) then
				delfolder(d)
			end
			a.await(fF(fG, d, fH))
			local a8 = { location = d, owner = fP, repo = fQ, tag = fG.tag_name }
			local aG = "asset"
			local aH = fH
			if aH == nil then
				aH = "Source code"
			end
			a8[aG] = aH
			a8.updated = true
			return a8
		end)
		local function ae()
			delfolder(ab("RELEASE_CACHE"))
			ad()
		end
		return { downloadRelease = ag, downloadLatestRelease = af, clearReleaseCache = ae }
	end)
	a.register("out/utils/fetch-github-release/getReleases.lua", "getReleases", function()
		local S = a.get("out/utils/fetch-github-release/getReleases.lua")
		local a = a._G[S]
		local ar = a.import(S, S.Parent.Parent.Parent, "modules", "services").HttpService
		local http = a.import(S, S.Parent.Parent, "http")
		local fT = a.async(function(fP, fQ, fU)
			if fU == nil then
				fU = function(fG)
					return not fG.draft
				end
			end
			local fK = a.await(
				http.request({
					Url = "https://api.github.com/repos/" .. fP .. "/" .. fQ .. "/releases",
					Headers = { ["User-Agent"] = "rostruct" },
				})
			)
			local T = fK.Success
			local a0 = fK.StatusMessage
			assert(T, a0)
			local fV = ar:JSONDecode(fK.Body)
			local a1 = fV
			local a2 = fU
			local a6 = {}
			local a8 = 0
			for aG, aH in ipairs(a1) do
				if a2(aH, aG - 1, a1) == true then
					a8 = a8 + 1
					a6[a8] = aH
				end
			end
			return a6
		end)
		local fN = a.async(function(fP, fQ, fR)
			local fK = a.await(
				http.request({
					Url = "https://api.github.com/repos/" .. fP .. "/" .. fQ .. "/releases/tags/" .. fR,
					Headers = { ["User-Agent"] = "rostruct" },
				})
			)
			local T = fK.Success
			local a0 = fK.StatusMessage
			assert(T, a0)
			return ar:JSONDecode(fK.Body)
		end)
		local fM = a.async(function(fP, fQ)
			local fK = a.await(
				http.request({
					Url = "https://api.github.com/repos/" .. fP .. "/" .. fQ .. "/releases/latest",
					Headers = { ["User-Agent"] = "rostruct" },
				})
			)
			local T = fK.Success
			local a0 = fK.StatusMessage
			assert(T, a0)
			return ar:JSONDecode(fK.Body)
		end)
		return { getReleases = fT, getRelease = fN, getLatestRelease = fM }
	end)
	a.register("out/utils/fetch-github-release/identify.lua", "identify", function()
		local S = a.get("out/utils/fetch-github-release/identify.lua")
		local function fL(fP, fQ, fR, fH)
			local fW = "%s-%s-%s-%s"
			local T = fW
			local a0 = string.lower(fP)
			local a1 = string.lower(fQ)
			local a2 = fR ~= nil and string.lower(fR) or "LATEST"
			local a6 = fH ~= nil and string.lower(fH) or "ZIPBALL"
			return string.format(T, a0, a1, a2, a6)
		end
		return { identify = fL }
	end)
	a.register("out/utils/fetch-github-release/init.lua", "init", function()
		local S = a.get("out/utils/fetch-github-release/init.lua")
		local a = a._G[S]
		local ap = {}
		for T, a0 in pairs(a.import(S, S, "getReleases")) do
			ap[T] = a0
		end
		for T, a0 in pairs(a.import(S, S, "downloadRelease")) do
			ap[T] = a0
		end
		for T, a0 in pairs(a.import(S, S, "identify")) do
			ap[T] = a0
		end
		return ap
	end)
	a.register("out/utils/fetch-github-release/types.lua", "types", function()
		local S = a.get("out/utils/fetch-github-release/types.lua")
		return nil
	end)
	a.register("out/utils/file-utils/init.lua", "init", function()
		local S = a.get("out/utils/file-utils/init.lua")
		local a = a._G[S]
		local ap = {}
		ap.makeUtils = a.import(S, S, "make-utils")
		ap.pathUtils = a.import(S, S, "path-utils")
		return ap
	end)
	a.register("out/utils/file-utils/make-utils.lua", "make-utils", function()
		local S = a.get("out/utils/file-utils/make-utils.lua")
		local a = a._G[S]
		local W = a.import(S, S.Parent, "path-utils")
		local function fX(fY)
			local fZ = ""
			for h in string.gmatch(fY, "[^/]*/") do
				fZ = fZ .. tostring(h)
				makefolder(fZ)
			end
		end
		local function f_(aJ, g0)
			fX(aJ)
			local T = W.addExtension(aJ)
			local a0 = g0
			if a0 == nil then
				a0 = ""
			end
			writefile(T, a0)
		end
		local function g1(fx)
			for k, T in ipairs(fx) do
				local d = T[1]
				local fy = T[2]
				if string.sub(d, -1) == "/" and not isfolder(d) then
					fX(d)
				elseif string.sub(d, -1) ~= "/" and not isfile(d) then
					f_(d, fy)
				end
			end
		end
		return { makeFolder = fX, makeFile = f_, makeFiles = g1 }
	end)
	a.register("out/utils/file-utils/path-utils.lua", "path-utils", function()
		local S = a.get("out/utils/file-utils/path-utils.lua")
		local function g2(d)
			local T = isfile(d) or isfolder(d)
			local a0 = "'" .. d .. "' does not point to a folder or file"
			assert(T, a0)
			d = string.gsub(d, "\\", "/")
			if isfolder(d) then
				if string.sub(d, -1) ~= "/" then
					d = d .. "/"
				end
			end
			return d
		end
		local function g3(d)
			d = string.gsub(d, "\\", "/")
			if string.match(d, "%.([^%./]+)$") == nil and string.sub(d, -1) ~= "/" then
				return d .. "/"
			else
				return d
			end
		end
		local function g4(aJ)
			local g5 = string.match(string.reverse(aJ), "^([^%./]+%.)") ~= nil
			if not g5 then
				return aJ .. ".file"
			else
				return aJ
			end
		end
		local function g6(d)
			return string.match(d, "([^/]+)/*$")
		end
		local function g7(d)
			return string.match(d, "^(.*[/])[^/]+")
		end
		local function g8(g9, ga)
			local T = ga
			local a0 = function(aJ)
				return isfile(g9 .. aJ)
			end
			local a1 = nil
			for a2, a6 in ipairs(T) do
				if a0(a6, a2 - 1, T) == true then
					a1 = a6
					break
				end
			end
			return a1
		end
		return { formatPath = g2, addTrailingSlash = g3, addExtension = g4, getName = g6, getParent = g7, locateFiles = g8 }
	end)
	a.register("out/utils/file-utils/types.lua", "types", function()
		local S = a.get("out/utils/file-utils/types.lua")
		return nil
	end)
	return a.initialize("init")
end)()

-- Download the latest release to local files
return Rostruct
	.fetchLatest("richie0866", "MidiPlayer")
	-- Then, build and start all scripts
	:andThen(function(package)
		package:build("src/")
		package:start()
		return package
	end)
	-- Finally, wait until the Promise is done
	:expect()
