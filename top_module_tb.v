`timescale 1ns/10ps

module top_module_tb();

reg reset_i, clk_i, wen_i;
reg [31:0] instr_i;
reg [10:0] addr_i;

top_module uut(.reset_i(reset_i), .clk_i(clk_i), .instr_i(instr_i), .addr_i(addr_i), .wen_i(wen_i));

always begin
clk_i = 1'b0; #50; clk_i = 1'b1; #50;
end

//load instructions here
//the instructions below execute multiplication algorithm.
//commented out part is bubble sort
initial begin
reset_i = 1'b0; wen_i = 1'b0;
instr_i = 32'h24000113; addr_i = 11'd0; #100; 
instr_i = 32'h00010433; addr_i = 11'd4; #100; 
instr_i = 32'h0A40006F; addr_i = 11'd8; #100; 
instr_i = 32'hFD010113; addr_i = 11'd12; #100; 
instr_i = 32'h02812623; addr_i = 11'd16; #100; 
instr_i = 32'h03010413; addr_i = 11'd20; #100; 
instr_i = 32'hFCA42E23; addr_i = 11'd24; #100; 
instr_i = 32'hFCB42C23; addr_i = 11'd28; #100; 
instr_i = 32'hFE042623; addr_i = 11'd32; #100; 
instr_i = 32'h00100793; addr_i = 11'd36; #100; 
instr_i = 32'hFEF42423; addr_i = 11'd40; #100; 
instr_i = 32'h00100793; addr_i = 11'd44; #100; 
instr_i = 32'hFEF42223; addr_i = 11'd48; #100; 
instr_i = 32'h0540006F; addr_i = 11'd52; #100; 
instr_i = 32'hFD842703; addr_i = 11'd56; #100; 
instr_i = 32'hFE442783; addr_i = 11'd60; #100; 
instr_i = 32'h00F777B3; addr_i = 11'd64; #100; 
instr_i = 32'h02078063; addr_i = 11'd68; #100; 
instr_i = 32'hFE842783; addr_i = 11'd72; #100; 
instr_i = 32'hFFF78793; addr_i = 11'd76; #100; 
instr_i = 32'hFDC42703; addr_i = 11'd80; #100; 
instr_i = 32'h00F717B3; addr_i = 11'd84; #100; 
instr_i = 32'hFEC42703; addr_i = 11'd88; #100; 
instr_i = 32'h00F707B3; addr_i = 11'd92; #100; 
instr_i = 32'hFEF42623; addr_i = 11'd96; #100; 
instr_i = 32'hFE442783; addr_i = 11'd100; #100; 
instr_i = 32'h00179793; addr_i = 11'd104; #100; 
instr_i = 32'hFEF42223; addr_i = 11'd108; #100; 
instr_i = 32'hFE842783; addr_i = 11'd112; #100; 
instr_i = 32'h00178793; addr_i = 11'd116; #100; 
instr_i = 32'hFEF42423; addr_i = 11'd120; #100; 
instr_i = 32'hFD842783; addr_i = 11'd124; #100; 
instr_i = 32'hFE442703; addr_i = 11'd128; #100; 
instr_i = 32'h00E7E863; addr_i = 11'd132; #100; 
instr_i = 32'hFE442783; addr_i = 11'd136; #100; 
instr_i = 32'hFA07D6E3; addr_i = 11'd140; #100; 
instr_i = 32'h0080006F; addr_i = 11'd144; #100; 
instr_i = 32'h00000013; addr_i = 11'd148; #100; 
instr_i = 32'hFEC42783; addr_i = 11'd152; #100; 
instr_i = 32'h00078513; addr_i = 11'd156; #100; 
instr_i = 32'h02C12403; addr_i = 11'd160; #100; 
instr_i = 32'h03010113; addr_i = 11'd164; #100; 
instr_i = 32'h00008067; addr_i = 11'd168; #100; 
instr_i = 32'hFE010113; addr_i = 11'd172; #100; 
instr_i = 32'h00112E23; addr_i = 11'd176; #100; 
instr_i = 32'h00812C23; addr_i = 11'd180; #100; 
instr_i = 32'h02010413; addr_i = 11'd184; #100; 
instr_i = 32'h000027B7; addr_i = 11'd188; #100; 
instr_i = 32'hC5A78793; addr_i = 11'd192; #100; 
instr_i = 32'hFEF42623; addr_i = 11'd196; #100; 
instr_i = 32'h5B700793; addr_i = 11'd200; #100; 
instr_i = 32'hFEF42423; addr_i = 11'd204; #100; 
instr_i = 32'hFE842583; addr_i = 11'd208; #100; 
instr_i = 32'hFEC42503; addr_i = 11'd212; #100; 
instr_i = 32'hF35FF0EF; addr_i = 11'd216; #100; 
instr_i = 32'hFEA42223; addr_i = 11'd220; #100; 
instr_i = 32'h00000793; addr_i = 11'd224; #100; 
instr_i = 32'h00078513; addr_i = 11'd228; #100; 
instr_i = 32'h01C12083; addr_i = 11'd232; #100; 
instr_i = 32'h01812403; addr_i = 11'd236; #100; 
instr_i = 32'h02010113; addr_i = 11'd240; #100; 
instr_i = 32'h00008067; addr_i = 11'd244; #100; 



/*instr_i = 32'h24000113; addr_i = 9'd0; #100; 
instr_i = 32'h00010433; addr_i = 9'd4; #100; 
instr_i = 32'h0F80006F; addr_i = 9'd8; #100; 
instr_i = 32'hFD010113; addr_i = 9'd12; #100; 
instr_i = 32'h02812623; addr_i = 9'd16; #100; 
instr_i = 32'h03010413; addr_i = 9'd20; #100; 
instr_i = 32'hFCA42E23; addr_i = 9'd24; #100; 
instr_i = 32'hFCB42C23; addr_i = 9'd28; #100; 
instr_i = 32'hFE042623; addr_i = 9'd32; #100; 
instr_i = 32'hFE042423; addr_i = 9'd36; #100; 
instr_i = 32'h0AC0006F; addr_i = 9'd40; #100; 
instr_i = 32'hFE842783; addr_i = 9'd44; #100; 
instr_i = 32'h00279793; addr_i = 9'd48; #100; 
instr_i = 32'hFDC42703; addr_i = 9'd52; #100; 
instr_i = 32'h00F707B3; addr_i = 9'd56; #100; 
instr_i = 32'h0007A703; addr_i = 9'd60; #100; 
instr_i = 32'hFE842783; addr_i = 9'd64; #100; 
instr_i = 32'h00178793; addr_i = 9'd68; #100; 
instr_i = 32'h00279793; addr_i = 9'd72; #100; 
instr_i = 32'hFDC42683; addr_i = 9'd76; #100; 
instr_i = 32'h00F687B3; addr_i = 9'd80; #100; 
instr_i = 32'h0007A783; addr_i = 9'd84; #100; 
instr_i = 32'h06E7D863; addr_i = 9'd88; #100; 
instr_i = 32'hFE842783; addr_i = 9'd92; #100; 
instr_i = 32'h00279793; addr_i = 9'd96; #100; 
instr_i = 32'hFDC42703; addr_i = 9'd100; #100; 
instr_i = 32'h00F707B3; addr_i = 9'd104; #100; 
instr_i = 32'h0007A783; addr_i = 9'd108; #100; 
instr_i = 32'hFEF42223; addr_i = 9'd112; #100; 
instr_i = 32'hFE842783; addr_i = 9'd116; #100; 
instr_i = 32'h00178793; addr_i = 9'd120; #100; 
instr_i = 32'h00279793; addr_i = 9'd124; #100; 
instr_i = 32'hFDC42703; addr_i = 9'd128; #100; 
instr_i = 32'h00F70733; addr_i = 9'd132; #100; 
instr_i = 32'hFE842783; addr_i = 9'd136; #100; 
instr_i = 32'h00279793; addr_i = 9'd140; #100; 
instr_i = 32'hFDC42683; addr_i = 9'd144; #100; 
instr_i = 32'h00F687B3; addr_i = 9'd148; #100; 
instr_i = 32'h00072703; addr_i = 9'd152; #100; 
instr_i = 32'h00E7A023; addr_i = 9'd156; #100; 
instr_i = 32'hFE842783; addr_i = 9'd160; #100; 
instr_i = 32'h00178793; addr_i = 9'd164; #100; 
instr_i = 32'h00279793; addr_i = 9'd168; #100; 
instr_i = 32'hFDC42703; addr_i = 9'd172; #100; 
instr_i = 32'h00F707B3; addr_i = 9'd176; #100; 
instr_i = 32'hFE442703; addr_i = 9'd180; #100; 
instr_i = 32'h00E7A023; addr_i = 9'd184; #100; 
instr_i = 32'hFEC42783; addr_i = 9'd188; #100; 
instr_i = 32'h00178793; addr_i = 9'd192; #100; 
instr_i = 32'hFEF42623; addr_i = 9'd196; #100; 
instr_i = 32'hFE842783; addr_i = 9'd200; #100; 
instr_i = 32'h00178793; addr_i = 9'd204; #100; 
instr_i = 32'hFEF42423; addr_i = 9'd208; #100; 
instr_i = 32'hFD842783; addr_i = 9'd212; #100; 
instr_i = 32'hFFF78793; addr_i = 9'd216; #100; 
instr_i = 32'hFE842703; addr_i = 9'd220; #100; 
instr_i = 32'hF4F746E3; addr_i = 9'd224; #100; 
instr_i = 32'hFEC42783; addr_i = 9'd228; #100; 
instr_i = 32'hF2079CE3; addr_i = 9'd232; #100; 
instr_i = 32'h00000013; addr_i = 9'd236; #100; 
instr_i = 32'h00000013; addr_i = 9'd240; #100; 
instr_i = 32'h02C12403; addr_i = 9'd244; #100; 
instr_i = 32'h03010113; addr_i = 9'd248; #100; 
instr_i = 32'h00008067; addr_i = 9'd252; #100; 
instr_i = 32'hFD010113; addr_i = 9'd256; #100; 
instr_i = 32'h02112623; addr_i = 9'd260; #100; 
instr_i = 32'h02812423; addr_i = 9'd264; #100; 
instr_i = 32'h03010413; addr_i = 9'd268; #100; 
instr_i = 32'h17400793; addr_i = 9'd272; #100; 
instr_i = 32'h0007A803; addr_i = 9'd276; #100; 
instr_i = 32'h0047A503; addr_i = 9'd280; #100; 
instr_i = 32'h0087A583; addr_i = 9'd284; #100; 
instr_i = 32'h00C7A603; addr_i = 9'd288; #100; 
instr_i = 32'h0107A683; addr_i = 9'd292; #100; 
instr_i = 32'h0147A703; addr_i = 9'd296; #100; 
instr_i = 32'h0187A783; addr_i = 9'd300; #100; 
instr_i = 32'hFD042A23; addr_i = 9'd304; #100; 
instr_i = 32'hFCA42C23; addr_i = 9'd308; #100; 
instr_i = 32'hFCB42E23; addr_i = 9'd312; #100; 
instr_i = 32'hFEC42023; addr_i = 9'd316; #100; 
instr_i = 32'hFED42223; addr_i = 9'd320; #100; 
instr_i = 32'hFEE42423; addr_i = 9'd324; #100; 
instr_i = 32'hFEF42623; addr_i = 9'd328; #100; 
instr_i = 32'hFD440793; addr_i = 9'd332; #100; 
instr_i = 32'h00700593; addr_i = 9'd336; #100; 
instr_i = 32'h00078513; addr_i = 9'd340; #100; 
instr_i = 32'hEB5FF0EF; addr_i = 9'd344; #100; 
instr_i = 32'h00000793; addr_i = 9'd348; #100; 
instr_i = 32'h00078513; addr_i = 9'd352; #100; 
instr_i = 32'h02C12083; addr_i = 9'd356; #100; 
instr_i = 32'h02812403; addr_i = 9'd360; #100; 
instr_i = 32'h03010113; addr_i = 9'd364; #100; 
instr_i = 32'h00008067; addr_i = 9'd368; #100; 
instr_i = 32'h000000C3; addr_i = 9'd372; #100; 
instr_i = 32'h0000000E; addr_i = 9'd376; #100; 
instr_i = 32'h000000B0; addr_i = 9'd380; #100; 
instr_i = 32'h00000067; addr_i = 9'd384; #100; 
instr_i = 32'h00000036; addr_i = 9'd388; #100; 
instr_i = 32'h00000020; addr_i = 9'd392; #100; 
instr_i = 32'h00000080; addr_i = 9'd396; #100;*/
wen_i = 1'b1; #200;
reset_i = 1'b1;

end

endmodule
