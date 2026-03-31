module safecrack_fsm (
    input  logic       clk,        // Clock do sistema
    input  logic       rst_n,      // Reset assíncrono (ativo em 0)
    input  logic [3:0] btn,        // Entrada dos botões (one-hot)
    output logic       unlocked    // Saída: cofre aberto
);

    // =========================================================================
    // [1] DEFINIÇÃO DOS ESTADOS (ONE-HOT)
    // =========================================================================
    typedef enum logic [4:0] {
        INICIO   = 5'b00001, // aguardando primeiro botão
        AZUL     = 5'b00010, // recebeu azul corretamente
        AMARELO1 = 5'b00100, // recebeu primeiro amarelo
        AMARELO2 = 5'b01000, // recebeu segundo amarelo
        ABERTO   = 5'b10000  // cofre desbloqueado
    } estado_t;

    estado_t estado_atual, proximo_estado;

    // =========================================================================
    // [2] DETECÇÃO DE BORDA (pressionamento único)
    // =========================================================================
    logic [3:0] btn_anterior;
    logic [3:0] btn_borda;
    logic       evento;

    // Detecta transição 0 → 1
    assign btn_borda = btn & ~btn_anterior;

    // Existe evento quando algum botão sobe
    assign evento = (btn_borda != 4'b0000);

    // Armazena valor anterior do botão
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            btn_anterior <= 4'b0000;
        else
            btn_anterior <= btn;
    end

    // =========================================================================
    // [3] VALIDAÇÃO ONE-HOT (apenas 1 botão pressionado)
    // =========================================================================
    logic botao_valido;

    assign botao_valido =
        (btn == 4'b0001) || // azul
        (btn == 4'b0010) || // amarelo
        (btn == 4'b0100) || // verde
        (btn == 4'b1000);   // vermelho

    // =========================================================================
    // [4] REGISTRADOR DE ESTADO
    // =========================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            estado_atual <= INICIO;
        else
            estado_atual <= proximo_estado;
    end

    // =========================================================================
    // [5] LÓGICA DE TRANSIÇÃO
    // =========================================================================
    always_comb begin
        proximo_estado = estado_atual; // padrão

        // Se evento inválido → volta pro início
        if (evento && !botao_valido)
            proximo_estado = INICIO;

        else begin
            unique case (estado_atual)

                // -------------------------
                INICIO: begin
                    if (evento) begin
                        if (btn == 4'b0001) // azul
                            proximo_estado = AZUL;
                        else
                            proximo_estado = INICIO;
                    end
                end

                // -------------------------
                AZUL: begin
                    if (evento) begin
                        if (btn == 4'b0010) // amarelo
                            proximo_estado = AMARELO1;
                        else
                            proximo_estado = INICIO;
                    end
                end

                // -------------------------
                AMARELO1: begin
                    if (evento) begin
                        if (btn == 4'b0010) // amarelo
                            proximo_estado = AMARELO2;
                        else
                            proximo_estado = INICIO;
                    end
                end

                // -------------------------
                AMARELO2: begin
                    if (evento) begin
                        if (btn == 4'b1000) // vermelho
                            proximo_estado = ABERTO;
                        else
                            proximo_estado = INICIO;
                    end
                end

                // -------------------------
                ABERTO: begin
                    proximo_estado = ABERTO; // trava até reset
                end

                default: proximo_estado = INICIO;
            endcase
        end
    end

    // =========================================================================
    // [6] SAÍDA (Máquina de Moore)
    // =========================================================================
    assign unlocked = (estado_atual == ABERTO);

endmodule