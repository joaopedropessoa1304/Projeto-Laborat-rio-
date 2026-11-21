# RV32I Pipelined Base Project

Processador RISC-V de 32 bits com pipeline de 5 estágios implementado em SystemVerilog, baseado nas seções 4.6 a 4.10 de *Computer Organization and Design: RISC-V Edition* (Patterson & Hennessy). O projeto tem como plataforma alvo a placa **DE2-115** (Intel Cyclone IV E) e é estruturado para servir de base para extensões do conjunto de instruções pelos alunos.

---

## Instruções suportadas

O processador implementa as **37 instruções do RV32I**.

### Instruções do projeto base

| # | Instrução | Tipo | Opcode  | Status |
|---|-----------|------|---------|:------:|
| 1 | `ADD`     | R    | 0110011 | ✅ |
| 2 | `SUB`     | R    | 0110011 | ✅ |
| 3 | `OR`      | R    | 0110011 | ✅ |
| 4 | `AND`     | R    | 0110011 | ✅ |
| 5 | `SLT`     | R    | 0110011 | ✅ |
| 6 | `LW`      | I    | 0000011 | ✅ |
| 7 | `SW`      | S    | 0100011 | ✅ |
| 8 | `BEQ`     | B    | 1100011 | ✅ |

### Resumo de cobertura do ISA RV32I

| Categoria          | Total ISA | Implementadas | Faltando |
|--------------------|:---------:|:-------------:|:--------:|
| R-type             | 10        | 10            | 0        |
| I-type aritmético  | 9         | 9             | 0        |
| I-type load        | 5         | 5             | 0        |
| S-type             | 3         | 3             | 0        |
| B-type             | 6         | 6             | 0        |
| U-type             | 2         | 2             | 0        |
| J-type (JAL + JALR)| 2         | 2             | 0        |
| **Total**          | **37**    | **37**        | **0**    |

### Etapa 01 — Aritmética, lógica e deslocamentos

#### Registrador-registrador (R-type)

| # | Instrução | Tipo | Opcode  | Status |
|---|-----------|------|---------|:------:|
| 1 | `XOR`     | R    | 0110011 | ✅ |
| 2 | `SLL`     | R    | 0110011 | ✅ |
| 3 | `SRL`     | R    | 0110011 | ✅ |
| 4 | `SRA`     | R    | 0110011 | ✅ |
| 5 | `SLTU`    | R    | 0110011 | ✅ |

#### Com imediato (I-type aritmético, opcode `0010011`)

| # | Instrução | Tipo | Opcode  | Status |
|---|-----------|------|---------|:------:|
| 1 | `ADDI`    | I    | 0010011 | ✅ |
| 2 | `ANDI`    | I    | 0010011 | ✅ |
| 3 | `ORI`     | I    | 0010011 | ✅ |
| 4 | `XORI`    | I    | 0010011 | ✅ |
| 5 | `SLTI`    | I    | 0010011 | ✅ |
| 6 | `SLTIU`   | I    | 0010011 | ✅ |
| 7 | `SLLI`    | I    | 0010011 | ✅ |
| 8 | `SRLI`    | I    | 0010011 | ✅ |
| 9 | `SRAI`    | I    | 0010011 | ✅ |

### Etapa 02 — Memória, desvios, jumps e imediato superior

#### Acesso à memória — loads (I-type)

| # | Instrução | Tipo | Opcode  | Status |
|---|-----------|------|---------|:------:|
| 1 | `LB`      | I    | 0000011 | ✅ |
| 2 | `LH`      | I    | 0000011 | ✅ |
| 3 | `LBU`     | I    | 0000011 | ✅ |
| 4 | `LHU`     | I    | 0000011 | ✅ |

#### Acesso à memória — stores (S-type)

| # | Instrução | Tipo | Opcode  | Status |
|---|-----------|------|---------|:------:|
| 1 | `SB`      | S    | 0100011 | ✅ |
| 2 | `SH`      | S    | 0100011 | ✅ |

#### Desvios condicionais (B-type)

