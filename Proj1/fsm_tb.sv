module fsm_tb();

    logic clk, rst, bank_card_insert, deposit_withdrawal_selection, account_selection, open_atm_dispense, open_atm_receive, ready;
    logic [13:0] amount, pin;

    int err = 0;
    int test_num;

    // DUT w/ wildcard to input everything that matches by name, keep default parameters
    fsm dut(.*);

    // Clock generation
    initial begin
        clk = 0;
        forever begin
            #1;
            clk = ~clk;
        end
    end

    // Main body of test bench.
    initial begin
        // Initialize inputs
        rst = 1;
        bank_card_insert = 0;
        deposit_withdrawal_selection = 0;
        account_selection = 0;
        amount = 1;
        pin = 0;
        #3;
        rst = 0;

        test_num = 0;
        // Test 0: assert ready because bank card insert isn't asserted
        for(int i = 0; i < 10; i++) begin
            assert(ready)
            else begin
                $error("Not ready!");
                err++;
            end
            #2;
        end

        bank_card_insert = 1;
        
        test_num = 1;
        // Test 1a: Check to see if incorrect pin gives expected states of idle and pin_check.
        // Default pin that matches is 1234, should be wrong. 
        for (int i = 0; i < 10; i++) begin
            pin = i[13:0];
            assert(dut.state === dut.idle || dut.state === dut.pin_check)
            else begin
                $error("Pin check state is incorrect!");
                err++;
            end
            #2;
        end
        
        test_num = 2;
        // Test 1b: Check to see if correct pin gives expected state
        pin = 14'd1234;
        // Do one extra cycle because we're not at the correct state to check for pin.
        if(dut.state == dut.idle) begin
            #2;
        end
        #2;
        assert(dut.state !== dut.idle || dut.state !== dut.pin_check)
        else begin
            $error("Correct pin states!");
            err++;
        end

        test_num = 3;
        // Test 2a: to see if selection of withdrawal goes to correct states.
        // Withdrawal == 0, Deposit == 1;
        #2;
        assert(dut.state === dut.withdrawal_account_selection)
        else begin
            $error("Withdrawal state incorrect!");
            err++;
        end

        test_num = 4;
        // Test 2b: see if deposit goes to correct state. Reset states first
        rst = 1;
        #2;
        rst = 0;
        deposit_withdrawal_selection = 1'b1;
            // State should be idle
        #2;
            // State should be pin check
        #2; 
            // State should be selecting deposit or withdrawal
        #2;
        assert(dut.state === dut.deposit_account_selection)
        else begin
            $error("Deposit state incorrect!");
            err++;
        end

        test_num = 5;
        // Test 3: check to see if deposited correctly
        #2;
        assert(dut.chequing_local > dut.CHEQUING_FUNDS_AMOUNT)
        else begin
            $error("Incorrect amount in chequing! Must have more because deposited money!");
            err++;
        end

        test_num = 6;
        // Test 4: Check withdrawal correct
        deposit_withdrawal_selection = 1'b0;
        rst = 1;
        #2;
        rst = 0;
        #12;
        assert(dut.chequing_local < dut.CHEQUING_FUNDS_AMOUNT)
        else begin
            $error("Incorrect amount in chequing! Must have less because we withdrew money!");
            err++;
        end

        test_num = 7;
        // Test 5: Check insufficient funds
        amount = 14'd5000;
        rst = 1;
        #2;
        rst = 0;
        #12;
        assert(dut.state == dut.insufficient_funds_check)
        else begin
            $error("Insufficient funds unexpected state!");
            err++;
        end

        test_num = 8;
        // Test 6: Check if withdraw card not 0 makes it loop indefinitely at withdraw card state.
        amount = 14'd1;
        #30;
        assert(dut.state === dut.withdraw_card)
        else begin
            $error("Incorrect end state! Must be withdraw card state!");
            err++;
        end

        test_num = 9;
        // Test 6b: Check if withdrawing card makes loop end
        bank_card_insert = 0;
        #30;
        assert(dut.state !== dut.withdraw_card)
        else begin
            $error("Incorrect end state! Must be NOT be in withdraw card state!");
            err++;
        end

        if (err > 0)
            $display("FAILED; Errors encountered!");
        else
            $display("ALL TESTS PASSED!");

    end

endmodule