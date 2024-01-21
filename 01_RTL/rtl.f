+v2k 
-debug_access+all 
+notimingcheck 
-P /usr/cad/synopsys/verdi/cur/share/PLI/VCS/LINUX64/novas.tab
/usr/cad/synopsys/verdi/cur/share/PLI/VCS/LINUX64/pli.a
-sverilog 
-assert svaext
+lint=TFIPC-L
+fsdb+parameter=on

-y /usr/cad/synopsys/synthesis/cur/dw/sim_ver +libext+.v
+incdir+/usr/cad/synopsys/synthesis/cur/dw/sim_ver/+

// Change different packets
+define+P6

//sram and design
define.v
QR_Engine.v
Register.v
cal_Rii.v
cal_e.v
cal_inner.v
projection.v
cal_yhat.v
// tb

testfixture.v
//testbench.v
