LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY fsm_controller IS
    PORT (
        clk              : IN  STD_LOGIC;
        reset_n          : IN  STD_LOGIC;
        
        -- Entradas
        power            : IN  STD_LOGIC;  -- SW[0]
        reset_btn        : IN  STD_LOGIC;  -- KEY[2] (ya debounced)
        left_hand        : IN  STD_LOGIC;  -- KEY[0] (ya debounced)
        right_hand       : IN  STD_LOGIC;  -- KEY[1] (ya debounced)
        start_inspection : IN  STD_LOGIC;  -- KEY[3] (ya debounced)
        countdown_done   : IN  STD_LOGIC;  -- De time_counter
        
        -- Salidas de control
        state_out        : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);  -- Para LEDs
        timer_enable     : OUT STD_LOGIC;  -- Habilita contador
        timer_reset      : OUT STD_LOGIC;  -- Resetea contador
        timer_mode_down  : OUT STD_LOGIC;  -- '1' = descendente
        timer_start_val  : OUT INTEGER RANGE 0 TO 5999999;
        display_blink    : OUT STD_LOGIC;  -- Parpadeo display
        led_hands        : OUT STD_LOGIC   -- LED verde manos
    );
END ENTITY fsm_controller;

ARCHITECTURE behavioral OF fsm_controller IS
    TYPE state_type IS (OFF, IDLE_DOWN, COUNTDOWN, WAITING, RUN, PAUSED);
    SIGNAL state, next_state : state_type;
    
    CONSTANT START_COUNTDOWN_MS : INTEGER := 15000;  -- 15 segundos
BEGIN
    -- Registro de estado (sincronico)
    PROCESS(clk, reset_n)
    BEGIN
        IF reset_n = '0' THEN
            state <= OFF;
        ELSIF RISING_EDGE(clk) THEN
            state <= next_state;
        END IF;
    END PROCESS;
    
    -- Lógica de transición de estados (combinacional)
    PROCESS(state, power, reset_btn, left_hand, right_hand, 
            start_inspection, countdown_done)
    BEGIN
        -- Default: mantener estado
        next_state <= state;
        
        CASE state IS
            WHEN OFF =>
                IF power = '1' THEN
                    next_state <= IDLE_DOWN;
                END IF;
                
            WHEN IDLE_DOWN =>
                IF power = '0' THEN
                    next_state <= OFF;
                ELSIF reset_btn = '1' THEN
                    next_state <= IDLE_DOWN;  -- Ya está aquí
                ELSIF start_inspection = '1' THEN
                    next_state <= COUNTDOWN;
                END IF;
                
            WHEN COUNTDOWN =>
                IF power = '0' THEN
                    next_state <= OFF;
                ELSIF reset_btn = '1' THEN
                    next_state <= IDLE_DOWN;
                ELSIF countdown_done = '1' THEN
                    next_state <= IDLE_DOWN;  -- Se pasó el tiempo
                ELSIF left_hand = '1' AND right_hand = '1' THEN
                    next_state <= WAITING;  -- Ambas manos puestas
                END IF;
                
            WHEN WAITING =>
                IF power = '0' THEN
                    next_state <= OFF;
                ELSIF reset_btn = '1' THEN
                    next_state <= IDLE_DOWN;
                ELSIF left_hand = '0' OR right_hand = '0' THEN
                    -- Suelta AL MENOS UNA mano → RUN
                    next_state <= RUN;
                END IF;
                
            WHEN RUN =>
                IF power = '0' THEN
                    next_state <= OFF;
                ELSIF reset_btn = '1' THEN
                    next_state <= IDLE_DOWN;
                ELSIF left_hand = '1' AND right_hand = '1' THEN
                    -- Ambas manos presionadas → PAUSED
                    next_state <= PAUSED;
                END IF;
                
            WHEN PAUSED =>
                IF power = '0' THEN
                    next_state <= OFF;
                ELSIF reset_btn = '1' THEN
                    next_state <= IDLE_DOWN;
                ELSIF left_hand = '0' OR right_hand = '0' THEN
                    -- Suelta AL MENOS UNA mano → RUN
                    next_state <= RUN;
                END IF;
                
            WHEN OTHERS =>
                next_state <= OFF;
        END CASE;
    END PROCESS;
    
    -- Salidas de control según estado
    PROCESS(state)
    BEGIN
        -- Defaults
        timer_enable    <= '0';
        timer_reset     <= '0';
        timer_mode_down <= '0';
        timer_start_val <= 0;
        display_blink   <= '0';
        led_hands       <= '0';
        state_out       <= "000";
        
        CASE state IS
            WHEN OFF =>
                state_out     <= "000";
                timer_reset   <= '1';
                
            WHEN IDLE_DOWN =>
                state_out     <= "001";
                timer_reset   <= '1';
                
            WHEN COUNTDOWN =>
                state_out     <= "010";
                timer_enable  <= '1';
                timer_mode_down <= '1';
                timer_start_val <= START_COUNTDOWN_MS;
                display_blink <= '1';  -- Parpadeo rápido
                
            WHEN WAITING =>
                state_out     <= "011";
                led_hands     <= '1';  -- LED verde: manos listas
                
            WHEN RUN =>
                state_out     <= "100";
                timer_enable  <= '1';
                timer_mode_down <= '0';  -- Ascendente
                
            WHEN PAUSED =>
                state_out     <= "101";
                -- Timer congelado, enable = 0
                display_blink <= '1';  -- Parpadeo lento
                
            WHEN OTHERS =>
                state_out <= "000";
        END CASE;
    END PROCESS;
    
END ARCHITECTURE behavioral;
