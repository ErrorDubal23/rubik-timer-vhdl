LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY seg7_driver IS
    PORT (
        min_tens    : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
        min_units   : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
        sec_tens    : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
        sec_units   : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
        ms_hundreds : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
        ms_tens     : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
        ms_units    : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
        
        blink       : IN  STD_LOGIC;  -- Para parpadeo
        blink_en    : IN  STD_LOGIC;  -- Habilitar parpadeo
        
        -- Salidas a displays (catodo común, activo bajo)
        hex7 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);  -- min_tens
        hex6 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);  -- min_units
        hex5 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);  -- sec_tens
        hex4 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);  -- sec_units
        hex3 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);  -- ms_hundreds
        hex2 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);  -- ms_tens
        hex1 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);  -- ms_units
        hex0 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)   -- no usado / apagado
    );
END ENTITY seg7_driver;

ARCHITECTURE behavioral OF seg7_driver IS
    -- Decodificador BCD a 7-segmentos
    -- Segmentos: g,f,e,d,c,b,a (catodo común, 0 = encendido)
    FUNCTION bcd_to_7seg(bcd : STD_LOGIC_VECTOR(3 DOWNTO 0)) RETURN STD_LOGIC_VECTOR IS
    BEGIN
        CASE bcd IS
            WHEN "0000" => RETURN "1000000"; -- 0
            WHEN "0001" => RETURN "1111001"; -- 1
            WHEN "0010" => RETURN "0100100"; -- 2
            WHEN "0011" => RETURN "0110000"; -- 3
            WHEN "0100" => RETURN "0011001"; -- 4
            WHEN "0101" => RETURN "0010010"; -- 5
            WHEN "0110" => RETURN "0000010"; -- 6
            WHEN "0111" => RETURN "1111000"; -- 7
            WHEN "1000" => RETURN "0000000"; -- 8
            WHEN "1001" => RETURN "0010000"; -- 9
            WHEN OTHERS => RETURN "1111111"; -- Apagado
        END CASE;
    END FUNCTION;
    
    SIGNAL blink_mask : STD_LOGIC_VECTOR(6 DOWNTO 0);
BEGIN
    -- Máscara de parpadeo
    blink_mask <= (OTHERS => '0') WHEN (blink_en = '1' AND blink = '1') ELSE (OTHERS => '1');
    
    -- Asignar displays con posible parpadeo
    hex7 <= bcd_to_7seg(min_tens)    OR blink_mask;
    hex6 <= bcd_to_7seg(min_units)   OR blink_mask;
    hex5 <= bcd_to_7seg(sec_tens)    OR blink_mask;
    hex4 <= bcd_to_7seg(sec_units)   OR blink_mask;
    hex3 <= bcd_to_7seg(ms_hundreds) OR blink_mask;
    hex2 <= bcd_to_7seg(ms_tens)     OR blink_mask;
    hex1 <= bcd_to_7seg(ms_units)    OR blink_mask;
    hex0 <= "1111111"; -- Apagado
    
END ARCHITECTURE behavioral;
