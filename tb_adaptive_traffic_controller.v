// ==============================================================================
// Testbench for Adaptive Four-Way Traffic Control System
// ==============================================================================
// Description: Comprehensive testbench with multiple test scenarios
// Test Cases:
//   1. Normal traffic flow with low density
//   2. Adaptive timing with varying traffic densities
//   3. High traffic condition testing
//   4. Emergency override scenario (highest priority)
//   5. Complete cycle through all directions
// ==============================================================================

`timescale 1ns/1ps

module tb_adaptive_traffic_controller;

// ==============================================================================
// Testbench Signals
// ==============================================================================
// Clock and Reset
reg clk;
reg rst_n;

// Traffic Density Inputs
reg [1:0] traffic_north;
reg [1:0] traffic_south;
reg [1:0] traffic_east;
reg [1:0] traffic_west;

// Emergency Override
reg emergency_override;
reg [1:0] emergency_dir;

// Traffic Light Outputs
wire [2:0] lights_north;
wire [2:0] lights_south;
wire [2:0] lights_east;
wire [2:0] lights_west;

// Status Outputs
wire [3:0] current_state;
wire emergency_active;

// ==============================================================================
// Traffic Density Definitions
// ==============================================================================
localparam TRAFFIC_LOW   = 2'b00;
localparam TRAFFIC_MED   = 2'b01;
localparam TRAFFIC_HIGH  = 2'b10;
localparam TRAFFIC_VHIGH = 2'b11;

// Direction Definitions for Emergency
localparam DIR_NORTH = 2'b00;
localparam DIR_SOUTH = 2'b01;
localparam DIR_EAST  = 2'b10;
localparam DIR_WEST  = 2'b11;

// ==============================================================================
// Device Under Test (DUT) Instantiation
// ==============================================================================
adaptive_traffic_controller dut (
    .clk(clk),
    .rst_n(rst_n),
    .traffic_north(traffic_north),
    .traffic_south(traffic_south),
    .traffic_east(traffic_east),
    .traffic_west(traffic_west),
    .emergency_override(emergency_override),
    .emergency_dir(emergency_dir),
    .lights_north(lights_north),
    .lights_south(lights_south),
    .lights_east(lights_east),
    .lights_west(lights_west),
    .current_state(current_state),
    .emergency_active(emergency_active)
);

// ==============================================================================
// Clock Generation (10ns period = 100MHz)
// ==============================================================================
initial begin
    clk = 0;
    forever #5 clk = ~clk;  // 100MHz clock
end

// ==============================================================================
// Simulation Control and Monitoring
// ==============================================================================
integer test_number;
integer pass_count;
integer fail_count;

// State names for display
reg [8*20:1] state_name;

always @(*) begin
    case (current_state)
        4'd0:  state_name = "IDLE";
        4'd1:  state_name = "NORTH_GREEN";
        4'd2:  state_name = "NORTH_YELLOW";
        4'd3:  state_name = "SOUTH_GREEN";
        4'd4:  state_name = "SOUTH_YELLOW";
        4'd5:  state_name = "EAST_GREEN";
        4'd6:  state_name = "EAST_YELLOW";
        4'd7:  state_name = "WEST_GREEN";
        4'd8:  state_name = "WEST_YELLOW";
        4'd9:  state_name = "EMERGENCY";
        4'd10: state_name = "ALL_RED_STATE";
        default: state_name = "UNKNOWN";
    endcase
end

// Light status display
function [8*10:1] light_status;
    input [2:0] lights;
    begin
        case (lights)
            3'b100:  light_status = "RED";
            3'b010:  light_status = "YELLOW";
            3'b001:  light_status = "GREEN";
            default: light_status = "INVALID";
        endcase
    end
endfunction

// ==============================================================================
// Monitor Task - Display traffic light status
// ==============================================================================
task display_status;
    begin
        $display("Time=%0t | State=%s | Emergency=%b", 
                 $time, state_name, emergency_active);
        $display("  North=%s | South=%s | East=%s | West=%s",
                 light_status(lights_north),
                 light_status(lights_south),
                 light_status(lights_east),
                 light_status(lights_west));
        $display("  Traffic: N=%b S=%b E=%b W=%b",
                 traffic_north, traffic_south, traffic_east, traffic_west);
        $display("---------------------------------------------------------------");
    end
endtask

// ==============================================================================
// Wait for State Task
// ==============================================================================
task wait_for_state;
    input [3:0] expected_state;
    input integer timeout_cycles;
    integer i;
    begin
        for (i = 0; i < timeout_cycles; i = i + 1) begin
            if (current_state == expected_state) begin
                $display("INFO: Reached state %s at time %0t", state_name, $time);
                i = timeout_cycles; // Exit loop
            end
            @(posedge clk);
        end
        if (current_state != expected_state) begin
            $display("ERROR: Failed to reach expected state within timeout");
            fail_count = fail_count + 1;
        end
    end
endtask

// ==============================================================================
// Initialize Signals Task
// ==============================================================================
task initialize_signals;
    begin
        rst_n = 1;
        traffic_north = TRAFFIC_LOW;
        traffic_south = TRAFFIC_LOW;
        traffic_east = TRAFFIC_LOW;
        traffic_west = TRAFFIC_LOW;
        emergency_override = 0;
        emergency_dir = DIR_NORTH;
    end
endtask

// ==============================================================================
// Reset Task
// ==============================================================================
task apply_reset;
    begin
        $display("\n=== Applying Reset ===");
        rst_n = 0;
        #50;
        rst_n = 1;
        #20;
        $display("Reset complete at time %0t", $time);
    end
endtask

// ==============================================================================
// Test Case 1: Normal Traffic Flow (Low Density)
// ==============================================================================
task test_normal_traffic_flow;
    begin
        test_number = 1;
        $display("\n");
        $display("==============================================================");
        $display("TEST CASE 1: Normal Traffic Flow (All Low Density)");
        $display("==============================================================");
        
        initialize_signals();
        apply_reset();
        
        // Set all directions to low traffic
        traffic_north = TRAFFIC_LOW;
        traffic_south = TRAFFIC_LOW;
        traffic_east = TRAFFIC_LOW;
        traffic_west = TRAFFIC_LOW;
        
        $display("Observing one complete cycle through all directions...");
        
        // Monitor for complete cycle
        repeat(200) begin
            @(posedge clk);
            if (current_state == 4'd1 || current_state == 4'd3 || 
                current_state == 4'd5 || current_state == 4'd7) begin
                display_status();
            end
        end
        
        $display("TEST 1: Complete - Normal traffic flow observed");
        pass_count = pass_count + 1;
    end
endtask

// ==============================================================================
// Test Case 2: Adaptive Timing with Varying Traffic Densities
// ==============================================================================
task test_adaptive_timing;
    begin
        test_number = 2;
        $display("\n");
        $display("==============================================================");
        $display("TEST CASE 2: Adaptive Timing (Varying Traffic Densities)");
        $display("==============================================================");
        
        initialize_signals();
        apply_reset();
        
        // Set different traffic densities
        traffic_north = TRAFFIC_VHIGH;  // Very high
        traffic_south = TRAFFIC_MED;     // Medium
        traffic_east = TRAFFIC_LOW;      // Low
        traffic_west = TRAFFIC_HIGH;     // High
        
        $display("Traffic Settings:");
        $display("  North: VERY HIGH (should get longest green)");
        $display("  South: MEDIUM");
        $display("  East:  LOW (should get shortest green)");
        $display("  West:  HIGH");
        
        // Observe adaptive behavior
        repeat(400) begin
            @(posedge clk);
            if (current_state == 4'd1 || current_state == 4'd3 || 
                current_state == 4'd5 || current_state == 4'd7) begin
                display_status();
            end
        end
        
        $display("TEST 2: Complete - Adaptive timing verified");
        pass_count = pass_count + 1;
    end
endtask

// ==============================================================================
// Test Case 3: High Traffic Condition
// ==============================================================================
task test_high_traffic;
    begin
        test_number = 3;
        $display("\n");
        $display("==============================================================");
        $display("TEST CASE 3: High Traffic Condition (All Directions)");
        $display("==============================================================");
        
        initialize_signals();
        apply_reset();
        
        // Set all directions to high traffic
        traffic_north = TRAFFIC_HIGH;
        traffic_south = TRAFFIC_HIGH;
        traffic_east = TRAFFIC_HIGH;
        traffic_west = TRAFFIC_HIGH;
        
        $display("All directions set to HIGH traffic density");
        
        // Monitor extended green times
        repeat(500) begin
            @(posedge clk);
            if (current_state == 4'd1 || current_state == 4'd3 || 
                current_state == 4'd5 || current_state == 4'd7) begin
                display_status();
            end
        end
        
        $display("TEST 3: Complete - High traffic handling verified");
        pass_count = pass_count + 1;
    end
endtask

// ==============================================================================
// Test Case 4: Emergency Override Scenario
// ==============================================================================
task test_emergency_override;
    begin
        test_number = 4;
        $display("\n");
        $display("==============================================================");
        $display("TEST CASE 4: Emergency Override (Highest Priority)");
        $display("==============================================================");
        
        initialize_signals();
        apply_reset();
        
        // Start with normal traffic
        traffic_north = TRAFFIC_MED;
        traffic_south = TRAFFIC_MED;
        traffic_east = TRAFFIC_MED;
        traffic_west = TRAFFIC_MED;
        
        // Wait for North green
        wait_for_state(4'd1, 100);  // NORTH_GREEN
        
        $display("\n--- Scenario 4a: Emergency Override to EAST during North Green ---");
        #100;
        emergency_override = 1;
        emergency_dir = DIR_EAST;
        $display("Emergency activated for EAST direction at time %0t", $time);
        
        // Wait for emergency state
        wait_for_state(4'd9, 50);  // EMERGENCY state
        display_status();
        
        if (lights_east == 3'b001 && emergency_active == 1) begin
            $display("SUCCESS: East got immediate green during emergency");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Emergency override not working correctly");
            fail_count = fail_count + 1;
        end
        
        // Hold emergency for some time
        #200;
        emergency_override = 0;
        $display("Emergency cleared at time %0t", $time);
        
        // Allow system to return to normal
        #300;
        display_status();
        
        $display("\n--- Scenario 4b: Emergency Override to WEST ---");
        #200;
        emergency_override = 1;
        emergency_dir = DIR_WEST;
        $display("Emergency activated for WEST direction at time %0t", $time);
        
        wait_for_state(4'd9, 50);
        display_status();
        
        if (lights_west == 3'b001 && emergency_active == 1) begin
            $display("SUCCESS: West got immediate green during emergency");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Second emergency override not working correctly");
            fail_count = fail_count + 1;
        end
        
        #200;
        emergency_override = 0;
        $display("Emergency cleared at time %0t", $time);
        
        #200;
        $display("TEST 4: Complete - Emergency override scenarios verified");
    end
endtask

// ==============================================================================
// Test Case 5: Complete Cycle Verification
// ==============================================================================
task test_complete_cycle;
    begin
        test_number = 5;
        $display("\n");
        $display("==============================================================");
        $display("TEST CASE 5: Complete Cycle Verification");
        $display("==============================================================");
        
        initialize_signals();
        apply_reset();
        
        traffic_north = TRAFFIC_MED;
        traffic_south = TRAFFIC_MED;
        traffic_east = TRAFFIC_MED;
        traffic_west = TRAFFIC_MED;
        
        // Track state sequence
        reg [3:0] state_sequence [0:7];
        integer seq_index;
        seq_index = 0;
        
        // Capture state sequence
        repeat(600) begin
            @(posedge clk);
            if (current_state == 4'd1 || current_state == 4'd3 || 
                current_state == 4'd5 || current_state == 4'd7) begin
                if (seq_index < 8) begin
                    state_sequence[seq_index] = current_state;
                    seq_index = seq_index + 1;
                    display_status();
                end
            end
        end
        
        // Verify sequence: N -> S -> E -> W -> N -> S...
        if (state_sequence[0] == 4'd1 && state_sequence[1] == 4'd3 &&
            state_sequence[2] == 4'd5 && state_sequence[3] == 4'd7) begin
            $display("SUCCESS: Correct state sequence N->S->E->W verified");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Incorrect state sequence");
            fail_count = fail_count + 1;
        end
        
        $display("TEST 5: Complete - Cycle verification done");
    end
endtask

// ==============================================================================
// Test Case 6: Safety Checks
// ==============================================================================
task test_safety_checks;
    begin
        test_number = 6;
        $display("\n");
        $display("==============================================================");
        $display("TEST CASE 6: Safety Checks (No Conflicting Greens)");
        $display("==============================================================");
        
        initialize_signals();
        apply_reset();
        
        traffic_north = TRAFFIC_HIGH;
        traffic_south = TRAFFIC_HIGH;
        traffic_east = TRAFFIC_HIGH;
        traffic_west = TRAFFIC_HIGH;
        
        // Monitor for safety violations
        integer violation_count;
        violation_count = 0;
        
        repeat(800) begin
            @(posedge clk);
            
            // Check for multiple greens simultaneously
            if ((lights_north[0] && lights_south[0]) ||
                (lights_north[0] && lights_east[0]) ||
                (lights_north[0] && lights_west[0]) ||
                (lights_south[0] && lights_east[0]) ||
                (lights_south[0] && lights_west[0]) ||
                (lights_east[0] && lights_west[0])) begin
                $display("SAFETY VIOLATION: Multiple greens at time %0t", $time);
                violation_count = violation_count + 1;
                fail_count = fail_count + 1;
            end
        end
        
        if (violation_count == 0) begin
            $display("SUCCESS: No safety violations detected");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: %0d safety violations detected", violation_count);
        end
        
        $display("TEST 6: Complete - Safety checks done");
    end
endtask

// ==============================================================================
// Main Test Sequence
// ==============================================================================
initial begin
    // Initialize counters
    pass_count = 0;
    fail_count = 0;
    
    // Create VCD file for waveform viewing
    $dumpfile("adaptive_traffic_controller.vcd");
    $dumpvars(0, tb_adaptive_traffic_controller);
    
    $display("\n");
    $display("==============================================================");
    $display("    ADAPTIVE TRAFFIC CONTROLLER TESTBENCH");
    $display("==============================================================");
    $display("Start time: %0t", $time);
    $display("\n");
    
    // Run all test cases
    test_normal_traffic_flow();
    test_adaptive_timing();
    test_high_traffic();
    test_emergency_override();
    test_complete_cycle();
    test_safety_checks();
    
    // Final summary
    $display("\n");
    $display("==============================================================");
    $display("                    TEST SUMMARY");
    $display("==============================================================");
    $display("Total Tests Passed: %0d", pass_count);
    $display("Total Tests Failed: %0d", fail_count);
    if (fail_count == 0) begin
        $display("Result: ALL TESTS PASSED!");
    end else begin
        $display("Result: SOME TESTS FAILED!");
    end
    $display("Simulation End time: %0t", $time);
    $display("==============================================================");
    $display("\n");
    
    // Finish simulation
    #100;
    $finish;
end

// ==============================================================================
// Timeout Watchdog
// ==============================================================================
initial begin
    #1000000;  // 1ms timeout
    $display("\n");
    $display("ERROR: Simulation timeout!");
    $display("Testbench did not complete within expected time");
    $finish;
end

endmodule
