//

#include <Rcpp.h>
#include <fstream>
#include <stdexcept>

using namespace Rcpp;

// [[Rcpp::export]]
NumericMatrix fcs_rcpp_read_data(
        const std::string& file_path,
        long byte_offset,
        long n_row,
        long n_par,
        bool swap
) {
    // open file in binary mode
    std::ifstream con(file_path, std::ios::binary);
    if (!con.is_open())
        stop("Cannot open file: " + file_path);
    
    // seek to byte offset
    con.seekg(byte_offset, std::ios::beg);
    if (con.fail())
        stop("Failed to seek to offset " + std::to_string(byte_offset));
    
    // read n_vals float32 values into a flat buffer
    int n_vals = n_row * n_par;
    std::vector<float> buf(n_vals);
    con.read(reinterpret_cast<char*>(buf.data()), n_vals * sizeof(float));
    if (con.fail())
        stop("Failed to read " + std::to_string(n_vals) + " values from file");
    
    // swap bytes if file endian differs from host
    if (swap) {
        for (int k = 0; k < n_vals; k++) {
            char* p = reinterpret_cast<char*>(&buf[k]);
            std::swap(p[0], p[3]);
            std::swap(p[1], p[2]);
        }
    }
    
    // fill matrix row-by-row (byrow = TRUE means values are row-major)
    NumericMatrix data_mat(n_row, n_par);
    for (int row = 0; row < n_row; row++) {
        for (int col = 0; col < n_par; col++) {
            data_mat(row, col) = static_cast<double>(buf[row * n_par + col]);
        }
    }
    
    return data_mat;
}
