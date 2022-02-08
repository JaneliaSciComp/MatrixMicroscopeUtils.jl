function pad_and_chunk(A::Array, chunk_size::Dims)
    dims = calculate_padded_and_chunked_dims(A, chunk_size)
    padded = PaddedView(0, A, dims.padded)
    chunked = reshape(padded, dims.chunked)
    permuted = PermutedDimsArray(chunked, dims.permutation)
    return permuted
end

function pad_and_chunk_eager!(
    permuted_buffer::Array{T},
    padded_buffer::Array{T},
    A::Array{T},
    chunk_size::Dims,
    dims = calculate_padded_and_chunked_dims(A, chunk_size)
) where T
    if size(A) == dims.padded
        # No padding necessary, do not copy
        padded_buffer = A
    else
        padded_buffer = reshape(padded_buffer, dims.padded)
        copy!(padded_buffer, PaddedView(0, A, dims.padded))
    end

    padded_buffer = reshape(padded_buffer, dims.chunked)
    permutedims!(permuted_buffer, padded_buffer, dims.permutation)
    return permuted_buffer
end
function pad_and_chunk_eager!(
    permuted_buffer::Array{T},
    A::Array{T},
    chunk_size::Dims,
    dims = calculate_padded_and_chunked_dims(A, chunk_size)
) where T
    @assert size(A) == dims.padded
    pad_and_chunk_eager!(permuted_buffer, A, A, chunk_size, dims)
end
function pad_and_chunk_eager(
    A::Array{T},
    chunk_size::Dims,
    dims = calculate_padded_and_chunked_dims(A, chunk_size)
) where T
    permuted_buffer = similar(A, dims.permuted)
    if size(A) == dims.padded
        pad_and_chunk_eager!(permuted_buffer, A, A, chunk_size, dims)
    else
        padded_buffer = similar(A, dims.padded)
        pad_and_chunk_eager!(permuted_buffer, padded_buffer, A, chunk_size, dims)
    end
    return permuted_buffer
end

function calculate_padded_and_chunked_dims(A::Array, chunk_size::Dims)
    array_size = size(A)
    num_chunks = div.(array_size, chunk_size, RoundUp)
    padded_size = num_chunks .* chunk_size

    chunked_dims = (Iterators.flatten(zip(chunk_size, num_chunks))..., )

    C = length(chunked_dims)
    permutation = vcat(1:2:C, 2:2:C)

    permuted_dims = chunked_dims[permutation]
    (padded      = padded_size,
     chunked     = chunked_dims,
     permutation = permutation,
     permuted    = permuted_dims)
end