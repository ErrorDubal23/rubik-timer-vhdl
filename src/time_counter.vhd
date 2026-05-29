LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY time_counter IS
    PORT (
        clk        : IN  STD_LOGIC;                    -- 50 MHz
        reset_n    : IN  STD_LOGIC;                    -- Reset general
        tick_1k    : IN  STD_LOGIC;                    -- Pulso 1 ms
        enable     : IN  STD_LOGIC;                    -- Habilita cuenta
        reset_time : IN  STD_LOGIC;                    -- Reset del tiempo
        mode_down  : IN  STD_LOGIC;                    -- '1' = descendente, '0' = ascendente
        start_val  : IN  INTEGER RANGE 0 TO 5999999;   -- Valor inicial para cuenta descendente (en ms)
        
        -- Salidas en BCD
        min_tens   : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        min_units  : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        sec_tens   : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        sec_units  : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        ms_hundreds: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        ms_tens    : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        ms_units   : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        
        -- Flags
        done       : OUT STD_LOGIC;                     -- Cuenta terminada (para countdown)
        total_ms   : OUT INTEGER RANGE 0 TO 5999999     -- Tiempo total en ms (para pausa)
    );
END ENTITY time_counter;

ARCHITECTURE behavioral OF time_counter IS
    SIGNAL count_ms   : INTEGER RANGE 0 TO 5999999;  -- Hasta 99:59.999
    SIGNAL total_time : INTEGER RANGE 0 TO 5999999;
    
    -- Registros BCD
    SIGNAL m_tens, m_units : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL s_tens, s_units : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL ms_h, ms_t, ms_u : STD_LOGIC_VECTOR(3 DOWNTO 0);
BEGIN
    -- Proceso de conteo
    PROCESS(clk, reset_n)
    BEGIN
        IF reset_n = '0' THEN
            count_ms <= 0;
            done <= '0';
        ELSIF RISING_EDGE(clk) THEN
            IF reset_time = '1' THEN
                IF mode_down = '1' THEN
                    count_ms <= start_val;  -- 15000 para 15 segundos
                ELSE
                    count_ms <= 0;
                END IF;
                done <= '0';
            ELSIF tick_1k = '1' AND enable = '1' THEN
                IF mode_down = '1' THEN
                    -- Cuenta descendente
                    IF count_ms = 0 THEN
                        done <= '1';
                    ELSE
                        count_ms <= count_ms - 1;
                    END IF;
                ELSE
                    -- Cuenta ascendente
                    IF count_ms < 5999999 THEN
                        count_ms <= count_ms + 1;
                    END IF;
                    done <= '0';
                END IF;
            END IF;
        END IF;
    END PROCESS;
    
    -- Total ms para pausa
    total_time <= count_ms;
    total_ms <= total_time;
    
    -- Conversión a BCD
    PROCESS(count_ms)
        VARIABLE temp  : INTEGER RANGE 0 TO 5999999;
        VARIABLE m_t, m_u : INTEGER RANGE 0 TO 9;
        VARIABLE s_t, s_u : INTEGER RANGE 0 TO 9;
        VARIABLE ms_h_v, ms_t_v, ms_u_v : INTEGER RANGE 0 TO 9;
    BEGIN
        temp := count_ms;
        
        -- Extraer milisegundos
        ms_u_v := temp MOD 10;
        temp := temp / 10;
        ms_t_v := temp MOD 10;
        temp := temp / 10;
        ms_h_v := temp MOD 10;
        temp := temp / 10;
        
        -- Extraer segundos
        s_u := temp MOD 10;
        temp := temp / 10;
        s_t := temp MOD 10;
        temp := temp / 10;
        
        -- Extraer minutos
        m_u := temp MOD 10;
        temp := temp / 10;
        m_t := temp MOD 10;
        
        -- Asignar a señales
        ms_units <= STD_LOGIC_VECTOR(TO_UNSIGNED(ms_u_v, 4));
        ms_tens <= STD_LOGIC_VECTOR(TO_UNSIGNED(ms_t_v, 4));
        ms_hundreds <= STD_LOGIC_VECTOR(TO_UNSIGNED(ms_h_v, 4));
        sec_units <= STD_LOGIC_VECTOR(TO_UNSIGNED(s_u, 4));
        sec_tens <= STD_LOGIC_VECTOR(TO_UNSIGNED(s_t, 4));
        min_units <= STD_LOGIC_VECTOR(TO_UNSIGNED(m_u, 4));
        min_tens <= STD_LOGIC_VECTOR(TO_UNSIGNED(m_t, 4));
    END PROCESS;
    
    -- Asignar salidas
    min_tens <= m_tens;
    min_units <= m_units;
    sec_tens <= s_tens;
    sec_units <= s_units;
    ms_hundreds <= ms_h;
    ms_tens <= ms_t;
    ms_units <= ms_u;
    
END ARCHITECTURE behavioral;
