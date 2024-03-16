-- title:   Tic80VbankDemos
-- author:  ArchaicVirus
-- desc:    Carousel for displaying various pixel effects using up to 31 colors
-- site:    github.com/archaicvirus/
-- license: MIT License (change this to your license of choice)
-- version: 0.1
-- script:  lua

-- CONTROLS
-- Left / Right arrow keys			Switch effect
-- Up / Down arrow keys				Swap Palette
-- NUMPAD MINUS						Unsort Palette
-- NUMPAD PLUS						Sort Palette - HUE
-- NUMPAD ENTER						Sort Palette - BRIGHTNESS
-- NUMPAD 1							Switch color mode - 16x / 32x
-- NUMPAD 4 & 6						Switch background color
-- NUMPAD 0							Disable UI

-- 16x color mode takes a 16-color palette, and creates a new darker palette using these colors, so it still uses 31 total colors
-- 32x color mode uses native 32 color palettes

-----------------------------------------------
---Simplex Noise
-- Original Java Source: http://staffwww.itn.liu.se/~stegu/simplexnoise/simplexnoise.pdf
-- (most) Original comments included
-----------------------------------------------

local math = math
local table = table
local tonumber = tonumber
local ipairs = ipairs
local error = error
--local bit = require("bit")

simplex = {}

simplex.DIR_X = 0
simplex.DIR_Y = 1
simplex.DIR_Z = 2
simplex.DIR_W = 3
simplex.internalCache = false


local Gradients3D = { { 1, 1, 0 }, { -1, 1, 0 }, { 1, -1, 0 }, { -1, -1, 0 },
	{ 1, 0, 1 }, { -1, 0, 1 }, { 1, 0, -1 }, { -1, 0, -1 },
	{ 0, 1, 1 }, { 0, -1, 1 }, { 0, 1, -1 }, { 0, -1, -1 } };
local Gradients4D = { { 0, 1, 1, 1 }, { 0, 1, 1, -1 }, { 0, 1, -1, 1 }, { 0, 1, -1, -1 },
	{ 0, -1, 1, 1 }, { 0, -1, 1, -1 }, { 0, -1, -1, 1 }, { 0, -1, -1, -1 },
	{ 1,  0, 1, 1 }, { 1, 0, 1, -1 }, { 1, 0, -1, 1 }, { 1, 0, -1, -1 },
	{ -1, 0, 1, 1 }, { -1, 0, 1, -1 }, { -1, 0, -1, 1 }, { -1, 0, -1, -1 },
	{ 1,  1, 0, 1 }, { 1, 1, 0, -1 }, { 1, -1, 0, 1 }, { 1, -1, 0, -1 },
	{ -1, 1, 0, 1 }, { -1, 1, 0, -1 }, { -1, -1, 0, 1 }, { -1, -1, 0, -1 },
	{ 1,  1, 1, 0 }, { 1, 1, -1, 0 }, { 1, -1, 1, 0 }, { 1, -1, -1, 0 },
	{ -1, 1, 1, 0 }, { -1, 1, -1, 0 }, { -1, -1, 1, 0 }, { -1, -1, -1, 0 } };
local p = { 151, 160, 137, 91, 90, 15,
	131, 13, 201, 95, 96, 53, 194, 233, 7, 225, 140, 36, 103, 30, 69, 142, 8, 99, 37, 240, 21, 10, 23,
	190, 6, 148, 247, 120, 234, 75, 0, 26, 197, 62, 94, 252, 219, 203, 117, 35, 11, 32, 57, 177, 33,
	88, 237, 149, 56, 87, 174, 20, 125, 136, 171, 168, 68, 175, 74, 165, 71, 134, 139, 48, 27, 166,
	77, 146, 158, 231, 83, 111, 229, 122, 60, 211, 133, 230, 220, 105, 92, 41, 55, 46, 245, 40, 244,
	102, 143, 54, 65, 25, 63, 161, 1, 216, 80, 73, 209, 76, 132, 187, 208, 89, 18, 169, 200, 196,
	135, 130, 116, 188, 159, 86, 164, 100, 109, 198, 173, 186, 3, 64, 52, 217, 226, 250, 124, 123,
	5, 202, 38, 147, 118, 126, 255, 82, 85, 212, 207, 206, 59, 227, 47, 16, 58, 17, 182, 189, 28, 42,
	223, 183, 170, 213, 119, 248, 152, 2, 44, 154, 163, 70, 221, 153, 101, 155, 167, 43, 172, 9,
	129, 22, 39, 253, 19, 98, 108, 110, 79, 113, 224, 232, 178, 185, 112, 104, 218, 246, 97, 228,
	251, 34, 242, 193, 238, 210, 144, 12, 191, 179, 162, 241, 81, 51, 145, 235, 249, 14, 239, 107,
	49, 192, 214, 31, 181, 199, 106, 157, 184, 84, 204, 176, 115, 121, 50, 45, 127, 4, 150, 254,
	138, 236, 205, 93, 222, 114, 67, 29, 24, 72, 243, 141, 128, 195, 78, 66, 215, 61, 156, 180 };

-- To remove the need for index wrapping, double the permutation table length

for i = 1, #p do
	p[i - 1] = p[i]
	p[i] = nil
end

for i = 1, #Gradients3D do
	Gradients3D[i - 1] = Gradients3D[i]
	Gradients3D[i] = nil
end

for i = 1, #Gradients4D do
	Gradients4D[i - 1] = Gradients4D[i]
	Gradients4D[i] = nil
end

local perm = {}

for i = 0, 255 do
	perm[i] = p[i]
	perm[i + 256] = p[i]
end

-- A lookup table to traverse the sim around a given point in 4D.
-- Details can be found where this table is used, in the 4D noise method.

local sim = {
	{ 0, 1, 2, 3 }, { 0, 1, 3, 2 }, { 0, 0, 0, 0 }, { 0, 2, 3, 1 }, { 0, 0, 0, 0 }, { 0, 0, 0, 0 }, { 0, 0, 0, 0 }, { 1, 2, 3, 0 },
	{ 0, 2, 1, 3 }, { 0, 0, 0, 0 }, { 0, 3, 1, 2 }, { 0, 3, 2, 1 }, { 0, 0, 0, 0 }, { 0, 0, 0, 0 }, { 0, 0, 0, 0 }, { 1, 3, 2, 0 },
	{ 0, 0, 0, 0 }, { 0, 0, 0, 0 }, { 0, 0, 0, 0 }, { 0, 0, 0, 0 }, { 0, 0, 0, 0 }, { 0, 0, 0, 0 }, { 0, 0, 0, 0 }, { 0, 0, 0, 0 },
	{ 1, 2, 0, 3 }, { 0, 0, 0, 0 }, { 1, 3, 0, 2 }, { 0, 0, 0, 0 }, { 0, 0, 0, 0 }, { 0, 0, 0, 0 }, { 2, 3, 0, 1 }, { 2, 3, 1, 0 },
	{ 1, 0, 2, 3 }, { 1, 0, 3, 2 }, { 0, 0, 0, 0 }, { 0, 0, 0, 0 }, { 0, 0, 0, 0 }, { 2, 0, 3, 1 }, { 0, 0, 0, 0 }, { 2, 1, 3, 0 },
	{ 0, 0, 0, 0 }, { 0, 0, 0, 0 }, { 0, 0, 0, 0 }, { 0, 0, 0, 0 }, { 0, 0, 0, 0 }, { 0, 0, 0, 0 }, { 0, 0, 0, 0 }, { 0, 0, 0, 0 },
	{ 2, 0, 1, 3 }, { 0, 0, 0, 0 }, { 0, 0, 0, 0 }, { 0, 0, 0, 0 }, { 3, 0, 1, 2 }, { 3, 0, 2, 1 }, { 0, 0, 0, 0 }, { 3, 1, 2, 0 },
	{ 2, 1, 0, 3 }, { 0, 0, 0, 0 }, { 0, 0, 0, 0 }, { 0, 0, 0, 0 }, { 3, 1, 0, 2 }, { 0, 0, 0, 0 }, { 3, 2, 0, 1 }, { 3, 2, 1, 0 } };

local function Dot2D(tbl, x, y)
	return tbl[1] * x + tbl[2] * y;
end

local function Dot3D(tbl, x, y, z)
	return tbl[1] * x + tbl[2] * y + tbl[3] * z
end

local function Dot4D(tbl, x, y, z, w)
	return tbl[1] * x + tbl[2] * y + tbl[3] * z + tbl[3] * w;
end


local Prev2D = {}

function simplex.seed(seed)
	Prev2D = {}
	seed = seed or tstamp()
	math.randomseed(seed * seed)
	for i = 1, 256 do
		p[i] = math.floor(math.random() * 256)
	end
end

-- Helper function to calculate the dot product between a gradient and a distance
local function dot(gradient, distance)
	return gradient * distance
end

-- Helper function to calculate the 1D gradient for a given hash value
local function grad1(hash, x)
	local h = hash & 15
	local grad = 1 + (h & 7)            -- Gradient value in the range 1 to 8
	if (h & 8) ~= 0 then grad = -grad end -- Randomly invert half of the gradients
	return grad * x
end

-- 1D Simplex Noise function
function simplex.Noise1D(x)
	-- Define the constants for 1D noise
	local F2 = 0.5 * (math.sqrt(3.0) - 1.0)
	local G2 = (3.0 - math.sqrt(3.0)) / 6.0

	-- Calculate the simplex skewing and unskewing factors
	local s = (x + x) * F2
	local i = math.floor(x + s)
	local t = (i + i) * G2
	local X0 = i - t -- Unskewed lattice point in x

	-- Calculate the hash values for the two simplex corners
	local i1 = i + 1
	local X1 = X0 - 1.0 -- Unskewed lattice point in x + 1

	-- Calculate the relative distances from the input point to the simplex corners
	local x0 = x - X0
	local x1 = x - X1

	-- Calculate the contribution from the two simplex corners
	local n0 = 0.0
	local n1 = 0.0

	local t0 = 0.5 - x0 * x0
	if t0 >= 0 then
		t0 = t0 * t0
		n0 = t0 * t0 * grad1(perm[i & 255], x0)
	end

	local t1 = 0.5 - x1 * x1
	if t1 >= 0 then
		t1 = t1 * t1
		n1 = t1 * t1 * grad1(perm[i1 & 255], x1)
	end

	-- Sum up the contributions from the two corners
	-- to get the final noise value.
	-- You can scale the result as needed.
	return 40.0 * (n0 + n1)
end

-- 2D simplex noise

function simplex.Noise2D(xin, yin)
	if simplex.internalCache and Prev2D[xin] and Prev2D[xin][yin] then return Prev2D[xin][yin] end

	local n0, n1, n2; -- Noise contributions from the three corners
	-- Skew the input space to determine which simplex cell we're in
	local F2 = 0.5 * (math.sqrt(3.0) - 1.0);
	local s = (xin + yin) * F2; -- Hairy factor for 2D
	local i = math.floor(xin + s);
	local j = math.floor(yin + s);
	local G2 = (3.0 - math.sqrt(3.0)) / 6.0;

	local t = (i + j) * G2;
	local X0 = i - t; -- Unskew the cell origin back to (x,y) space
	local Y0 = j - t;
	local x0 = xin - X0; -- The x,y distances from the cell origin
	local y0 = yin - Y0;

	-- For the 2D case, the simplex shape is an equilateral triangle.
	-- Determine which simplex we are in.
	local i1, j1; -- Offsets for second (middle) corner of simplex in (i,j) coords
	if (x0 > y0) then
		i1 = 1
		j1 = 0 -- lower triangle, XY order: (0,0)->(1,0)->(1,1)
	else
		i1 = 0
		j1 = 1 -- upper triangle, YX order: (0,0)->(0,1)->(1,1)
	end

	-- A step of (1,0) in (i,j) means a step of (1-c,-c) in (x,y), and
	-- a step of (0,1) in (i,j) means a step of (-c,1-c) in (x,y), where
	-- c = (3-sqrt(3))/6

	local x1 = x0 - i1 + G2;     -- Offsets for middle corner in (x,y) unskewed coords
	local y1 = y0 - j1 + G2;
	local x2 = x0 - 1.0 + 2.0 * G2; -- Offsets for last corner in (x,y) unskewed coords
	local y2 = y0 - 1.0 + 2.0 * G2;

	-- Work out the hashed gradient indices of the three simplex corners
	local ii = i & 255
	local jj = j & 255
	local gi0 = perm[ii + perm[jj]] % 12;
	local gi1 = perm[ii + i1 + perm[jj + j1]] % 12;
	local gi2 = perm[ii + 1 + perm[jj + 1]] % 12;

	-- Calculate the contribution from the three corners
	local t0 = 0.5 - x0 * x0 - y0 * y0;
	if t0 < 0 then
		n0 = 0.0;
	else
		t0 = t0 * t0
		n0 = t0 * t0 * Dot2D(Gradients3D[gi0], x0, y0); -- (x,y) of Gradients3D used for 2D gradient
	end

	local t1 = 0.5 - x1 * x1 - y1 * y1;
	if (t1 < 0) then
		n1 = 0.0;
	else
		t1 = t1 * t1
		n1 = t1 * t1 * Dot2D(Gradients3D[gi1], x1, y1);
	end

	local t2 = 0.5 - x2 * x2 - y2 * y2;
	if (t2 < 0) then
		n2 = 0.0;
	else
		t2 = t2 * t2
		n2 = t2 * t2 * Dot2D(Gradients3D[gi2], x2, y2);
	end


	-- Add contributions from each corner to get the final noise value.
	-- The result is scaled to return values in the localerval [-1,1].

	local retval = 70.0 * (n0 + n1 + n2)

	if simplex.internalCache then
		if not Prev2D[xin] then Prev2D[xin] = {} end
		Prev2D[xin][yin] = retval
	end

	return retval;
end

local Prev3D = {}

-- 3D simplex noise
function simplex.Noise3D(xin, yin, zin)
	if simplex.internalCache and Prev3D[xin] and Prev3D[xin][yin] and Prev3D[xin][yin][zin] then return Prev3D[xin][yin]
		[zin] end

	local n0, n1, n2, n3; -- Noise contributions from the four corners

	-- Skew the input space to determine which simplex cell we're in
	local F3 = 1.0 / 3.0;
	local s = (xin + yin + zin) * F3; -- Very nice and simple skew factor for 3D
	local i = math.floor(xin + s);
	local j = math.floor(yin + s);
	local k = math.floor(zin + s);

	local G3 = 1.0 / 6.0; -- Very nice and simple unskew factor, too
	local t = (i + j + k) * G3;

	local X0 = i - t; -- Unskew the cell origin back to (x,y,z) space
	local Y0 = j - t;
	local Z0 = k - t;

	local x0 = xin - X0; -- The x,y,z distances from the cell origin
	local y0 = yin - Y0;
	local z0 = zin - Z0;

	-- For the 3D case, the simplex shape is a slightly irregular tetrahedron.
	-- Determine which simplex we are in.
	local i1, j1, k1; -- Offsets for second corner of simplex in (i,j,k) coords
	local i2, j2, k2; -- Offsets for third corner of simplex in (i,j,k) coords

	if (x0 >= y0) then
		if (y0 >= z0) then
			i1 = 1; j1 = 0; k1 = 0; i2 = 1; j2 = 1; k2 = 0; -- X Y Z order
		elseif (x0 >= z0) then
			i1 = 1; j1 = 0; k1 = 0; i2 = 1; j2 = 0; k2 = 1; -- X Z Y order
		else
			i1 = 0; j1 = 0; k1 = 1; i2 = 1; j2 = 0; k2 = 1; -- Z X Y order
		end
	else                               -- x0<y0
		if (y0 < z0) then
			i1 = 0; j1 = 0; k1 = 1; i2 = 0; j2 = 1; k2 = 1; -- Z Y X order
		elseif (x0 < z0) then
			i1 = 0; j1 = 1; k1 = 0; i2 = 0; j2 = 1; k2 = 1; -- Y Z X order
		else
			i1 = 0; j1 = 1; k1 = 0; i2 = 1; j2 = 1; k2 = 0; -- Y X Z order
		end
	end

	-- A step of (1,0,0) in (i,j,k) means a step of (1-c,-c,-c) in (x,y,z),
	-- a step of (0,1,0) in (i,j,k) means a step of (-c,1-c,-c) in (x,y,z), and
	-- a step of (0,0,1) in (i,j,k) means a step of (-c,-c,1-c) in (x,y,z), where
	-- c = 1/6.

	local x1 = x0 - i1 + G3; -- Offsets for second corner in (x,y,z) coords
	local y1 = y0 - j1 + G3;
	local z1 = z0 - k1 + G3;

	local x2 = x0 - i2 + 2.0 * G3; -- Offsets for third corner in (x,y,z) coords
	local y2 = y0 - j2 + 2.0 * G3;
	local z2 = z0 - k2 + 2.0 * G3;

	local x3 = x0 - 1.0 + 3.0 * G3; -- Offsets for last corner in (x,y,z) coords
	local y3 = y0 - 1.0 + 3.0 * G3;
	local z3 = z0 - 1.0 + 3.0 * G3;

	-- Work out the hashed gradient indices of the four simplex corners
	local ii = i & 255
	local jj = j & 255
	local kk = k & 255

	local gi0 = perm[ii + perm[jj + perm[kk]]] % 12;
	local gi1 = perm[ii + i1 + perm[jj + j1 + perm[kk + k1]]] % 12;
	local gi2 = perm[ii + i2 + perm[jj + j2 + perm[kk + k2]]] % 12;
	local gi3 = perm[ii + 1 + perm[jj + 1 + perm[kk + 1]]] % 12;

	-- Calculate the contribution from the four corners
	local t0 = 0.5 - x0 * x0 - y0 * y0 - z0 * z0;

	if (t0 < 0) then
		n0 = 0.0;
	else
		t0 = t0 * t0;
		n0 = t0 * t0 * Dot3D(Gradients3D[gi0], x0, y0, z0);
	end

	local t1 = 0.5 - x1 * x1 - y1 * y1 - z1 * z1;

	if (t1 < 0) then
		n1 = 0.0;
	else
		t1 = t1 * t1;
		n1 = t1 * t1 * Dot3D(Gradients3D[gi1], x1, y1, z1);
	end

	local t2 = 0.5 - x2 * x2 - y2 * y2 - z2 * z2;

	if (t2 < 0) then
		n2 = 0.0;
	else
		t2 = t2 * t2;
		n2 = t2 * t2 * Dot3D(Gradients3D[gi2], x2, y2, z2);
	end

	local t3 = 0.5 - x3 * x3 - y3 * y3 - z3 * z3;

	if (t3 < 0) then
		n3 = 0.0;
	else
		t3 = t3 * t3;
		n3 = t3 * t3 * Dot3D(Gradients3D[gi3], x3, y3, z3);
	end


	-- Add contributions from each corner to get the final noise value.
	-- The result is scaled to stay just inside [-1,1]
	local retval = 32.0 * (n0 + n1 + n2 + n3)

	if simplex.internalCache then
		if not Prev3D[xin] then Prev3D[xin] = {} end
		if not Prev3D[xin][yin] then Prev3D[xin][yin] = {} end
		Prev3D[xin][yin][zin] = retval
	end

	return retval;
end

local Prev4D = {}