| # | Instrução | Tipo | Opcode  | Status |
|---|-----------|------|---------|:------:|
| 1 | `BNE`     | B    | 1100011 | ✅ |
| 2 | `BLT`     | B    | 1100011 | ✅ |
| 3 | `BGE`     | B    | 1100011 | ✅ |
| 4 | `BLTU`    | B    | 1100011 | ✅ |
| 5 | `BGEU`    | B    | 1100011 | ✅ |

#### Jumps

| # | Instrução | Tipo | Opcode  | Status |
|---|-----------|------|---------|:------:|
| 1 | `JAL`     | J    | 1101111 | ✅ |
| 2 | `JALR`    | I    | 1100111 | ✅ |

#### Imediato superior (U-type)

| # | Instrução | Tipo | Opcode  | Status |
|---|-----------|------|---------|:------:|
| 1 | `LUI`     | U    | 0110111 | ✅ |
| 2 | `AUIPC`   | U    | 0010111 | ✅ |

---

## Arquitetura

### Pipeline de 5 estágios

```
+------+     +------+     +------+     +------+     +------+
|  IF  | --> |  ID  | --> |  EX  | --> | MEM  | --> |  WB  |
+------+     +------+     +------+     +------+     +------+
  Busca      Decode       Execução     Memória     Write-back
  instrução  Regs         ALU          dmem/MMIO   Regfile
             Sign-ext     Br/Jump
```

**Registradores de pipeline:** `IF/ID`, `ID/EX`, `EX/MEM`, `MEM/WB` (definidos em `pl_pipe_pkg.sv`).

### Tratamento de hazards

| Hazard | Mecanismo | Detalhe |
|--------|-----------|---------|
| RAW (dado) | Forwarding | EX/MEM → EX e MEM/WB → EX (`pl_forward.sv`) |
| Load-use | Stall | 1 bolha inserida em ID/EX (`pl_hazard.sv`) |
| Branch tomado, JAL, JALR | Flush | 2 NOPs (IF e ID) na resolução em EX (`pl_datapath.sv`) |

**Resolução de branch e jump no estágio EX:** quando um branch é tomado, ou quando a instrução é `JAL`/`JALR`, o PC é redirecionado ao alvo e os dois estágios anteriores (IF e ID) são esvaziados. O custo é de 2 ciclos de penalidade por desvio tomado.

**Banco de registradores com escrita em negedge:** a escrita ocorre na borda de descida do clock, garantindo que o estágio ID leia o valor atualizado no próximo posedge sem necessidade de forwarding WB→ID explícito.

### Desvios condicionais (BEQ, BNE, BLT, BGE, BLTU, BGEU)

O comparador fica no estágio EX e usa rs1 e rs2 **já adiantados** pelo forwarding. A condição é escolhida pelo `funct3`:

| `funct3` | Instrução | Condição |
|:--------:|-----------|----------|
| `000` | `BEQ`  | `rs1 == rs2` |
| `001` | `BNE`  | `rs1 != rs2` |
| `100` | `BLT`  | `rs1 < rs2` (com sinal) |
| `101` | `BGE`  | `rs1 >= rs2` (com sinal) |
| `110` | `BLTU` | `rs1 < rs2` (sem sinal) |
| `111` | `BGEU` | `rs1 >= rs2` (sem sinal) |

O alvo do branch é `PC + imm_B`.

### JAL e JALR

| | `JAL` | `JALR` |
|---|---|---|
| Formato | J | I |
| Alvo | `PC + imm_J` | `(rs1 + imm_I) & ~1` |
| Alcance | ±1 MiB (relativo ao PC) | qualquer endereço de 32 bits |
| Link | `rd ← PC + 4` | `rd ← PC + 4` |
| Uso típico | chamar função, `j label` (`jal x0, label`) | retornar (`jalr x0, x1, 0`), ponteiro de função |

Como funciona no pipeline (`pl_datapath.sv`):

