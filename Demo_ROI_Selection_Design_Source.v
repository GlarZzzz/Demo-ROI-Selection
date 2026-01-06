`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/06/2026 02:21:05 PM
// Design Name: 
// Module Name: Demo_ROI_Selection_Design_Source
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


module Demo_ROI_Selection_Design_Source #(
    parameter integer IMAGE_WIDTH  = 640,
    parameter integer IMAGE_HEIGHT = 480,
    // Vertices must be specified in COUNTER-CLOCKWISE order --
    parameter integer P1_X = 210, parameter integer P1_Y = 250,  // Top-left
    parameter integer P2_X = 12,  parameter integer P2_Y = 479,  // Bottom-left
    parameter integer P3_X = 410, parameter integer P3_Y = 479,  // Bottom-right
    parameter integer P4_X = 380, parameter integer P4_Y = 252   // Top-right
    )
    (
    
    input  wire         aclk,
    input  wire         aresetn,
    input  wire [23:0]  s_axis_tdata,
    input  wire         s_axis_tvalid,
    output wire         s_axis_tready,
    input  wire         s_axis_tlast,
    input  wire         s_axis_tuser,
    output wire [23:0]  m_axis_tdata,
    output wire         m_axis_tvalid,
    input  wire         m_axis_tready,
    output wire         m_axis_tlast,
    output wire         m_axis_tuser    
    
    );
    
    reg [$clog2(IMAGE_WIDTH)-1:0]  x_cnt;
    reg [$clog2(IMAGE_HEIGHT)-1:0] y_cnt;
    reg [23:0] m_axis_tdata_reg;
    reg        m_axis_tvalid_reg;
    reg        m_axis_tlast_reg;
    reg        m_axis_tuser_reg;

    wire s_axis_fire = s_axis_tvalid && s_axis_tready;
    
    wire signed [31:0] side1, side2, side3, side4;
    wire is_inside;

    wire signed [$clog2(IMAGE_WIDTH):0]  signed_x;
    wire signed [$clog2(IMAGE_HEIGHT):0] signed_y;
    assign signed_x = x_cnt;
    assign signed_y = y_cnt;

    assign s_axis_tready = m_axis_tready;
    assign m_axis_tvalid = m_axis_tvalid_reg;
    assign m_axis_tdata  = m_axis_tdata_reg;
    assign m_axis_tlast  = m_axis_tlast_reg;
    assign m_axis_tuser  = m_axis_tuser_reg;

    always @(posedge aclk) begin
        if (!aresetn) begin
            x_cnt <= 0; y_cnt <= 0;
        end else if (s_axis_fire) begin
            if (s_axis_tuser) begin
                x_cnt <= 0; y_cnt <= 0;
            end else if (x_cnt == IMAGE_WIDTH - 1) begin
                x_cnt <= 0; y_cnt <= y_cnt + 1;
            end else begin
                x_cnt <= x_cnt + 1;
            end
        end
    end
    
    assign side1 = (P2_X - P1_X) * (signed_y - P1_Y) - (P2_Y - P1_Y) * (signed_x - P1_X);
    assign side2 = (P3_X - P2_X) * (signed_y - P2_Y) - (P3_Y - P2_Y) * (signed_x - P2_X);
    assign side3 = (P4_X - P3_X) * (signed_y - P3_Y) - (P4_Y - P3_Y) * (signed_x - P3_X);
    assign side4 = (P1_X - P4_X) * (signed_y - P4_Y) - (P1_Y - P4_Y) * (signed_x - P4_X);

    assign is_inside = (side1 <= 0) && (side2 <= 0) && (side3 <= 0) && (side4 <= 0);

    always @(posedge aclk) begin
        if (!aresetn) begin
            m_axis_tvalid_reg <= 1'b0;
            m_axis_tdata_reg  <= 24'b0;
            m_axis_tlast_reg  <= 1'b0;
            m_axis_tuser_reg  <= 1'b0;
        end else begin
            if (s_axis_fire) begin
                m_axis_tvalid_reg <= 1'b1;
                m_axis_tlast_reg  <= s_axis_tlast;
                m_axis_tuser_reg  <= s_axis_tuser;
                if (is_inside) begin
                    m_axis_tdata_reg <= s_axis_tdata;
                end else begin
                    m_axis_tdata_reg <= 24'h000000;
                end
            end else begin
                 m_axis_tvalid_reg <= 1'b0;
            end
        end
    end
    
endmodule
