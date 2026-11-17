// =============================================================================
// pl_control.sv
// Unidade de Controle Principal -- RV32I pipelined (P&H secao 4.4)
//
// Decodifica o opcode de 7 bits (estagio ID) e gera os sinais de controle
// que serao propagados pelos registradores de pipeline.
//
// Instrucoes suportadas:
//   R-type  (0110011): add, sub, and, or, xor, slt, sltu, sll, srl, sra
//   I-type  (0010011): addi, andi, ori, xori, slti, sltiu, slli, srli, srai
//   I-type  (0000011): lb, lh, lw, lbu, lhu
//   S-type  (0100011): sb, sh, sw
//   B-type  (1100011): beq, bne, blt, bge, bltu, bgeu
//   J-type  (1101111): jal
//   I-type  (1100111): jalr
//   U-type  (0110111): lui
//   U-type  (0010111): auipc
//
// Tabela de sinais de controle:
//   Sinal     | R-type | OP-IMM | load | store | branch | lui | auipc | jal | jalr
//   ----------|--------|--------|------|-------|--------|-----|-------|-----|-----
//   ALUSrc    |   0    |   1    |  1   |   1   |   0    |  1  |  1    |  0  |  1     0=reg, 1=imm
//   ALUSrcA   |  00    |  00    | 00   |  00   |  00    | 10  | 01    | 00  | 00     00=rs1, 01=PC, 10=zero
//   MemtoReg  |   0    |   0    |  1   |   -   |   -    |  0  |  0    |  0  |  0     0=ALU, 1=mem
//   RegWrite  |   1    |   1    |  1   |   0   |   0    |  1  |  1    |  1  |  1
//   MemRead   |   0    |   0    |  1   |   0   |   0    |  0  |  0    |  0  |  0
//   MemWrite  |   0    |   0    |  0   |   1   |   0    |  0  |  0    |  0  |  0
//   Branch    |   0    |   0    |  0   |   0   |   1    |  0  |  0    |  0  |  0
//   Jump      |   0    |   0    |  0   |   0   |   0    |  0  |  0    |  1  |  0     JAL
//   Jalr      |   0    |   0    |  0   |   0   |   0    |  0  |  0    |  0  |  1     JALR
//   ALUOp     |  10    |  11    | 00   |  00   |  01    | 00  | 00    | 00  | 00
//
// JAL/JALR: o valor gravado em rd e PC+4 (calculado no estagio EX); o alvo do
// salto e resolvido no estagio EX (flush de IF e ID).
// =============================================================================

`timescale 1ns / 1ps

module pl_control (
    input  logic [6:0] Opcode,
    output logic       ALUSrc,
    output logic       MemtoReg,
    output logic       RegWrite,
    output logic       MemRead,
    output logic       MemWrite,
    output logic       Branch,
    output logic [1:0] ALUOp,
    output logic [1:0] ALUSrcA,
    output logic       Jump,
    output logic       Jalr
);

    localparam R_TYPE = 7'b0110011;
    localparam OP_IMM = 7'b0010011;
    localparam LOAD   = 7'b0000011;
    localparam STORE  = 7'b0100011;
    localparam BRANCH = 7'b1100011;
    localparam LUI    = 7'b0110111;
    localparam AUIPC  = 7'b0010111;
    localparam JAL    = 7'b1101111;
    localparam JALR   = 7'b1100111;

    always_comb begin
        ALUSrc   = 1'b0;
        MemtoReg = 1'b0;
        RegWrite = 1'b0;
        MemRead  = 1'b0;
        MemWrite = 1'b0;
        Branch   = 1'b0;
        ALUOp    = 2'b00;
        ALUSrcA  = 2'b00;
        Jump     = 1'b0;
        Jalr     = 1'b0;

        case (Opcode)
            R_TYPE: begin
                ALUSrc   = 1'b0;
                MemtoReg = 1'b0;
                RegWrite = 1'b1;
                ALUOp    = 2'b10;
            end
            OP_IMM: begin
                ALUSrc   = 1'b1;
                RegWrite = 1'b1;
                ALUOp    = 2'b11;   // I-type aritmetico (decodifica funct3/funct7)
            end
            LOAD: begin
                ALUSrc   = 1'b1;
                MemtoReg = 1'b1;
                RegWrite = 1'b1;
                MemRead  = 1'b1;
                ALUOp    = 2'b00;
            end
            STORE: begin
                ALUSrc   = 1'b1;
                MemWrite = 1'b1;
                ALUOp    = 2'b00;
            end
            BRANCH: begin
                Branch   = 1'b1;
                ALUOp    = 2'b01;
            end
            LUI: begin
                ALUSrc   = 1'b1;
                RegWrite = 1'b1;
                ALUOp    = 2'b00;   // soma
                ALUSrcA  = 2'b10;   // 0 + imm
            end
            AUIPC: begin
                ALUSrc   = 1'b1;
                RegWrite = 1'b1;
                ALUOp    = 2'b00;   // soma
                ALUSrcA  = 2'b01;   // PC + imm
            end
            JAL: begin
                RegWrite = 1'b1;    // rd <- PC+4
                Jump     = 1'b1;
            end
            JALR: begin
                ALUSrc   = 1'b1;
                RegWrite = 1'b1;    // rd <- PC+4
                Jalr     = 1'b1;
            end
            default: ; // sinais permanecem em zero (seguro)
        endcase
    end

endmodule
