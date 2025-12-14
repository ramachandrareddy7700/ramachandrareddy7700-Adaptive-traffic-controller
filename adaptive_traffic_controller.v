// ==============================================================================
// Adaptive Four-Way Traffic Control System using Verilog HDL
// ==============================================================================
// Designer: Digital Design Engineer
// Description: FSM-based adaptive traffic light controller with emergency override
// Features:
//   - Four-way traffic control (North, South, East, West)
//   - Adaptive timing based on traffic density
//   - Emergency vehicle override with highest priority
//   - Synchronous design with reset capability
// ==============================================================================

module adaptive_traffic_controller (
    // Clock and Reset
    input wire clk,                    // System clock
    input wire rst_n,                  // Active-low asynchronous reset
    
    // Traffic Density Inputs (2-bit per direction)
    // 00 = Low, 01 = Medium, 10 = High, 11 = Very High
    input wire [1:0] traffic_north,    // North direction traffic density
    input wire [1:0] traffic_south,    // South direction traffic density
    input wire [1:0] traffic_east,     // East direction traffic density
    input wire [1:0] traffic_west,     // West direction traffic density
    
    // Emergency Override Inputs
    input wire emergency_override,     // Emergency override enable
    input wire [1:0] emergency_dir,    // Emergency direction: 00=N, 01=S, 10=E, 11=W
    
    // Traffic Light Outputs (3-bit per direction: Red, Yellow, Green)
    output reg [2:0] lights_north,     // North lights [R,Y,G]
    output reg [2:0] lights_south,     // South lights [R,Y,G]
    output reg [2:0] lights_east,      // East lights [R,Y,G]
    output reg [2:0] lights_west,      // West lights [R,Y,G]
    
    // Status Outputs
    output reg [3:0] current_state,    // Current FSM state for debugging
    output reg emergency_active        // Emergency mode indicator
);

// ==============================================================================
// Light Color Definitions
// ==============================================================================
localparam RED    = 3'b100;
localparam YELLOW = 3'b010;
localparam GREEN  = 3'b001;
localparam ALL_RED = 3'b100;

// ==============================================================================
// FSM State Definitions
// ==============================================================================
localparam IDLE         = 4'd0;
localparam NORTH_GREEN  = 4'd1;
localparam NORTH_YELLOW = 4'd2;
localparam SOUTH_GREEN  = 4'd3;
localparam SOUTH_YELLOW = 4'd4;
localparam EAST_GREEN   = 4'd5;
localparam EAST_YELLOW  = 4'd6;
localparam WEST_GREEN   = 4'd7;
localparam WEST_YELLOW  = 4'd8;
localparam EMERGENCY    = 4'd9;
localparam ALL_RED_STATE = 4'd10;

// ==============================================================================
// Timing Parameters (in clock cycles)
// Assuming 1 MHz clock for simulation; scale for actual FPGA clock
// ==============================================================================
localparam YELLOW_TIME = 16'd3;    // Yellow light duration (3 cycles)
localparam ALL_RED_TIME = 16'd2;   // All red safety interval (2 cycles)

// Base green times for different traffic densities
localparam GREEN_LOW  = 16'd10;    // Low traffic
localparam GREEN_MED  = 16'd20;    // Medium traffic
localparam GREEN_HIGH = 16'd30;    // High traffic
localparam GREEN_VHIGH = 16'd40;   // Very high traffic

// ==============================================================================
// Internal Registers and Wires
// ==============================================================================
reg [3:0] state, next_state;
reg [15:0] timer;
reg [15:0] green_duration;
reg emergency_latched;

// ==============================================================================
// Adaptive Green Time Calculation
// ==============================================================================
// Calculates green light duration based on current direction's traffic density
function [15:0] calculate_green_time;
    input [1:0] traffic_density;
    begin
        case (traffic_density)
            2'b00:   calculate_green_time = GREEN_LOW;
            2'b01:   calculate_green_time = GREEN_MED;
            2'b10:   calculate_green_time = GREEN_HIGH;
            2'b11:   calculate_green_time = GREEN_VHIGH;
            default: calculate_green_time = GREEN_MED;
        endcase
    end
