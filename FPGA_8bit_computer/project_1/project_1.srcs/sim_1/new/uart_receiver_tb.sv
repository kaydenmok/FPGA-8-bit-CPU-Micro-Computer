`timescale 1ns / 1ps

// !! NOTE !! You must enter "run 200 us" in the tcl console for the full tb to run


module uart_receiver_tb;

    // INPUT / OUTPUT SIGNALS
    logic       clk;
    logic       reset;

    // Serial UART input driven by the testbench.
    logic       rx;

    // Reconstructed byte from the UART receiver.
    logic [7:0] data_out;

    // Pulses HIGH for one clock cycle when a full byte is received.
    logic       data_valid;


    // UART SETTINGS
    // Must match uart_receiver.sv
    localparam integer CLKS_PER_BIT = 868;


    // DEVICE UNDER TEST
    uart_receiver dut (

        .clk        (clk),
        .reset      (reset),

        .rx         (rx),

        .data_out   (data_out),
        .data_valid (data_valid)

    );

    // CLOCK
    // 100 MHz clock
    // Full period = 10 ns

    initial begin

        clk = 1'b0;

        forever begin
            #5 clk = ~clk;
        end

    end


    // ============================================================
    // CHECK TASK
    // ============================================================

    task automatic check(
        input logic condition,
        input string message
    );

        begin

            if (condition) begin
                $display("PASS: %s", message);
            end

            else begin
                $error("FAIL: %s", message);
                $finish;
            end

        end

    endtask


    // ============================================================
    // SEND ONE UART BIT
    // ============================================================
    //
    // Holds RX at one logic value for exactly one UART bit period.
    //
    // Example:
    //
    // send_uart_bit(1'b0);
    //
    // keeps RX LOW for 868 FPGA clock cycles.

    task automatic send_uart_bit(
        input logic bit_value
    );

        begin

            rx = bit_value;

            repeat (CLKS_PER_BIT) @(posedge clk);

        end

    endtask


    // ============================================================
    // TEST SEQUENCE
    // ============================================================

    initial begin

        // Safe starting values
        reset = 1'b1;

        // UART RX line normally sits HIGH while idle
        rx = 1'b1;


        // Hold reset for two clock cycles
        repeat (2) @(posedge clk);

        @(negedge clk);
        reset = 1'b0;

        #1;


        // ========================================================
        // TEST 1: IDLE STATE
        // ========================================================

        check(
            data_valid == 1'b0,
            "UART receiver starts with data_valid LOW"
        );

        check(
            data_out == 8'h00,
            "UART receiver starts with data_out cleared"
        );


        // ========================================================
        // TEST BYTE
        // ========================================================
        //
        // Byte being sent:
        //
        // 11010010
        //
        // Normal bit order:
        //
        // bit 7 6 5 4 3 2 1 0
        //     1 1 0 1 0 0 1 0
        //
        // UART sends least-significant bit first:
        //
        //     0 1 0 0 1 0 1 1
        //
        // Full UART frame:
        //
        // Idle | Start | 0 1 0 0 1 0 1 1 | Stop
        //   1      0                       1
        // ========================================================


        // ========================================================
        // TEST 2: START BIT
        // ========================================================

        send_uart_bit(1'b0);


        // ========================================================
        // TEST 3: DATA BIT 0
        // ========================================================

        send_uart_bit(1'b0);


        // ========================================================
        // TEST 4: DATA BIT 1
        // ========================================================

        send_uart_bit(1'b1);


        // ========================================================
        // TEST 5: DATA BIT 2
        // ========================================================

        send_uart_bit(1'b0);


        // ========================================================
        // TEST 6: DATA BIT 3
        // ========================================================

        send_uart_bit(1'b0);


        // ========================================================
        // TEST 7: DATA BIT 4
        // ========================================================

        send_uart_bit(1'b1);


        // ========================================================
        // TEST 8: DATA BIT 5
        // ========================================================

        send_uart_bit(1'b0);


        // ========================================================
        // TEST 9: DATA BIT 6
        // ========================================================

        send_uart_bit(1'b1);


        // ========================================================
        // TEST 10: DATA BIT 7
        // ========================================================

        send_uart_bit(1'b1);


        // ========================================================
        // TEST 11: STOP BIT
        // ========================================================
        //
        // Instead of waiting through the entire stop-bit period,
        // hold RX HIGH and wait directly for data_valid.
        //
        // This prevents the testbench from missing the one-clock
        // data_valid pulse.

        rx = 1'b1;

        wait (data_valid == 1'b1);

        #1;


        // ========================================================
        // TEST 12: VERIFY RECEIVED BYTE
        // ========================================================

        check(
            data_out == 8'b11010010,
            "UART receiver reconstructs byte 11010010"
        );


        // ========================================================
        // TEST 13: VERIFY DATA VALID
        // ========================================================

        check(
            data_valid == 1'b1,
            "UART receiver pulses data_valid after full byte"
        );


        // ========================================================
        // TEST 14: VERIFY DATA VALID RETURNS LOW
        // ========================================================

        @(posedge clk);
        #1;

        check(
            data_valid == 1'b0,
            "data_valid returns LOW after one clock cycle"
        );


        // ========================================================
        // TEST 15: RETURN TO IDLE
        // ========================================================

        check(
            rx == 1'b1,
            "RX line remains HIGH in idle state"
        );


        // ========================================================
        // TEST COMPLETE
        // ========================================================

        $display("");
        $display("==============================================");
        $display(" UART RECEIVER TEST PASSED");
        $display("");
        $display(" Received byte: %b", data_out);
        $display(" UART format: 8-N-1");
        $display(" Baud rate: 115200");
        $display("==============================================");
        $display("");

        $finish;

    end


    // ============================================================
    // TIMEOUT PROTECTION
    // ============================================================

    initial begin

        // One UART frame takes roughly:
        //
        // 10 bits x 868 clocks x 10 ns
        // ≈ 86.8 us
        //
        // Give the simulation plenty of time to finish.

        #200000;

        $error("Simulation timeout: UART receiver did not finish.");
        $finish;

    end

endmodule