-- 4D simplex noise
function simplex.Noise4D(x, y, z, w)
	if simplex.internalCache and Prev4D[x] and Prev4D[x][y] and Prev4D[x][y][z] and Prev4D[x][y][z][w] then return Prev4D
		[x][y][z][w] end

	-- The skewing and unskewing factors are hairy again for the 4D case
	local F4 = (math.sqrt(5.0) - 1.0) / 4.0;
	local G4 = (5.0 - math.sqrt(5.0)) / 20.0;
	local n0, n1, n2, n3, n4;    -- Noise contributions from the five corners
	-- Skew the (x,y,z,w) space to determine which cell of 24 simplices we're in
	local s = (x + y + z + w) * F4; -- Factor for 4D skewing
	local i = math.floor(x + s);
	local j = math.floor(y + s);
	local k = math.floor(z + s);
	local l = math.floor(w + s);
	local t = (i + j + k + l) * G4; -- Factor for 4D unskewing
	local X0 = i - t;            -- Unskew the cell origin back to (x,y,z,w) space
	local Y0 = j - t;
	local Z0 = k - t;
	local W0 = l - t;
	local x0 = x - X0; -- The x,y,z,w distances from the cell origin
	local y0 = y - Y0;
	local z0 = z - Z0;
	local w0 = w - W0;
	-- For the 4D case, the simplex is a 4D shape I won't even try to describe.
	-- To find out which of the 24 possible simplices we're in, we need to
	-- determine the magnitude ordering of x0, y0, z0 and w0.
	-- The method below is a good way of finding the ordering of x,y,z,w and
	-- then find the correct traversal order for the simplex we�re in.
	-- First, six pair-wise comparisons are performed between each possible pair
	-- of the four coordinates, and the results are used to add up binary bits
	-- for an localeger index.
	local c1 = (x0 > y0) and 32 or 1;
	local c2 = (x0 > z0) and 16 or 1;
	local c3 = (y0 > z0) and 8 or 1;
	local c4 = (x0 > w0) and 4 or 1;
	local c5 = (y0 > w0) and 2 or 1;
	local c6 = (z0 > w0) and 1 or 1;
	local c = c1 + c2 + c3 + c4 + c5 + c6;
	local i1, j1, k1, l1; -- The localeger offsets for the second simplex corner
	local i2, j2, k2, l2; -- The localeger offsets for the third simplex corner
	local i3, j3, k3, l3; -- The localeger offsets for the fourth simplex corner

	-- sim[c] is a 4-vector with the numbers 0, 1, 2 and 3 in some order.
	-- Many values of c will never occur, since e.g. x>y>z>w makes x<z, y<w and x<w
	-- impossible. Only the 24 indices which have non-zero entries make any sense.
	-- We use a thresholding to set the coordinates in turn from the largest magnitude.
	-- The number 3 in the "sim" array is at the position of the largest coordinate.

	i1 = sim[c][1] >= 3 and 1 or 0;
	j1 = sim[c][2] >= 3 and 1 or 0;
	k1 = sim[c][3] >= 3 and 1 or 0;
	l1 = sim[c][4] >= 3 and 1 or 0;
	-- The number 2 in the "sim" array is at the second largest coordinate.
	i2 = sim[c][1] >= 2 and 1 or 0;
	j2 = sim[c][2] >= 2 and 1 or 0;
	k2 = sim[c][3] >= 2 and 1 or 0;
	l2 = sim[c][4] >= 2 and 1 or 0;
	-- The number 1 in the "sim" array is at the second smallest coordinate.
	i3 = sim[c][1] >= 1 and 1 or 0;
	j3 = sim[c][2] >= 1 and 1 or 0;
	k3 = sim[c][3] >= 1 and 1 or 0;
	l3 = sim[c][4] >= 1 and 1 or 0;
	-- The fifth corner has all coordinate offsets = 1, so no need to look that up.
	local x1 = x0 - i1 + G4; -- Offsets for second corner in (x,y,z,w) coords
	local y1 = y0 - j1 + G4;
	local z1 = z0 - k1 + G4;
	local w1 = w0 - l1 + G4;
	local x2 = x0 - i2 + 2.0 * G4; -- Offsets for third corner in (x,y,z,w) coords
	local y2 = y0 - j2 + 2.0 * G4;
	local z2 = z0 - k2 + 2.0 * G4;
	local w2 = w0 - l2 + 2.0 * G4;
	local x3 = x0 - i3 + 3.0 * G4; -- Offsets for fourth corner in (x,y,z,w) coords
	local y3 = y0 - j3 + 3.0 * G4;
	local z3 = z0 - k3 + 3.0 * G4;
	local w3 = w0 - l3 + 3.0 * G4;
	local x4 = x0 - 1.0 + 4.0 * G4; -- Offsets for last corner in (x,y,z,w) coords
	local y4 = y0 - 1.0 + 4.0 * G4;
	local z4 = z0 - 1.0 + 4.0 * G4;
	local w4 = w0 - 1.0 + 4.0 * G4;

	-- Work out the hashed gradient indices of the five simplex corners
	local ii = i & 255
	local jj = j & 255
	local kk = k & 255
	local ll = l & 255
	local gi0 = perm[ii + perm[jj + perm[kk + perm[ll]]]] % 32;
	local gi1 = perm[ii + i1 + perm[jj + j1 + perm[kk + k1 + perm[ll + l1]]]] % 32;
	local gi2 = perm[ii + i2 + perm[jj + j2 + perm[kk + k2 + perm[ll + l2]]]] % 32;
	local gi3 = perm[ii + i3 + perm[jj + j3 + perm[kk + k3 + perm[ll + l3]]]] % 32;
	local gi4 = perm[ii + 1 + perm[jj + 1 + perm[kk + 1 + perm[ll + 1]]]] % 32;


	-- Calculate the contribution from the five corners
	local t0 = 0.5 - x0 * x0 - y0 * y0 - z0 * z0 - w0 * w0;
	if (t0 < 0) then
		n0 = 0.0;
	else
		t0 = t0 * t0;
		n0 = t0 * t0 * Dot4D(Gradients4D[gi0], x0, y0, z0, w0);
	end

	local t1 = 0.5 - x1 * x1 - y1 * y1 - z1 * z1 - w1 * w1;
	if (t1 < 0) then
		n1 = 0.0;
	else
		t1 = t1 * t1;
		n1 = t1 * t1 * Dot4D(Gradients4D[gi1], x1, y1, z1, w1);
	end

	local t2 = 0.5 - x2 * x2 - y2 * y2 - z2 * z2 - w2 * w2;
	if (t2 < 0) then
		n2 = 0.0;
	else
		t2 = t2 * t2;
		n2 = t2 * t2 * Dot4D(Gradients4D[gi2], x2, y2, z2, w2);
	end

	local t3 = 0.5 - x3 * x3 - y3 * y3 - z3 * z3 - w3 * w3;
	if (t3 < 0) then
		n3 = 0.0;
	else
		t3 = t3 * t3;
		n3 = t3 * t3 * Dot4D(Gradients4D[gi3], x3, y3, z3, w3);
	end

	local t4 = 0.5 - x4 * x4 - y4 * y4 - z4 * z4 - w4 * w4;
	if (t4 < 0) then
		n4 = 0.0;
	else
		t4 = t4 * t4;
		n4 = t4 * t4 * Dot4D(Gradients4D[gi4], x4, y4, z4, w4);
	end

	-- Sum up and scale the result to cover the range [-1,1]

	local retval = 27.0 * (n0 + n1 + n2 + n3 + n4)

	if simplex.internalCache then
		if not Prev4D[x] then Prev4D[x] = {} end
		if not Prev4D[x][y] then Prev4D[x][y] = {} end
		if not Prev4D[x][y][z] then Prev4D[x][y][z] = {} end
		Prev4D[x][y][z][w] = retval
	end

	return retval;
end

local e = 2.71828182845904523536

local PrevBlur2D = {}

function simplex.GBlur2D(x, y, stdDev)
	if simplex.internalCache and PrevBlur2D[x] and PrevBlur2D[x][y] and PrevBlur2D[x][y][stdDev] then return PrevBlur2D
		[x][y][stdDev] end
	local pwr = ((x ^ 2 + y ^ 2) / (2 * (stdDev ^ 2))) * -1
	local ret = (1 / (2 * math.pi * (stdDev ^ 2))) * (e ^ pwr)

	if simplex.internalCache then
		if not PrevBlur2D[x] then PrevBlur2D[x] = {} end
		if not PrevBlur2D[x][y] then PrevBlur2D[x][y] = {} end
		PrevBlur2D[x][y][stdDev] = ret
	end
	return ret
end

local PrevBlur1D = {}

function simplex.GBlur1D(x, stdDev)
	if simplex.internalCache and PrevBlur1D[x] and PrevBlur1D[x][stdDev] then return PrevBlur1D[x][stdDev] end
	local pwr = (x ^ 2 / (2 * stdDev ^ 2)) * -1
	local ret = (1 / (math.sqrt(2 * math.pi) * stdDev)) * (e ^ pwr)

	if simplex.internalCache then
		if not PrevBlur1D[x] then PrevBlur1D[x] = {} end
		PrevBlur1D[x][stdDev] = ret
	end
	return ret
end

function simplex.FractalSum(func, iter, ...)
	local ret = func(...)
	for i = 1, iter do
		local power = 2 ^ iter
		local s = power / i

		local scaled = {}
		for elem in ipairs({ ... }) do
			table.insert(scaled, elem * s)
		end
		ret = ret + (i / power) * (func(table.unpack(scaled)))
	end
	return ret
end

function simplex.FractalSumAbs(func, iter, ...)
	local ret = math.abs(func(...))
	for i = 1, iter do
		local power = 2 ^ iter
		local s = power / i

		local scaled = {}
		for elem in ipairs({ ... }) do
			table.insert(scaled, elem * s)
		end
		ret = ret + (i / power) * (math.abs(func(table.unpack(scaled))))
	end
	return ret
end

function simplex.Turbulence(func, direction, iter, ...)
	local ret = math.abs(func(...))
	for i = 1, iter do
		local power = 2 ^ iter
		local s = power / i

		local scaled = {}
		for elem in ipairs({ ... }) do
			table.insert(scaled, elem * s)
		end
		ret = ret + (i / power) * (math.abs(func(table.unpack(scaled))))
	end
	local args = { ... }
	local dir_component = args[direction + 1]
	return math.sin(dir_component + ret)
end

vec2 = {}
vec2_mt = {}
vec2_mt.__index = vec2_mt

function vec2_mt:__add( v )
	if type(v) == 'table' then
		return vec2(self.x + v.x, self.y + v.y)
	else
		return vec2(self.x + v, self.y + v)
	end
end

function vec2_mt:__sub( v )
	if type(v) == 'table' then
		return vec2(self.x - v.x, self.y - v.y)
	else
		return vec2(self.x - v, self.y - v)
	end
end

function vec2_mt:__mul( v )
	if type(v) == "table"
		then return vec2(self.x * v.x, self.y * v.y)
		else return vec2(self.x * v, self.y * v) end
end

function vec2_mt:__div( v )
	if type(v) == "table"
	then return vec2(self.x / v.x, self.y / v.y)
	else return vec2(self.x / v, self.y / v) end
end

function vec2_mt:__unm()
	return vec2(-self.x, -self.y)
end

function vec2_mt:dot( v )
	return self.x * v.x + self.y * v.y
end

function vec2_mt:length()
	return math.sqrt(self.x * self.x + self.y * self.y)
end

function vec2_mt:distance(v)
	return ((self.x - v.x) ^ 2 + (self.y - v.y) ^ 2) ^ 0.5
end

function vec2_mt:floor()
	return vec2(floor(self.x), floor(self.y))
end

function vec2_mt:ceil()
	return vec2(ceil(self.x), ceil(self.y))
end

function vec2_mt:normalize()
	local lengthSquared = self.x * self.x + self.y * self.y
	if lengthSquared == 0 then
		return vec2(0, 0)
	end
	local lengthInv = 1 / math.sqrt(lengthSquared)
	return vec2(self.x * lengthInv, self.y * lengthInv)
end

function vec2_mt:lerp(lerp_to, lerp_amount)
	if type(lerp_to) == 'table' then
		return vec2(lerp(self.x, lerp_to.x, lerp_amount), lerp(self.y, lerp_to.y, lerp_amount))
	else
		return vec2(lerp(self.x, lerp_to, lerp_amount), lerp(self.y, lerp_to, lerp_amount))
	end
end

function vec2_mt:rotate(angle)
	local cs = math.cos(angle)
	local sn = math.sin(angle)
	return vec2(self.x * cs - self.y * sn, self.x * sn + self.y * cs)
end

function vec2_mt:div()
	return self.x / self.y
end

function vec2_mt:min(v)
	if type(v) == "table"
	then return vec2(math.min(self.x, v.x), math.min(self.y, v.y))
	else return math.min(self.x, self.y) end
end

function vec2_mt:max(v)
	if type(v) == "table"
	then return vec2(math.max(self.x, v.x), math.max(self.y, v.y))
	else return math.max(self.x, self.y) end
end

function vec2_mt:abs()
	return vec2(math.abs(self.x), math.abs(self.y))
end

function vec2_mt:mix(v, n)
	return self * n + v * math.max(0, 1 - n)
end

function vec2_mt:__tostring()
	return "x: " .. self.x .. ", y: " .. self.y
	--return ("(%g , %g)"):format(self:tuple())
end

function vec2_mt:tuple()
	return self.x, self.y
end

function vec2_mt:__eq(b)
	return type(b) == 'table' and self.x == b.x and self.y == b.y
end

setmetatable(vec2, {__call = function(V, x, y ) return setmetatable({x = x or 0, y = y or x or 0}, vec2_mt) end})

vec3 = {}
vec3.__index = vec3

function vec3:dot(other)
	return self.x * other.x + self.y * other.y + self.z * other.z
end

function vec3:normalize()
	local len = math.sqrt(self.x * self.x + self.y * self.y + self.z * self.z)
	return vec3.new(self.x / len, self.y / len, self.z / len)
end

function vec3:__len()
	return math.sqrt(self.x * self.x + self.y * self.y + self.z * self.z)
end

function vec3.__add(v1, v2)
	return vec3(v1.x + v2.x, v1.y + v2.y, v1.z + v2.z)
end

function vec3.__sub(v1, v2)
	return vec3(v1.x - v2.x, v1.y - v2.y, v1.z - v2.z)
end

function vec3.__mul(v, scalar)
	return vec3(v.x * scalar, v.y * scalar, v.z * scalar)
end

function vec3.__div(v, scalar)
	return vec3(v.x / scalar, v.y / scalar, v.z / scalar)
end

function vec3.__unm(v)
	return vec3(-v.x, -v.y, -v.z)
end

function vec3.__eq(v1, v2)
	return v1.x == v2.x and v1.y == v2.y and v1.z == v2.z
end

function vec3.__tostring(v)
	return string.format("vec3(%f, %f, %f)", v.x, v.y, v.z)
end

function vec3:length()
	return self:__len()
end

function vec3:rotate(axis, angle)
	local u, v, w = axis.x, axis.y, axis.z
	local x, y, z = self.x, self.y, self.z

	local cos_angle = math.cos(angle)
	local sin_angle = math.sin(angle)

	local rotated_x = (u * (u * x + v * y + w * z) * (1 - cos_angle) + x * cos_angle + (-w * y + v * z) * sin_angle)
	local rotated_y = (v * (u * x + v * y + w * z) * (1 - cos_angle) + y * cos_angle + (w * x - u * z) * sin_angle)
	local rotated_z = (w * (u * x + v * y + w * z) * (1 - cos_angle) + z * cos_angle + (-v * x + u * y) * sin_angle)

	return vec3(rotated_x, rotated_y, rotated_z)
end

function vec3:random()
	return vec3(math.random() * 2 - 1, math.random() * 2 - 1, math.random() * 2 - 1)
end

function vec3:copy()
	return vec3(self.x, self.y, self.z)
end

function vec3.new(x, y, z)
	return setmetatable({ x = x, y = y, z = z }, vec3)
end

setmetatable(vec3, { __call = function(_, ...) return vec3.new(...) end })

BUTTON_CLOSE = 1994
BUTTON_ARROW = 1990
BUTTON_MENU = 1991
BUTTON_MENU_SMALL = 1992
BUTTON_LAYER = 1993
BUTTON_EXPORT = 1998
BUTTON_TEXT = 504
BUTTON_MAP = 1990
BUTTON_MARQUEE = 1986
BUTTON_FILL = 1984
BUTTON_PENCIL = 1985
BUTTON_BRUSH = 1987
BUTTON_CLONE = 1988
BUTTON_COPY = 1999
BUTTON_TRASH = 1989
BUTTON_GRID = 1995
BUTTON_HIGHLIGHT = 1996
BUTTON_DITHER = 1997
BUTTON_COOLDOWN = 30

--KEY-MAPPINGS FOR TEXT INPUT
KEYS = {
	[ 1] = {'A', 'a'},
	[ 2] = {'B', 'b'},
	[ 3] = {'C', 'c'},
	[ 4] = {'D', 'd'},
	[ 5] = {'E', 'e'},
	[ 6] = {'F', 'f'},
	[ 7] = {'G', 'g'},
	[ 8] = {'H', 'h'},
	[ 9] = {'I', 'i'},
	[10] = {'J', 'j'},
	[11] = {'K', 'k'},
	[12] = {'L', 'l'},
	[13] = {'M', 'm'},
	[14] = {'N', 'n'},
	[15] = {'O', 'o'},
	[16] = {'P', 'p'},
	[17] = {'Q', 'q'},
	[18] = {'R', 'r'},
	[19] = {'S', 's'},
	[20] = {'T', 't'},
	[21] = {'U', 'u'},
	[22] = {'V', 'v'},
	[23] = {'W', 'w'},
	[24] = {'X', 'x'},
	[25] = {'Y', 'y'},
	[26] = {'Z', 'z'},
	[27] = {')', '0'},
	[28] = {'@', '1'},
	[29] = {'#', '2'},
	[30] = {'$', '3'},
	[31] = {'%', '4'},
	[32] = {'^', '5'},
	[33] = {'&', '6'},
	[34] = {'*', '7'},
	[35] = {'(', '8'},
	[36] = {'(', '9'},
	[37] = {'_', '-'},
	[38] = {'+', '='},
	[39] = {'{', '['},
	[40] = {'}', ']'},
	[41] = {'|', '\\'},
	[42] = {':', ';'},
	[43] = {'"', '\''},
	[44] = {'~', '`'},
	[45] = {'<', ','},
	[46] = {'>', '.'},
	[47] = {'?', '/'},
	[48] = {' '}, --SPACE
	--[49] = {'    '}, --TAB
	--[50] = {'\n'}, --ENTER KEY
	[79] = {'0'},
	[80] = {'1'},
	[81] = {'2'},
	[82] = {'3'},
	[83] = {'4'},
	[84] = {'5'},
	[85] = {'6'},
	[86] = {'7'},
	[87] = {'8'},
	[88] = {'9'},
	[89] = {'+'},
	[90] = {'-'},
	[91] = {'*'},
	[92] = {'/'},
	[93] = {''}, -- NUMPAD ENTER
	[94] = {'.'},
}

floor, ceil, rnd, abs, rad, deg, cos, sin, min, max, pi, sqrt, atan2 =  math.floor, math.ceil, math.random, math.abs, math.rad, math.deg, math.cos, math.sin, math.min, math.max, math.pi, math.sqrt, math.atan2

SIN_LUT = {}
COS_LUT = {}

for i = 0, 360 do
  SIN_LUT[i] = sin(math.rad(i))
  COS_LUT[i] = cos(math.rad(i))
end

-- palettes = {
default_bg = '1d1d20ba5d1d856d2844690c203810185050346d912424441414147530619d557d59300c611c10242c2c5d5d5d999595'
default_fg = '1d1d20f9801dfed83d80c71f5e7c16169c9c4c7dca20387d141414c74ebdf38baa8d4820b02e26474f528d8d89d6d6d2'
-- }

palettes16 = {}

