----------------------------------------------------------------------------------
-- Students:        Belotti Ottavia    CP:__
--                  Barone Javin       CP:__
--
-- Module Name:     project_reti_logiche - Behavioral
-- Project Name:    Progetto Reti Logiche A.A. 2020/21
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

----------------------------------------------------------------------------------
-- PROJECT DEFINED INPUT AND OUTPUT
----------------------------------------------------------------------------------

entity project_reti_logiche is
  Port (
    i_clk       : in std_logic;
    i_rst       : in std_logic;
    i_start     : in std_logic;
    i_data      : in std_logic_vector(7 downto 0);
    o_address   : out std_logic_vector(15 downto 0);
    o_done      : out std_logic;
    o_en        : out std_logic;
    o_we        : out std_logic;
    o_data      : out std_logic_vector(7 downto 0)
   );
end project_reti_logiche;


architecture Behavioral of project_reti_logiche is
    type fsm_state is (
        IDLE,
        DIM_READING,
        LAST_ADDR_COMPUTE,
        MIN_MAX_FETCH,
        DELTA_VALUE_COMPUTE,
        SHIFT_COMPUTE,
        NEW_PIXEL_COMPUTE,
        MEM_WRITE_PIXEL,
        MEM_READ,
        END_COMPUTE,
        WAIT_CONFIRM
    );

----------------------------------------------------------------------------------
-- INTERNAL SIGNALS
----------------------------------------------------------------------------------

    -- General
    signal current_state, next_state        : fsm_state := IDLE;
    signal last_address, next_last_address  : std_logic_vector(15 downto 0) := (others => '0');

    -- Variables and flags
    signal width, next_width                : std_logic_vector(7 downto 0);
    signal height, next_height              : std_logic_vector(7 downto 0);
    signal read_size, next_read_size        : std_logic := '0';             -- width: addr(0) , height: addr(1)

    signal min, next_min                    : std_logic_vector(7 downto 0);
    signal max, next_max                    : std_logic_vector(7 downto 0);

    signal delta_value, next_delta_value    : std_logic_vector(8 downto 0) := (others => '0');
    signal log, next_log                    : std_logic_vector(3 downto 0) := (others => '0');
    signal shift_level, next_shift_level    : std_logic_vector(3 downto 0) := (others => '0');

    signal temp_pixel, next_temp_pixel      : std_logic_vector(15 downto 0);

    -- Counters
    signal counter, next_counter : std_logic_vector(15 downto 0) := (others => '0');


----------------------------------------------------------------------------------
-- SIGNAL HANDLING
----------------------------------------------------------------------------------

begin
    STATE_OUTPUT: process(i_clk, i_rst)
    begin
        if(i_rst='1') then
            current_state <= IDLE;

         elsif rising_edge(i_clk) then
            last_address <= next_last_address;
            current_state <= next_state;

            width <= next_width;
            height <= next_height;
            read_size <= next_read_size;

            min <= next_min;
            max <= next_max;

            delta_value <= next_delta_value;
            log <= next_log;
            shift_level <= next_shift_level;

            temp_pixel <= next_temp_pixel;

            counter <= next_counter;

         end if;
    end process;

    DELTA_LAMBDA: process(i_start, current_state, i_data, last_address, read_size, width, height, min, max, shift_level, counter, temp_pixel, log, delta_value)
    begin
        o_data <= (others => '0');
        o_done <= '0';
        o_address <= (others => '0');
        o_en <= '0';
        o_we <= '0';

        next_last_address <= last_address;
        next_state <= current_state;

        next_width <= width;
        next_height <= height;
        next_read_size <= read_size;

        next_min <= min;
        next_max <= max;

        next_delta_value <= delta_value;
        next_log <= log;
        next_shift_level <= shift_level;

        next_temp_pixel <= temp_pixel;

        next_counter <= counter;

        case current_state is

----------------------------------------------------------------------------------
-- IDLE
----------------------------------------------------------------------------------

            when IDLE =>

                if(i_start = '1') then
                    o_done <= '0';
                    o_en <= '1';
                    o_we <= '0';
                    o_address <= (others => '0');

                    next_last_address <= (others => '0');
                    next_shift_level <= (others => '0');
                    next_min <= (others => '1');
                    next_max <= (others => '0');
                    next_read_size <= '0';
                    next_delta_value <= (others => '0');

                    next_state <= DIM_READING;
                 else
                    next_state <= IDLE;
                end if;


----------------------------------------------------------------------------------
-- DIM_READING
----------------------------------------------------------------------------------

            when DIM_READING =>
                o_en <= '1';
                o_we <= '0';


                if (read_size = '0') then                          -- read width at address 0001
                    o_address <= "0000000000000001";

                    next_width <= i_data;
                    next_read_size <= '1';

                    next_state <= DIM_READING;

                else                                               -- read height at address 0010
                    o_address <= "0000000000000010";

                    next_height <= i_data;
                    next_counter <= (others => '0');
                    next_last_address <= (others => '0');

                    next_state <= LAST_ADDR_COMPUTE;

                end if;