```systemverilog
assign branch_target = id_ex.jalr ? ((fwd_srca + id_ex.imm_ext) & 32'hFFFF_FFFE)
                                  : (id_ex.pc + id_ex.imm_ext);
assign pc_src        = (id_ex.branch && br_taken) || id_ex.jump || id_ex.jalr;
assign ex_result     = (id_ex.jump || id_ex.jalr) ? (id_ex.pc + 32'd4) : alu_result;
```

- O `JAL` reaproveita o somador `PC + imm` do branch. O `JALR` usa `rs1` já adiantado e **zera o bit 0** do alvo, como manda a especificação.
- O valor de link (`PC + 4`) entra no lugar do resultado da ALU (`ex_result`). Assim ele segue o caminho normal EX/MEM → MEM/WB e também pode ser adiantado por forwarding, sem mux novo no write-back.
- Os dois sempre desviam, então sempre fazem o flush de IF e ID.

### Acesso à memória por byte e meia-palavra

`pl_dmem` tem habilitação de escrita por byte (`ByteEn[3:0]`). O estágio MEM posiciona o dado e liga os bytes certos pelo `funct3` e pelos 2 bits baixos do endereço:

| Instrução | Dado escrito | `ByteEn` |
|-----------|--------------|----------|
| `SB` | byte replicado nos 4 bytes | `0001 << offset` |
| `SH` | meia-palavra replicada | `0011` (offset 0) ou `1100` (offset 2) |
| `SW` | palavra inteira | `1111` |

Na leitura, a palavra é deslocada pelo offset e formatada pelo `funct3`: `LB`/`LH` estendem o sinal, `LBU`/`LHU` completam com zeros e `LW` devolve a palavra inteira. A formatação vale só para a memória de dados; leituras de MMIO continuam sendo de 32 bits.

O acesso deve ser alinhado (`SH`/`LH` em endereço par, `SW`/`LW` em múltiplo de 4); acesso desalinhado não é tratado.

### Unidade de controle

| Sinal | R-type | OP-IMM | load | store | branch | `LUI` | `AUIPC` | `JAL` | `JALR` |
|-------|:------:|:------:|:----:|:-----:|:------:|:-----:|:-------:|:-----:|:------:|
| `ALUSrc`   | 0 | 1 | 1 | 1 | 0 | 1 | 1 | 0 | 1 |
| `ALUSrcA`  | 00 | 00 | 00 | 00 | 00 | 10 | 01 | 00 | 00 |
| `MemtoReg` | 0 | 0 | 1 | - | - | 0 | 0 | 0 | 0 |
| `RegWrite` | 1 | 1 | 1 | 0 | 0 | 1 | 1 | 1 | 1 |
| `MemRead`  | 0 | 0 | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| `MemWrite` | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 0 | 0 |
| `Branch`   | 0 | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 0 |
| `Jump`     | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 0 |
| `Jalr`     | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 |
| `ALUOp`    | 10 | 11 | 00 | 00 | 01 | 00 | 00 | 00 | 00 |

`ALUSrcA` escolhe a entrada A da ALU (depois do forwarding): `00` = rs1, `01` = PC (usado pelo `AUIPC`), `10` = zero (usado pelo `LUI`, que vira `0 + imm`).

### Mapa de memória

| Endereço (byte) | Tamanho | Acesso | Descrição |
|-----------------|---------|--------|-----------|
| `0x000 – 0x3FC` | 256 × 32 b | R/W | Memória de dados (`pl_dmem`) |
| `0x400` | 32 b | R | SW\[17:0\] — chaves deslizantes |
| `0x404` | 32 b | R | KEY\[3:0\] — botões push |
| `0x408` | 32 b | W | LEDR\[17:0\] — LEDs vermelhos |
| `0x40C` | 32 b | W | LEDG\[8:0\] — LEDs verdes |
| `0x410` | 32 b | R/W | UART RS-232 (8N1, 9600 baud) |
| `0x414` | 32 b | R | Contador de ciclos de clock (32 bits, reset em 0) |

Seleção: `alu_result[10] = 1` redireciona o acesso ao controlador MMIO (`pl_mmio`).

**Leitura da UART (`lw` em 0x410):** `{22'b0, tx_busy[9], rx_ready[8], rx_data[7:0]}`