palettes32 = {
	{name = '2 Bit Venture', val = '1601161e051f4f084f8a0f8a11084f220f8a4f08088a0f0f1b4f081a8a0f084f460f8a834d4f088a860f4f2d088a5d0f898989b0b0b05126518753873834505f578a513636875b5b374d2f598b54344f4b5c89865252388a8853503f2d8e7854'},
	{name = 'AE-32', val = '15141a25254d285263228b9926c99b66f26dffe1a8fcffdeb4f4fa78c7e65386c93c568f3228385e2f58a84087cc6283e68681ffaf94ffae6bff8336eb3528b81e427a3159804229a1623dc48b56dec77ab5c3c78c929c686c854a4c5c26222b'},
	{name = 'ACRADE HERO', val = '000000202020404040747474808080c0c0c0e0e0e0ffffff405e006ea100f2ff00fcffc487edff3b9dff1611ba0300618f0043de0025de5b87de97b2800000a3390bde4d10f571180052360a8c1770d61cceff63f037d78b00b54c00822a0047'},
	{name = 'ADB HYBRID 32', val = '0000001f22345b2837b42d32dc6276f0bf96fffffffaeb50eda52ce46c1fac55266f452c847235a7994a9dda3c40bf6a3d8f4530745632542b3b3e374d514e686b6d908d91b3bcc1b2dcef49b8ea7d80fd3f65eb195c823a3585a04298e684c7'},
	{name = 'Aerugo', val = '2f1e1a4f332272362795392cc75533e76d46934e28a2663cc87d40f5a95b6b8b8c81a38eaac39effffffd1d0cebab7b2898a8a686461554d4b3c3d3b34323087d1ef64a1c24664802f485c242e351b2026aa9c8a917f6d86624a715b485e4835'},
	{name = 'AFR-32', val = 'ecebe7cbc6c1b28b78847066695b594f4240352f2e723012845425a76343dc6a36f682bfd74060c5452bb022228d19316a13253e1909406a3b76771d939446d3bd4699e0a8399a4d204f1a0f2c0c1a0a0114266a194f802067a749a3b41de9de'},
	{name = 'AlienGarden 32', val = '35120e6b2b15b35324d48e55e8c8a9ffaeb6ff8095ff4785bd1e7d660e49330a33590924801224b3102bc1460fee8201ffc52cd3fc7e99e65f5ac54f33984b1e6f50134c4c0c2e4400396d0069aa0098dc92a1b9657392424c6e2a2f4e1a1932'},
	{name = 'Andrew Kensler 32', val = 'd6a090fe3b1ea12c32fa2f7afb9fdae61cf7992f7c47011f0511554f02ec2d69cb00a6ee6febff08a29a2a666a0636190000004a49578e7ba4b7c0ffffffffacbe9c827c705a3b1cae6507f7aa30f4ea5c9b950056620411963b51e11308fdcc'},
	{name = 'ANSI32', val = '0000000000a30037d14b4cff91a4f04cffffacffff00a3a30047460c380c0077014cff4dc5ffc5dfdfdfcacacaa3a3a37070704c4c4c292929773800dc6a00ffa300fe4746c20000770000762979cc29ccff4cfeff9dffefbbbbfff28cffffff'},
	{name = 'Aren32', val = '1a151621181b2c20253d293652333f8f4d57bd6a62ffae70ffce91fea7a7451d42611e4a81204fad2f45de523ee67839f0b541ffee83c8d45da4c44363ab3f3b7d4f233b362a594f3687824fa4b892e8c0ffffffa3a7c2686f99454a6a1d2235'},
	{name = 'Arne-199X', val = '223355ddddddaaaaaa88888855555533333322222200000099bbdd6688bb446699224477112255001133ffbb66dd9955bb7733aa5522774411662200ff9999ee5555cc333399222277111166000088cc6666aa44338822226611114400002200'},
	{name = 'Arne 32', val = '000000493c2bbe2633e06f8ba46422eb8931f7e26bffffff9d9d9d2f484e1b263244891aa3ce2700578431a2f2b2dcef342a97656d71cccccc732930cb43a7524f40ad9d33ec4700fab40b115e3314807e15c2a5225af69964f9f78ed6f4b990'},
	{name = 'Aspiria-32', val = '14141553545a787981a9a9b1ffffff2a0707681717d163636a3b19a34f12d7864aebbc9a8c6315c69933dbbc4aeeda8c052d181159243db33585dd650f573d24846e41afa87cdfd90a163b17266b2e349a4d4ac747176b602e9a6c4ac78e8bea'},
	{name = 'Astron STE32', val = '000000c04050f0f0f0c0c0b0809090606070604040403020705030b07040e0a050e0c080f0e060e08030d05020903020603070b060a0e080c0c0a0d07070c03040902020402060d040a0e080d0e0a0f09030a06030403030702070a030a0d050'},
	{name = 'Atapki-Baby32', val = '0000004242427f7e7fbebebeffffffff9c7cff00009d163643142b8c3a21c96e19efb300ffff0004be000c7a421139390000ff3776ff37bbff04ffffffb5ecff00ffa018cf4e1f7f13122538466c32421b5e5e39a9e0a6f4d1c34f38351d1918'},
	{name = 'Aubrey-32', val = 'f5f7fbb9bfc93a383f03030483c5c55c96b7355e86141f4379aa5c458f451d5137041f1fd2b660b78632a667296b3514e09363c96d42b3552d8f3b1ed27676c54e4e982020550b0bd97fe4bc5abc9d4089671d4ea57fd78966c567469d432067'},
	{name = 'Ax coral-32 Color', val = '000000fcfcfcc4c7ee988dd86660992d336821233effe3aecdbbaba6858fd4639297506dffb98ae38e88b56e74f7c965e8965fcf6f3cb0d07e66aa5d52b5ab2a83791c56597be1f6589ffc5069e42e44ae7e55d95c3da7ffbfe3e68ec8bc6ccb'},
	{name = 'AxulArt 32 color Palette', val = '000000fcfcfcc4c7ee9a8fe0635d96292f651b1d34ffe3aecdbbaba6858fcf5d8b964968ffb482dd867db2696ff6c65ee49057c46833b0d07e66aa5d52b5ab2a83791c56597be1f6589ffc5069e42e44ae8056d45a3b96ffbae1e687c5a759b9'},
	{name = 'Baba32', val = '52002d682e2e8f5931a6834ef6d884ffffff861008b54b12d4821e2638470a544f14783c459c288bb8420d6a731a869c3da3bf79cfd9bfedf2654c6856587672847fa4b2a0d9d4c4b60e2ddc2828ee9481ffc9bd823fa1ab63d4e573cfffaef8'},
	{name = 'Blend 32', val = '0000001f00473b005873005ebf2432ec841afff768a4ed3a46ba2920875a085166002d7e006cc420a7de6fe8ff90ffe5ffffffbfe0e099adc1656f954a4270680489a723b2db52b9ff96cbffcdd9ffdea1d09676a75c438134315911313a0121'},
	{name = 'bly32', val = '1a1a21322a49783e54b05656dd7664f79979ffc19cff8b7fe65d83a640916c3271c0426ef6695affa854ffdc67bccc4863af571b806024525d4676756f9785a3ba99d2d8b4f5eed976e5cb3fc1d83a90d03f60b53b3d876b58bfb172d8f68cbd'},
	{name = 'Brilliance 32', val = '8658d1e883ffffd4c9ff6f7ad02a48762b25441d26781122ad0707ca5624d68622ffb537ffef859dfa877cca71469e4a376527263a210a25261f3d6a3d5a7d559fbc6dd7ff9cffffffffffb0b5c379757a4743470000003a231a895d45dba68d'},
	{name = 'Brzezinski-32', val = '3330334a41435f4c3f6258446d6a5066736a867780929181afa698bcbcbcdcd9cbfffffff9e896f1ba61a8744faf4e3d8346655a3d62393c4f445b634f78746d8d628c9d5db1b5609dcf759aed9ee1f7ff7f546aa05aaeba75a6d6a4a9fbc9c9'},
	{name = 'calmness', val = 'b34827992d1f801a1a6614224d0f1f2967b32236991c21802c16662d114d29b3452399431e8040186637124d2c8fb32d7e992675801f5d6618494d12b38e7199715f805a4d66433e4d2f2fb32d9f992691801f7a661a6643144dffffff000000'},
	{name = 'Carnival 32', val = '4d223571282a975638d0763eebac4df2d08dddac88c68d80af6d77c744469f38476e406da7a75871814149654137433b2a1c314231574d528a556a975c81a37dadc8b0d6d9ece6dfcfcccaa6a6a67878786262624a4a4a363636618c708b7463'},
	{name = 'Celestial', val = '222222787878b9b9b9ffffffac6666c07878d89191ebacacdeb04fe9c26fefd295ffe9bb7a866099a67cb2bf97c7d4ab688dbb7ea1cca8c4e7cbe2ff8e79baa995d2c1afe4d3c5f07162538d7c6cae9d8dcdbdae8c6239ac7e50cd9c6de8b98a'},
	{name = 'Cell Soft 32', val = 'f3d0d1edb1bdc994b0aa6782793433ac4f5ebe6b82e992afb7b9c0989fa7867c7d6e6770493f3f705045816254a885653e60823053701a3952071b2c00072100185020355a3c4563dae2eecdd5e4929ab67c7f9e6a6a8b464062241e41020105'},
	{name = 'Cheerful-32', val = '0e11122b2d334c50598a9399c2c9ccfff9f266ccff2e8ae61f479917204d0f4d380f993216d9168cff19ffff4dffd500f27900e62200b3001e800d20590924330a33660a47bf0070ff3399ff8095ffbb99e68a5cb353246b2b1540150d2b0f0f'},
	{name = 'Circuit Board', val = '86c35925b1580aa978222b34154071043bb9f1cc4d9971107f490e841300ce1729b51498f11bda3d404513171a070707a2d27e57d88682d5bb4e667e4370d77bafebffe27d9a8349ae783ea6564ae35e6bc282b7f37ce6626b7a26333df2f2f2'},
	{name = 'Cold Morning 32', val = '0a0a0b2926404b4e5e818686b6bcbbdcdcd5fffff2b9faff95daf46eb1d9517fac42577b51819957a9a660c79981d799d8ffb4f4e5c3e7cfb6d7af9abc897fa6606761375a7e5999c185cfe49fdbf7e0ece1c9b9d7928cc75876944c90603b66'},
	{name = 'colorbase 32', val = '70c6aa3784932c476625273c1934252f6333379e6079d683fcfcf4aad1506a99354d5c1d31320f4327186d4324a0703fddb274e9ba53c06e3184411b5c1c279e3329dc5b45f79b8fbc5b807e35664020400a0a09282a2b4a434a76756db6aea8'},
	{name = 'colordome-32', val = '0d0b0dfff8e1c8b89f987a686749493a39416b6f72adb9b8add9b76eb39d30555b1a1e2d284e43467e3e93ab52f2cf5cec773db835307220302817216d2944c85257ec9983dbaf77b77854833e3550282f65432f7e6d376ebe70b75834d55c4d'},
	{name = 'Colorpop-32', val = '050413191d2829265036344a34378d496bbe59a5dd6cdde1fffee0a9bbbc8e93986d72704a505640747066966999be7cced36ff3dd96f0b996dc9b57b3927c987e59c86d4595635067453643281d70253098353580489cb34c6cd56caef2a5d3'},
	{name = 'CPC Boy', val = '0000001b1b653535c9661e255533617f35c9bc3535c0466edf6d9b1b651b1b6e831e79e5795f1b8080809194dfc97f35e39b8df878f835af3535b78f35c1d77fc935adc8aa8de1c7e1c643e4dd9affffffeeeae0acb56b7684483f503f243137'},
	{name = 'Cubicle32 Sticker', val = '1a15174f53549ba4a3ffffffbb0028e80024f54413f56706f5a502f4d200f5f514f7ffb000683100895c50a4382ff5150500740044950077b9008cce410d60381ba07273b2a78bbbe20164f52686ec9db5987b00b0a14248230bc4690cf5803d'},
	{name = 'DarkVania', val = '120e2f1b1b522933775670c2cfe8ffaabfe09b9ed24d3c661d102338173c4e0b3c66123bad4557c9757eebb1aeffdcd6ecb78ccb9367b8814f77491e572b16360c017b2f11d6761cf69d18ffd21cc7fba17ec177519a5733694a265448102f2e'},
	{name = 'DawnBringer 32', val = '00000022203445283c6639318f563bdf7126d9a066eec39afbf23699e5506abe3037946e4b692f524b24323c393f3f743060825b6ee1639bff5fcde4cbdbfcffffff9badb7847e87696a6a59565276428aac3232d95763d77bba8f974a8a6f30'},
	{name = 'Delete', val = 'ffcdc6fa9788f37952b46e85613c5276b8e1436586223d53191e2c71c19246906f36764e1a4414d8e1979a9b4e7c7d23ffffffd3dad88592925f6966343f3fded7ceb3a59377614e4c382cf5e890ffaa66d17b479c4134532826261619000000'},
	{name = 'Discord32', val = '390c13a0041edd2e44ea596ef2b183d38b75c1694f952b0b3c13077f4d04f4900cffcc4dffdba76fcf8d0eb5401a7d290c3439313f7c5865f29cabdfe6e7e89f81cd744eaa53437431373d7c868d99aab5d7dee5ffffff8ccaf77289da5864b7'},
	{name = 'downgraded 32', val = '7b334ca14d55c77369e3a084f2cb9bd37b86af5d8b8040855b33744120515c486a887d8db8b4b2dcdac9ffffe0b6f5db89d9d972b6cf5c8ba84e667946496944355d3d003d621748942c4bc7424fe06b51f2a561fcef8db1d48080b878658d78'},
	{name = 'Dralette', val = '1312131b1b1b2726273c3c3c5c5d5d848584b4b4b5fffeff0c405701719c01abc56fddd5792348a83e88d162c8ec94ea891f2bc52530ea323df780876e241cc1460fee8201ffc52c1a7a3e15a12e59c0359dda438b4937bf6f4be69d68f7cb9f'},
	{name = 'EG32', val = '510500901c00c6420cd47d39deb669e9dbb8bdc06085a526497d00214600417f60b6e3c586d1ba63a4b841629e2b3588141d656c2283a2367dc96094d5cdc7adaa9e8d81805d5c5535383b261a166727138d4226b46f3dde9a6affc08ffff8e0'},
	{name = 'Endesga 32', val = 'be4a2fd77643ead4aae4a672b86f50733e393e2731a22633e43b44f77622feae34fee76163c74d3e8948265c42193c3e124e890099db2ce8f5ffffffc0cbdc8b9bb45a69883a4466262b44181425ff004468386cb55088f6757ae8b796c28569'},
	{name = 'ENON-32', val = '000000ffffff111122331133551133881133cc1133ff1133222233665566aa8899ddcccc553344aa6666ddaa99ffddcc22444422775522bb5522ee55aa4444dd7744eeaa44ffdd442233552255882288bb22ccee441166771177bb1188ff1199'},
	{name = 'environmental station alpha', val = '15181f2931414e5a949183d73e76882b87705f9dd183c8e53038244b5c1c5c8339a5b13f503f2490673ec29e46ede2854219107a3f2a82261ce5533b682e4cd9396aa46badeb91ca242424737373c3c3c3ffffff080808e499506dcb43abc08c'},
	{name = 'Evening32', val = '1b0d1f231f5f2c329f356ee251a6ee7fc1dcaeddcaf5f5cefcb2bfe284a1c756849a212d6c1b2b3d152a733531a85639cb8a51eebe68f1d99bddab6bc97e3bb14f34344233537058729f7cacaa5fe6b543ac753a59404b826b75ab96a0d2c8b8'},
	{name = 'Fancade32-Secret Palette', val = 'eea5a2cb75899c5a64ffffffffe7cfffc3b4c098ff997aea715badffcbfcffa4e0ff7bbaffaaaaff5173ce3b56ffb98eff7b5bd75947ffff86ffeb00f6b900c2ff7648d05500935278cfff009aff0075edced0d89c9ead6d6f7e4444531f1f29'},
	{name = 'Fancade32', val = 'e39191bc6479924d59ffeaeaffc9b7f8aa9ead83ff8768d9654ea2ffb5ecff8dccdf67a1ff9494ff4a68bb3049ffa279ff674ac84a39ffff70ffc900e8a100adff613bbf4600864800b5ff008fff0066dbffffffaaadbf63657e3d3d521c1c28'},
	{name = 'fantasy_', val = 'ede4dabfb8b4918d8d636167353540a94949ca5954e56f4be39347eeb551e8c65bbda3518b9150557d554463503e554c8bb0ad769fa6668da95c699f5a58887c6da2947a9dbc87a5d9a6a6d4c2b6bdaa9786735b7e674c735b42604b3d4d3f38'},
	{name = 'Final32', val = '110e1a281c43511b648f2782cc5196ff9aadffddb2eb8357b0302c6e233b3b1f2b612f38a1483bcf8557f5d745b5f15054c22d2c85531f55591b28424c536e8192a1b6ccd1f9fee7ffadf59f5bbe48328920204f28377533619e5aa5c77fefef'},
	{name = 'fractals die die die!!!', val = '0000001a212a362a414e474a6a6b7dba9baaffffff6dcd8c3f8f4a36561521301b271b023535096c4e208a871eddd259e1ae6ab86d30793d1e4a25113c0b1a5f1a389d2f2fcb624ef58f95b9538364395f795c9784b2e92c7ca03048621c343a'},
	{name = 'GNOME 32', val = 'eae8e3bab5ab807d74565248c5d2c883a67f5d7555445632e0b6afc1665a884631663822ada7c8887fa3625b814940669db8d27590ae4b6983314e6cefe0cde0c39eb39169826647df421e990000eed680d1940c46a046267726ffffff000000'},
	{name = 'GoldenStar 32', val = 'ffffffb2c7ab81677f2a1f427e3568c05770f5a67dcd4d3b8b2f3b5426372d1b2911151a4e344c775266a8867fded4a3d0d8507e833e5b55463b383d231f2cf1bf59b96234863b36562f359e5132d9995aeed492cbd38d848465574a4f392d38'},
	{name = 'Greenstar32', val = '312e2f635c5a81776bc6b5a5ffedd496567aca709160434f884f5eaf6567bb7979c37c6bdd997ee9b58cc68b5b8c594a5e443fe1ad56f8cf8eefdc76cebe559d9f3772792b515e2e45644f508657bbd18a5b546c6a71897a949c80aba4aed7b9'},
	{name = 'Grim32', val = '0816110f1e1d1626272134342c413c3e4e47515f4f6168545056414749323d3b2634311f231f13342d20453a2d56473a6c584d8670696c5e615f4c5352414a382b342319212e2430362f3d403c494a48565253636668754e57633e4852222b34'},
	{name = 'Heathcliff', val = 'fffffffdfdf7ebecece8e9e5d3d3cecbcfcfd4ece4cdd4b4b2b2b2a3cad7bdccaaaabeb494bcc4babd97a6aabcc0d698d9a6bbc7a3b0c4cc7cab919ddbb851819097e4bc49b2976481798d8d81487f794e3779afa46464b3302f2c3438000000'},
	{name = 'hept32', val = '000000180d2f353658686b728b97b6c5cddbffffff5ee9e92890dc1831a7053239005f4108b23b47f641e8ff75fbbe82de9751b668318a4926461c141e090d720d0d813704da2424ef6e10ecab11ece910f78d8df94e6dc124588412523d083b'},
	{name = 'HWBasic-32', val = 'fff7f5f9ded1f1b3a3ab716bf6dbbff2b095d7bca1c0957c825e4c4739332d252326445253a691adc16f5596442a6222cdc9d9ffffffd9e2eb738aa24d677e243b50f47e35a84c0cadb3b98a8d9256616b303539d83a2c91251c50201e422e2e'},
	{name = 'Hybrid32', val = '101b212e2a35645964979ea8c0c7b7e4edf5ffffffe5df52c2c2376aba3b3b8f5b526626376129335a5c29629138c2d65095e6565299353456613755903d62955b8dd467a2f21e44a83135ec6b24edce9fdd9c68d96f67ae62539d5a33593339'},
	{name = 'Jehkoba32', val = '00000000021c1c284d3434732d52804d7a997497a6a3ccd9f0edd8732866a6216ed94c87d9214ff25565f27961993649b36159f09c60b38f24b3b324f7c93e17735f11995567b31b1ba68347cca996e3c92469b30b8be60bafe6f28d85f0bb90'},
	{name = 'juice32', val = '330e22662435994c4ccc897cffccb5e57239b235357f184b3d063d07000e4f1f1b874d36d89d61ffc759ffeb8cb2d66050b247257c491054480a3947121d353847666b7a99b8c5d8fffff291e0cc3582823e6ab21928665b3582a5528bd37484'},
	{name = 'Kirb32', val = '0d03053c34446e576e917d9bc5b7cbf7f4e85f4f47851246d720487d322f9d4c2fc65e2df96a2dffa300e29138f7c233f9ec4111442c287a3352b1398ae9310e131e203c622a69b000a1de6bdad5a52eb8f7406efc83a2f9cf9dfba176f66f67'},
	{name = 'Koni32', val = '0000000b0a0d1615242226402b405730656634a87049f25aa4ff63fff240f2a53fcc7a47f54025a63a3a9953487337584d2a4946346a8c2eb8f261daffa8d4b3dfff70a5fa407cff1f50cc213ea6272f664145586d7078898b8cbbbdbfffffff'},
	{name = 'Le/Place', val = '40002b990033ff4500ff9000ffd635fff8b8aff25700b36800806400485200778000ccc091fff8358de62446a4312680493fb08e68d9e4abffb44ac0721b8cba0d8bff5392ffbfbfffffffd4d7d9898d905152520000005c39219c6926ffb470'},
	{name = 'LEXIP-32', val = '1712193a393b9e9e9ec7c7c7edefe32317592e2c9e3e59b85ea0ce74ccde154334296d433c62585ca89053c06d82d46e66173b9a1a52b33250d75a54e9986e865e2bbe8433d0c252723080a13fb5c457acde8fa6e3b0bb7d2415a35f49e0b287'},
	{name = 'Losing is Fun', val = 'c49088a462569a534682463c68342ea63737c83939d718181f0f0f39271d4b3b306d6b659e978fd1beaec09469a46721cc9629cdaa656e733b55673539592e3349312d38354e727877cbc93f57703b49554c32686e4c93845d69c7653bffffff'},
	{name = 'Lospec CDI', val = '1010102226355b60798a90abb9c0dbfffffff8c67beb17175b2222af5211ebc388fee5d399b5780f96500f4d3f051a1a1d1e4a2a46af4c7fb181a9c7a56e8f723e72242348111327ad5806f1d42beafa6adeffc1c39d66ae51107b330e49160a'},
	{name = 'lxj-32', val = 'fffffffbffd6f4ff75f5d868f5c356f8b242f296067cb2d36281c24548ae502fbb4122a9a53636882a2a7824246221219156aa6a387e552766431f518d62307657347b6a5c6b5e51544a443f3938332f2e5e685c3a4537262e251d221c121412'},
	{name = 'MaoMaoYT\'s Doodle', val = '3100416f0286ff2b5effa804fcff9222ff5b5f86d5523b7318355322578db0d7ff22ccccfeda68e94963a83f5d532a48351232772d46cc4452e4b79af7e4acdbd7a8fca19eff3c7e5a294918183a9f1793f43c7cffb39bffe0a9eef6639dec5f'},
	{name = 'Marblelous', val = 'ffffffbbcceeaabbdd99aaff7799aa668899557777666677556677335566334455333344222222000000550022773333995544bb8877ddbbaaffff00ff9900cc6600dd000088000000886655aa9977ccbb2266ff2244cc332299222266222255'},
	{name = 'MarshMellow32', val = '2b3f413a535657797d8ca6973f3e20555735767f45a4ab795932347341418c504db87a66c1bcacafa491907b6771554a3c3c3c544a44a1623bb68241e2b55fb2b2b27c7c7c4b50533c3a3f4e3c5c6e4d7e8f619a20415b235b7c2d80a65eb3bc'},
	{name = 'MegaBall', val = 'f0f0f0c0d0f0a0a0f08080c0606090404060202030000000d0f080b0f00090c000609000b040f09000f07000c06000a0f070b0f00080a0005050003070b0f00080f00050b00030700000f0f0f080f0f000f0a000f05000f00000900000400000'},
	{name = 'MiniMax-32', val = 'faffffc1d7db697d8e38435f262245130e2634ddda2c9cd57781ff494fe1213fbe0d2487e33d989822a8e53a4a8f1157eb822bb02b36ffe570f9a13565ef42118c60a8c4af698e86325555162527e3b175b6683c8a3e1b491816ffd5bcf5a59f'},
	{name = 'Morning 32', val = 'fff7b9f1cea0da9f8a9d6e686b4c5244323a7f3c4ccb4251f37a2effbe34fffd4db5e82a53b8252b8d381f5e3f1f413718191f3137484b596f728697bcd1d9fcfefe8feeee67c9e74e95d7436ca53c48792c2b48643e8ba34ea7e988cfffcae1'},
	{name = 'Mr. Cool Juicy fruit', val = '0000002816193f151c87161da03312e3640af39f12dea44e97a937618629536d4e17292114162c23294334495b54739465686e8c8787aba5a5a6937a6d69547c746f6a5854544f4e3a302c534a3585543d996d4dd58869f0ba7edfd0b9ffffff'},
	{name = 'mulfok32', val = '5ba6756bc96cabdd64fcef8dffb879ea6262cc425ea32858751756390947611851873555a6555fc97373f2ae99ffc3f2ee8fcbd46eb3873e841f102a4a30527b5480a6859fd9bdc8ffffffaee2ff8db7ff6d80fa8465ec834dc47d2da04e187c'},
	{name = 'Multa 32', val = '240b284f4359736675b19fb5d4c9d6fff4f74f1f42822050a81a4add3e3eea786bf9ae8e962800c15a00ff9900ffd026ffe7a53531683a56874782997cc4cc95dde513544835805b5ca0588dbf6eb1ce908b20a0ba32bae552cfed80b8f7a8c2'},
	{name = 'Nanner 32', val = '6074ab6b9acf8bbde6aae0f3c8ededfaffe0dde6e0b4bec2949da87a7a995b52804e3161421e426124477a375796485bbd6868d18b79dbac8ce6cfa1e7ebbcb2dba087c29370a18f637c8fb56e75c98f8fdfb6aeedd5cabd71829e5476753c6a'},
	{name = 'Nanner Pancakes', val = 'a0ddd36fb0b7577f9d4a57863e3b663929452d1e2f452e3f5d45507b62689c807ec3a79cdbc9b4fcecd1aad79564b0824888853f5b74ebc8a7d3a084b87e6c8f52526a3948c57f79ab597d7c3d644e2b457a3b4fa94b54d8725ef09f71f7cf91'},
	{name = 'Neutral-32', val = 'fffcd9f5e48ae0bfa3d4a054c78a84ad6f4f9c647c84443e65251f3c1d14210c05101e3e52375a3063824e77a27d90bd8ab1f3b1d5fbcdf2ffa9c3a08ba761627b5239523a213c214a3729614c3d63646777705d777c8a9884749ca0a9adb8ca'},
	{name = 'Nvidia Gaugan', val = '9ceedd5e5bc59364c89999007f45027c32c87064199600b18696647d3054ae29748f2a916e6e287ec86487716f6969699ac6daaad16ab0c1c3946e288b302777ba1d9564329e9eaaa1a1647bc800b1c8ff760000b57b00a2a3eb606e32a8c832'},
	{name = 'Optimism', val = 'fff9c9ffe482f5aa21f2bf85e68d4ff56037ed39157b3526580f0bab6c5c684c3c46322025170bd98b90b8486963335f422f4a222038c1d6d65bcad90383bf153f9400a1932d70743c5457183f39446927929e0ac4be12a58c27705d1f8f7759'},
	{name = 'Orbitron 32', val = 'cce3e1a3bab8859899647982505966363a42212429110f1f2f1d422f3675365680538abd78c2db82eff5c4fffffffffffcff5ca4eb8455c281408a9175265cab3057ed2139ff6052ff8636fab941f0d787cfa25db0734a8f4d34803636592444'},
	{name = 'paint.net base colors', val = '000000404040808080ffffff7f0000ff00007f3300ff6a007f6a00ffd8005b7f00b6ff00267f004cff00007f0e00ff21007f4600ff90007f7f00ffff004a7f0094ff00137f0026ff21007f4800ff57007fb200ff7f006eff00dc7f0037ff006e'},
	{name = 'pastel', val = 'ffefe3ffd0b6efab88d1f2f7adcad088adb3feddfad6afceb480aeffeae9ffc3c3ec8c8dffffebfbfbc7dbda99d2fafcb7effc5bb2c5c7e06f9dc12e799223eb6052dd3e029b2c1defead5b3b4ad232620a439388d31338f28004a63731a303f'},
	{name = 'Phi-32', val = '201f23382f536b6188a597cbece6fcfefdfff5b79eeb8b64be5b32973a15971585c8129ee92681ff4763ffaf22ffde4b99ff4b50f19808b7570793460c823c1f8db92eb1e620bfff87ddff87a8ff4a75e60132b3152c681201644701646b1391'},
	{name = 'PICO-8 Secret Palette', val = '0000001d2b537e2553008751ab52365f574fc2c3c7fff1e8ff004dffa300ffec2700e43629adff83769cff77a8ffccaa291814111d35422136125359742f2949333ba28879f3ef7dbe1250ff6c24a8e72e00b543065ab5754665ff6e59ff9d81'},
	{name = 'Picotron (WIP v3)', val = '0000001d2b537e2553008751ab52365f574fc2c3c7fff1e8ff004dffa300ffec2700e43629adff83769cff77a8ffccaa672d8a0a62be422136125359742f29d48e6fa28879fff57dbe1226ff6c24a8f12e00b25183ebf5bd9adfb937b8ffacc5'},
	{name = 'Picotron (WIP v4)', val = '0000007e2553c3002eff004dff6600ffa300ffec27ffff7da7f73500e43600b2510087511253591d2b530a62be29adff83ebf5fff1e8ffccaad48e6fab5236742f294221365f347edb37b8ff77a8ffacc5bd9adf83769c5f574fa28879c2c3c7'},
	{name = 'Pineapple 32', val = '43002a890027d9243cff6157ffb762c76e4673392e34111f030710273b2d4582399cb93bffd832ff823bd1401f7c191a310c1b833f34eb9c6effdaacffffe4bfc3c66d8a8d293b49041528033e5e1c92a777d6c1ffe0dcff88a9c03b94601761'},
	{name = 'Pix Brix - Official Brick Colours', val = 'b92024ed1e24f2614ef25624f57828faa32ffdd009fbed1bf2ed4b0a804847b8688fc74019479516b0e27ad1ec603a97966caed3b5d7e376aff6a6c9fac8d3eab988faddbbfdf3b6683721976039c88e4f575757979797d3d3d3060709ffffff'},
	{name = 'Pix Brix', val = 'f4614dffa52bfffb667fe93f82f0ffe6c4f7ffccd8ff010cff812cfef20013cd6800b5e0ac6edbffa2d1c40001ff5c01fece00007f4408419a641fc8ff60cafff1b6f9dcbaeab887c68b4f965f385e2d1c000000565656969696d8d8d8ffffff'},
	{name = 'PK 32', val = '170d1c312647574e6975728c929fa3b7c7c7f0fffa451a4575203f992f2fbf674ce6bb65fdff6b191e4f2a4d73467394549dbf6dbadb85d5dea8fff830786e51a35b8dc756401d2e57373e914e3ac7885effbd8affe1ba8c5c7fc77394eb9b9b'},
	{name = 'PK32C', val = '0000006f394f944b4bca9067f6f693bedc9c80dbe3e2aacb6127537b304bbc4940f2c1677bd05a62abeee65a8da3a3a3461b4c501d40913853da7e5742b8505a8bdfbd4b5b5454541e16282f1c356d2b5bb737553f8c315066e5aa3b45ffffff'},
	{name = 'poly 32', val = '42343b72615fb4a091f6f5deb3bdb66d767b393b421a151f7d413ca1624ec68b60e5bd85ead074dd9254b4563e8138366a2f56b03b59e06465f29380e981e4b158d369469b3c336a36274b474c805590b481d7cec1dc716bb4533c7253264042'},
	{name = 'Popular32', val = 'fc233e03010654546ea6a7c0fcfdfef9ad92e44a677e144e42083e71142cbb460fe2a255fcdd82f1b162de62068a2606ae6506d8b606efe695b9aa07536a0603402b036e303fb93398d55f8bfddc51cbdd2969a32a0b6c392d9d2b63e270c9fb'},
	{name = 'Prismatica', val = '1b08131c102e32303c595a61919191bdbdbde9e9e96fd3e93e95cb1c47ab12197e151e4a124a430f6c3f259d159fd228fbf135fb981ef55718b516377e0b365008393607363019115738247d5c38bfa363e0d18cfbc2fff780ffee31ebc5179c'},
	{name = 'Proportion-32', val = 'fff268f8ca2bed9f3de1723ec23d4a8919315b0024fc95aae9638daf56a874408d3c246596cdf9638de0464abd63a7b93d898d1f5d54002316003d22115e0b377e1c6b9f2ba0c25af8f7ffafaabd766d7c3532410a0a0d583a41b67965ecc599'},
	{name = 'Punolite Plus Plus', val = '2e2e434a4b5b707b89a9bcbfe6eeedfcfbf3fceba8f5c47ce39764c068529d43438136455422402a152d4f2d4d5b3a56794e6d3e4c7e495f945a78b27396d57fbbdcaaeeead5f89396dc7f6ec0774e93633c6c542c504934404f4059675c8995'},
	{name = 'Pxls Default', val = '000000222222555555888888cdcdcdffffffffd5bcffb783b66d3d77431ffc7510fca80efde817fff491beff4070dd1331a1170b5f35277e6c32b69f88fff324b5fe125cc72629608b2fa8d24ce9ff59efffa9d9ff6474f02523b11206740c00'},
	{name = 'QAOS Compact 32', val = 'ffffffe8e4dc8080807e7567222323000000ff0000d62411c28b5c804000ff8000fc5626ffff00ffb40080ff008080005ccf1340800000ff8055a8948cfbe600c0c089cff00080ff0000ff004080aa00ff8000ffff00ffc00040ffc0cbf8b88b'},
	{name = 'Quentin Tarantinos Color Palette', val = '535f986e76a27c94bd88a2cc4e75ba4a8bde639ee294beedafcfffa0b9e28f7a4db58947cda852e8be5bf5d264414b5a4f5a69706d6581797a83868ff95542e44a35c83b2ca2412483472253361f68482e825a3a8d6a4d9b7e5d001223f8f9dc'},
	{name = 'r/place 2022 32 Colors', val = '6d001abe0039ff4500ffa800ffd635fff8b800a36800cc787eed5600756f009eaa00ccc02450a43690ea51e9f4493ac16a5cff94b3ff811e9fb44ac0e4abffde107fff3881ff99aa6d482f9c6926ffb470000000515252898d90d4d7d9ffffff'},
	{name = 'r/place 2022 Day3', val = '6d001abe0039ff4500ffa800ffd635fff8b800a36800cc787eed5600756f009eaa00ccc02450a43690ea51e9f4493ac16a5cff94b3ff811e9fb44ac0e4abffde107fff3881ff99aa6d482f9c6926ffb470000000515252898d90d4d7d9ffffff'},
	{name = 'Rainbow Plague 32', val = '00000065a942446b2d373e201d1e184e442fa9876ddfaa93dc8678c95b509e35357924242b191d512123913e29cf6d39e4983ceabb53daea769bd75b52c97320ae800a867d1d465623305b1b15264020406b2e46615079888da4abbfcfffffff'},
	{name = 'Ranged Punch', val = '0000001d18165a5a5abcbcbcfcfcfc9cfcf05a91f70070ec24188c0034002873254cdc48f7d8bcfce4a0fc9838c84c0cd82800a400007c08003f241b6431207e4425c8834ffcbcb0fcc4d8fcc4fcf478fcf7725ed0604fb87e6884634e402c00'},
	{name = 'Resurrect 32', val = 'fffffffb6b1de83b3b831c5dc32454f04f78f68181fca790e3c896ab947a966c6c6255653e35460b5e650b8a8f1ebc7391db69fbff86fbb954cd683d9e45397a30456b3e75905ea9a884f3eaaded8fd3ff4d9be64d65b4484a7730e1b98ff8e2'},
	{name = 'RPGVania', val = '3125803b42a1435cde7aa3e6cce7ff9db0cd7679a05744733d21573019395e106c872b59b1385cf09190ffbcb8ffe7cff2cba7e6b183d98d52c7723e9d50193c190478340aac4d00ffa319ffd21cdeffb56ebc514d96553c805127614e143b3a'},
	{name = 'RuziKB 32-color', val = '04003aa60047ff336cffc74cfff395fff7eaf7ff9cb8ff713aff06009714005f9b18d6ff88fdff83e6ff005ef90012843900d5886effe0dbff807dd2504e95810096c63fffef95ffffc5d9d27d97954e684a002fffab63ffe0b2a5ffcf00eaaa'},
	{name = 'RY-32', val = '2f1e45861043b41e40c83737da5a3ad4a864c38e65b16c59944c4c7f37485f253e662c2a8e4f24c6801de5a7329abf44679c3022783f164a45203b68345f994293ca64c3dea6c4bf829fa1687f8852636d3944513f23527d2f7ea83690ce4999'},
	{name = 'Sheltzy32', val = '8cffde45b8b3839740c9ec8546c6571589682c5b6d222a5c566a898babbfcce2e1ffdba5ccac68a36d3e683c3400000038002c663b938b72de9cd8fc5e96dd3953c0800c53c34b91ff94b3bd1f3fec614affa468fff6aeffda70f4b03cffffff'},
	{name = 'Small Sprite Bright 32', val = '1a1a1a4d4d4d999999ccccccffffff46516e858fabb8c0d9403631786654c7b48bfff7c4751e21a30f11d4151fff4050995943f28135ffc96b3b1c70402c993952c46c94f070e5ff6a24a89c45e3c380ffea9efc0a4d2d08905070d038b4e448'},
	{name = 'Softmilk 32', val = '23213dd95b9a9e4491633662903d62bd515ad69a4ef3d040ffe88cf2f2f094e0921f998322636b57546fc5687676747d5c3841945848d17f6beb9f7ff1c28fb9b5c3454194425bbd4884d445a1de7cd8ebe2f266c3d44282aa28597f1e376129'},
	{name = 'Soul32', val = '9e0000c53000ff4600ff8f93754902c26b29ff932bffac75af9200dbaa00ffd800ffd8911855004286004cc900c5ed9d00406e0062a80094ff56c3ff21007f4e00c1b200ffd67fff7f0037cd3a71ff59aa0010104954549ea8a8c5dbdbf4fcfc'},
	{name = 'Star32', val = 'ffffff75cefb4c6ac8282159773198c54daaf78f9fe039408e243f531f372d1b2911151a4838616a689399a9c7cce8ebb0ef4945a346326d552240441a212d562f35863b36b96234f1bf599e5132d9995aeed492a6e5bf52a5932a58661d2d3a'},
	{name = 'Stardust32', val = '000833200261330a80851694d42a6eff5b4fffb366fff673aff04f48d43b1aab872e51c72320ab3f87d954b8e378f0e2b8ffd9ffffe1ffa8bfe681acbd448effdac9eba698cc6e6ea1486980335e521d452b174454508a6f75a691a2c2cadbe8'},
	{name = 'Sunny Meadow 32', val = '00000040414d696e80a3b4ccffffff36a3d9173899210a662602404b0459802671b35181cc7078d99f82e6b85ccc7333a64319991717731d0c5927167344178c6631b39c5993a6323b801a09591026402f33806039bfa9ccb4a38076694d4a40'},
	{name = 'Survival Horror 32', val = 'cea19d9e636371353f4f1b30380e27c9cb9fa99a73805947623333471f1f95bf91679a7341745a20494b0f293596a5bc6f779e514a78402c56351740b29cc3a278ad8b50846930545a2033b7c0c78c929e5c6174403e522d2738ffffff000000'},
	{name = 'Sweet Canyon 32', val = '0f0e112d2c3351545c7c8389a8b2b6eeebe0eec99fe1a17ecc95629a643a783a29541d29782349a93e89d062c8ec94ea64e7e72fb6c325739d2145741014453c0d3b901f3dbb3030ec6a45fb9b41f0c04cfffb7697d9486fba3b229443116548'},
	{name = 'Tempoppy Witchy Muted', val = '0d0c132c294da843d0e37ae0f0ccd6fff5f820131b391928702938cc3845de6868462e1b93482edf76347a671fd5d220e6e25b25655f3ebf4475d85aa9efce4bd293374b952f7dd049c7e42224213337376474749faea6d1875cf0cba8f8eeb9'},
	{name = 'The Lospec Snackbar', val = '0b24580c5c6712916b27e931fff34ff6c23be97b21d44b49a218395d093a3e03467d1475ba2e89f481b0eeb8b49756c72c226e11073a2424af4b7cdb6acaf486ffedfff7e9ffd8a5dd9c607523144b050a2c000835281f3c3c3c7f7f7fb8a7b9'},
	{name = 'TLP', val = '630d26b52d1bf07508fbc5313e2020853e33ca7538f5b97ddb6e530e353e15694859b32dd3e5491eb6781c6470251e6a214aa70a98d849e3da47125c981e82ee6283f9b2a73e30306d5d5bb0a28defefe97eaea345697528354a110a03ffffff'},
	{name = 'Turd32', val = 'fffed6b0dcd27bb2a27b8d78e99cedee71cef23c85c22346c58e25b256189c2519711919f0d839f9b3517ad6792bd234779c21248d1f2462002c400d1bd2a81f78772b2e0b062a0f2228341a2524131c25050a192f48482636421c396a182446'},
	{name = 'TY - Fictional Computer OS - 32', val = 'ffffffcbc4ba8e9c998b8d5a5c6a5326292114141572cbc6729de03c7e974a5c782f45419edb7ba2aa5468924f305838efc26db68d476165284a4126a98ac687716f6a445a4c3435e08f5ecd6627875c30703a1abf8d77cb593a7d544f682f2f'},
	{name = 'UFO 50', val = 'ffffffa48080feb854e8ea4a58f5b164a4a4cc68e4fe626ec8c8c8e03c32fe700063b31da4f02227badbfe48ded10f4c707070991515ca4a00a3a324008456006ab49600dc8616500000004c00007834508a6042003d102020403400584430ba'},
	{name = 'Vibrant Magic', val = 'ffe3efffabe7f675ffc735f08f19d4b3fff475e3ff3bb4ff1381e80053c7000d990c0c24ffe387ffbd59ff833be6532ed12c349e1e40860038d9ffe9d1fab996f77c4de0481bc43d048f4a24524323305240597a5d82a18eb9d1b4dfeddef7fc'},
	{name = 'Vintage Autumn', val = '000000111010a22512c94d2ee1906449423d81746ab9a697f2d9c550361eb66813c5884583571ee5bd7f9b8039dbcc83b1a13dc5bf3fb4b3a0b7b768747c3753612e314524738c7a4e7664275e4c2e3f3f415c5d567c7d23282a3d1f2962272c'},
	{name = 'Void Train', val = '0d0d0df2efebadc8d9a8bfb06b867a39445939505615403bb1bf93c6d93b93a66a727a58a69c17f2eda0a69d726c6b5b58658c524a59c4b7b8d25c50a73f368c1f1f733f49f2daacf2a74bd9753be5c3798c6046a1816abc9770d9d4ba888c8c'},
	{name = 'Warm32', val = '0d0e1e2f3144626a7394a5aad3dfe1291820694749a56e66cb9670ecd8b728092d692b58804061a1516ae193931e1d3851456984788bbea8bf232d4f3a4b6d65799a99b4dd41648b6fa9c3b9e2e5d3ead80a23252040393e6248778f73b4c3a8'},
	{name = 'WATT32', val = '2426722b59b735aeeb7ed5e9f4e9e9f9d2a8f9b87cd981488d6970654e68190d1439323861636b91979dc4d0d80a34222066243f9c2cb5ce2df9e554fdc11aff7524e9362b94142d540e357f3687bd5596ff827cf9aa8baa4a26741b0b480e04'},
	{name = 'Worms Open Warfare 2', val = '000000fffffeffd721e79742ef30289528085a29105a9efe2851bd0010847bcf5b629e21429629316920284929212921ef61189c51185a5129636943b58e42b5ae63ded7cfb4cfe794b6ce7396b55b718c39495affbe84ef8e73bd60639c494b'},
	{name = 'Xd-pal', val = '2a003342003869003d8f0028c43b00ed8200ffd724fff982ffba26ad6a267d461357280a05073b2d2e525455709a9badfffdedebc8bceb8d8dff5c7feb367ebd009d6f009e2700750057a30c9bcf00e9edb5fff9d9ffa155e65a328c6e005755'},
	{name = 'YEET32', val = '8f0018b80000ff0000ff4100ff6f00ffaa00ffff00ffff9c0400211d1840362554643e7084638fa793ade0dfbfffffd90400443900a44d9aff73f1ff2700425700579e007ed60068004015307800568f009ecf003300065c10068f3114a15b1a'},
	{name = 'Yeetzi 32', val = '160d16fffffff1ebd6d7d5cfaca87d9498557e6d5a6c58704e49443a3a3c342f382321236d1d549e4843b97649dd9d5df7bb50ecdd8c81c9c661b0885e7cb556639c29455e286654559c54b0bd71f1b5dbb58be39969c9782c90a946a4d266a5'},
	{name = 'Zughy 32', val = '472d3c5e36437a444aa05b53bf7958eea160f4cca1b6d53c71aa34397b443c5956302c2e5a53537d7071a0938ecfc6b8dff6f58aebf128ccdf3978a839477839314b5640648e478ccd6093ffaeb6f4b41bf47e1be6482ea93b3b8270944f546b'},
	{name = 'ZyKro-32', val = '000000181a1a3b494f5d6d727a8e9599aab0bfced3ffffff7a07248f091da70a0aca1818de4c35c74c20cc7223e6a029f7ca40f7d87c5814147b402aa76542ca865506402206662539a32a86cc3ec2f5762d0f844044dc4085dc6ec1edbbf5ff'}
}

