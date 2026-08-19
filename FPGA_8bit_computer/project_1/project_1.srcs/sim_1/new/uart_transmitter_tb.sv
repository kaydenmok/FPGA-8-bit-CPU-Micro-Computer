`timescale 1ns / 1ps

// !! NOTE !! You must enter "run 200 us" in the tcl console for the full tb to run

module uart_transmitter_tb;

    logic       clk;
    logic       reset;

    logic [7:0] data_in;
    logic       start;

    logic       tx;
    logic       busy;


    // UART SETTINGS
    // Must match uart_transmitter.sv.
    localparam integer CLKS_PER_BIT = 868;

    // Basys 3 clock period:
    // 100 MHz = 10 ns period
    localparam integer CLOCK_PERIOD = 10;


    // DEVICE UNDER TEST
    uart_transmitter dut (

        .clk     (clk),
        .reset   (reset),

        .data_in (data_in),
        .start   (start),

        .tx      (tx),
        .busy    (busy)

    );



    // CLOCK
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
    // TEST SEQUENCE
    // ============================================================

    initial begin

        // Safe starting values.
        reset   = 1'b1;
        data_in = 8'b00000000;
        start   = 1'b0;


        // Hold reset for two clock cycles.
        repeat (2) @(posedge clk);

        @(negedge clk);
        reset = 1'b0;

        #1;


        // ========================================================
        // TEST 1: UART IDLE STATE
        // ========================================================

        check(
            tx == 1'b1,
            "UART TX line idles HIGH"
        );

        check(
            busy == 1'b0,
            "UART transmitter starts not busy"
        );


        // ========================================================
        // TEST 2: START TRANSMISSION
        //
        // Test byte:
        //
        // data_in = 10100101
        //
        // UART sends least-significant bit first:
        //
        // bit0 = 1
        // bit1 = 0
        // bit2 = 1
        // bit3 = 0
        // bit4 = 0
        // bit5 = 1
        // bit6 = 0
        // bit7 = 0
        // ========================================================

        data_in = 8'b00100101;

        // Pulse start HIGH for one clock cycle.
        @(negedge clk);
        start = 1'b1;

        @(posedge clk);
        #1;

        start = 1'b0;


        check(
            busy == 1'b1,
            "UART becomes busy after start"
        );

        check(
            tx == 1'b0,
            "UART begins with LOW start bit"
        );


        // ========================================================
        // TEST 3: START BIT DURATION
        // ========================================================

        // Wait for the start bit to finish.
        repeat (CLKS_PER_BIT) @(posedge clk);

        #1;


        // ========================================================
        // TEST 4: DATA BIT 0
        //
        // data_in[0] = 1
        // ========================================================

        check(
            tx == 1'b1,
            "UART sends data bit 0 = 1"
        );

        check(
            busy == 1'b1,
            "UART remains busy during data transmission"
        );


        // ========================================================
        // TEST 5: DATA BIT 1
        //
        // data_in[1] = 0
        // ========================================================

        repeat (CLKS_PER_BIT) @(posedge clk);
        #1;

        check(
            tx == 1'b0,
            "UART sends data bit 1 = 0"
        );


        // ========================================================
        // TEST 6: DATA BIT 2
        //
        // data_in[2] = 1
        // ========================================================

        repeat (CLKS_PER_BIT) @(posedge clk);
        #1;

        check(
            tx == 1'b1,
            "UART sends data bit 2 = 1"
        );


        // ========================================================
        // TEST 7: DATA BIT 3
        //
        // data_in[3] = 0
        // ========================================================

        repeat (CLKS_PER_BIT) @(posedge clk);
        #1;

        check(
            tx == 1'b0,
            "UART sends data bit 3 = 0"
        );


        // ========================================================
        // TEST 8: DATA BIT 4
        //
        // data_in[4] = 0
        // ========================================================

        repeat (CLKS_PER_BIT) @(posedge clk);
        #1;

        check(
            tx == 1'b0,
            "UART sends data bit 4 = 0"
        );


        // ========================================================
        // TEST 9: DATA BIT 5
        //
        // data_in[5] = 1
        // ========================================================

        repeat (CLKS_PER_BIT) @(posedge clk);
        #1;

        check(
            tx == 1'b1,
            "UART sends data bit 5 = 1"
        );


        // ========================================================
        // TEST 10: DATA BIT 6
        //
        // data_in[6] = 0
        // ========================================================

        repeat (CLKS_PER_BIT) @(posedge clk);
        #1;

        check(
            tx == 1'b0,
            "UART sends data bit 6 = 0"
        );


        // ========================================================
        // TEST 11: DATA BIT 7
        //
        // data_in[7] = 0
        // ========================================================

        repeat (CLKS_PER_BIT) @(posedge clk);
        #1;

        check(
            tx == 1'b0,
            "UART sends data bit 7 = 0"
        );


        // ========================================================
        // TEST 12: STOP BIT
        // ========================================================

        repeat (CLKS_PER_BIT) @(posedge clk);
        #1;

        check(
            tx == 1'b1,
            "UART sends HIGH stop bit"
        );

        check(
            busy == 1'b1,
            "UART remains busy during stop bit"
        );


        // ========================================================
        // TEST 13: TRANSMISSION COMPLETE
        // ========================================================

        repeat (CLKS_PER_BIT) @(posedge clk);
        #1;

        check(
            tx == 1'b1,
            "UART returns to HIGH idle state"
        );

        check(
            busy == 1'b0,
            "UART clears busy after transmission"
        );


        // ========================================================
        // TEST COMPLETE
        // ========================================================

        $display("");
        $display("==============================================");
        $display(" UART TRANSMITTER TEST PASSED");
        $display("");
        $display(" Byte transmitted: %b", data_in);
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
        // = approx 86.8 us
        //
        // Give the simulation plenty of room to finish.
        #200000;

        $error("Simulation timeout: UART transmission did not finish.");
        $finish;

    end

endmodule