**Escrita na UART (`sw` em 0x410):** o hardware (`pl_mmio`) divide automaticamente a palavra de 32 bits em 4 bytes e os envia em sequência little-endian (byte 0 primeiro). `tx_busy` permanece alto até o último byte ser aceito pelo shift register. O software deve aguardar `tx_busy = 0` antes de escrever nova palavra.

### ALU — codificação de operação

| Operation | Operação | Instruções |
|-----------|----------|------------|
| `4'd01` | ADD  | LW, SW, ADD, ADDI, LUI, AUIPC (e loads/stores em geral) |
| `4'd02` | SUB  | SUB |
| `4'd03` | XOR  | XOR, XORI |
| `4'd04` | OR   | OR, ORI |
| `4'd05` | AND  | AND, ANDI |
| `4'd06` | SLL  | SLL, SLLI |
| `4'd07` | SRL  | SRL, SRLI |
| `4'd08` | SRA  | SRA, SRAI |
| `4'd09` | SLTU | SLTU, SLTIU |
| `4'd11` | SLT  | SLT, SLTI |

O campo `ALUOp` (vindo da unidade de controle) diz como o `pl_alu_ctrl` escolhe a operação:

| `ALUOp` | Usado por | Operação |
|:-------:|-----------|----------|
| `00` | load, store, LUI, AUIPC, JAL, JALR | ADD |
| `01` | branch | SUB (a decisão do branch vem do comparador dedicado) |
| `10` | R-type | decodificada por `funct3` / `funct7` |
| `11` | I-type aritmético | decodificada por `funct3` (`funct7[5]` só diferencia SRLI de SRAI) |

---

## Estrutura do repositório

```
rv32i_pipelined_base_project/
│
├── src/                        Código-fonte SystemVerilog
│   ├── pl_pipe_pkg.sv          Structs dos registradores de pipeline
│   ├── pl_top.sv               Top-level (PLL 50→10 MHz + CPU)
│   ├── pl_top_no_pll.sv        Top-level alternativo, sem PLL (clock de 50 MHz direto)
│   ├── pl_cpu.sv               Wrapper: Control + ALU_Ctrl + Datapath
│   ├── pl_control.sv           Unidade de controle (estágio ID)
│   ├── pl_alu_ctrl.sv          Controle da ALU (estágio EX)
│   ├── pl_alu.sv               ALU 32 bits
│   ├── pl_regfile.sv           Banco de registradores 32×32 b
│   ├── pl_sign_ext.sv          Extensão de sinal I/S/B/U/J
│   ├── pl_imem.sv              Memória de instruções 256×32 b (MIF)
│   ├── pl_dmem.sv              Memória de dados 256×32 b (MIF)
│   ├── pl_mmio.sv              Controlador MMIO (SW/KEY/LED/UART)
│   ├── pl_uart.sv              UART RS-232 8N1 (9600 baud, 50 MHz)
│   ├── pl_hazard.sv            Detecção de hazard load-use
│   ├── pl_forward.sv           Unidade de forwarding
│   ├── pl_datapath.sv          Datapath 5 estágios
│   ├── pl_cpu_tb.sv            Testbench de verificação
│   └── pll_10mhz.v             PLL Altera (50 MHz → 10 MHz)
│
├── mifs/                       Arquivos de inicialização de memória
│   ├── instruction_halt_serial.mif  Programa de teste (hazards + "HALT!" na serial + LEDs)
│   ├── data_halt_serial.mif         Dados iniciais desse programa
│   ├── mmio_test_program.mif        Programa de teste MMIO + UART
│   └── mmio_test_data.mif           Dados para o teste MMIO
│
├── assembler/
│   ├── assembler.py            Montador Python: assembly → .mif / dump
│   ├── hello.asm               Programa de entrada padrão (termina em halt)
│   ├── instruction.mif         MIF gerado no modo normal
│   └── program.hex             Hex gerado no modo normal
│
├── dump/
│   └── serial_dump.py          Captura e decodifica dump serial do FPGA
│
├── modelsim/                   Projeto ModelSim para simulação
│   ├── *.mpf                   Arquivo de projeto ModelSim
│   ├── program.hex             Imagem da instrução (.hex para $readmemh)
│   ├── data.hex                Imagem dos dados (.hex para $readmemh)
│   ├── golden.txt              Saída esperada pelo testbench
│   ├── teste_etapa1/           Teste da etapa 1 (.asm, program.hex e golden.txt)
│   └── output.txt              Saída gerada na última simulação
│
└── quartus/                    Projeto Quartus Prime para síntese
    ├── setup_projeto.tcl       Cria o projeto (dispositivo, top-level, arquivos, pinos)
    ├── *.qpf / *.qsf           Projeto Quartus (gerado pelo script, não versionado)
    ├── pl_top.sdc              Restrições de timing
    ├── instruction.mif         MIF da instrução (gerado por assembler.py --dump)
    └── data.mif                MIF dos dados (gerado por assembler.py --dump)
```