preset_palettes = {
	-- GrafxKid
	['Sweetie 16'] = '1a1c2c5d275db13e53ef7d57ffcd75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57',
	['PICO-8'] = '0000001d2b537e255383769cab5236008751ff004d5f574fff77a8ffa300c2c3c700e436ffccaa29adffffec27fff1e8',

	-- PureAbestos
	['PICO-DB'] = '1209191b1f4b592942106836854a2f4d4b44a4b2bfdeeed6d04648ed8f3bebd95161ad365190c8776e87e384a2e5bba7',
	['Eroge Copper'] = '0d080d4f2b24825b31c59154f0bd77fbdf9bfff9e4bebbb27bb24e74adbb4180a032535f2a23497d3840c16c5be89973',

	-- CopheeMoth
	['Lost Century'] = 'd1b187c77b58ae5d4079444a4b3d44ba91589274414d453977743bb3a555d2c9a58caba14b726e574852847875ab9b8e',
	['Fading 16'] = 'ddcf99cca87bb97a609c524e7742514b3d444e54635b7d738e9f7d6453558c7c79a99c8d7d7b62aaa25d846d59a88a5e',

	-- Slynyrd
	['Steam Lords'] = '213b253a604a4f7754a19f7c77744f775c4f603b3a3b2137170e192f213b433a604f527765738c7c94a1a0b9bac0d1cc',

	-- Naurus
	['NA16'] = '8c8fae5845633e21379a6348d79b7df5edbac0c741647d34e4943a9d303bd2647170377f7ec4c134859d17434b1f0e1c',

	-- Space Sandwich
	['Vanilla Milkshake'] = '28282e6c5671d9c8bff98284b0a9e4accce4b3e3dafeaae487a889b0eb93e9f59dffe6c6dea38bffc384fff7a0fff7e4',
	['System Mini 16'] = '00000068605cb0b0b8fcfcfc1c38ac7070fca82814fc484820880070f828b82cd0fc74ecac581cf8a8503cd4e4f8ec20',
	['Combi 16'] = '060310252bc57c3d135351559c2f9b239725d84b372d9f628272ecbf8321ed629477d0515ed6eab7ba9de5e052ffffff',

	-- Kerrie Lake
	['Island Joy 16'] = 'ffffff6df7c111adc1606c813934571e88755bb361a1e55af7e476f99252cb4d686a3771c92464f48cb6f7b69e9b9c82',
	['Peachy Pop 16'] = 'fdffffff8686fb4771ce186a8f0b5f53034bad6dea9fb9ff567feb0a547b278c7f0ce7a7acfcadffec6dffa763ff4040',

	--ENDESGA
	['Endesga 16'] = 'e4a672b86f50743f393f28329e2835e53b44fb922bffe76263c64d327345193d3f4f6781afbfd2ffffff2ce8f40484d1',
	['Endesga Soft 16'] = 'fefed7dbbc96ddac46c25940683d649c665988434f4d2831a9aba366686951b1ca1773b8639f5b376e49323441161323',
	['ARQ16'] = 'ffffffffd19daeb5bd4d80c9e93841100820511e43054494f1892d823e2cffa9a95ae150ffe9477d3ebfeb6c821e8a4c',

	-- PineappleOnPizza
	['Bubblegum 16'] = '16171a7f0622d62411ff8426ffd100fafdffff80a4ff267494216a43006723497568aed4bfff3c10d275007899002859',
	['Taffy 16'] = '2225336275baa3c0e6fafffcffab7bff6c7adc435b3f48c2448de72bdb72a7f547ffeb33f58931db4b3da63d5736354d',

	-- Rhoq
	['Galaxy Flame'] = '699fad3a708e2b454f111215151d1a1d3230314e3f4f5d429a9f87ede6cbf5d893e8b26fb6834c704d2b40231e151015',
	['Triton 16'] = '0000002b223247375998879f2324335f6f87829eb393abc21a21204248495e7173c3b3c8866273a2878ab09ea0daced3',

	-- Joao Vasconcelos
	['Cretaceous-16'] = '313432323e42454b4b3a5f3b7c4545675239625055516b43796c647182459e805c998579ac9086a6a296b4ab8fbcb7a5',

	-- ILTA
	['Antiquity16'] = '2020202d211e4529236d3d29b16b4ae89f6ee8be825d75578e9257707b888aa7ace55d4df1866cd26730de9a28e8d8a5',

	-- DawnBringer
	['Dawnbringer 16'] = '140c1c44243430346d4e4a4e854c30346524d04648757161597dced27d2c8595a16daa2cd2aa996dc2cadad45edeeed6',

	-- Zackie Photon
	['Go-Line'] = '43006794216aff004dff8426ffdd3450e1123fa66f3659870000000033ff29adff00ffccfff1e8c2c3c7ab52365f574f',

	-- keidding
	['Summers Past-16'] = '3200115f3a60876672b7a39dece8c26db7c35e80b26270578da24ed2cb3ef7d554e8bf92e78c5bc66f5ec33846933942',

	-- Shidoengie
	['Shido Cyberneon'] = '00033c005260009d4a0aff52003884008ac500f7ffff5cffac29ce600088b10585ff004e2a2e794e6ea8add4faffffff',

	-- Eclipse89
	['Forest-16'] = '64988e3d70850f2c2e3456446b7f5cb0b17ce1c584c89660ad5f52913636692f1189542f796e63a17d5eb4a18fecddba',
	['Satellite Sky'] = '87d6ff87b3ff8791ff7d84d2875dbd414ccc0b147c040a481c2798333c9f5058b2747ab69f88cbcc8ce0ee97e7ffa5cf',

	-- Afterimage
	['Nanner Jam'] = '352b40653d48933f45b25e46cc925edacb80f0e9c976c379508d76535c897b99c899d4e6be7979d8b1a17d6e6ec2b5a9',
	['Nanner 16'] = '7acccc627db3554080592858804055b37d62ccc97a70b36240806a274457cccccc999491665c5f332b33804e464d2a2a',

	-- BlackedIRL
	['16 Bital'] = '212b5e636fb2adc4ffffffffffccd7ff7fbd872450e52d40ef604affd87700cc8b005a75513ae819baff7731a5b97cff',
	['Pastel Horizon'] = '53437fa89fccffffffffd9e8ff9bb69968e2be9bff7fceff6d81ff2c6f9900bcaac48f9e8e586fff5470ff9b71ffd9ae',

	-- Punoli
	['Punolite'] = '64c2240fa10d0979380b64570a50580a41580a2e58091837281961552067702763863453a14b4bb67a5bc8a26ee1d483',

	-- polyphrog
	['Colorquest-16'] = '99d4aa498e86324859437a4d7dbe58eadb77dc8254c13d3761363db06163e6af89fff9e5c1a68c8b69620d0b0d9d5745',
	['Retrobubble'] = '9dc1c0525b80312139120e1f28464662ab4695533d6a2435654147fff169d7793fab32299e8f84fffacee0b56df68b69',
	['Magicolor 16'] = '1d18194826322736354d3d2f933633316436825c3ab95358c77331617a6f7fa533ca9864afaa947dcfa8e7dc58f7f6db',
	['Mystic-16'] = '160d1331293e4d666095b666ef9e4ead403056212a904b41a699985f575e8eb89ef6f2c3e79b7c9b4c63432142d1935f',
	['Retro_Cal'] = '2e1b374e53a27394bae6e1cc28524e3a7e4c7da446edd15a4b1d458c315dcf4f4ff6788d6a5154a45a41d87e46b49a8d',
	['Cartoon Army'] = '20161637403b4d6a8993aae2975cac5b2a4de53d63f8a095ffffffc1bfbe7d707b822525b07032e6c369728933aade6e',
	['Colorquest (Retro Recolor)'] = '95cecd4c898b0e3e5b15894c95ce56eeee77f7a046d64b335a340eb05670ffad93ffffffacaaac626562000000ad601a',
	['Cottonville'] = '8342003232132b6c21888d0dffc249da6d00a228006400000000001d1d67264bab409e9ea6da97ffffff9191aa555555',
	['Prospec_cal'] = '1b0f284c668483bfcaf4f9e6233e38357b458ab954f2e05a3120396e2745c6434ee7937e5442429e523be985498d8878',
	['Invert Compatible'] = '234eaf11abbc72dfb556a22f0b6a591d1f266142246e6f6291909d9ebddbe2e0d9f495a6a95dd08d204aee5443dcb150',
	['Ramp-Rainbow'] = 'c64d43633324b16b33e7b8606482281343320c0c145f2b449c4c91e79299f7f9f05bceb9427a9e3432657a6b79b3a3b1',
	['Pastel-16'] = 'ea7286eab281e3e19fa9c4845d937b58525aa07ca7f4a4bff5d1b6eeede3d6cec2a2a6a9777f8fa3b2d2bfded8bf796d',

	-- Rustocrat
	['Urbex 16'] = 'cbd1be8f938952534c26201de0a46e91a47a5d76434d533aa931307a13388346649176921607125930843870be579fb4',

	-- mingapur
	['Parchment & Ink'] = 'f1e2bee6d1a1f0d696caac77a58a62886243c0977a944431d2bc76ad9d62887c56594a45a9a99487867a445162000000',

	-- Gormie
	['Flowers'] = '6138328b5851bf8f75ffdeb2ffa5a5ff8db5b87ca48560825a4a6073628b887fce8cc1d48bf0c478bab45273782f4447',
	['Autumn'] = 'ec6f1cb4522e7a3030f6ae3cfbdb7aeafba3e3f6d59ce77f49d8664087612d46473454523a878b3da4db95c5f2cacff9',

	-- Yousurname
	['Daylight 16'] = 'f2d3ace7a76cc28462905b54513a3d7a6977878c87b5c69a272223606b31b19e3ff8c65cd58b399963366a422cb55b39',
	['Bloom 16'] = 'ff9072ffc567fce39af7f7c7afe48d61d86829ab7d2b75b700408f092867110f3e371a776f2a8fab2aa3d64d9aff718c',
	['Melody 16'] = 'c686ca7853a73c3e665d91d89dddf0eff5f5a3b0bb676b8b23232e4d33478e516ace6374f4ae70f1de826fc4533d8367',
	['Shine 16'] = '9de4e45d9ddd070760612f93bf66bffdefffb99cd4784a5f2b000049132fbe3131efa65decec7797d9542d892d153f2f',

	-- Tellurium_
	['Oxygen 16'] = 'f9fff2f5d6786be0bfbab19796d45bf56c77e0864a59909e5794609e48916e6660505273ab3737693c363a363d202026',

	-- Star
	['Cthulhu 16'] = '1d2531a5e5c5f0fafd52a5932b62671e303a3b4251527b927dc1c1c7fff3b8cbd87e8da18fa990e5debbcea061854731',
	['Europe 16'] = 'ffffff75ceea317ad72837851a1b352e354e4f6678a4bcc2ecf86094d4463b785020322e512031a43e4bdc7d5ef0cc90',

	-- Anubi
	['ANB16'] = '0a080d697594dfe9f5f7aaa8d4689a782c96e83562f2825cffc76e88c44d3f9e593734614854a87199d99e52524d2536',
	['Rampy16'] = '252945515369848fa1d9d9cca13567e067677d309cbd46b74e4cc75d74cf7994d479bee063b04fa7d950d4996ad9cf91',

	-- SoundsDotZip
	['Muddygrass16'] = '100a0a333025585e53a5a589eae5d1dec66697ab50516b3825150f5227329c323cc4663de48d806392af2c3c6a2c1d34',
	['Graveyard Mist'] = '0b0d0a383730665f5782857bb1b8a9dee6b895bdb25a7b85273245477a5a81ba78d4ea92b597668f545066403c40292f',
	['BitterSweet16'] = '1e1818534c5697978ededcd37ec0c2416f8a3f355b7d3b55b14852be8162d4a09de1be8897b668568f73685d45543734',

	-- JRiggles
	['Outrunner 16'] = '4d004c8f0076c70083f50078ff4764ff9393ffd5ccfff3f000022100076900228f0050c7008bf500bbff47edff93fff8',

	-- Ricardo Juchem
	['Darkseed 16'] = '000000001418002024002c38143444443444583c486c4c448060586c706c888078a49484c4ac9cd8b0a8ecd4d0fcfcfc',

	-- Bloe
	['Soul of the Sea'] = '92503f703a2856452b403521cfbc9594957681784d605f337a7e6793a39951675a2f4845425961467e7301141a203633',

	-- Adigun A. Polack
	['AAP-16'] = '070708332222774433cc8855993311dd7711ffdd55ffff3355aa4411552244eebb3388dd5544aa555577aabbbbffffff',
	['SIMPLEJPC-16'] = '050403221f315435169b6e2de1b047f5ee9bfefefe8be1e07cc264678fcb316f23404a68a14d3fa568d49a93b7ea9182',

	-- Isa
	['Versatile 16'] = '0c0b0faf3f525f39592e2937905c9ad78d4293593b8d92acd47fb0dddd5075b5464a6db2f3cb94eff0e9a7d6da56a1c8',
	['Soldier 16'] = 'fffddaf1d29eb58c6e6b4a413b2422665953a39d77ebdc6cd9903da7512d6b27273b1b23170f0d1e2f2751634d9dba6c',
	['Murky 16'] = '00000008457e8e7ecafdb0f75996bc97e7ec6a23376275437b6d55b5a863bd3b56ed8f879f5a49cfa37defdbb7ffffff',
	['Lump 16'] = '00000020123b451c33a8274bed7332fff167ffffd97defff2dd6602c7cc73030a13813788c2da6f57fc6ffd7a8c8765c',

	-- Creepy Cute Games
	['Corruption-16'] = 'e1d8cbc3b197a68a64614f38362c2082998f525e5a3a40402223260a0d0a20331f495840888f72c7c7a5de8d7d833121',

	-- Space-AgeWrangler
	['Aragon16'] = 'f9f8ddd2e291a8d4559cab6c5c8d583b473c8b889354555ce0bf7aba9572876661272120b7c4d08daad69197b66b72d4',

	-- Ruchary
	['RGR-PROTO16'] = 'fff9b3b9c5cc4774b3144b668fb3472e994ef29066e65050707d7c293c40170b1a0a010d570932871e2effbf40cc1424',

	-- Jonk Make Game
	['Jonk 16'] = '242e36455951798766b7bca2d6d6d6f4f0ea6988a1a1b0be595b7c95819dc9a5a9f4dec2704f4fb7635be39669ebc790',

	-- jumbledFox
	['Sulu'] = 'ee70b5eeb570b5ee7070eeb570b5eeb570eebabad3474751ffbcecffecbcecffbcbcffecbcecffecbcffe3e3f28e8ea3',

	-- skeddles
	['Skedd16'] = '8c1e2cdc443cff8c66c75b38d66f24e4ba3221913b83b535ebd5bd66c3d9387cee3539a2998da2594e6f2b1a4b08050e',

	-- Retromantis
	['FeelTheSun'] = '000000291a13724c30b68c56fff0a0463007755a0bab811d5e260ea1430fff8b18f6bf3a5520129a361eeb5731ee9852',

	-- Durk
	['Trixbit'] = '0f0d0fd01f6c732050b54e35f7983186bd28184a4a1e1a4f2da1c47d4582dca8c9f7e0b2e37f8ff7f1e4b5a9a35f5666',

	-- Nathan Kirby
	['Blank VHS Box'] = 'fef6ddf3e46dbf98acb1739aed7275eb5b2be1202de67216edd6000e8743a0c5c60a5c9f392874c3347986215f212425',

	-- jeremy
	['MIRI16'] = '1b1b1743322630408c5756473f60508e3a4786553b6b6ab36b7636a969605e8b9b9c7829ac82b2ad9688d8b47aecd9d6',
	['REHA16'] = '010e051223032b2c213b3453673d491e624e943b388d61489b6e703b884cb57e67bc9b7251b09dd4b0a2d3cfb1f5e1e8',
	['ALIA16'] = '1e202151245060522247559d8f416aca475a4588557f72667a889ae166bcab933edb8e81a7a8ddeeb487ccd2c9f8e6e6',
	['REGU16'] = 'cd372f2840b7d3ab0c121c1c3d39345e3c288646304b6130627e64906243c67439ae8f586fabbcafae9ecec1d0d8d8e5',

	-- Psiweapon Schuldigun
	['SARA-98A'] = 'b61030e24050ee7175f69d9dfffff2ead6aadaa56dca713cae4c307d181855100871341065715071958da5baae1c0810',

	-- Morganne
	['Hamburger Time'] = '1f1f22a7954ea2651b694e4b9b796e582a348f2a4d9d5d85bba7a4cac9ab545c89322b3b73865076b0985239645c85a8',

	-- Joao Vasconcelos
	['Cookiebox-16'] = '1b1a1a4e38467f38371f6c37625c4c0a8a69ba554e6092387e7b71ab852e3bb2b8bd8b67bfb24cc9b49c8ef6c4e9d7bd',
	['Tauriel-16'] = '17171c282a3049363a4047353b536a9b353592583f21927ea16a417e7b7171a14ebe8d687abbb9d9bd66e8c6a1dcd6cf',

	-- Arisuki
	['Kawaii16'] = '65471eb57075dcab80f8d8abb8aaaafff5f5fca5c2ec4646ffa322f9fa937bc1888ed3f85989a3d793fa74518e1d173c',

	-- Thorogrim
	['Doomed'] = '0000001b3e3c3e5b516e7e55a9a96bffe1cbffc190ffb54aff8837ff5d00ba45099022004e0d00dd2200ff4e1dffffff',

	-- Miguel Lucero
	['BOT16'] = 'fbffceb4dc2526a6305af0f7fbd439ff9cc925e2c008a0c0f09432f43666c635bc165a7ddc532da125366f288b260e3e',

	-- adamPhoebe
	['Console 16'] = 'ff032b800034ffff0dff8f000aff0a0070620dffff3c80db2929ff2d006eff08ff6e0085260a34000000ffffff7d7da3',

	-- Blylzz
	['OLDSAND-16'] = 'b4c9d8a5a3b37e8e994e5d66b0c09a8f9f917a885e525747ddb9a1a0a294a3856d6f5f52d29a8da0949aa06b636e504d',

	-- Poltergasm
	['NOTEPAD'] = '373545616478e0e0e0aed6f54a82645db365ad8c4bc4b1525a6ead7c9fd9c9597ae8899e6956618f6f7ac4a082e5cea5',

	-- Puff
	['PP-16'] = '2b0a0369273183403aab613bb57735bf914fc1b3675cbb7249af755d99845d7c8f63364e63416b6a54896569a0627bb4',

	-- Life Forever Together
	['COLORBLIND 16'] = '000000252525676767ffffff17172300494900999922cf22490092006ddbb66dffff6db69200008f4e00db6d00ffdf4d',

	-- Solitaire
	['Ice-Cream Adventure'] = '3d322b6b3c1d0b5fa48f2764606b67a719b118b7b1a36c41eb4163949fa3d774b9dbc78cb1d499ff8a90f0b7c7f0eee2',

	-- SZIEBERTH Ádám
	['Grayscale 16'] = '0000001818182828283838384747475656566464647171717e7e7e8c8c8c9b9b9babababbdbdbdd1d1d1e7e7e7ffffff',

	-- Fusionnist
	['FXT Ethereal 16'] = 'f3f3f3f9c2a4b8700e5e0d24a29eb4c259df8f27b8c1002b6c606f0047ed00a8f3ddb41100495207865c00c37d051c25',

	-- denypixel
	['Softel16'] = 'fffef9f8f2e1d7e2defcea9effdc86db835ecaefa6a7d0748ba764f36684f3506f9c4071a0d7eb6287be5e5e80404b4f',

	-- Sansh
	['16-Metallic'] = 'fabaf8534459311290170f1affffff866c85274893330b11b5e9d481bde63877c5561d25fce778c88f49a4562a973a35',

	-- mesthbly
	['MEM16'] = '29213b363d697f4a3dd05757fc9849ffd5598ccc4b3e9d4d3e62784789b299aeb488dfd7fff9b6ffbe97f6779c9f57af',
	['BLY16'] = '333344444455774444445566bb5555667788996699448888dd885577aa6666aa9999aabbee99aa88bbbbeebb77eeddcc',

	-- RuziKB²
	['Winterfes 16'] = '3c1c4a574084655ec05a78e3549fff4fd8ff7fffffbfffffffffffffdaefffa8dfef60bfe716ac9916745c024a300020',

	-- Jehkoba
	['Jehkoba16'] = '00000098d9d32bbcd92980a621a65d97bf30f0cd30f2ece6ff9959bf6060ffa6a6ff336699457d4040806b86b308091a',

	-- Nukman147
	['Pantheons16'] = 'ffd8baf7a983f28a91db3b5d57253bac2925ef692feca5493e88b74b3b9c6a6c56adac8efff4e0cecfbf9394872b2b26',

	-- Snowl Owl
	['Snowl16'] = '1e151e4d4c477c7973b8b4a94b356f746eb1af7fa373b5de5b2a35b14a5eb15c47dcde73356f5476b15adebe98dedacb',

	-- her boulion
	['PYXEL'] = '0000002b335f7e207219959c8b4852395c98a9c1ffeeeeeed4186cd38441e9c35ba3a3a370c6a97696deff9798edc7b0',

	-- Vapayt
	['Emerald Peach'] = '3fe3923dc58d3aa986379a8a3482883260772b3a68120855241356351e565931617a446d975973b0606ec96266e16863',

	-- reins910
	['ETERN16'] = '000000ada97dffdb80e69c53bd683a854f3a63384585eb8163d4bd56a0a641607839365c212333ab432e85172b571027',

	-- Sk3ll Sk3ll
	['SK 16'] = '2497fc283d85271f36592b66a60d0dff5a00fcb500ede54785d45102992500401c000000475370798b9499cfc5ebffcc',

	-- Toby_Yasha
	['TY - Disaster Girl 16'] = 'cdbeac7b7d6a4e554e352f284a484a3c3b4a3432342a252ac5a46b9f673e7a5c5460484dee999c8b484a613234080400',

	-- lop choco
	['Super Pocket Boy'] = '3a3a3a81719aa777b7d8b0c0efafbfdf77a7cf4f2ff79f4ff7df6fcf9f00a76f47479f579fcf7fa0d0f888a0f0f8e8f8',



	--Custom
	['Autumn Bliss'] = 'A45A2A9F5328874F1D6B3E126F301D734027764F3179503B7C605F7F726484836994936E9F9E73AAA57DB5AD87C0B591',
	['Morning Haze'] = 'DAC7EFCABBE1B8AED3A690C59373B78155A96E369C5C18905C1A8767367F72527A7D6E74897B6F948772A09276AC9E79',
	['Cyberpunk'] = '2a213dff94008c00ffa600f9ff00ccff006600ff2a00ff1a1a1a5500ff00ffaa00aaff002aff00ffff005e0048917c48',
	['Midnight Sky'] = '1a1a1a3434344e4e4e6868688282829c9c9cb6b6b6d0d0d0eaeaeaffffffff5252521a1a1a1a1a1a1a1a1a1a1a1a1a1a',

	-- 'Pastel Dream' = 'ffd9d9ffd4d4ffceceffc9c9ffc3c3ffbdbdffb8b8ffb2b2ffacacffa6a6ffa1a1ff9b9bff9595ff8f8f',
	-- 'Sunset Boulevard' = 'ff7e00ff6400ff4a00ff3000ff1600ff0000ff2a00ff5400ff7e00ffa800ffd200fffc00ffffff5e5e5e5e5e5e5e5e',
	['Galactic Voyage'] = '1a1a1a3434344e4e4e6868688282829c9c9cb6b6b6d0d0d0eaeaeaffffffff5252521a1a1a1a1a1a1a1a1a1a1a1a1a1a',
	
	-- Pepto
	['Colodore'] = '0000004a4a4a7b7b7bb2b2b2ffffff813338c46c715538008e5029edf171a9ff9f56ac4d75cec8706deb2e2c9b8e3c97',

	-- ArchaicVirus
	['AV Logo'] = '2f2f2f10aa00aec3af15e10060ff50e5fce62cff021a1a1a595959178a00a8ff6e4ec3007a7a7aa1a1a15ae1001e6410',
	['Neverending Story'] = '74968049766d2e1d25345f5ee0cd9afbedb3b4a37f6f56510a050d82776ab5823f613333bc4a460b456234999b86bda2',
	['Junk World'] = '00000031261925190c0e0f0d3b2f1f230b00493a234f28130a1b1c634f26595739454c3b71593b6f684a817b51677961',

	-- Retro
	['Commodore 64'] = '000000626262898989adadadffffff9f4e44cb7e756d5412a1683cc9d4879ae29b5cab5e6abfc6887ecb50459ba057a3',
	['Commodore VIC-20'] = '000000ffffffa8734ae9b287772d26b6686285d4dcc5ffffa85fb4e99df5559e4a92df8742348b7e70cabdcc71ffffb0',
	['Color Graphics Adapter (CGA)'] = '000000555555aaaaaaffffff0000aa5555ff00aa0055ff5500aaaa55ffffaa0000ff5555aa00aaff55ffaa5500ffff55',
	['APPLE MAC'] = 'fffffffbf305ff6403dd0907f208844700a50000d302abea1fb714006412562c0590713ac0c0c0808080404040000000',
	['Macintosh II'] = 'ffffffffff00ff6500dc0000ff00973600970000ca0097ff00a800006500653600976536b9b9b9868686454545000000',
	['MSWIN/IBM OS/2'] = '000000800000008000808000000080800080008080c0c0c0808080ff000000ff00ffff000000ffff00ff00ffffffffff',
}

