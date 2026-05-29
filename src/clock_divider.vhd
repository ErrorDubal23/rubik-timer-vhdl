LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY clock_divider IS
    PORT (
        clk     : IN  STD_LOGIC;  -- 50 MHz
        reset_n : IN  STD_LOGIC;  -- Reset activo bajo
        tick_1k : OUT STD_LOGIC   -- Pulso de 1 kHz (1 ms)
    );
END ENTITY clock_divider;

ARCHITECTURE behavioral OF clock_divider IS
    CONSTANT DIVISOR : INTEGER := 50000; -- 50 MHz / 1000 = 50,000
    SIGNAL counter   : INTEGER RANGE 0 TO DIVISOR - 1;
    SIGNAL tick_reg  : STD_LOGIC;
BEGIN
    PROCESS(clk, reset_n)
    BEGIN
        IF reset_n = '0' THEN
            counter  <= 0;
            tick_reg <= '0';
        ELSIF RISING_EDGE(clk) THEN
            tick_reg <= '0'; -- Default
            IF counter = DIVISOR - 1 THEN
                counter  <= 0;
                tick_reg <= '1'; -- Pulso de 1 ciclo cada 1 ms
            ELSE
                counter <= counter + 1;
            END IF;
        END IF;
    END PROCESS;

    tick_1k <= tick_reg;
END ARCHITECTURE behavioral;
