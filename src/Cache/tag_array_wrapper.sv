module tag_array_wrapper (
    input         CK,
    input         CS,
    input         OE,
    input  [4:0]  A,
    input  [22:0] DI,
    input         WEB1,
    input         WEB2,
    output [22:0] DO1,
    output [22:0] DO2
);

    logic        CEB1, CEB2;
    logic [31:0] Q1, Q2, D;

    assign CEB1 = ~(CS & (OE | WEB1));
    assign CEB2 = ~(CS & (OE | WEB2));
    assign D    = {9'd0, DI};
    assign DO1  = Q1[22:0];
    assign DO2  = Q2[22:0];

    TS1N16ADFPCLLLVTA128X64M4SWSHOD_tag_array i_tag_array1 (
        .CLK        ( CK    ),
        .A          ( A     ),
        .CEB        ( CEB1  ),  // chip enable, active LOW
        .WEB        ( ~WEB1 ),  // write:LOW, read:HIGH
        .BWEB       ( 32'd0 ),  // bitwise write enable write:LOW
        .D          ( D     ),  // Data into RAM
        .Q          ( Q1    ),  // Data out of RAM
        .RTSEL      (       ),
        .WTSEL      (       ),
        .SLP        (       ),
        .DSLP       (       ),
        .SD         (       ),
        .PUDELAY    (       )
    );

    TS1N16ADFPCLLLVTA128X64M4SWSHOD_tag_array i_tag_array2 (
        .CLK        ( CK    ),
        .A          ( A     ),
        .CEB        ( CEB2  ),  // chip enable, active LOW
        .WEB        ( ~WEB2 ),  // write:LOW, read:HIGH
        .BWEB       ( 32'd0 ),  // bitwise write enable write:LOW
        .D          ( D     ),  // Data into RAM
        .Q          ( Q2    ),  // Data out of RAM
        .RTSEL      (       ),
        .WTSEL      (       ),
        .SLP        (       ),
        .DSLP       (       ),
        .SD         (       ),
        .PUDELAY    (       )
    );

endmodule