local _i = 1
for k, v in pairs(preset_palettes) do
	palettes16[_i] = {name = k, val = v}
	_i = _i + 1
end

table.sort(palettes16, function(a, b) return a.name < b.name end)

function darkenPalette(paletteStr, factor)
	local function darkenColor(color)
		local r, g, b = tonumber(color:sub(1,2),16), tonumber(color:sub(3,4),16), tonumber(color:sub(5,6),16)
		r, g, b = floor(r * factor + 0.5), floor(g * factor + 0.5), floor(b * factor + 0.5)
		return string.format("%02x%02x%02x", r, g, b)
	end
	local darkenedPalette = ""
	for i=1, #paletteStr, 6 do
		darkenedPalette = darkenedPalette .. darkenColor(paletteStr:sub(i, i+5) or "FFFFFF")
	end
	return darkenedPalette
end

function loadPalette(palette, bank)
	vbank(bank)
	for i=0,15 do
		local r=tonumber(string.sub(palette,i*6+1,i*6+2),16)
		local g=tonumber(string.sub(palette,i*6+3,i*6+4),16)
		local b=tonumber(string.sub(palette,i*6+5,i*6+6),16)
		poke(0x3FC0+(i*3)+0,r)
		poke(0x3FC0+(i*3)+1,g)
		poke(0x3FC0+(i*3)+2,b)
	end
