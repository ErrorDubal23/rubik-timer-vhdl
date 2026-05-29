LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY rubik_timer_top IS
    PORT (
        -- Clock y reset
        CLOCK_50 : IN  STD_LOGIC;
        
        -- Botones (activos bajos en DE2-115)
        KEY : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
        
        -- Switches
        SW  : IN  STD_LOGIC_VECTOR(0 DOWNTO 0);
        
        -- Displays 7 segmentos (catodo común)
        HEX0 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        HEX1 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        HEX2 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        HEX3 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        HEX4 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        HEX5 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        HEX6 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        HEX7 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        
        -- LEDs
        LEDR : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);  -- Estado
        LEDG : OUT STD_LOGIC_VECTOR(0 DOWNTO 0)   -- Manos detectadas
    );
END ENTITY rubik_timer_top;

ARCHITECTURE structural OF rubik_timer_top IS
    -- Señales internas
    SIGNAL reset_n       : STD_LOGIC;
    SIGNAL btn_debounced : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL tick_1k       : STD_LOGIC;
    
    -- Entradas procesadas
    SIGNAL power         : STD_LOGIC;
    SIGNAL reset_btn     : STD_LOGIC;
    SIGNAL left_hand     : STD_LOGIC;
    SIGNAL right_hand    : STD_LOGIC;
    SIGNAL start_insp    : STD_LOGIC;
    
    -- Salidas FSM
    SIGNAL state_out     : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL timer_enable  : STD_LOGIC;
    SIGNAL timer_reset   : STD_LOGIC;
    SIGNAL timer_mode_d  : STD_LOGIC;
    SIGNAL display_blink : STD_LOGIC;
    SIGNAL led_hands     : STD_LOGIC;
    
    -- Salidas tiempo
    SIGNAL min_tens, min_units       : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL sec_tens, sec_units       : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL ms_hundreds, ms_tens, ms_units : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL countdown_done : STD_LOGIC;
    
    -- Señal de reset global (power OFF o reset físico)
    SIGNAL global_reset  : STD_LOGIC;
    SIGNAL timer_start_val_sig : INTEGER RANGE 0 TO 5999999;
    
BEGIN
    -- Reset global: activo bajo (power debe ser '1' para encender)
    reset_n <= SW(0);
    global_reset <= reset_n;
    
    -- Asignar entradas debounced (ya invertidas por debouncer)
    power      <= SW(0);
    reset_btn  <= btn_debounced(2);
    left_hand  <= btn_debounced(0);
    right_hand <= btn_debounced(1);
    start_insp <= btn_debounced(3);
    
    -- Instancia del debouncer
    debouncer_inst : ENTITY work.debouncer
        PORT MAP (
            clk     => CLOCK_50,
            reset_n => global_reset,
            btn_in  => KEY,
            btn_out => btn_debounced
        );
    
    -- Divisor de clock (50 MHz → 1 kHz)
    clock_div_inst : ENTITY work.clock_divider
        PORT MAP (
            clk     => CLOCK_50,
            reset_n => global_reset,
            tick_1k => tick_1k
        );
    
    -- Máquina de estados
    fsm_inst : ENTITY work.fsm_controller
        PORT MAP (
            clk              => CLOCK_50,
            reset_n          => global_reset,
            power            => power,
            reset_btn        => reset_btn,
            left_hand        => left_hand,
            right_hand       => right_hand,
            start_inspection => start_insp,
            countdown_done   => countdown_done,
            state_out        => state_out,
            timer_enable     => timer_enable,
            timer_reset      => timer_reset,
            timer_mode_down  => timer_mode_d,
            timer_start_val  => timer_start_val_sig,
            display_blink    => display_blink,
            led_hands        => led_hands
        );
    
    -- Contador de tiempo
    time_counter_inst : ENTITY work.time_counter
        PORT MAP (
            clk         => CLOCK_50,
            reset_n     => global_reset,
            tick_1k     => tick_1k,
            enable      => timer_enable,
            reset_time  => timer_reset,
            mode_down   => timer_mode_d,
            start_val   => timer_start_val_sig,
            min_tens    => min_tens,
            min_units   => min_units,
            sec_tens    => sec_tens,
            sec_units   => sec_units,
            ms_hundreds => ms_hundreds,
            ms_tens     => ms_tens,
            ms_units    => ms_units,
            done        => countdown_done
        );
    
    -- Driver de 7 segmentos
    seg7_inst : ENTITY work.seg7_driver
        PORT MAP (
            min_tens    => min_tens,
            min_units   => min_units,
            sec_tens    => sec_tens,
            sec_units   => sec_units,
            ms_hundreds => ms_hundreds,
            ms_tens     => ms_tens,
            ms_units    => ms_units,
            blink       => display_blink,
            blink_en    => display_blink,
            hex7        => HEX7,
            hex6        => HEX6,
            hex5        => HEX5,
            hex4        => HEX4,
            hex3        => HEX3,
            hex2        => HEX2,
            hex1        => HEX1,
            hex0        => HEX0
        );
    
    -- Salidas LED
    LEDR <= state_out;
    LEDG(0) <= led_hands;
    
END ARCHITECTURE structural;