---

## Como simular (ModelSim)

1. Abra o ModelSim e carregue o projeto `modelsim/rv32i_pipelined_base_project.mpf`.
2. Compile todos os arquivos em `src/` — compilar `pl_pipe_pkg.sv` primeiro.
3. Inicie a simulação com o top `pl_cpu_tb`.
4. Execute `run -all`.

O testbench detecta o halt automaticamente (repetição periódica do PC causada pelo `beq x0, x0, 0`), imprime o estado final dos registradores e da memória, e compara a saída com `modelsim/golden.txt`.

**Programa de teste padrão (parte 1 de `mifs/instruction_halt_serial.mif`):**

```
000: lw  x1,  0(x0)   x1 = 10
001: lw  x2,  4(x0)   x2 = 20
002: add x3, x1, x2   x3 = 30   -- forwarding MEM/WB→EX
003: and x4, x3, x1   x4 = 10   -- forwarding EX/MEM→EX
004: lw  x5,  0(x0)   x5 = 10   -- causa load-use stall
005: add x6, x5, x2   x6 = 30   -- executado após 1 ciclo de stall
006: sw  x3,  8(x0)   dmem[2] = 30
007: beq x1, x2, +8   NÃO tomado (10 ≠ 20)
008: add x7, x1, x2   x7 = 30
009: beq x1, x5, +8   TOMADO (10 = 10) → flush de 00A
00A: add x8, x0, x0   DESCARTADO
00B: add x8, x1, x4   x8 = 20
00C: beq x0, x0,  0   halt
```

Estado final esperado: `x1=10  x2=20  x3=30  x4=10  x5=10  x6=30  x7=30  x8=20  dmem[2]=30`

---

## Como sintetizar (Quartus)

1. Crie o projeto com o script (uma vez só): no terminal, dentro de `quartus/`, rode `quartus_sh -t setup_projeto.tcl`. Ele configura o dispositivo, o top-level `pl_top`, os arquivos de síntese (sem o testbench), o SDC e os 52 pinos.
2. Abra `quartus/projeto.qpf` no Quartus. Os arquivos `instruction.mif` e `data.mif` são lidos da própria pasta `quartus/`.
3. Execute **Processing → Start Compilation**.
4. Grave `quartus/output_files/projeto.sof` na DE2-115 via JTAG (**Tools → Programmer**).

> Cuidado: o projeto precisa ficar dentro de `quartus/`. Se ele for criado na raiz do repositório, o Quartus não acha os `.mif` e acusa "Can't find Memory Initialization File". O `pl_cpu_tb.sv` e o `pl_top_no_pll.sv` não podem estar na lista de arquivos do projeto.

**Dispositivo alvo:** Intel Cyclone IV E — EP4CE115F29C7  
**Clock:** 50 MHz (entrada) → 10 MHz (saída da PLL, usado pelo CPU)  
**Reset:** KEY\[0\] ativo-baixo; liberado após a PLL travar (saída do reset sincronizada com o clock da CPU).

### O que deve aparecer na placa (programa `hello.asm` com `--dump`)