end

function pal2table(palette)
	local new_palette = {}
	for i=0,15 do
		local r=tonumber(string.sub(palette,i*6+1,i*6+2),16)
		local g=tonumber(string.sub(palette,i*6+3,i*6+4),16)
		local b=tonumber(string.sub(palette,i*6+5,i*6+6),16)
		new_palette[i] = {r=r,g=g,b=b}
	end
	return new_palette
end

function setPaletteColor(index, color)
	color = color or {r=0,g=0,b=0}
	index = clamp(index, 0, 15)
	poke(0x3FC0 + index * 3, color.r)
	poke(0x3FC0 + index * 3 + 1, color.g)
	poke(0x3FC0 + index * 3 + 2, color.b)
end

function expandPalette(paletteStr, darken, sort)
	local darkenedPalette = darkenPalette(paletteStr, darken*0.75)
	if sort == 2 then
		--local sorted = sortPalette(darkenedPalette .. darkenPalette(paletteStr, darken))
		local sorted = (sortPaletteByHue(darkenedPalette .. darkenPalette(paletteStr, darken)))
		return sorted:sub(1, 96), sorted:sub(97)
	elseif sort == 1 then
			local sorted = sortPalette(darkenedPalette .. darkenPalette(paletteStr, darken))
			--local sorted = (sortPaletteByHue(darkenedPalette .. darkenPalette(paletteStr, darken)))
			return sorted:sub(1, 96), sorted:sub(97)
	else
		return darkenedPalette, darkenPalette(paletteStr, darken)
	end
	-- local expandedPalette = ""
	-- for i=1, #sorted, 6 do
	-- 	expandedPalette = expandedPalette .. darkenedPalette:sub(i, i+5) .. paletteStr:sub(i, i+5)
	-- end
	-- return expandedPalette:sub(1, 96), expandedPalette:sub(97)
end

