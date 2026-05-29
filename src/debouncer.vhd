LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY debouncer IS
    PORT (
        clk     : IN  STD_LOGIC;                    -- 50 MHz
        reset_n : IN  STD_LOGIC;                    -- Reset activo bajo
        btn_in  : IN  STD_LOGIC_VECTOR(3 DOWNTO 0); -- Botones crudos (activos bajos)
        btn_out : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)  -- Botones limpios (activos altos, después de debounce)
    );
END ENTITY debouncer;

ARCHITECTURE behavioral OF debouncer IS
    -- Contador para 20 ms a 50 MHz = 1,000,000 ciclos
    CONSTANT DEBOUNCE_LIMIT : INTEGER := 1_000_000;
    
    SIGNAL counter : INTEGER RANGE 0 TO DEBOUNCE_LIMIT;
    SIGNAL btn_sync_0, btn_sync_1 : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL btn_stable : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL btn_prev   : STD_LOGIC_VECTOR(3 DOWNTO 0);
BEGIN
    -- Sincronización y debounce
    PROCESS(clk, reset_n)
    BEGIN
        IF reset_n = '0' THEN
            btn_sync_0 <= (OTHERS => '1'); -- Botones activos bajos, estado inactivo = '1'
            btn_sync_1 <= (OTHERS => '1');
            btn_stable <= (OTHERS => '1');
            btn_prev   <= (OTHERS => '1');
            counter    <= 0;
            
        ELSIF RISING_EDGE(clk) THEN
            -- Doble sincronización para metastabilidad
            btn_sync_0 <= btn_in;
            btn_sync_1 <= btn_sync_0;
            
            -- Debounce por contador
            IF btn_sync_1 = btn_prev THEN
                -- Estado estable, verificar si cumplió tiempo
                IF counter < DEBOUNCE_LIMIT THEN
                    counter <= counter + 1;
                ELSE
                    btn_stable <= btn_sync_1;
                END IF;
            ELSE
                -- Cambio detectado, reiniciar contador
                btn_prev <= btn_sync_1;
                counter  <= 0;
            END IF;
        END IF;
    END PROCESS;
    
    -- Salida: invertir (activo bajo → activo alto)
    btn_out <= NOT btn_stable;
    
END ARCHITECTURE behavioral;