----------------------------------------------------------------------------------
-- LAST_ADDR_COMPUTE
----------------------------------------------------------------------------------

            when LAST_ADDR_COMPUTE =>

                if(counter = "000000001000") then
                    o_address <= "0000000000000010";
                    o_en <= '1';
                    o_we <= '0';

                    next_state <= MIN_MAX_FETCH;

                    next_counter <= (others => '0');
                    next_last_address <= last_address + "0000000000000001";
                else
                    --last_address <= width*height: shift width vector according to each height bit's weight (2*n)
                    next_counter <= counter + "0000000000000001";
                    if(height(0) = '1') then
                        next_last_address <= last_address + std_logic_vector(shift_left("00000000" & unsigned(width), to_integer(unsigned(counter))));
                    end if;
                    --consume 1 bit of height vector for the next operation
                    next_height <= std_logic_vector(shift_right(unsigned(height), 1));

                    next_state <= LAST_ADDR_COMPUTE;

                end if;

----------------------------------------------------------------------------------
-- MIN_MAX_FETCH
----------------------------------------------------------------------------------

            when MIN_MAX_FETCH =>
                if(last_address = "0000000000000001") then
                    o_done <= '1';
                    next_state <= WAIT_CONFIRM;
                elsif((counter = last_address - "0000000000000001") or (min="00000000" and max="11111111")) then
                    o_address <= "0000000000000010";

                    next_delta_value <= ('0' & max) - ('0' & min) + "000000001";

                    next_state <= DELTA_VALUE_COMPUTE;

                else
                    if(i_data < min) then                   -- compare data to min
                        next_min <= i_data;
                    else
                        next_min <= min;
                    end if;

                    if(i_data > max) then                   -- compare data to max
                        next_max <= i_data;
                    else
                        next_max <= max;
                    end if;

                    o_address <= counter + "0000000000000011";
                    o_en <= '1';
                    o_we <= '0';

                    next_counter <= counter + "0000000000000001";

                    next_state <= MIN_MAX_FETCH;
                end if;

----------------------------------------------------------------------------------
-- DELTA_VALUE_COMPUTE
----------------------------------------------------------------------------------

            when DELTA_VALUE_COMPUTE =>

                if(   delta_value >= "100000000") then
                    next_log <= "1000";
                elsif(delta_value >= "010000000") then
                    next_log <= "0111";
                elsif(delta_value >= "001000000") then
                    next_log <= "0110";
                elsif(delta_value >= "000100000") then
                    next_log <= "0101";
                elsif(delta_value >= "000010000") then
                    next_log <= "0100";
                elsif(delta_value >= "000001000") then
                    next_log <= "0011";
                elsif(delta_value >= "000000100") then
                    next_log <= "0010";
                elsif(delta_value >= "000000010") then
                    next_log <= "0001";
                elsif(delta_value >= "000000001") then
                    next_log <= "0000";
                else
                    next_log <= "XXXX";
                end if;

                next_counter <= (others => '0');

                next_state <= SHIFT_COMPUTE;


----------------------------------------------------------------------------------
-- SHIFT_COMPUTE
----------------------------------------------------------------------------------

            when SHIFT_COMPUTE =>
                o_address <= "0000000000000010";
                o_en <= '1';
                o_we <= '0';

                next_shift_level <= "1000" - log;

                next_state <= NEW_PIXEL_COMPUTE;

----------------------------------------------------------------------------------
-- NEW_PIXEL_COMPUTE
----------------------------------------------------------------------------------

            when NEW_PIXEL_COMPUTE =>
                  o_en <= '0';
                  o_we <= '0';


                  next_temp_pixel <= std_logic_vector(shift_left(("00000000" & unsigned(i_data - min)), to_integer(unsigned(shift_level))));

                  next_state <= MEM_WRITE_PIXEL;

----------------------------------------------------------------------------------
-- MEM_WRITE_PIXEL
----------------------------------------------------------------------------------

            when MEM_WRITE_PIXEL =>

                if(temp_pixel < "0000000011111111") then
                    o_data <= temp_pixel(7 downto 0);

                else
                    o_data <= "11111111";
                end if;

                o_address <= last_address + counter + "0000000000000001";
                o_en <= '1';
                o_we <= '1';

                next_counter <= counter + "0000000000000001";

                next_state <= MEM_READ;


----------------------------------------------------------------------------------
-- MEM_READ
----------------------------------------------------------------------------------

            when MEM_READ =>
                if(counter = last_address - "0000000000000001") then
                    --o_done <= '1';
                    o_en <= '0';
                    o_we <= '0';

                    next_state <= END_COMPUTE;

                else
                    o_address <= counter + "0000000000000010";
                    o_en <= '1';
                    o_we <= '0';


                    next_state <= NEW_PIXEL_COMPUTE;
                end if;

----------------------------------------------------------------------------------
-- END_COMPUTE
----------------------------------------------------------------------------------

              when END_COMPUTE =>
                o_done <= '1';
                next_state <= WAIT_CONFIRM;

----------------------------------------------------------------------------------
-- WAIT_CONFIRM
----------------------------------------------------------------------------------

             when WAIT_CONFIRM =>

                if(i_start = '0') then
                    o_done <= '0';

                    next_state <= IDLE;

                else
                    o_done <= '1';

                    next_state <= WAIT_CONFIRM;
                end if;


          end case;
    end process;

end Behavioral;