function splitPalette(palette)
	return palette:sub(1, #palette/2), palette:sub(#palette/2 + 1)
end

function perceivedBrightness(r, g, b)
	-- Using the luminance formula: 0.299 * R + 0.587 * G + 0.114 * B
	return 0.299 * r + 0.587 * g + 0.114 * b
end

function sortPalette(paletteStr)
	local colors = {}
	for i = 1, #paletteStr, 6 do
		local color = paletteStr:sub(i, i+5)
		local r, g, b = tonumber(color:sub(1, 2), 16), tonumber(color:sub(3, 4), 16), tonumber(color:sub(5, 6), 16)
		table.insert(colors, {color = color, brightness = perceivedBrightness(r, g, b)})
	end

	table.sort(colors, function(a, b) return a.brightness < b.brightness end)

	local sortedPalette = ""
	for _, v in ipairs(colors) do
		sortedPalette = sortedPalette .. v.color
	end
	return sortedPalette
end

function rgbToHsl(r, g, b)
	r, g, b = r / 255, g / 255, b / 255
	local max, min = math.max(r, g, b), math.min(r, g, b)
	local h, s, l = (max + min) / 2, (max + min) / 2, (max + min) / 2

	if max == min then
		h, s = 0, 0 -- achromatic
	else
		local d = max - min
		s = l > 0.5 and d / (2 - max - min) or d / (max + min)
		if max == r then
			h = (g - b) / d + (g < b and 6 or 0)
		elseif max == g then
			h = (b - r) / d + 2
		elseif max == b then
			h = (r - g) / d + 4
		end
		h = h / 6
	end

	return h, s, l
end

function sortPaletteByHue(palette)
	local colors = {}

	-- Extract colors from the palette string
	for i = 1, #palette, 6 do
		local hex = string.sub(palette, i, i + 5)
		local r = tonumber(string.sub(hex, 1, 2), 16)
		local g = tonumber(string.sub(hex, 3, 4), 16)
		local b = tonumber(string.sub(hex, 5, 6), 16)
		table.insert(colors, {r = r, g = g, b = b})
	end

	-- Sort colors by hue
	table.sort(colors, function(a, b)
		local h1 = rgbToHsl(a.r, a.g, a.b)
		local h2 = rgbToHsl(b.r, b.g, b.b)
		return h1 < h2
	end)

	-- Reconstruct the sorted palette string
	local sortedPalette = ""
	for _, color in ipairs(colors) do
		sortedPalette = sortedPalette .. string.format("%02X%02X%02X", color.r, color.g, color.b)
	end

	return sortedPalette
end

function draw_palette_widget(pos, bank, bg)
	local cell_size = 2
	local spacing = 1
	vbank(0)
	rect(pos.x, pos.y, 1 + ((cell_size + spacing) * 8), 1 + (cell_size + spacing) * 2, bg or 0)
	vbank(bank)
	local i = 0
	for y = 1, 2 do
		for x = 1, 8 do
			rect(pos.x + 1 + (x - 1) * (cell_size + spacing), pos.y + 1 + (y-1) * (cell_size + spacing), cell_size, cell_size, i)
			i = i + 1
		end
	end
end

function draw_palette_widget2(pos, bank, bg)
	--vbank(bank)
	local cell_size = 2
	local spacing = 1
	rect(pos.x, pos.y, 1 + ((cell_size + spacing) * 32), 4, bg or 2)
	local i = 0
	for x = 0, 15 do
		vbank(0)
		rect(pos.x + 1 + (x * (cell_size + spacing)), pos.y + 1, cell_size, cell_size, x)
		vbank(1)
		rect(((cell_size + spacing) * 16) + pos.x + 1 + (x * (cell_size + spacing)), pos.y + 1, cell_size, cell_size, x)
		-- if x == 0 then
		-- 	spr(16, ((cell_size + spacing) * 16) + pos.x + 1 + (x * (cell_size + spacing)), pos.y + 1, 1)
		-- else
		-- end
	end
end

cursor = {
	x = 8,
	y = 8,
	id = 352,
	lx = 8,
	ly = 8,
	tx = 8,
	ty = 8,
	wx = 0,
	wy = 0,
	sx = 0,
	sy = 0,
	lsx = 0,
	lsy = 0,
	l = false,
	ll = false,
	released_left = false,
	m = false,
	lm = false,
	r = false,
	lr = false,
	released_right = false,
	prog = false,
	cooldown = 0,
	rot = 0,
	last_rotation = 0,
	hold_time = 0,
	drag = false,
	drag_dir = 0,
	drag_loc = {x = 0, y = 0},
	drag_loc2 = {x = 0, y = 0},
	drag_offset = {x = 0, y = 0},
}

pages = {
	[0] = 0,
	[1] = 256,
	[2] = 0,
	[3] = 256,
	[4] = 0,
	[5] = 256,
	[6] = 0,
	[7] = 256,
	[8] = 0,
	[9] = 256,
	[10] = 0,
	[11] = 256,
	[12] = 0,
	[13] = 256,
	[14] = 0,
	[15] = 256,
}

--PRE-CALCULATED TABLE FOR TEXT WIDTH
CHARS = {
	["A"] = {char = "A", large = 6, small = 4},
	["B"] = {char = "B", large = 6, small = 4},
	["C"] = {char = "C", large = 6, small = 4},
	["D"] = {char = "D", large = 6, small = 4},
	["E"] = {char = "E", large = 6, small = 4},
	["F"] = {char = "F", large = 6, small = 4},
	["G"] = {char = "G", large = 6, small = 4},
	["H"] = {char = "H", large = 6, small = 4},
	["I"] = {char = "I", large = 5, small = 4},
	["J"] = {char = "J", large = 6, small = 4},
	["K"] = {char = "K", large = 6, small = 4},
	["L"] = {char = "L", large = 6, small = 4},
	["M"] = {char = "M", large = 6, small = 4},
	["N"] = {char = "N", large = 6, small = 4},
	["O"] = {char = "O", large = 6, small = 4},
	["P"] = {char = "P", large = 6, small = 4},
	["Q"] = {char = "Q", large = 6, small = 4},
	["R"] = {char = "R", large = 6, small = 4},
	["S"] = {char = "S", large = 6, small = 4},
	["T"] = {char = "T", large = 5, small = 4},
	["U"] = {char = "U", large = 6, small = 4},
	["V"] = {char = "V", large = 6, small = 4},
	["W"] = {char = "W", large = 6, small = 4},
	["X"] = {char = "X", large = 6, small = 4},
	["Y"] = {char = "Y", large = 5, small = 4},
	["Z"] = {char = "Z", large = 6, small = 4},
	["a"] = {char = "a", large = 6, small = 4},
	["b"] = {char = "b", large = 6, small = 4},
	["c"] = {char = "c", large = 6, small = 4},
	["d"] = {char = "d", large = 6, small = 4},
	["e"] = {char = "e", large = 6, small = 4},
	["f"] = {char = "f", large = 6, small = 4},
	["g"] = {char = "g", large = 6, small = 4},
	["h"] = {char = "h", large = 6, small = 4},
	["i"] = {char = "i", large = 3, small = 2},
	["j"] = {char = "j", large = 6, small = 4},
	["k"] = {char = "k", large = 6, small = 4},
	["l"] = {char = "l", large = 5, small = 4},
	["m"] = {char = "m", large = 6, small = 4},
	["n"] = {char = "n", large = 6, small = 4},
	["o"] = {char = "o", large = 6, small = 4},
	["p"] = {char = "p", large = 6, small = 4},
	["q"] = {char = "q", large = 6, small = 4},
	["r"] = {char = "r", large = 6, small = 4},
	["s"] = {char = "s", large = 6, small = 4},
	["t"] = {char = "t", large = 6, small = 4},
	["u"] = {char = "u", large = 6, small = 4},
	["v"] = {char = "v", large = 6, small = 4},
	["w"] = {char = "w", large = 6, small = 4},
	["x"] = {char = "x", large = 6, small = 4},
	["y"] = {char = "y", large = 6, small = 4},
	["z"] = {char = "z", large = 6, small = 4},
	["0"] = {char = "0", large = 6, small = 4},
	["1"] = {char = "1", large = 5, small = 4},
	["2"] = {char = "2", large = 6, small = 4},
	["3"] = {char = "3", large = 6, small = 4},
	["4"] = {char = "4", large = 6, small = 4},
	["5"] = {char = "5", large = 6, small = 4},
	["6"] = {char = "6", large = 6, small = 4},
	["7"] = {char = "7", large = 6, small = 4},
	["8"] = {char = "8", large = 6, small = 4},
	["9"] = {char = "9", large = 6, small = 4},
	["!"] = {char = "!", large = 3, small = 2},
	["@"] = {char = "@", large = 6, small = 4},
	["#"] = {char = "#", large = 6, small = 4},
	["$"] = {char = "$", large = 6, small = 4},
	["%"] = {char = "%", large = 6, small = 4},
	["^"] = {char = "^", large = 6, small = 4},
	["&"] = {char = "&", large = 6, small = 4},
	["*"] = {char = "*", large = 6, small = 4},
	["("] = {char = "(", large = 3, small = 3},
	[")"] = {char = ")", large = 3, small = 3},
	["-"] = {char = "-", large = 4, small = 4},
	["_"] = {char = "_", large = 5, small = 4},
	["="] = {char = "=", large = 4, small = 4},
	["+"] = {char = "+", large = 4, small = 4},
	["{"] = {char = "{", large = 4, small = 4},
	["}"] = {char = "}", large = 4, small = 4},
	["["] = {char = "[", large = 3, small = 3},
	["]"] = {char = "]", large = 3, small = 3},
	[";"] = {char = ";", large = 3, small = 3},
	[":"] = {char = ":", large = 3, small = 2},
	["'"] = {char = "'", large = 3, small = 2},
	[","] = {char = ",", large = 3, small = 3},
	["<"] = {char = "<", large = 4, small = 4},
	["."] = {char = ".", large = 3, small = 2},
	[">"] = {char = ">", large = 4, small = 4},
	["/"] = {char = "/", large = 6, small = 4},
	["?"] = {char = "?", large = 5, small = 4},
	['\"']= {char = '\"', large = 4, small = 4},
	["\\"] = {char = "\\", large = 4, small = 4},
	["|"]= {char = '|', large = 4, small = 4},
	['`'] = {char = '`', large = 3, small = 3},
	['~'] = {char = '~', large = 5, small = 4},
	[' '] = {char = ' ', large = 4, small = 2},
}

SHADOW_SWAP = {}
for i = 1, 15 do
	table.insert(SHADOW_SWAP, i)
	table.insert(SHADOW_SWAP, 8)
end

function encodeTile(id, rotation, flip)
	-- First byte: high 8 bits of ID
	local highId = id >> 1
	local firstChar = string.char(highId)

	-- Second byte: 1 low bit of ID, 2 bits for rotation, 2 bits for flip, 3 unused bits
	local lowId = id & 1 -- extract the lowest bit of id
	local secondByte = (lowId << 7) | (rotation << 5) | (flip << 3)
	local secondChar = string.char(secondByte)

	return firstChar .. secondChar
end

function decodeTile(encodedString)
	-- Extract bytes
	local firstByte = string.byte(encodedString:sub(1, 1))
	local secondByte = string.byte(encodedString:sub(2, 2))

	-- Decode ID
	local highId = firstByte << 1
	local lowId = (secondByte & 0x80) >> 7
	local id = highId | lowId

	-- Decode rotation and flip
	local rotation = (secondByte & 0x60) >> 5
	local flip = (secondByte & 0x18) >> 3

	return id, rotation, flip
end

function toBinaryString(num, bits)
	local binStr = ""
	for i = bits, 1, -1 do
		local bit = num & (1 << (i - 1))
		binStr = binStr .. (bit > 0 and "1" or "0")
	end
	return binStr
end


function encodeString(str)
	local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	local charToBits = {}
	local bitsToChar = {}
	for i = 1, #chars do
		local char = chars:sub(i, i)
		local bits = toBinaryString(i-1, 6)
		charToBits[char] = bits
		bitsToChar[bits] = char
	end


	local bitString = ""
	for i = 1, #str do
		local char = str:sub(i, i)
		bitString = bitString .. charToBits[char]
	end

	-- Padding
	local padding = (8 - (#bitString % 8)) % 8
	bitString = bitString .. string.rep("0", padding)

	local encoded = ""
	for i = 1, #bitString, 8 do
		local byte = bitString:sub(i, i + 7)
		encoded = encoded .. string.char(tonumber(byte, 2))
	end

	-- Append padding info as a single character
	encoded = encoded .. string.char(padding)

	return encoded
end

function decodeString(encoded)
	local charToBits = {}
	local bitsToChar = {}
	local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	for i = 1, #chars do
		local char = chars:sub(i, i)
		local bits = string.format("%06b", i-1)
		charToBits[char] = bits
		bitsToChar[bits] = char
	end
	-- Extract padding information from the last character
	local padding = string.byte(encoded:sub(-1))
	encoded = encoded:sub(1, #encoded - 1)

	local bitString = ""
	for i = 1, #encoded do
		local byte = encoded:sub(i, i)
		bitString = bitString .. string.format("%08b", string.byte(byte))
	end

	-- Remove padding
	bitString = bitString:sub(1, #bitString - padding)

	local decoded = ""
	for i = 1, #bitString, 6 do
		local bits = bitString:sub(i, i + 5)
		decoded = decoded .. bitsToChar[bits]
	end

	return decoded
end

function update_cursor_state()
	local x, y, l, m, r, sx, sy = mouse()
	if l and cursor.l and not cursor.held_left and not cursor.r then
		cursor.held_left = true
	end

	if r and cursor.r and not cursor.held_right and not cursor.l then
		cursor.held_right = true
	end

	if cursor.held_left or cursor.held_right then
		cursor.hold_time = cursor.hold_time + 1
	end

	if not l and cursor.held_left then
		cursor.held_left = false
		cursor.hold_time = 0
	end

	if not r and cursor.held_right then
		cursor.held_right = false
		cursor.hold_time = 0
	end

	cursor.lwx, cursor.lwy = cursor.wx, cursor.wy
	cursor.wx, cursor.wy = wx, wy
	cursor.ltx, cursor.lty = cursor.tx, cursor.ty
	cursor.tx, cursor.ty, cursor.sx, cursor.sy = tx, ty, sx, sy
	cursor.lx, cursor.ly, cursor.ll, cursor.lm, cursor.lr, cursor.lsx, cursor.lsy = cursor.x, cursor.y, cursor.l, cursor.m, cursor.r, cursor.sx, cursor.sy
	cursor.x, cursor.y, cursor.l, cursor.m, cursor.r, cursor.sx, cursor.sy = x, y, l, m, r, sx, sy
	if cursor.tx ~= cursor.ltx or cursor.ty ~= cursor.lty then
		cursor.hold_time = 0
	end
	if cursor.cooldown > 0 then
		cursor.cooldown = cursor.cooldown - 1
		cursor.l, cursor.r, cursor.ll, cursor.lr, cursor.held_left, cursor.held_right, cursor.hold_time = false, false, false, false, false, false, 0
	end
	cursor.released_left = cursor.ll and not cursor.l
	cursor.released_right = cursor.lr and not cursor.r
end

--RETURNS EXACT PIXEL WIDTH OF A STRING, IN LARGE OR SMALL FONT
function tw(text, size)
	local output = 0
	for i = 1, #text do
		output = output + (size and CHARS[text:sub(i,i)].small or CHARS[text:sub(i,i)].large)
	end
	return output - 1
end
--ALIAS
text_width = function(...) return tw(...) end

function hovered(_mouse, _box)
	if not _box then
		_mouse, _box = cursor, _mouse
	end
	local mx, my, bx, by, bw, bh = _mouse.x, _mouse.y, _box.x, _box.y, _box.w, _box.h
	return mx >= bx and mx < bx + bw and my >= by and my < by + bh
end

function rspr(id, x, y, colorkey, scaleX, scaleY, flip, rotate, tile_width, tile_height, pivot, skip)
	colorkey = colorkey or -1
	scaleX = scaleX or 1
	scaleY = scaleY or 1
	flip = flip or 0
	rotate = rotate or 0
	tile_width = tile_width or 1
	tile_height =	tile_height or 1
	pivot = pivot or vec2(4, 4)
	skip = skip or {false, false}

	-- Draw a sprite using two textured triangles.
	-- Apply affine transformations: scale, shear, rotate, flip

	-- scale / flip
	if flip % 2 == 1 then
		scaleX = -scaleX
	end
	if flip >= 2 then
		scaleY = -scaleY
	end
	ox = tile_width * 8 // 2
	oy = tile_height * 8 // 2
	ox = ox * -scaleX
	oy = oy * -scaleY

	-- shear / rotate
	shx1 = 0
	shy1 = 0
	shx2 = 0
	shy2 = 0
	shx1 = shx1 * -scaleX
	shy1 = shy1 * -scaleY
	shx2 = shx2 * -scaleX
	shy2 = shy2 * -scaleY
	rr = math.rad(rotate)
	sa = math.sin(rr)
	ca = math.cos(rr)

	function rot(x, y)
		return x * ca - y * sa, x * sa + y * ca
	end

	rx1, ry1 = rot(ox + shx1, oy + shy1)
	rx2, ry2 = rot((( tile_width * 8) * scaleX) + ox + shx1, oy + shy2)
	rx3, ry3 = rot(ox + shx2, ((tile_height * 8) * scaleY) + oy + shy1)
	rx4, ry4 = rot((( tile_width * 8) * scaleX) + ox + shx2, ((tile_height * 8) * scaleY) + oy + shy2)
	x1 = x + rx1 - pivot.x
	y1 = y + ry1 - pivot.y
	x2 = x + rx2 - pivot.x
	y2 = y + ry2 - pivot.y
	x3 = x + rx3 - pivot.x
	y3 = y + ry3 - pivot.y
	x4 = x + rx4 - pivot.x
	y4 = y + ry4 - pivot.y

	-- UV coords
	u1 = (id % 16) * 8
	v1 = math.floor(id / 16) * 8
	u2 = u1 + tile_width * 8
	v2 = v1 + tile_height * 8
	if not skip[1] then
		ttri(x1, y1, x2, y2, x3, y3, u1, v1, u2, v1, u1, v2, 0, colorkey)
	end
	if not skip[2] then
		ttri(x3, y3, x4, y4, x2, y2, u1, v2, u2, v2, u2, v1, 0, colorkey)
	end
end

function lerp(a,b,mu)
	return a*(1-mu)+b*mu
end

function clamp(val, min, max)
	return math.max(min, math.min(val, max))
end

function remap(n, a, b, c, d)
	return c + (n - a) * (d - c) / (b - a)
end

function is_air(id)
	return id == 0 or id == 144
end

function world_to_screen(world_x, world_y)
	local wx, wy = world_x, world_y
	if type(world_x) == 'table' then
		wx, wy = world_x.x, world_x.y
	end
	local screen_x = (wx * 8) - (floor(player.cam.x) - 116)
	local screen_y = (wy * 8) - (floor(player.cam.y) - 64)
	return screen_x - 8, screen_y - 8
end

function prints(txt, x, y, bg, fg, shadow_offset, small_font)
	bg, fg = bg or 0, fg or 4
	shadow_offset = shadow_offset or {x = 1, y = 0}
	print(txt, x + shadow_offset.x, y + shadow_offset.y, bg, false, 1, small_font)
	print(txt, x, y, fg, false, 1, small_font)
end

_rect = rect
rect = function(x, y, w, h, color)
	if type(x) == 'table' then
		_rect(x.x, x.y, x.w, x.h, y)
	else
		_rect(x, y, w, h, color)
	end
end

_rectb = rectb
rectb = function(x, y, w, h, color)
	if type(x) == 'table' then
		_rectb(x.x, x.y, x.w, x.h, y)
	else
		_rectb(x, y, w, h, color)
	end
end

_clip = clip
clip = function(x, y, w, h)
	if not x then _clip() return end
	if type(x) == 'table' then
		_clip(x.x, x.y, x.w, x.h)
	else
		_clip(x, y, w, h)
	end
end

function rndi(min, max)
	if min == 0 and max == 0 then return 0 end
	min, max = floor(min), floor(max)
	if min > max then
		min, max = max, min
	end
	return math.random(min, max)
end

function rndf(min, max)
	if min == 0 and max == 0 then return 0 end
	if min > max then
		min, max = max, min
	end
	return min + math.random() * (max - min)
end

function deep_copy(obj, seen)
	if type(obj) ~= 'table' then return obj end
	if seen and seen[obj] then return seen[obj] end
	local s = seen or {}
	local res = setmetatable({}, getmetatable(obj))
	s[obj] = res
	for k, v in pairs(obj) do res[deep_copy(k, s)] = deep_copy(v, s) end
	return res
end

function pal(c0, c1)
	if not c0 and not c1 then
		for i = 0, 15 do
			poke4(0x3FF0 * 2 + i, i)
		end
	elseif type(c0) == 'table' then
		for i = 1, #c0, 2 do
			poke4(0x3FF0*2 + c0[i], c0[i + 1])
		end
	else
		poke4(0x3FF0*2 + c0, c1)
	end
end

function rotatePoint(center, point, angle)
	local radians = angle * math.pi / 180
	local cosine = math.cos(radians)
	local sine = math.sin(radians)

	return vec2(center.x + (point.x - center.x) * cosine - (point.y - center.y) * sine,
		center.y + (point.x - center.x) * sine + (point.y - center.y) * cosine)
end

local _cls = cls

function cls(color)
	cla(color)
end

function cla(color)
	vbank(0)
	_cls(color or BG_COLOR)
	vbank(1)
	_cls()
end

function draw_planet(planet, x, y, radius, layer)
	local w, h = #planet.data[1], #planet.data
	planet.rotation_angle = (time() * planet.rotation_speed) % (2 * math.pi)
	--Go through each pixel in the sphere's bounding box
	for dy = -radius, radius do
		for dx = -radius, radius do
			--Calculate the pixels position relative to the sphere center
			local distance_squared = dx * dx + dy * dy
			if distance_squared < radius * radius then
				--Pixel falls onto sphere, find its 3D position on the sphere
				local dz = math.sqrt(radius * radius - distance_squared)
				--Normalizing the 3D position to get the normal vector on the sphere surface
				local nx, ny, nz = dx / radius, dy / radius, dz / radius
				--rotate the normal vector around the rotation axis
				--local rotated_normal = vec3(nx, ny, nz):rotate(cursor.rotation, 1)
				local rotated_normal = vec3(nx, ny, nz):rotate(planet.rotation_axis, planet.rotation_angle)
				--Find the spherical coordinates of the rotated normal vector
				--Longitude
				local lon = math.atan2(rotated_normal.y, rotated_normal.x)
				--Map the longitude from o-1
				lon = (lon + math.pi) / (2 * math.pi)
				--Latitude
				local lat = math.acos(rotated_normal.z) / math.pi
				--Map lat/long to the texture coordinates
				local tex_x = clamp(floor(lon * w) + 1, 1, #planet.data[1])
				local tex_y = clamp(floor(lat * h) + 1, 1, #planet.data)
				if not planet.data[tex_y][tex_x] or not planet.data[tex_y] or planet.data[tex_y][tex_x] < 0 then
					--trace("INVALID TEXTURE INDEX")
				end
				local pixel = planet.data[tex_y][tex_x] or 1
				if pixel > 0 then
					pix(x + dx, y + dy, pixel)
				end
				-- if pixel > 0 then
				-- 	if pixel > 15 then
				-- 		vbank(1)
				-- 		pix(x + dx, y + dy, pixel - 16)
				-- 	else
				-- 		vbank(0)
				-- 		pix(x + dx, y + dy, pixel)
				-- 	end
				-- end
			end
		end
	end
end

function create_map(size, wx, wy, index)
	local offset = rnd(1, 50) / (index + 1 * 10)
	local map_seed = wx*wy + offset + (index + 1 *1000)
	math.randomseed(map_seed)
	local scale  = rndf(1, 7) + rnd()
	local scale1 = remap(rnd(1, 100), 1, 100, 0.0005, 0.0075)
	local scale2 = remap(rnd(1, 100), 1, 100, 0.1, 0.75)
	if rnd() > 0.5 then scale = scale * -1 end
	-- local scale = -5.5
	-- local scale1 = 0.0029
	-- local scale2 = 0.29
	local map_size = size or 50
	local w = map_size * 4
	local h = map_size * 2
	local planet = {data = {}}
	planet.rotation_angle = rad(rndi(0,360))
	planet.rotation_axis = vec3(0, 0.85, 0)
	planet.rotation_speed = 0.001
	--creating a seamless 3D noise texture
	for y = 1, h do
		planet.data[y] = {}
		for x = 1, w do
			--convert 2D map coordinates to 3D coordinates on a sphere
			--latitude, varies from 0 to pi
			local lat = (y / h) * math.pi
			--longitude, varies from 0 to 2pi
			local lon = (x / w) * 2 * math.pi
			--convert spherical coordinates to cartesian coordinates
			local nx, ny, nz = math.sin(lat) * math.cos(lon) + (offset), math.sin(lat) * math.sin(lon) + (offset), math.cos(lat)
			--sample 3D noise at the calculated 3D point and store in map
			local noise1 = math.abs(simplex.Noise3D(wx + nx * scale1, wy + ny * scale1, nz))
			local noise2 = math.abs(simplex.Noise3D(wx + nx * scale2, wy + ny * scale2, nz))
			local noise = floor(remap(lerp(noise1, noise2, scale), -1, 1, 0, 15) + 0.5)
			--Map noise to look-up table for planet's type
			local dither = DITHER_MATRIX[floor((y % #DITHER_MATRIX) + 1)][floor((x % #DITHER_MATRIX[1]) + 1)]
			local noise = noise + (dither - 2.5) * 0.25  -- Adjust dithering range
			planet.data[y][x] = noise
		end
	end
	return planet
end

BG_COLOR = 0

CURRENT_EFFECT = 1
CURRENT_PALETTE = 7
REPEAT_DELAY = 20
REPEAT_TIME = 1
COLOR_MODE = 32
FG_PAL = default_fg
BG_PAL = default_bg
TICK = 0
SHOW_PALETTE = true

local default = {
	[0] = {
		init = function()

		end,

		draw = function()

		end,
	},
}

local colors = {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31}

EFFECTS = {
	[1] = {
		init = function()
			-- Initialize any variables specific to the plasma effect
			-- These can be constants for speed, color palette, etc.
			PLASMA_SPEED = 0.1
		end,

		draw = function()
			vbank(0)
			cls()
			vbank(1)
			--cls()
			local t = time() / 1000
			local w, h = 100, 50
			local sx, sy = 120 - (w/2), 68 - (h/2)
			for y = sy, sy + h do
				for x = sx, sx + w do
					-- Calculate plasma effect based on position and time
					local v = sin(x * 100.75 + t) + sin(y * 100.75 - t)
					v = v + sin((x + y) * 0.05) + sin(sqrt(x * x + y * y) * 0.1 - t)
					-- Generate a color index based on the plasma value
					local color = colors[clamp(floor((sin(v) + 1) * 31) % 31, 1, 31)]
					--if TICK % 60 == 0 then trace(color) end
					if color > 15 then
						vbank(1)
						pix(x, y, color - 16)
					else
						vbank(0)
						pix(x, y, color)
					end
				end
			end
		end,
	},

	[2] = {
		init = function()
			-- Initialize constants
			cla()
			PLASMA_SPEED = 1.35
			NOISE_SCALE = 0.1
			NOISE_SCALE2 = 0.05
			LERP_SCALE = -0.5
			SCALE_DOWN = 1
		end,

		draw = function()
			cla()
			local t = floor(time() / 40) % 360
			local t2 = floor(time() / 20) % 720
			local w, h = 100, 50
			local sx, sy = 120 - (w/2), 68 - (h/2)
			for y = sy, sy + h do
				for x = sx, sx + w do
					-- Plasma effect calculation using precomputed sine values
					local a, b = floor(clamp((x + t + t2) % 360, 0, 360)), floor(clamp((y - t + t2) % 360, 0, 360))
					local c, d = floor(clamp(((x + y + t2) * 0.5) % 360, 0, 360)), floor(clamp((sqrt(x * x + y * y) * 0.1 - t + t2) % 360, 0, 360))
					--trace("a: " .. tostring(a) .. ", b: " .. tostring(b))
					--trace("c: " .. tostring(c) .. ", d: " .. tostring(d))
					local v = SIN_LUT[a] + SIN_LUT[b]
					v = v + SIN_LUT[c] + SIN_LUT[d]

					-- Adding noise variation
					local noise = lerp(simplex.Noise2D(x * NOISE_SCALE, y * NOISE_SCALE), simplex.Noise2D(x * NOISE_SCALE2, y * NOISE_SCALE2), LERP_SCALE)
					v = v + noise

					-- Generate color index
					local color = floor((sin(v) + 1) * vec2(x, y):distance(vec2(120, 68))/2) % 16

					-- Draw scaled up pixels
					pix(x, y, color)
					-- for dy = 0, SCALE_DOWN - 1 do
					-- 	for dx = 0, SCALE_DOWN - 1 do
					-- 	end
					-- end
				end
			end
		end,
	},

	[3] = {
		init = function()
			PLASMA_SPEED = 0.35
			NOISE_SCALE = 0.1
			NOISE_SCALE2 = 0.003
			LERP_SCALE = 1.5
			SCALE_DOWN = 1
			-- loadPalette(darkenPalette(palettes[CURRENT_PALETTE].val, 0.25), 0)
			-- loadPalette(palettes[CURRENT_PALETTE].val, 1)
		end,

		draw = function()
			local t = floor(time() / 30) % 720
			local t2 = floor(time() / 20) % 360
			local t2 = 0
			local w, h = 200, 50
			local sx, sy = 120 - (w/2), 68 - (h/2)
			vbank(0)
			cls()
			vbank(1)
			cls()
			for y = sy, sy + h do
				for x = sx, sx + w do
					local a, b = floor(clamp((x + t + t2) % 360, 0, 360)), floor(clamp((y - t + t2) % 360, 0, 360))
					local c, d = floor(clamp(((x + y + t2) * 0.5) % 360, 0, 360)), floor(clamp((sqrt(x * x + y * y) * 0.1 - t + t2) % 360, 0, 360))
					local v = SIN_LUT[a] + SIN_LUT[b]
					v = v + SIN_LUT[c] + SIN_LUT[d]
					local noise = lerp(simplex.Noise2D((time()/1000*0.005) + x * NOISE_SCALE - v, (time()/1000*0.005) + y * NOISE_SCALE - v), simplex.Noise2D((time()/1000*0.005) + x * NOISE_SCALE2 + v, (time()/1000*0.005) + y * NOISE_SCALE2 + v), LERP_SCALE)
					v = v + noise
					--local color = floor((sin((noise/v)*0.25) + 1) * (vec2(x, y):distance(vec2(120, 68))/4)) % 32
					local color = floor(remap(noise, -1, 1, 0, 31)) % 32
					if color > 15 then
						vbank(1)
						pix(x, y, color - 16)
					else
						vbank(0)
						pix(x, y, color)
					end
				end
			end
		end,
	},

	[4] = {
		init = function()
			-- Initialize constants
			PLASMA_SPEED = 3.1
			NOISE_SCALE = 0.03565
			NOISE_SCALE2 = 0.01555
			NOISE_LERP = 1.5
			SCALE_DOWN = 1
			COLOR_SCALE = 1.0
			-- local bg, fg = expandPalette(palettes[CURRENT_PALETTE].val, COLOR_SCALE, false)
			-- loadPalette(bg, 0)
			-- loadPalette(fg, 1)
			-- Dithering pattern (2x2 Bayer matrix)
			DITHER_MATRIX = {
				-- { -1, 1, -1},
				-- { 1, -1, 1},
				-- { -1, 1, -1},
				{1.25,0.5},
				{1.25,0.5},
			}
		end,

		draw = function()
			local t = floor(time() / 40) % 360
			--setPaletteColor(15)
			--local bg, fg = expandPalette(palettes[CURRENT_PALETTE].val, COLOR_SCALE, false)
			COLOR_SCALE = remap(sin(time()*0.0075), -1, 1, 0.15, 1.0)
			vbank(0)
			cls()
			vbank(1)
			cls()
			local color1 = {
				r = 15,
				g = COLOR_SCALE*(255/3),
				b = COLOR_SCALE*(255/3)
			}
			local color2 = {
				r = 35,
				g = COLOR_SCALE*255,
				b = 0
			}
			local color3 = {
				r = 25,
				g = COLOR_SCALE*(255/3),
				b = 0
			}
			-- setPaletteColor(1, color1)
			-- setPaletteColor(2, color1)
			-- setPaletteColor(3, color2)
			-- setPaletteColor(4, color1)
			-- setPaletteColor(5, color1)
			local w, h = 100, 50
			local sx, sy = 120 - (w/2), 68 - (h/2)
			for y = sy, sy + h, SCALE_DOWN do
				for x = sx, sx + w, SCALE_DOWN do
					-- Plasma effect calculation using precomputed sine values
					local v = SIN_LUT[clamp(floor((x + t) % 360), 0, 360)] + SIN_LUT[clamp(floor((y - t) % 360), 0, 360)]
					v = v + SIN_LUT[clamp(floor(((x + y) * 0.5) % 360), 0, 360)] + SIN_LUT[clamp(floor((sqrt(x * x + y * y) * 0.1 - t) % 360), 0, 360)]

					-- Adding noise variation
					local noise = simplex.Noise2D(x * NOISE_SCALE, y * NOISE_SCALE)
					local noise2 = simplex.Noise2D(x * NOISE_SCALE2, y * NOISE_SCALE2)
					local noise3 = lerp(noise, noise2, NOISE_LERP)
					v = v + noise3

					-- Apply dithering

					local dither = DITHER_MATRIX[floor((y % #DITHER_MATRIX) + 1)][floor((x % #DITHER_MATRIX[1]) + 1)]
					v = v + (dither - 2.5) / 4.0  -- Adjust dithering range

					-- Generate color index
					local color = floor((sin(noise-(v*0.5)) + 1) * 15) % 32

					-- Draw scaled up pixels using vbank
					for dy = 0, SCALE_DOWN - 1 do
						for dx = 0, SCALE_DOWN - 1 do
							if color > 15 then
								vbank(1)
								pix(x + dx, y + dy, color - 16)
							else
								vbank(0)
								pix(x + dx, y + dy, color)
							end
						end
					end
				end
			end
		end,
	},

	[5] = {
		init = function()
			-- Initialize constants for the plasma effect with noise
			PLASMA_SPEED = 0.1
			NOISE_SCALE = 0.02
			-- local bg, fg = expandPalette(palettes[CURRENT_PALETTE].val, 1.0, false)
			-- loadPalette(bg, 0)
			-- loadPalette(fg, 1)
		end,

		draw = function()
			local t = time() / 1000
			local w, h = 100, 50
			local sx, sy = 120 - (w/2), 68 - (h/2)
			vbank(0)
			cls()
			vbank(1)
			cls()
			for y = sy, sy + h do
				for x = sx, sx + w do
					-- Plasma effect calculation
					local v = sin(x * 0.05 + t) + sin(y * 0.05 - t) 
					v = v + sin((x + y) * 0.05) + sin(sqrt(x * x + y * y) * 0.1 - t)

					-- Adding noise variation
					local noise = simplex.Noise2D(x * NOISE_SCALE, y * NOISE_SCALE)
					v = v + noise

					-- Generate a color index based on the plasma value with noise
					local color = ((sin(v) + 1) * 15) % 32
					if color > 15 then
						vbank(1)
						pix(x, y, color - 16)
					else
						vbank(0)
						pix(x, y, color)
					end
				end
			end
		end,
	},

	[6] = {
		init = function()
			cla(BG_COLOR)
			player = vec2()
			player.cam = vec2()
			DITHER_MATRIX = {
				{ -1, 1, -1},
				{ 1, -1, 1},
				{ -1, 1, -1},
				-- {0.5,2},
				-- {2,0.5},
			}
			PIXELS = {}
			ZOOM_SCALE = 0.025
			inc = 0.001
			local w, h = 150, 50
			local sx, sy = 120 - w/2, 64 - h/2

			SCALE = 0.02

			for y = 1, h do
				PIXELS[y] = {}
				for x = 1, w do
					PIXELS[y][x] = {x = sx + x - 1, y = sy + y - 1, color = floor(remap(simplex.Noise2D(x * SCALE, y * SCALE), -1, 1, 1, 31) + 0.5)}
				end
			end
		end,

		draw = function()

			update_cursor_state()
			if abs(cursor.sy) > 0 then
				ZOOM_SCALE = clamp(ZOOM_SCALE + (cursor.sy*inc), 0.001, 0.5)
				trace("zoom: " .. ZOOM_SCALE)
			end
			vbank(0)
			cls()
			vbank(1)
			cls()
			for y, v in ipairs(PIXELS) do
				for x, pixel in ipairs(PIXELS[y]) do
					local offset = sin(time()/6000)
					local rotation = time()/6000
					--offset = remap(offset, -1, 1, 0.025, 0.025)
					offset = ZOOM_SCALE
					--SCALE = clamp(offset, -1, 1)
					local rotated = rotatePoint(vec2(120, 68), vec2(pixel.x, pixel.y), rotation)
					local n1 = floor(remap(simplex.Noise2D(rotated.x * offset + rotation, rotated.y * offset + rotation), -1, 1, 0, 31))
					local n2 = floor(remap(simplex.Noise2D(rotated.x * offset + rotation*2, rotated.y * offset + rotation*2), -1, 1, 0, 31))
					local n3 = floor(remap(simplex.Noise2D(rotated.x*rotated.y*offset, rotated.y*time()/1000*offset), -1, 1, 0, 31))
					local color = lerp(lerp(n1, n2, 0.5), n3, 0.1)
					local dither = DITHER_MATRIX[floor((y % #DITHER_MATRIX) + 1)][floor((x % #DITHER_MATRIX[1]) + 1)]
					color = color + (dither - 2.5) / 2  -- Adjust dithering range
					pixel.color = color
					rotated.x = floor(rotated.x)
					rotated.y = floor(rotated.y)
					if pixel.color > 15 then
						vbank(1)
						pix(pixel.x, pixel.y, pixel.color - 16)
					else
						vbank(0)
						pix(pixel.x, pixel.y, pixel.color)
					end
				end
			end
		end
	},

	[7] = {
		init = function()
			vbank(0)
			cls()
			vbank(1)
			cls()
		end,

		draw = function()
			local w, h = 60, 60
			local sx, sy = 120 - w/2, 68 - h/2
			--vbank(0)
			--cls()
			--vbank(1)
			--cls()
			local rot = (time() / 1000) * 360
			local offset = remap(sin(time() / 1000), -1, 1, 5, 15)
			local center = vec2(120, 68)
			local pos = rotatePoint(center, center + offset, rot)
			local pos2 = rotatePoint(center, center - offset, rot)
			vbank(1)
			circ(pos2.x, pos2.y, 1 + 1, 15)
			circ(pos2.x, pos2.y, 1 + 2, 14)
			vbank(0)
			circ(pos.x, pos.y, 1 + 1, 14)
			circ(pos.x, pos.y, 1 + 2, 15)
			local falloff = -2.001
			for y = sy - 5, sy + h + 10 do
				for x = sx - 5, sx + w + 10 do
					local col = floor(pix(x-1,y) + pix(x,y-1) + pix(x+1,y) + pix(x,y+1)) / 3
					local noise = simplex.Noise2D(sx * 0.156, sy * 0.0056)
					pix(x, y, clamp(col + falloff, 0, 15))
					if col > 0 then
					end
				end
			end
			vbank(1)
			for y = sy - 5, sy + h + 10 do
				for x = sx - 5, sx + w + 10 do
					local col = floor(pix(x-1,y) + pix(x,y-1) + pix(x+1,y) + pix(x,y+1)) / 3
					local noise = simplex.Noise2D(sx * 0.156, sy * 0.0056)
					pix(x, y, clamp(col + falloff, 0, 15))
					if col > 0 then
					end
				end
			end
		end
	},

	[8] = {
		init = function()
			pixels = {}
			local w, h = 50, 50
			local sx, sy = 120 - w/2, 68 - h/2
			scale = 0.1
			for dy = 0, h - 1 do
				for dx = 0, w - 1 do
					local x = sx + dx
					local y = sy + dy
					table.insert(pixels, {x = x, y = y, color = remap(simplex.Noise2D((x + time()/1000) * scale, (y + time()/1000) * scale), -1, 1, 0, 31)})
				end
			end
		end,

		draw = function()
			cla()
			for k, v in ipairs(pixels) do
				if v.color > 15 then
					vbank(1)
					if v.color - 16 > 0 then
						pix(v.x, v.y, v.color - 16)
					else
						v.color = remap(simplex.Noise2D((v.x + time()/1000) * scale, (v.y + time()/1000) * scale), -1, 1, 0, 31)
					end
				else
					vbank(0)
					if v.color > 0 then
						pix(v.x, v.y, v.color)
					else
						v.color = remap(simplex.Noise2D((v.x + time()/1000) * scale, (v.y + time()/1000) * scale), -1, 1, 0, 31)
					end
				end
				v.color = v.color - 0.1
			end
		end,
	},

	[9] = {
		init = function()
			cla()
			pixels = {}
			w, h = 75, 75
			local sx, sy = 120 - w/2, 68 - h/2
			dist_scale = 20
			scale = 0.01
			scale2 = 0.1
			for dy = 0, h - 1 do
				for dx = 0, w - 1 do
					local x = sx + dx
					local y = sy + dy
					local dist = vec2(x, y):distance(vec2(120, 68))
					local noise = simplex.Noise2D(x*scale*dist, y*scale*dist) * dist_scale
					local col = remap(noise, -dist_scale, dist_scale, 31, 0)
					if dist > noise then
						col = 0
					end
					table.insert(pixels, {x = x, y = y, color = col})
				end
			end
		end,

		draw = function()
			cla()
			for k, v in ipairs(pixels) do
				local dist = vec2(v.x, v.y):distance(vec2(120, 68))
				local interval = 35
				local offset = (time()/interval) % (interval + 1)
				local noise1 = simplex.Noise1D((dist+offset) * scale) * dist_scale
				local noise2 = simplex.Noise1D((dist+offset) * scale2) * dist_scale
				v.color = remap(lerp(noise1, noise2, 0.5), -dist_scale, dist_scale, 0, 31)
				-- if dist > lerp(noise1, noise2, 0.5) then
				-- 	v.color = 0
				-- end
				if v.color > 15 then
					vbank(1)
					if v.color - 16 > 0 then
						pix(v.x, v.y, v.color - 16)
					else
						--v.color = remap(simplex.Noise2D((v.x + time()/1000) * scale, (v.y + time()/1000) * scale), -1, 1, 0, 31)
					end
				else
					vbank(0)
					if v.color > 0 then
						pix(v.x, v.y, v.color)
					else
						--v.color = remap(simplex.Noise2D((v.x + time()/1000) * scale, (v.y + time()/1000) * scale), -1, 1, 0, 31)
					end
				end
				--v.color = v.color - 0.1
			end
		end,
	},

	[10] = {
		init = function ()
			cla()
			map = {bg={},fg={}}
			map.bg = create_map(32, rndi(-100000, 100000), rndi(-100000, 100000), rndi(-1000, 1000), nil)
			map.fg = create_map(64, rndi(-100000, 100000), rndi(-100000, 100000), rndi(1, 1000), nil)
			offset = 100
			DITHER_MATRIX = {
				-- { -1, 1, -1},
				-- { 1, -1, 1},
				-- { -1, 1, -1},
				{1,0},
				{0,1},
			}
		end,

		draw = function ()
			cla()
			vbank(0)
			draw_planet(map.bg, 120, 68, 16)
			vbank(1)
			draw_planet(map.fg, 120, 68, 32)
		end,
	},

	[11] = {
		init = function()
			-- Constants for Mandelbrot set
			MAX_ITER = 200  -- Maximum iterations to determine set inclusion
			ZOOM_SPEED = 1.0354  -- Speed of zooming in
			CURSOR_ZOOM_SPEED = 1
			offsetX, offsetY = -0.499, -0.51-- Initial offset
			zoom = 1  -- Initial zoom level
	
			-- Function to calculate Mandelbrot set
			function mandelbrot(x, y)
				local zx, zy, cx, cy = 0, 0, x, y
				local iter = 0
				while zx * zx + zy * zy < 4 and iter < MAX_ITER do
					zx, zy = zx * zx - zy * zy + cx, 2 * zx * zy + cy
					iter = iter + 1
				end
				return iter
			end
		end,
	
		draw = function()
			cla()
			update_cursor_state()
			-- Update zoom and offset
			--zoom = zoom * ZOOM_SPEED
			-- Adjust offsets to focus on an interesting part of the Mandelbrot set
			--offsetX = offsetX - 0.0005 / zoom
			--offsetY = offsetY - 0.0005 / zoom
			if cursor.sy then
				zoom = zoom + (cursor.sy*0.01)
			end
			if cursor.l then
				zoom = zoom + CURSOR_ZOOM_SPEED
			end
			if cursor.r then
				zoom = zoom - CURSOR_ZOOM_SPEED
			end
			local ofs = vec2(remap(cursor.x, 0, 240, -1, 1), remap(cursor.y, 0, 68, -1, 1)):normalize()
			offsetX = ofs.x
			offsetY = ofs.y
			local w, h = 40, 40
			local sx, sy = 120 - w/2, 68 - h/2
	
			for y = sy, sy + h do
				for x = sx, sx + w do
					-- Calculate Mandelbrot set
					local mx = (x - 120) / (45 * zoom) + offsetX
					local my = (y - 68) / (45 * zoom) + offsetY
					local iter = mandelbrot(mx, my)
	
					-- Determine color based on iterations
					local color = (iter % 32)
	
					-- Draw pixel using vbank
					if color > 0 then
						if color > 15 then
							vbank(1)
							if color - 16 > 0 then
								pix(x, y, color - 16)
							end
						else
							vbank(0)
							pix(x, y, color)
						end
					end
				end
			end
		end,
	},

	[12] = {
		init = function()

		end,

		draw = function()
			cla()
			local step = 0.75
			local radius = 30

			local width = 10

			for i = 0, 359/step, step do
				local rotation = (time()/100) % 360
				local noise = simplex.Noise1D(i*step + (time()/3000) * 0.1)
				local noise2 = simplex.Noise2D(i*step - (time()/3000) * 0.1, i*step + (time()/3000) * 0.5)
				local point = rotatePoint(vec2(120, 68), vec2(120, 68 - radius + noise/2), (i*step))
				local dir = vec2(120,68) - point
				local point2 = dir:normalize()
				local pixels = {}
				for j = 1, width do
					local pos = rotatePoint(vec2(120, 68), point2*j + point, rotation)
					local col = 1
					if j > width/2 then
						col = clamp(floor(remap(j, width/2, width, 31, 3)), 2, 31)
					else
						col = clamp(floor(remap(j, 2, width/2, 3, 31)), 2, 31)
					end
					table.insert(pixels, {pos = pos, col = col})
				end
				
				for k, v in ipairs(pixels) do
					if v.col > 15 then
						vbank(1)
						pix(v.pos.x, v.pos.y, v.col - 16)
					else
						vbank(0)
						pix(v.pos.x, v.pos.y, v.col)
					end
				end
			end
		end,
	},

	[13] = {
		init = function()
			color_scale = 1.0
			channel = 1
			fade = 0.035
			min_scale = 0.1
			max_scale = 0.8
		end,

		draw = function()
			cla()
			local base_val = 0
			color_scale = color_scale + fade
			if color_scale < min_scale then
				color_scale = min_scale
				fade = -fade
				channel = channel + 1
			elseif color_scale > max_scale then
				color_scale = max_scale
				fade = -fade
			end
			if channel > 3 then channel = 1 end
			vbank(0)
			local pbg = pal2table(BG_PAL)
			local pfg = pal2table(FG_PAL)
			for k, v in pairs(pbg) do
				local col = (v.r+v.g+v.b) / 3
				col = col*color_scale
				local r,g,b = channel == 1 and col or base_val, channel == 2 and col or base_val, channel == 3 and col or base_val
				setPaletteColor(k, {r = r, g = g, b = b})
			end
			vbank(1)
			for k, v in pairs(pfg) do
				local col = (v.r+v.g+v.b) / 3
				col = col*color_scale
				local r,g,b = channel == 1 and col or base_val, channel == 2 and col or base_val, channel == 3 and col or base_val
				setPaletteColor(k, {r = r, g = g, b = b})
			end
			local step = 0.5
			local radius = 30
			local width = 10

			for i = 0, 359/step, step do
				local rotation = (time()/100) % 360
				local noise = simplex.Noise1D(i*step + (time()/3000) * 0.1)
				local noise2 = simplex.Noise2D(i*step - (time()/3000) * 0.1, i*step + (time()/3000) * 0.5)
				local point = rotatePoint(vec2(120, 68), vec2(120, 68 - radius + noise/2 + noise2/2), (i*step))
				local dir = vec2(120,68) - point
				local p = dir:normalize()
				local pixels = {}
				for i = 1, width do
					local pos = rotatePoint(vec2(120, 68), p*i + point, rotation)
					local col = 1
					if i > width/2 then
						col = clamp(floor(remap(i, width/2, width, 31, 3)), 2, 31)
					else
						col = clamp(floor(remap(i, 2, width/2, 3, 31)), 2, 31)
					end
					table.insert(pixels, {pos = pos, col = col})
				end
				
				for k, v in ipairs(pixels) do
					if v.col > 15 then
						vbank(1)
						pix(v.pos.x, v.pos.y, v.col - 16)
					else
						vbank(0)
						pix(v.pos.x, v.pos.y, v.col)
					end
				end
			end
		end,
	},

	[14] = {
		init = function()
			color_scale = 1.0
			channel = 2
			fade = 0.1
			min_scale = 0.1
			max_scale = 0.85
		end,

		draw = function()
			cla()
			local base_val = 0
			color_scale = color_scale + fade
			if color_scale < min_scale then
				color_scale = min_scale
				fade = -fade
				channel = channel + 1
			elseif color_scale > max_scale then
				color_scale = max_scale
				fade = -fade
			end
			if channel > 31 then channel = 2 end
			local pbg = pal2table(BG_PAL)
			local pfg = pal2table(FG_PAL)

			local tc1 = pbg[channel]
			if channel > 15 then
				--target color
				tc1 = pfg[channel-16]
			end
			local target = (tc1.r+tc1.g+tc1.b)/3
			--trace("r: " .. tc.r .. " g: " .. tc.g .. ", b: " .. tc.b)
			vbank(0)
			for k, v in pairs(pbg) do
				if k > 0 then
					local scl = remap(k, 0, 15, min_scale, (max_scale - min_scale)/2)
					local r,g,b = tc1.r*color_scale*scl, tc1.g*color_scale*scl, tc1.b*color_scale*scl
					setPaletteColor(k, {r = r, g = g, b = b})
				end
			end

			vbank(1)
			for k, v in pairs(pbg) do
				local scl = remap(k, 0, 15, (max_scale - min_scale)/2, max_scale)
				local r,g,b = tc1.r*color_scale*scl, tc1.g*color_scale*scl, tc1.b*color_scale*scl
				setPaletteColor(k, {r = r, g = g, b = b})
			end
			local step = 0.75
			local radius = 45
			local width = 20

			vbank(0)
			for i = 0, 359/step, step do
				local rotation = (time()/100) % 360
				local noise = simplex.Noise1D(i*step + (time()/3000) * 0.1)
				local noise2 = simplex.Noise2D(i*step - (time()/3000) * 0.1, i*step + (time()/3000) * 0.5)
				local point = rotatePoint(vec2(120, 68), vec2(120, 68 - radius + noise/2), (i*step))
				local dir = vec2(120,68) - point
				local p = dir:normalize()
				local pixels = {}
				for i = 1, width do
					local pos = rotatePoint(vec2(120, 68), p*i + point, rotation)
					local col = 1
					if i > width/2 then
						col = clamp(floor(remap(i, width/2, width, 31, 3)), 2, 31)
					else
						col = clamp(floor(remap(i, 2, width/2, 3, 31)), 2, 31)
					end
					--trace('final col: ' .. col)
					table.insert(pixels, {pos = pos, col = col})
				end

				for k, v in ipairs(pixels) do
					if v.col > 15 then
						vbank(1)
						pix(v.pos.x, v.pos.y, v.col - 16)
					else
						vbank(0)
						pix(v.pos.x, v.pos.y, v.col)
					end
				end
			end
		end,
	},

	[15] = {
		init = function()
			-- Initialize any variables specific to the plasma effect
			-- These can be constants for speed, color palette, etc.
		end,

		draw = function()
			vbank(0)
			cls()
			vbank(1)
			cls()
			local t = time() * 0.001
			local color = 0
			local iterations = 1
			local scale = 0.0075
			local scale2 = -0.0525
			local w, h = 75, 75
			local sx, sy = 120 - w/2, 68 - h/2

			for y = sy, sy + h do
				for x = sx, sx + w do
					local n = rotatePoint(vec2(120, 68), vec2(x, y), t*10)
					local n2 = rotatePoint(vec2(120, 68), vec2(x, y), t*-10)
					local val = simplex.Noise2D(n.x * scale + t, n.y * scale + t)
					val = lerp(val, simplex.Noise2D(n2.x * scale2 + t, n2.y * scale2 + t), 0.5)
					color = colors[clamp(floor(remap(val, -1, 1, 1, 31)), 1, 31)]
					if color > 15 then
						vbank(1)
						pix(x, y, color - 16)
					else
						vbank(0)
						pix(x, y, color)
					end
				end
			end
		end,
	},
}

function draw3DGrid(vanishingPointX, vanishingPointY, gridSize, lineCount)
	-- Calculate the distances between grid lines as they move away from the vanishing point
	local distanceX, distanceY
	local horizon = vanishingPointY

	-- Draw the vertical grid lines
	for i = -lineCount, lineCount do
		distanceX = i * gridSize / (1 + 0.1 * math.abs(i))
		line(vanishingPointX + distanceX, horizon, vanishingPointX + distanceX, 136, 15)
	end

	-- Draw the horizontal grid lines
	for j = 1, lineCount * 2 do
		distanceY = j * gridSize / (1 + 0.1 * j)
		local leftX = vanishingPointX - (lineCount * gridSize) / (1 + 0.1 * j)
		local rightX = vanishingPointX + (lineCount * gridSize) / (1 + 0.1 * j)
		line(leftX, horizon + distanceY, rightX, horizon + distanceY, 15)
	end
end


function draw_palette_overlay()
	vbank(0)
	local w, h = 99, 28
	local palette = get_palette()
	if COLOR_MODE == 16 then

	else

	end
	local name = "Palette: " .. (COLOR_MODE == 16 and palettes16[CURRENT_PALETTE].name or palettes32[CURRENT_PALETTE].name)
	rect(1, 1, max(w, tw(name, true) + 2), h, 5)
	draw_palette_widget2(vec2(2, 16), 0, 0)
	draw_palette_widget(vec2(2, 21), 0, 0)
	draw_palette_widget(vec2(30, 21), 1, 0)
	vbank(1)
	local text = "Effect: " .. CURRENT_EFFECT
	prints(text, 2, 2, 3, 15, vec2(0, 0), true)
	prints("Color Mode: " .. COLOR_MODE .. 'x', 8 + tw(text, true), 2, 3, 15, vec2(0, 0), true)
	prints(name, 2, 9, 3, 15, vec2(0, 0), true)
end


function get_palette()
	if COLOR_MODE == 16 then
		return palettes16[CURRENT_PALETTE].val
	elseif COLOR_MODE == 32 then
		return palettes32[CURRENT_PALETTE].val
	end
end


function set_palette(index, sort)
	cla()
	if COLOR_MODE == 16 then
		CURRENT_PALETTE = clamp(index, 1, #palettes16)
		BG_PAL, FG_PAL = expandPalette(get_palette(), 1.0, sort)
		loadPalette(BG_PAL, 0)
		loadPalette(FG_PAL, 1)
	elseif COLOR_MODE == 32 then
		CURRENT_PALETTE = clamp(index, 1, #palettes32)
		local palette = get_palette()
		if sort == 1 then
			palette = sortPalette(palette)
		elseif sort == 2 then
			palette = sortPaletteByHue(palette)
		end
		BG_PAL, FG_PAL = splitPalette(palette)
		loadPalette(BG_PAL, 0)
		loadPalette(FG_PAL, 1)
	end
	-- trace(#palettes32 .. " 32-color palettes")
	-- trace(#palettes16 .. " 16-color palettes")
	-- trace(#palettes16 + #palettes32 .. " total palettes")
end


for k, v in ipairs(EFFECTS) do
	v:init()
end

set_palette(CURRENT_PALETTE, 3)
--loadPalette(palettes[CURRENT_PALETTE].val, 0)
EFFECTS[CURRENT_EFFECT]:init()

function TIC()
	if keyp(60) then
		vbank(0)
		cls()
		vbank(1)
		cls()
		CURRENT_EFFECT = max(1, CURRENT_EFFECT - 1)
		EFFECTS[CURRENT_EFFECT]:init()
	end
	if keyp(61) then
		vbank(0)
		cls()
		vbank(1)
		cls()
		CURRENT_EFFECT = min(#EFFECTS, CURRENT_EFFECT + 1)
		EFFECTS[CURRENT_EFFECT]:init()
	end
	if EFFECTS[CURRENT_EFFECT] then
		EFFECTS[CURRENT_EFFECT]:draw()
	end
	if keyp(58, REPEAT_DELAY, REPEAT_TIME) then
		set_palette(CURRENT_PALETTE - 1)
	end
	if keyp(59, REPEAT_DELAY, REPEAT_TIME) then
		set_palette(CURRENT_PALETTE + 1)
	end

	--vbank(1)
	--loadPalette('1a1c2c5d275db13e53ef7d57ffcd75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57', 1)
	if keyp(93) then
		set_palette(CURRENT_PALETTE, 1)
	end
	if keyp(89) then
		set_palette(CURRENT_PALETTE, 2)
	end
	if keyp(90) then
		set_palette(CURRENT_PALETTE, false)
	end
	if keyp(79) then
		cla()
		SHOW_PALETTE = not SHOW_PALETTE
	end
	if SHOW_PALETTE then
		draw_palette_overlay()
	end
	if keyp(80) then
		COLOR_MODE = COLOR_MODE == 16 and 32 or 16
		set_palette(CURRENT_PALETTE)
	end
	if keyp(83) then
		BG_COLOR = clamp(BG_COLOR - 1, 0, 15)
	end

	if keyp(85) then
		BG_COLOR = clamp(BG_COLOR + 1, 0, 15)
	end
	TICK = TICK + 1
end

-- <TILES>
-- 001:eccccccccc888888caaaaaaaca888888cacccccccacc0ccccacc0ccccacc0ccc
-- 002:ccccceee8888cceeaaaa0cee888a0ceeccca0ccc0cca0c0c0cca0c0c0cca0c0c
-- 003:eccccccccc888888caaaaaaaca888888cacccccccacccccccacc0ccccacc0ccc
-- 004:ccccceee8888cceeaaaa0cee888a0ceeccca0cccccca0c0c0cca0c0c0cca0c0c
-- 016:0011111100111111111111111111111111111111111111111111111111111111
-- 017:cacccccccaaaaaaacaaacaaacaaaaccccaaaaaaac8888888cc000cccecccccec
-- 018:ccca00ccaaaa0ccecaaa0ceeaaaa0ceeaaaa0cee8888ccee000cceeecccceeee
-- 019:cacccccccaaaaaaacaaacaaacaaaaccccaaaaaaac8888888cc000cccecccccec
-- 020:ccca00ccaaaa0ccecaaa0ceeaaaa0ceeaaaa0cee8888ccee000cceeecccceeee
-- </TILES>

-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES>

-- <TRACKS>
-- 000:100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </TRACKS>

-- <PALETTE>
-- 000:1a1c2c5d275db13e53ef7d57ffcd75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57
-- 001:1a1c2c5d275db13e53ef7d57ffcd75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57
-- </PALETTE>

-- <PALETTE1>
-- 000:64988e3d70850f2c2e3456446b7f5cb0b17ce1c584c89660ad5f52913636692f1189542f796e63a17d5eb4a18fecddba
-- 001:1a1c2c5d275db13e53ef7d57ffcd75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57
-- </PALETTE1>

