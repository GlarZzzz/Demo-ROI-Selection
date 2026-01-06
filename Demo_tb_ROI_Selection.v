`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/06/2026 02:20:20 PM
// Design Name: 
// Module Name: Demo_tb_ROI_Selection
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Demo_tb_ROI_Selection();

    localparam integer CLK_PERIOD       = 10; 
    localparam integer IMAGE_WIDTH      = 640;
    localparam integer IMAGE_HEIGHT     = 480;
    localparam integer AXIS_TDATA_WIDTH = 24;
    localparam integer TOTAL_PIXELS     = IMAGE_WIDTH * IMAGE_HEIGHT;


    parameter integer T_P1_X = 314; parameter integer T_P1_Y = 210;  // Top-left
    parameter integer T_P2_X = 2;  parameter integer T_P2_Y = 479;  // Bottom-left
    parameter integer T_P3_X = 639; parameter integer T_P3_Y = 422;  // Bottom-right
    parameter integer T_P4_X = 403; parameter integer T_P4_Y = 210;   // Top-right
    integer y;
    integer x;


    localparam  INPUT_FILENAME  = "input_image_ROI.hex";
    localparam  OUTPUT_FILENAME = "output_image_ROI.hex";

    reg aclk = 0;
    reg aresetn = 0;

    reg  [AXIS_TDATA_WIDTH-1:0] tb_s_tdata;
    reg                         tb_s_tvalid;
    wire                        tb_s_tready;
    reg                         tb_s_tlast;
    reg                         tb_s_tuser;
    
    wire [AXIS_TDATA_WIDTH-1:0] dut_m_tdata;
    wire                        dut_m_tvalid;
    reg                         dut_m_tready;
    wire                        dut_m_tlast;
    wire                        dut_m_tuser;

    reg [AXIS_TDATA_WIDTH-1:0] image_memory [0:TOTAL_PIXELS-1];
    
    integer output_file_handle;
    
    Demo_ROI_Selection_Design_Source #(
        .IMAGE_WIDTH(IMAGE_WIDTH),
        .IMAGE_HEIGHT(IMAGE_HEIGHT),
        .P1_X(T_P1_X), .P1_Y(T_P1_Y),
        .P2_X(T_P2_X), .P2_Y(T_P2_Y),
        .P3_X(T_P3_X), .P3_Y(T_P3_Y),
        .P4_X(T_P4_X), .P4_Y(T_P4_Y)
    ) dut_instance (
        .aclk(aclk),
        .aresetn(aresetn),
        .s_axis_tdata(tb_s_tdata),
        .s_axis_tvalid(tb_s_tvalid),
        .s_axis_tready(tb_s_tready),
        .s_axis_tlast(tb_s_tlast),
        .s_axis_tuser(tb_s_tuser),
        .m_axis_tdata(dut_m_tdata),
        .m_axis_tvalid(dut_m_tvalid),
        .m_axis_tready(dut_m_tready),
        .m_axis_tlast(dut_m_tlast),
        .m_axis_tuser(dut_m_tuser)
    );

    always # (CLK_PERIOD / 2) aclk = ~aclk;

    initial begin
        aresetn <= 0;
        tb_s_tvalid <= 0;
        tb_s_tlast <= 0;
        tb_s_tuser <= 0;
        dut_m_tready <= 1; 
        # (CLK_PERIOD * 10);
        aresetn <= 1;
        @ (posedge aclk);

        $readmemh(INPUT_FILENAME, image_memory);
        $display("INFO: Input image '%s' loaded into memory.", INPUT_FILENAME);

        output_file_handle = $fopen(OUTPUT_FILENAME, "w");
        if (output_file_handle == 0) begin
            $display("ERROR: Could not open output file '%s'.", OUTPUT_FILENAME);
            $finish;
        end
        $display("INFO: Opened output file '%s' for writing.", OUTPUT_FILENAME);

        $display("INFO: Starting frame transmission.");
        for ( y = 0; y < IMAGE_HEIGHT; y = y + 1) begin
            for ( x = 0; x < IMAGE_WIDTH; x = x + 1) begin
                @ (posedge aclk);
                wait (tb_s_tready === 1'b1); 
                
                tb_s_tvalid <= 1'b1;
                tb_s_tuser  <= (x == 0 && y == 0); 
                tb_s_tlast  <= (x == IMAGE_WIDTH - 1); 
                tb_s_tdata  <= image_memory[y * IMAGE_WIDTH + x];
            end
        end
        

        @ (posedge aclk);
        tb_s_tvalid <= 1'b0;
        tb_s_tlast  <= 1'b0;
        tb_s_tuser  <= 1'b0;
        $display("INFO: Frame transmission complete.");

        # (CLK_PERIOD * 100);
        $fclose(output_file_handle);
        $display("INFO: Testbench finished.");
        $finish;
    end
    

    always @(posedge aclk) begin
        if(aresetn) begin
            if (dut_m_tvalid && dut_m_tready) begin
                $fdisplayh(output_file_handle, dut_m_tdata);
            end
        end
    end

endmodule
