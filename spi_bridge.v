module spi_bridge (
    // peripheral clock signals
    input clk,
    input rst_n,
    // SPI master facing signals
    input sclk,
    input cs_n,
    input mosi,
    output miso,
    // internal facing 
    output byte_sync,
    output[7:0] data_in,
    input[7:0] data_out
);

// registre interne
reg [7:0] shift_in; // registru input pentru MOSI
reg [7:0] shift_out; // registru output pentru MISO
reg [2:0] bit_counter; // counter 0 - 7

// redeclararea porturilor output ca reg pentru a le putea folosi in blocuri always
reg miso_r;
reg byte_sync_r;
reg [7:0] data_in_r; 

// legam output-urile modulului de registrele interne
assign miso = cs_n ? 1'bZ : miso_r; // tri-state: linie deconectata, nu avem nimic pe fir
assign byte_sync = byte_sync_r;
assign data_in = data_in_r;


// ---------------------- Receptie (MOSI) ------------------------------

// pe frontul crescator al semnalului de ceas sau frontul descrescator al semnalului rst_n
// datele sunt citite pe frontul crescator de ceas (CPHA = 0)
always @(posedge sclk or negedge rst_n) begin
    // Cand semnalul reset e activat, slave-ul se afla intr-o stare sigura (zero)
    if (!rst_n) begin
        shift_in            <= 8'd0;
        bit_counter     <= 3'd0;
        data_in_r          <= 8'd0;
        byte_sync_r       <= 1'b0;
    end else begin
        byte_sync_r <= 1'b0; // puls de un singur ciclu de ceas
    
        // cat timp slave-ul este selectat, retinem serial valoarea transmisa prin firul MOSI
        if (!cs_n) begin
            shift_in <= {shift_in[6:0], mosi};  // shift la stanga, MSB e primul bit receptionat de la master
            bit_counter <= bit_counter + 1'b1;
            
            // daca am primit 8 biti
            if (bit_counter == 3'd7) begin
                data_in_r <= {shift_in[6:0], mosi}; // salvam byte-ul primit
                byte_sync_r <= 1'b1; // semnal pentru logica interna, notifica ca a fost receptionat un byte complet
                bit_counter <= 3'd0; // resetam counter-ul
            end
        end else begin
            // slave-ul nu e selectat
            bit_counter <= 3'd0;
        end
    end
end

// ---------------------- Transmitere (MISO) ------------------------------

// datele sunt scrise pe frontul descrescator de ceas (CPHA = 0)
always @(negedge sclk or negedge rst_n) begin
    if (!rst_n) begin
        shift_out <= 8'd0;
        miso_r       <= 1'b0; // va transmite catre master cate un bit din shift out
    end else begin
    
        if (cs_n) begin // cand CS NU e selectat: Preload
            // Pregatim primul byte cat timp asteptam selectarea slave-ului
           shift_out <= data_out; // incarcare paralela
            miso_r <= 1'b0;
         end else begin  // CS e selectat
            if (byte_sync_r) begin
                shift_out <= data_out;     // incarcam urmatorul byte daca s a incheiat cel anterior
                miso_r    <= data_out[7];  // transmitem MSB imediat
            end else begin
                miso_r <= shift_out[7]; // transmite MSB
                shift_out <= {shift_out[6:0], 1'b0}; // shift la stanga pentru urmatorul bit
            end
           end
    end
end

endmodule
