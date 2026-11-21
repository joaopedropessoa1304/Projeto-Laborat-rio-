# =============================================================================
# setup_projeto.tcl
# Cria (ou atualiza) o projeto Quartus do RV32I pipelined para a DE2-115.
#
# Como usar (o projeto fica DENTRO da pasta quartus/, ao lado dos .mif):
#   Opcao 1 - terminal, dentro de quartus/:
#       quartus_sh -t setup_projeto.tcl
#   Opcao 2 - Quartus aberto: Tools > Tcl Scripts... > setup_projeto.tcl > Run
#             (com o diretorio de trabalho em quartus/)
#   Depois: File > Open Project > quartus/projeto.qpf e Processing > Start Compilation.
#
# O que o script configura:
#   - dispositivo EP4CE115F29C7 (Cyclone IV E, DE2-115)
#   - top-level pl_top (CPU a 10 MHz pela PLL)
#   - so os arquivos de sintese (sem o testbench pl_cpu_tb.sv e sem pl_top_no_pll.sv)
#   - SDC de timing (pl_top.sdc)
#   - os 52 pinos (CLOCK_50, KEY, SW, LEDR, LEDG, UART)
# Os arquivos instruction.mif e data.mif sao lidos da propria pasta quartus/
# (e onde o assembler.py --dump grava).
# =============================================================================

load_package project

set proj projeto

if {[project_exists $proj]} {
    project_open $proj
} else {
    project_new $proj -overwrite
}

# ---- Dispositivo e top-level -------------------------------------------------
set_global_assignment -name FAMILY "Cyclone IV E"
set_global_assignment -name DEVICE EP4CE115F29C7
set_global_assignment -name TOP_LEVEL_ENTITY pl_top
set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files
set_global_assignment -name NUM_PARALLEL_PROCESSORS ALL

# ---- Arquivos de sintese (ordem: pacote primeiro) ----------------------------
foreach f {
    ../src/pl_pipe_pkg.sv
    ../src/pl_alu.sv
    ../src/pl_alu_ctrl.sv
    ../src/pl_control.sv
    ../src/pl_sign_ext.sv
    ../src/pl_regfile.sv
    ../src/pl_hazard.sv
    ../src/pl_forward.sv
    ../src/pl_imem.sv
    ../src/pl_dmem.sv
    ../src/pl_uart.sv
    ../src/pl_mmio.sv
    ../src/pl_datapath.sv
    ../src/pl_cpu.sv
    ../src/pl_top.sv
} {
    set_global_assignment -name SYSTEMVERILOG_FILE $f
}
set_global_assignment -name VERILOG_FILE ../src/pll_10mhz.v
set_global_assignment -name SDC_FILE pl_top.sdc

# Remove arquivos que nao devem ser sintetizados, caso tenham sido adicionados
catch {set_global_assignment -name SYSTEMVERILOG_FILE ../src/pl_cpu_tb.sv -remove}
catch {set_global_assignment -name SYSTEMVERILOG_FILE ../src/pl_top_no_pll.sv -remove}
catch {set_global_assignment -name SDC_FILE pl_top_no_pll.sdc -remove}

# ---- Pinagem DE2-115 (52 pinos) ----------------------------------------------
set_location_assignment PIN_Y23 -to SW[17]
set_location_assignment PIN_F17 -to LEDG[8]
set_location_assignment PIN_G21 -to LEDG[7]
set_location_assignment PIN_G22 -to LEDG[6]
set_location_assignment PIN_G20 -to LEDG[5]
set_location_assignment PIN_H21 -to LEDG[4]
set_location_assignment PIN_E24 -to LEDG[3]
set_location_assignment PIN_E25 -to LEDG[2]
set_location_assignment PIN_E22 -to LEDG[1]
set_location_assignment PIN_E21 -to LEDG[0]
set_location_assignment PIN_H15 -to LEDR[17]
set_location_assignment PIN_G16 -to LEDR[16]
set_location_assignment PIN_G15 -to LEDR[15]
set_location_assignment PIN_F15 -to LEDR[14]
set_location_assignment PIN_H17 -to LEDR[13]
set_location_assignment PIN_J16 -to LEDR[12]
set_location_assignment PIN_H16 -to LEDR[11]
set_location_assignment PIN_J15 -to LEDR[10]
set_location_assignment PIN_G17 -to LEDR[9]
set_location_assignment PIN_J17 -to LEDR[8]
set_location_assignment PIN_H19 -to LEDR[7]
set_location_assignment PIN_J19 -to LEDR[6]
set_location_assignment PIN_E18 -to LEDR[5]
set_location_assignment PIN_F18 -to LEDR[4]
set_location_assignment PIN_F21 -to LEDR[3]
set_location_assignment PIN_E19 -to LEDR[2]
set_location_assignment PIN_F19 -to LEDR[1]
set_location_assignment PIN_G19 -to LEDR[0]
set_location_assignment PIN_Y24 -to SW[16]
set_location_assignment PIN_AA23 -to SW[14]
set_location_assignment PIN_AA24 -to SW[13]
set_location_assignment PIN_AA22 -to SW[15]
set_location_assignment PIN_AB23 -to SW[12]
set_location_assignment PIN_AB24 -to SW[11]
set_location_assignment PIN_AC24 -to SW[10]
set_location_assignment PIN_AB25 -to SW[9]
set_location_assignment PIN_AC25 -to SW[8]
set_location_assignment PIN_AB26 -to SW[7]
set_location_assignment PIN_AD26 -to SW[6]
set_location_assignment PIN_AC26 -to SW[5]
set_location_assignment PIN_AB27 -to SW[4]
set_location_assignment PIN_AD27 -to SW[3]
set_location_assignment PIN_AC27 -to SW[2]
set_location_assignment PIN_AC28 -to SW[1]
set_location_assignment PIN_AB28 -to SW[0]
set_location_assignment PIN_G12 -to UART_RXD
set_location_assignment PIN_G9 -to UART_TXD
set_location_assignment PIN_Y2 -to CLOCK_50
set_location_assignment PIN_M23 -to KEY[0]
set_location_assignment PIN_R24 -to KEY[3]
set_location_assignment PIN_N21 -to KEY[2]
set_location_assignment PIN_M21 -to KEY[1]

export_assignments
project_close
puts "Projeto quartus/$proj configurado: EP4CE115F29C7, top pl_top, 52 pinos."