- Logo depois de gravar (ou de apertar e soltar KEY\[0\]), os **9 LEDs verdes acendem**: é o sinal de que o programa terminou e o dump foi enviado.
- O `serial_dump.py` recebe 41 palavras e mostra `x1=0xA x2=0x14 x3=0x1E x4=0xA x5=0xA x6=0x1E x7=0x1E x8=0x14` e `dmem[0..3] = 0xA 0x14 0x1E 0x2`.
- Abra o `serial_dump.py` **antes** de apertar KEY\[0\]: o dump é enviado uma vez só.

---

## Assembler

O script `assembler/assembler.py` converte assembly textual para o formato `.mif`.

### Uso

```bash
cd assembler

# modo normal — gera instruction.mif + program.hex
python3 assembler.py programa.asm

# sem argumento — usa instructions.txt como padrão
python3 assembler.py

# modo dump — gera quartus/instruction.mif + quartus/data.mif com dump serial
python3 assembler.py --dump programa.asm

# modo dump com dados iniciais na dmem (uma palavra hex por linha)
python3 assembler.py --dump hello.asm --data ../modelsim/data.hex
```

No modo normal os arquivos são gerados na pasta atual. No modo `--dump` eles vão direto para `quartus/`, onde o Quartus os lê.

### Modo normal

| Arquivo | Formato | Uso |
|---------|---------|-----|
| `instruction.mif` | Quartus MIF | Síntese (Quartus) e simulação (ModelSim via `ram_init_file`) |
| `program.hex` | Um word hex por linha | Simulação via `$readmemh` |

### Modo `--dump`

Anexa automaticamente o código de dump serial ao programa do usuário, sem que o usuário precise escrever nenhuma instrução extra.

| Arquivo | Conteúdo |
|---------|----------|
| `instruction.mif` | Código do usuário + `beq` de desvio + dump serial a partir de `0x080` |
| `data.mif` | Dados do `--data` (se houver) + zeros + constantes do dump em `0x080–0x087` |

Se o programa terminar com o halt `beq x0,x0,0`, o modo `--dump` remove esse halt automaticamente; senão o CPU ficaria preso nele e nunca chegaria ao dump. O dump tem o próprio halt no final.

**Layout da memória de instruções com `--dump`:**

```
0x000..N-1  Código do usuário (máx. 127 instruções)
0xN         beq x0,x0,→0x80   (desvio incondicional para o dump)
0xN+1..07F  NOP (addi x0,x0,0)
0x080..0x0AE  Dump serial — Parts 2–8 (47 instruções)
```

**Layout da memória de dados com `--dump`:**

```
0x000..0x01F  Área do usuário  (byte 0x000–0x07C) — transmitida no dump
0x078..0x07F  Saves de x1–x8  (byte 0x1E0–0x1FC) — escritos em runtime
0x080..0x087  Constantes de infraestrutura         — inicializadas no MIF
```

**O que o dump transmite via UART (164 bytes = 41 palavras):**

```
bytes  0–  3   Contador de ciclos (MMIO 0x414)
bytes  4– 35   Registradores x1–x8
bytes 36–163   dmem[0x000–0x07C] (32 palavras do usuário)
```

O programa do usuário pode ter no máximo **127 instruções**; o assembler valida e reporta erro se excedido.

### Formato de entrada aceito

```
add  x3,x1,x2
lw   x1,0(x0)
sw   x3,8(x0)
beq  x1,x2,-4
```

Exemplos das instruções da etapa 02:

```
addi  x1,x0,8
lui   x5,1
lb    x3,1(x2)
sb    x3,2(x2)
bne   x1,x2,8
jal   x1,8
jalr  x0,x1,0
```

- Offsets de branch e de `jal` são em **bytes** (o `jal x1,8` pula a próxima instrução).
- O `jalr` usa a forma `jalr rd,rs1,imm` (não `imm(rs1)`). O retorno de função é `jalr x0,x1,0`.

Uma instrução por linha, sem rótulos, sem comentários. O argumento de arquivo é opcional — o padrão é `instructions.txt`.

