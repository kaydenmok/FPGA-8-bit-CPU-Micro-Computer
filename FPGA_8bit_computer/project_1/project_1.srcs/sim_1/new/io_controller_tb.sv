`timescale 1ns / 1ps

module io_controller_tb;

    // INPUT SIGNALS
    logic        clk;
    logic        reset;

    logic [7:0]  address;
    logic [7:0]  write_data;
    logic        write_enable;
    logic        read_enable;

    logic [15:0] switches;
    logic [3:0]  buttons;

    // UART inputs
    logic        uart_tx_busy;
    logic [7:0]  uart_rx_data;
    logic        uart_rx_valid;


    // OUTPUT SIGNALS
    logic [15:0] leds;

    logic [7:0]  read_data;
    logic        io_selected;

    logic [7:0]  display_value;

    logic [7:0]  uart_tx_data;
    logic        uart_tx_start;


    // DEVICE UNDER TEST
    io_controller dut (

        .clk           (clk),
        .reset         (reset),

        .address       (address),
        .write_data    (write_data),
        .write_enable  (write_enable),
        .read_enable   (read_enable),

        .switches      (switches),
        .buttons       (buttons),

        .uart_tx_busy  (uart_tx_busy),
        .uart_rx_data  (uart_rx_data),
        .uart_rx_valid (uart_rx_valid),

        .leds           (leds),

        .read_data      (read_data),
        .io_selected    (io_selected),

        .display_value  (display_value),

        .uart_tx_data   (uart_tx_data),
        .uart_tx_start  (uart_tx_start)

    );

    // CLOCK
    // 100 MHz clock
    // 10 ns period

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
    // SEND UART RX BYTE TASK
    // ============================================================
    //
    // Simulates uart_receiver producing a completed byte.
    //
    // uart_rx_valid is pulsed HIGH for one clock cycle.

    task automatic receive_uart_byte(
        input logic [7:0] byte_value
    );

        begin

            @(negedge clk);

            uart_rx_data  = byte_value;
            uart_rx_valid = 1'b1;

            @(posedge clk);
            #1;

            uart_rx_valid = 1'b0;

        end

    endtask


    // ============================================================
    // TEST SEQUENCE
    // ============================================================

    initial begin

        // Safe startup values
        reset         = 1'b1;

        address       = 8'h00;
        write_data    = 8'h00;

        write_enable  = 1'b0;
        read_enable   = 1'b0;

        switches      = 16'h0000;
        buttons       = 4'b0000;

        uart_tx_busy  = 1'b0;

        uart_rx_data  = 8'h00;
        uart_rx_valid = 1'b0;


        // Hold reset for two clock cycles
        repeat (2) @(posedge clk);

        @(negedge clk);
        reset = 1'b0;

        #1;


        // ========================================================
        // TEST 1: RESET VALUES
        // ========================================================

        check(
            leds == 16'h0000,
            "LED outputs reset to zero"
        );

        check(
            display_value == 8'h00,
            "Seven-segment value resets to zero"
        );

        check(
            uart_tx_start == 1'b0,
            "UART TX start begins LOW"
        );

        check(
            dut.rx_count == 4'd0,
            "UART RX FIFO begins empty"
        );

        check(
            dut.rx_overflow == 1'b0,
            "UART overflow flag begins cleared"
        );


        // ========================================================
        // TEST 2: NORMAL RAM ADDRESS IS NOT I/O
        // ========================================================

        address = 8'h20;
        #1;

        check(
            io_selected == 1'b0,
            "Normal RAM address does not select I/O"
        );


        // ========================================================
        // TEST 3: I/O ADDRESS DETECTION
        // ========================================================

        address = 8'hF0;
        #1;

        check(
            io_selected == 1'b1,
            "Address F0 selects I/O"
        );


        // ========================================================
        // TEST 4: WRITE LOWER LEDs
        // ========================================================

        @(negedge clk);

        address      = 8'hF0;
        write_data   = 8'hA5;
        write_enable = 1'b1;

        @(posedge clk);
        #1;

        write_enable = 1'b0;

        check(
            leds[7:0] == 8'hA5,
            "Writing F0 updates lower LEDs"
        );


        // ========================================================
        // TEST 5: WRITE UPPER LEDs
        // ========================================================

        @(negedge clk);

        address      = 8'hF1;
        write_data   = 8'h3C;
        write_enable = 1'b1;

        @(posedge clk);
        #1;

        write_enable = 1'b0;

        check(
            leds[15:8] == 8'h3C,
            "Writing F1 updates upper LEDs"
        );


        // ========================================================
        // TEST 6: READ LOWER SWITCHES
        // ========================================================

        switches = 16'hB64D;

        address     = 8'hF2;
        read_enable = 1'b1;

        #1;

        check(
            read_data == 8'h4D,
            "Reading F2 returns lower switches"
        );

        read_enable = 1'b0;


        // ========================================================
        // TEST 7: READ UPPER SWITCHES
        // ========================================================

        address     = 8'hF3;
        read_enable = 1'b1;

        #1;

        check(
            read_data == 8'hB6,
            "Reading F3 returns upper switches"
        );

        read_enable = 1'b0;


        // ========================================================
        // TEST 8: READ BUTTONS
        // ========================================================

        buttons = 4'b1010;

        address     = 8'hF4;
        read_enable = 1'b1;

        #1;

        check(
            read_data == 8'b00001010,
            "Reading F4 returns four directional buttons"
        );

        read_enable = 1'b0;


        // ========================================================
        // TEST 9: WRITE SEVEN-SEGMENT VALUE
        // ========================================================

        @(negedge clk);

        address      = 8'hF5;
        write_data   = 8'hAC;
        write_enable = 1'b1;

        @(posedge clk);
        #1;

        write_enable = 1'b0;

        check(
            display_value == 8'hAC,
            "Writing F5 updates seven-segment value"
        );


        // ========================================================
        // TEST 10: UART TX WRITE
        // ========================================================
        //
        // UART is currently free.
        // Writing F6 should store the byte and generate
        // a one-clock start pulse.

        uart_tx_busy = 1'b0;

        @(negedge clk);

        address      = 8'hF6;
        write_data   = 8'h41;   // ASCII 'A'
        write_enable = 1'b1;

        @(posedge clk);
        #1;

        check(
            uart_tx_data == 8'h41,
            "Writing F6 stores UART transmit byte"
        );

        check(
            uart_tx_start == 1'b1,
            "Writing F6 creates UART start pulse"
        );

        write_enable = 1'b0;


        // ========================================================
        // TEST 11: UART TX START RETURNS LOW
        // ========================================================

        @(posedge clk);
        #1;

        check(
            uart_tx_start == 1'b0,
            "UART start pulse returns LOW after one clock"
        );


        // ========================================================
        // TEST 12: UART DOES NOT START WHILE BUSY
        // ========================================================

        uart_tx_busy = 1'b1;

        @(negedge clk);

        address      = 8'hF6;
        write_data   = 8'h55;
        write_enable = 1'b1;

        @(posedge clk);
        #1;

        write_enable = 1'b0;

        check(
            uart_tx_start == 1'b0,
            "UART does not start new transmission while busy"
        );

        check(
            uart_tx_data == 8'h41,
            "UART TX data remains unchanged while busy"
        );

        uart_tx_busy = 1'b0;


        // ========================================================
        // TEST 13: RECEIVE ONE UART BYTE
        // ========================================================

        receive_uart_byte(8'h11);

        check(
            dut.rx_count == 4'd1,
            "Received UART byte increases FIFO count to 1"
        );

        check(
            dut.rx_fifo[0] == 8'h11,
            "Received UART byte is stored in FIFO"
        );


        // ========================================================
        // TEST 14: UART STATUS - DATA AVAILABLE
        // ========================================================

        address     = 8'hF7;
        read_enable = 1'b1;

        #1;

        check(
            read_data[1] == 1'b1,
            "UART status reports RX data available"
        );

        check(
            read_data[2] == 1'b0,
            "UART status reports FIFO not full"
        );

        check(
            read_data[3] == 1'b0,
            "UART status reports no overflow"
        );

        read_enable = 1'b0;


        // ========================================================
        // TEST 15: RECEIVE MULTIPLE UART BYTES
        // ========================================================

        receive_uart_byte(8'h22);
        receive_uart_byte(8'h33);

        check(
            dut.rx_count == 4'd3,
            "Three UART bytes are stored in FIFO"
        );


        // ========================================================
        // TEST 16: FIFO RETURNS OLDEST BYTE FIRST
        // ========================================================
        //
        // FIFO currently contains:
        //
        // 11
        // 22
        // 33
        //
        // Reading F8 should return 11 first.

        address     = 8'hF8;
        read_enable = 1'b1;

        #1;

        check(
            read_data == 8'h11,
            "FIFO returns oldest received byte first"
        );


        // Execute the read so FIFO read pointer advances.
        @(posedge clk);
        #1;

        read_enable = 1'b0;

        check(
            dut.rx_count == 4'd2,
            "Reading RX data decreases FIFO count"
        );


        // ========================================================
        // TEST 17: SECOND FIFO BYTE
        // ========================================================

        address     = 8'hF8;
        read_enable = 1'b1;

        #1;

        check(
            read_data == 8'h22,
            "Second FIFO read returns second received byte"
        );

        @(posedge clk);
        #1;

        read_enable = 1'b0;


        // ========================================================
        // TEST 18: THIRD FIFO BYTE
        // ========================================================

        address     = 8'hF8;
        read_enable = 1'b1;

        #1;

        check(
            read_data == 8'h33,
            "Third FIFO read returns third received byte"
        );

        @(posedge clk);
        #1;

        read_enable = 1'b0;

        check(
            dut.rx_count == 4'd0,
            "FIFO becomes empty after all bytes are read"
        );


        // ========================================================
        // TEST 19: EMPTY FIFO RETURNS ZERO
        // ========================================================

        address     = 8'hF8;
        read_enable = 1'b1;

        #1;

        check(
            read_data == 8'h00,
            "Reading empty RX FIFO returns zero"
        );

        read_enable = 1'b0;


        // ========================================================
        // TEST 20: FILL UART FIFO
        // ========================================================
        //
        // Fill all 8 FIFO entries.

        receive_uart_byte(8'h10);
        receive_uart_byte(8'h20);
        receive_uart_byte(8'h30);
        receive_uart_byte(8'h40);

        receive_uart_byte(8'h50);
        receive_uart_byte(8'h60);
        receive_uart_byte(8'h70);
        receive_uart_byte(8'h80);

        check(
            dut.rx_count == 4'd8,
            "UART FIFO fills to eight bytes"
        );


        // ========================================================
        // TEST 21: FIFO FULL STATUS
        // ========================================================

        address     = 8'hF7;
        read_enable = 1'b1;

        #1;

        check(
            read_data[2] == 1'b1,
            "UART status reports FIFO full"
        );

        check(
            read_data[1] == 1'b1,
            "UART status still reports RX data available"
        );

        read_enable = 1'b0;


        // ========================================================
        // TEST 22: UART FIFO OVERFLOW
        // ========================================================
        //
        // FIFO is already full.
        //
        // Send another byte without reading anything.
        //
        // The byte should be dropped and overflow should be set.

        receive_uart_byte(8'h99);

        check(
            dut.rx_count == 4'd8,
            "FIFO count remains eight after overflow"
        );

        check(
            dut.rx_overflow == 1'b1,
            "UART overflow flag sets when full FIFO receives byte"
        );


        // ========================================================
        // TEST 23: OVERFLOW STATUS BIT
        // ========================================================

        address     = 8'hF7;
        read_enable = 1'b1;

        #1;

        check(
            read_data[3] == 1'b1,
            "UART status reports RX overflow"
        );

        read_enable = 1'b0;


        // ========================================================
        // TEST 24: CLEAR OVERFLOW FLAG
        // ========================================================
        //
        // Writing to the UART control/status register acknowledges
        // and clears the sticky overflow flag.

        @(negedge clk);

        address      = 8'hF7;
        write_data   = 8'h00;
        write_enable = 1'b1;

        @(posedge clk);
        #1;

        write_enable = 1'b0;

        check(
            dut.rx_overflow == 1'b0,
            "Writing F7 clears UART overflow flag"
        );


        // ========================================================
        // TEST 25: SIMULTANEOUS FIFO READ + RECEIVE
        // ========================================================
        //
        // FIFO currently contains 8 bytes.
        //
        // On the same clock:
        //
        // - CPU reads oldest byte
        // - UART receives new byte
        //
        // FIFO count should remain 8.

        address     = 8'hF8;
        read_enable = 1'b1;

        uart_rx_data  = 8'hAA;
        uart_rx_valid = 1'b1;

        #1;

        check(
            read_data == 8'h10,
            "Simultaneous read returns oldest FIFO byte"
        );

        @(posedge clk);
        #1;

        read_enable   = 1'b0;
        uart_rx_valid = 1'b0;

        check(
            dut.rx_count == 4'd8,
            "Simultaneous read and receive keeps FIFO count unchanged"
        );


        // ========================================================
        // TEST 26: TX BUSY STATUS BIT
        // ========================================================

        uart_tx_busy = 1'b1;

        address     = 8'hF7;
        read_enable = 1'b1;

        #1;

        check(
            read_data[0] == 1'b1,
            "UART status reports transmitter busy"
        );

        uart_tx_busy = 1'b0;
        read_enable  = 1'b0;


        // ========================================================
        // TEST COMPLETE
        // ========================================================

        $display("");
        $display("==============================================");
        $display(" I/O CONTROLLER UART + FIFO TEST PASSED");
        $display("");
        $display(" Memory-mapped I/O verified");
        $display(" UART TX mapping verified");
        $display(" UART RX FIFO verified");
        $display(" FIFO ordering verified");
        $display(" FIFO full detection verified");
        $display(" FIFO overflow verified");
        $display(" Simultaneous RX/read verified");
        $display("==============================================");
        $display("");

        $finish;

    end


    // ============================================================
    // TIMEOUT PROTECTION
    // ============================================================

    initial begin

        #5000;

        $error("Simulation timeout: I/O controller did not finish.");
        $finish;

    end

endmodule