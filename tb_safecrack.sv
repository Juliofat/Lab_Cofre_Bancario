`timescale 1ns/1ps

module safecrack_tb;

    logic clk;
    logic rst_n;
    logic [3:0] btn;
    logic unlocked;

    // Instância do DUT
    safecrack_fsm dut (
        .clk(clk),
        .rst_n(rst_n),
        .btn(btn),
        .unlocked(unlocked)
    );

    // Clock de 50 MHz
    initial clk = 0;
    always #10 clk = ~clk;

    // =========================================================================
    // TASK: pressionar botão
    // =========================================================================
    task pressionar(input logic [3:0] valor);
        begin
            @(negedge clk);
            btn = valor;      // pressiona

            @(posedge clk);

            @(negedge clk);
            btn = 4'b0000;    // solta

            repeat (2) @(posedge clk);
        end
    endtask

    // =========================================================================
    // TESTES
    // =========================================================================
    initial begin

        $dumpfile("safecrack.vcd");
        $dumpvars(0, safecrack_tb);

        // -------------------------
        // RESET
        // -------------------------
        rst_n = 0;
        btn   = 4'b0000;

        repeat (3) @(posedge clk);
        rst_n = 1;

        // ==============================================================
        // TESTE 1: sequência correta
        // ==============================================================
        $display("\n=== TESTE 1: SEQUÊNCIA CORRETA ===");

        pressionar(4'b0001); // azul
        pressionar(4'b0010); // amarelo
        pressionar(4'b0010); // amarelo
        pressionar(4'b1000); // vermelho

        if (unlocked)
            $display("PASS: Cofre abriu corretamente");
        else
            $display("FAIL: Cofre nao abriu");

        // ==============================================================
        // TESTE 2: erro na sequência
        // ==============================================================
        $display("\n=== TESTE 2: ERRO ===");

        rst_n = 0; @(posedge clk); rst_n = 1;

        pressionar(4'b0001);
        pressionar(4'b0100); // botão errado

        if (!unlocked)
            $display("PASS: erro tratado");
        else
            $display("FAIL: erro nao tratado");

        // ==============================================================
        // TESTE 3: botão inválido (não one-hot)
        // ==============================================================
        $display("\n=== TESTE 3: BOTAO INVALIDO ===");

        pressionar(4'b0011); // dois botões

        if (!unlocked)
            $display("PASS: entrada invalida tratada");
        else
            $display("FAIL: entrada invalida nao tratada");

        // ==============================================================
        // TESTE 4: botão segurado
        // ==============================================================
        $display("\n=== TESTE 4: BOTAO SEGURADO ===");

        @(negedge clk);
        btn = 4'b0001;

        repeat (10) @(posedge clk);

        btn = 4'b0000;

        if (!unlocked)
            $display("PASS: nao houve multiplas leituras");
        else
            $display("FAIL: erro de borda");

        $display("\n=== FIM DA SIMULACAO ===\n");
        $finish;
    end

endmodule