endfunction

// ==============================================================================
// Emergency Override Latch
// ==============================================================================
// Latches emergency signal to prevent glitches during state transitions
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        emergency_latched <= 1'b0;
    else if (emergency_override)
        emergency_latched <= 1'b1;
    else if (state == EMERGENCY && timer == 0)
        emergency_latched <= 1'b0;
end

// ==============================================================================
// FSM State Register
// ==============================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        state <= IDLE;
    else
        state <= next_state;
end

// ==============================================================================
// Timer Logic
// ==============================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        timer <= 16'd0;
    else if (state != next_state)
        timer <= 16'd0;  // Reset timer on state change
    else if (timer > 0)
        timer <= timer - 1'b1;
end

// ==============================================================================
// FSM Next State Logic
// ==============================================================================
always @(*) begin
    // Default assignments
    next_state = state;
    green_duration = GREEN_MED;
    emergency_active = 1'b0;
    
    // Emergency override has highest priority
    if (emergency_latched && state != EMERGENCY) begin
        next_state = EMERGENCY;
        emergency_active = 1'b1;
    end
    else begin
        case (state)
            // ==========================================
            // IDLE State - Initial state after reset
            // ==========================================
            IDLE: begin
                next_state = ALL_RED_STATE;
            end
            
            // ==========================================
            // ALL RED State - Safety interval
            // ==========================================
            ALL_RED_STATE: begin
                if (timer == 0) begin
                    next_state = NORTH_GREEN;
                end
            end
            
            // ==========================================
            // NORTH Direction States
            // ==========================================
            NORTH_GREEN: begin
                green_duration = calculate_green_time(traffic_north);
                if (timer == 0)
                    next_state = NORTH_YELLOW;
            end
            
            NORTH_YELLOW: begin
                if (timer == 0)
                    next_state = ALL_RED_STATE;
            end
            
            // ==========================================
            // SOUTH Direction States
            // ==========================================
            SOUTH_GREEN: begin
                green_duration = calculate_green_time(traffic_south);
                if (timer == 0)
                    next_state = SOUTH_YELLOW;
            end
            
            SOUTH_YELLOW: begin
                if (timer == 0)
                    next_state = ALL_RED_STATE;
            end
            
            // ==========================================
            // EAST Direction States
            // ==========================================
            EAST_GREEN: begin
                green_duration = calculate_green_time(traffic_east);
                if (timer == 0)
                    next_state = EAST_YELLOW;
            end
            
            EAST_YELLOW: begin
                if (timer == 0)
                    next_state = ALL_RED_STATE;
            end
            
            // ==========================================
            // WEST Direction States
            // ==========================================
            WEST_GREEN: begin
                green_duration = calculate_green_time(traffic_west);
                if (timer == 0)
                    next_state = WEST_YELLOW;
            end
            
            WEST_YELLOW: begin
                if (timer == 0)
                    next_state = ALL_RED_STATE;
            end
            
            // ==========================================
            // EMERGENCY State - Override mode
            // ==========================================
            EMERGENCY: begin
                emergency_active = 1'b1;
                if (!emergency_latched && timer == 0) begin
                    next_state = ALL_RED_STATE;
                end
            end
            
            default: next_state = IDLE;
        endcase
    end
end

// ==============================================================================
// State Sequence Logic (determines which direction goes next)
// ==============================================================================
reg [3:0] prev_state;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        prev_state <= IDLE;
    else
        prev_state <= state;
end

always @(*) begin
    case (state)
        ALL_RED_STATE: begin
            case (prev_state)
                NORTH_YELLOW: next_state = SOUTH_GREEN;
                SOUTH_YELLOW: next_state = EAST_GREEN;
                EAST_YELLOW:  next_state = WEST_GREEN;
                WEST_YELLOW:  next_state = NORTH_GREEN;
                EMERGENCY:    next_state = NORTH_GREEN;
                default:      next_state = NORTH_GREEN;
            endcase
        end
        default: begin
            // State transitions handled in main FSM logic
        end
    endcase
end

