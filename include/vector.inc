extern init_vector
extern push_vector

struc VectorInt
    .data_ptr: resq 1
    .size: resq 1
    .capacity: resq 1
endstruc