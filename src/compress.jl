using LibZstd

function parallel_compress_zstd(input_parts, output_parts)
    sz = zeros(Int, length(input_parts))
    cctx = [LibZstd.ZSTD_createCCtx() for i in 1:Threads.nthreads()]
    LibZstd.ZSTD_CCtx_setParameter.(cctx, LibZstd.ZSTD_c_compressionLevel, 1)
    @time Threads.@threads for i=1:length(input_parts)
        sz[i] = LibZstd.ZSTD_compress2(
            cctx[Threads.threadid()],
            output_parts[i], sizeof(output_parts[i]),
            input_parts[i], sizeof(input_parts[i])
        )
    end
    LibZstd.ZSTD_freeCCtx.(cctx)
    return sz
end

mutable struct Chunk{N}
    offset::Dims{N}
    buffer::Vector{UInt8}
    data_length::Int
end

struct ParallelChunkCompressor{Context}
    compressed_chunks::Channel{Chunk}
    uncompressed_chunks::Channel{Chunk}
    free_chunks::Channel{Chunk}
    contexts::Vector{Context}
end

function chunk_writer(comp::ParallelChunkCompressor)
    while true
        chunk = take!(comp.compressed_chunks)
        write_chunk(chunk)
        chunk.data_length = 0
        put!(comp.free_chunks, chunk)
    end
end

function chunk_compressor(comp::ParallelChunkCompressor)
    while true
        uncompressed_chunk = take!(comp.uncompressed_chunks)
        compressed_chunk = take!(comp.free_chunks)
        context = comp.contexts[Threads.threadid()]
        compressed_chunk.data_length = LibZstd.ZSTD_compress2(
            context,
            compressed_chunk.buffer,
            sizeof(compressed_chunk.buffer),
            uncompressed_chunk.buffer,
            uncompressed_chunk.data_length
        )
        put!(comp.compressed_chunks, compressed_chunk)
        put!(comp.free_chunks, uncompressed_chunk)
    end
end

function chunk_reader(comp::ParallelChunkCompressor)
    while true
        uncompressed_chunk = take!(comp.free_chunks)
        uncompressed_chunk.data_length = read_chunk!(uncompressed_chunk.buffer)
        put!(comp.uncompressed_chunks, uncompressed_chunk)
    end
end
    