// ==============================================================================
// Output Logic - Traffic Light Control
// ==============================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        lights_north <= RED;
        lights_south <= RED;
        lights_east  <= RED;
        lights_west  <= RED;
        current_state <= IDLE;
    end
    else begin
        current_state <= state;
        
        case (state)
            IDLE: begin
                lights_north <= RED;
                lights_south <= RED;
                lights_east  <= RED;
                lights_west  <= RED;
            end
            
            ALL_RED_STATE: begin
                lights_north <= RED;
                lights_south <= RED;
                lights_east  <= RED;
                lights_west  <= RED;
            end
            
            // North Direction
            NORTH_GREEN: begin
                lights_north <= GREEN;
                lights_south <= RED;
                lights_east  <= RED;
                lights_west  <= RED;
            end
            
            NORTH_YELLOW: begin
                lights_north <= YELLOW;
                lights_south <= RED;
                lights_east  <= RED;
                lights_west  <= RED;
            end
            
            // South Direction
            SOUTH_GREEN: begin
                lights_north <= RED;
                lights_south <= GREEN;
                lights_east  <= RED;
                lights_west  <= RED;
            end
            
            SOUTH_YELLOW: begin
                lights_north <= RED;
                lights_south <= YELLOW;
                lights_east  <= RED;
                lights_west  <= RED;
            end
            
            // East Direction
            EAST_GREEN: begin
                lights_north <= RED;
                lights_south <= RED;
                lights_east  <= GREEN;
                lights_west  <= RED;
            end
            
            EAST_YELLOW: begin
                lights_north <= RED;
                lights_south <= RED;
                lights_east  <= YELLOW;
                lights_west  <= RED;
            end
            
            // West Direction
            WEST_GREEN: begin
                lights_north <= RED;
                lights_south <= RED;
                lights_east  <= RED;
                lights_west  <= GREEN;
            end
            
            WEST_YELLOW: begin
                lights_north <= RED;
                lights_south <= RED;
                lights_east  <= RED;
                lights_west  <= YELLOW;
            end
            
            // Emergency Override
            EMERGENCY: begin
                case (emergency_dir)
                    2'b00: begin  // North
                        lights_north <= GREEN;
                        lights_south <= RED;
                        lights_east  <= RED;
                        lights_west  <= RED;
                    end
                    2'b01: begin  // South
                        lights_north <= RED;
                        lights_south <= GREEN;
                        lights_east  <= RED;
                        lights_west  <= RED;
                    end
                    2'b10: begin  // East
                        lights_north <= RED;
                        lights_south <= RED;
                        lights_east  <= GREEN;
                        lights_west  <= RED;
                    end
                    2'b11: begin  // West
                        lights_north <= RED;
                        lights_south <= RED;
                        lights_east  <= RED;
                        lights_west  <= GREEN;
                    end
                endcase
            end
            
            default: begin
                lights_north <= RED;
                lights_south <= RED;
                lights_east  <= RED;
                lights_west  <= RED;
            end
        endcase
    end
end

// ==============================================================================
// Timer Load Logic
// ==============================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        timer <= 16'd0;
    else begin
        if (state != next_state) begin
            // Load appropriate timer value for new state
            case (next_state)
                ALL_RED_STATE: timer <= ALL_RED_TIME;
                NORTH_GREEN:   timer <= calculate_green_time(traffic_north);
                NORTH_YELLOW:  timer <= YELLOW_TIME;
                SOUTH_GREEN:   timer <= calculate_green_time(traffic_south);
                SOUTH_YELLOW:  timer <= YELLOW_TIME;
                EAST_GREEN:    timer <= calculate_green_time(traffic_east);
                EAST_YELLOW:   timer <= YELLOW_TIME;
                WEST_GREEN:    timer <= calculate_green_time(traffic_west);
                WEST_YELLOW:   timer <= YELLOW_TIME;
                EMERGENCY:     timer <= GREEN_HIGH;  // Fixed emergency duration
                default:       timer <= 16'd0;
            endcase
        end
        else if (timer > 0) begin
            timer <= timer - 1'b1;
        end
    end
end

endmodule