---

## Detalhes de implementação

### Banco de registradores — escrita em negedge

A escrita no banco de registradores ocorre na **borda de descida** do clock (`negedge clk`). Isso resolve o conflito de leitura/escrita simultânea que ocorre quando, após um load-use stall, o estágio WB escreve um registrador no mesmo ciclo em que o estágio ID o lê para captura no registrador ID/EX. Com a escrita em negedge, o valor é garantidamente visível antes do próximo posedge. Esta é a solução descrita na Fig. 4.63 do P&H.

### Detecção de halt no testbench

O halt é implementado como `beq x0, x0, 0`. Com resolução de branch no estágio EX, o PC oscila com período 3 (H, H+4, H+8, H, …). O testbench detecta halt quando `PC_atual == PC_de_3_ciclos_atrás` por 9 ciclos consecutivos (3 períodos completos).

### UART (9600 8N1 a 50 MHz)

Implementada em `pl_uart.sv` (parâmetros `CLK_HZ=50_000_000`, `BAUD=9600`). Taxa de erro: < 0,1% (5208 clocks/bit, baud efetivo 9601). O sequenciador de 4 bytes em `pl_mmio.sv` divide automaticamente cada `sw` em 0x410 em 4 transmissões consecutivas, liberando o software de enviar byte a byte.

### Dump serial

O script `dump/serial_dump.py` captura e decodifica o dump transmitido pelo FPGA. Pré-requisito: `pip install pyserial`.

```bash
python3 dump/serial_dump.py COM3            # Windows
python3 dump/serial_dump.py /dev/ttyUSB0   # Linux
python3 dump/serial_dump.py COM3 --out resultado.txt
```

Aguarda **164 bytes** (41 palavras × ~4 ms a 9600 baud) e exibe ciclos, x1–x8 e dmem[0x000–0x07C]. Para usar, compile com `python3 assembler.py --dump` e grave o bitstream no FPGA.

**Fluxo completo:**

```bash
cd assembler
python3 assembler.py --dump meu_programa.asm  # gera quartus/instruction.mif + quartus/data.mif
# compilar e gravar na FPGA via Quartus (o .mif só é lido na compilação)...
cd ../dump
python3 serial_dump.py COM3                    # captura o resultado
```

---

## Decodificação das operações da ALU

#### R-type

| Instrução | `funct3` | `funct7` | `Operation` |
|---|---:|---:|---:|
| ADD  | `000` | `0000000` | `1` |
| SUB  | `000` | `0100000` | `2` |
| XOR  | `100` | `0000000` | `3` |
| OR   | `110` | `0000000` | `4` |
| AND  | `111` | `0000000` | `5` |
| SLL  | `001` | `0000000` | `6` |
| SRL  | `101` | `0000000` | `7` |
| SRA  | `101` | `0100000` | `8` |
| SLTU | `011` | `0000000` | `9` |
| SLT  | `010` | `0000000` | `11` |

#### I-type aritmético (opcode `0010011`)

| Instrução | `funct3` | `funct7` | `Operation` |
|---|---:|---:|---:|
| ADDI  | `000` | — | `1` |
| SLLI  | `001` | `0000000` | `6` |
| SLTI  | `010` | — | `11` |
| SLTIU | `011` | — | `9` |
| XORI  | `100` | — | `3` |
| SRLI  | `101` | `0000000` | `7` |
| SRAI  | `101` | `0100000` | `8` |
| ORI   | `110` | — | `4` |
| ANDI  | `111` | — | `5` |

## Recursos

- [Manual RISC-V ISA v2.2](https://riscv.org/wp-content/uploads/2017/05/riscv-spec-v2.2.pdf)
- [RISC-V ISA Reference (msyksphinz)](https://msyksphinz-self.github.io/riscv-isadoc/html/rvi.html)
- [RISC-V Interpreter — Cornell University](https://www.cs.cornell.edu/courses/cs3410/2019sp/riscv/interpreter/)
- Patterson & Hennessy, *Computer Organization and Design: RISC-V Edition*, seções 4.6 – 4.10
