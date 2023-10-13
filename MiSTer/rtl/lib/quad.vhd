-- (c) 2020 d18c7db(a)hotmail
--
-- This program is free software; you can redistribute it and/or modify it under
-- the terms of the GNU General Public License version 3 or, at your option,
-- any later version as published by the Free Software Foundation.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
--
-- For full details, see the GNU General Public License at www.gnu.org/licenses

-- Convert mouse or joystick inputs to quadrature outputs for driving LETA
-- Wheel mode simulates a wheel which turns 90 degrees CW or CCW from a center idle position (only outputs on quadrature channel X)

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_unsigned.all;
	use ieee.numeric_std.all;

entity QUAD is
	port(
		clk        : in  std_logic;
		mode       : in  std_logic; -- 1 = wheel mode, 0 = joy/mouse
		joy        : in  std_logic_vector(15 downto 0);
		mouse      : in  std_logic_vector(24 downto 0);
		speed      : in  std_logic_vector( 1 downto 0);

		-- quadrature outputs
		XA         : out std_logic := '0'; -- horizontal movement and wheel turns
		XB         : out std_logic := '0'; -- horizontal movement and wheel turns
		YA         : out std_logic := '0'; -- vertical movement
		YB         : out std_logic := '0'  -- vertical movement
	);
end QUAD;

architecture RTL of QUAD is
	constant sample_interval : natural range 0 to 31 := 15;
	signal sample            : natural range 0 to 31:= sample_interval;
	signal idx               : natural range 0 to 15 := 12;

	alias  mclk              : std_logic is mouse(24);
	signal mclk_last         : std_logic := '0';
	signal x_dir, y_dir      : std_logic := '0';
	signal wheel             : signed( 3 downto 0) := (others => '0');
	signal timer             : std_logic_vector(13 downto 0) := (others => '0'); -- clocked at 7.159Mhz gives 437 rollovers / second
	signal x_ctr, y_ctr      : signed( 7 downto 0) := (others => '0');
begin
	idx <=
		10 when (mode = '0' and speed = "00") else -- 1:1 fastest
		11 when (mode = '0' and speed = "01") else -- 1:2 fast
		12 when (mode = '0' and speed = "10") else -- 1:4 medium
		13 when (mode = '0' and speed = "11") else -- 1:8 slow
		11; -- when in wheel mode

	-- generate horizontal quadrature outputs
	p_QX : process
	begin
		wait until rising_edge(clk);
		if (x_ctr /= 0) then
			XA <= timer(idx) xor ( (    x_dir) and timer(idx-1) );
			XB <= timer(idx) xor ( (not x_dir) and timer(idx-1) );
		end if;
	end process;

	-- generate vertical quadrature outputs
	p_QY : process
	begin
		wait until rising_edge(clk);
		if (y_ctr /= 0) then
			YA <= timer(idx) xor ( (    y_dir) and timer(idx-1) );
			YB <= timer(idx) xor ( (not y_dir) and timer(idx-1) );
		end if;
	end process;

	-- scans joystick inputs for changes
	p_inputs : process
	begin
		wait until rising_edge(clk);
		timer <= timer - 1;
		-- mouse input is not sampled because it provides us with a clock for each event
		if (mode = '0') then -- if mouse mode
			mclk_last <= mclk; -- mouse clock seems to run at 62 Hz
			if (mclk_last /= mclk) then
				timer <= (others=>'1');
				-- Horizontal mouse movement
				x_dir <= mouse(4); -- 1=L 0=R
				x_ctr <= abs(signed((mouse(4) & mouse(15 downto  9))));
				-- Vertical mouse movement
				y_dir <= not mouse(5); -- 0=U 1=D (invert to match joystick)
				y_ctr <= abs(signed((mouse(5) & mouse(23 downto 17))));
			end if;
		end if;

		-- on timer rollover scan joystick and update x/y counters
		if (timer = 0) then
			if (sample = 0) then
				sample <= sample_interval;
			else
				sample <= sample - 1;
			end if;
			if (x_ctr /= 0) then
				x_ctr <= x_ctr - 1;
			end if;
			if (y_ctr /= 0) then
				y_ctr <= y_ctr - 1;
			end if;

			-- joystick is sampled every 7.158Mhz/(timer*sample_interval) roughly at 27Hz
			if (sample = 0) then
				if (mode = '1') then -- if weel mode
					if    (wheel = signed(joy(7 downto 4))) then
						x_ctr <= (others => '0');
						y_ctr <= (others => '0');
					elsif (wheel > signed(joy(7 downto 4))) then
						x_dir <= '1'; -- 1=L
						x_ctr <= x"01";
						wheel <= wheel - 1;
					elsif (wheel < signed(joy(7 downto 4))) then
						x_dir <= '0'; -- 0=R
						x_ctr <= x"01";
						wheel <= wheel + 1;
					end if;
				else -- else mouse/joystick mode
					x_dir <= joy( 7); -- 1=L 0=R
					x_ctr <= abs(signed(joy( 7 downto 0))/8);
					y_dir <= joy(15); -- 1=U 0=D
					y_ctr <= abs(signed(joy(15 downto 8))/8);
				end if;
			end if;
		end if;
	end process;
end RTL;
