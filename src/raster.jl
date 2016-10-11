"""
    rasterize_points(cloud::PointCloud, dx::AbstractFloat)
    rasterize_points(cloud::Matrix{<:AbstractFloat}, dx::AbstractFloat)

Rasterize points in 2D by a cell size `dx`.
Returns a dictionary containing the indices points that are in a cell.

"""
immutable Raster <: Associative
    pixels::Dict{Tuple{Int,Int}, Vector{Int}}
end

# TODO points should be able to be any matrix
function rasterize_points{T <: AbstractVector}(points::Vector{T}, dx::AbstractFloat)
    min_xy = SVector{3, Float64}(minimum(map(x->x[1], points)), minimum(map(x->x[2], points)), 0) # TODO do this better!
    pixels = Dict{Tuple{Int, Int}, Vector{Int}}()
    inv_dx = 1.0/dx
    for i = 1:length(points)
        @inbounds p = points[i] - min_xy
        key = (floor(Int, p[1]*inv_dx), floor(Int, p[2]*inv_dx))
        if haskey(pixels, key)
            push!(pixels[key], i)
        else
            pixels[key] = Vector{Int}()
            push!(pixels[key], i)
        end
    end
    return Raster(pixels)
end

function rasterize_points(cloud::PointCloud, dx::AbstractFloat)
    rasterize_points(positions(cloud), dx)
end

function rasterize_points{T <: Number}(points::Matrix{T}, dx::AbstractFloat)
    ndim = size(points, 1)
    npoints = size(points, 2)
    if isbits(T)
        new_data = reinterpret(SVector{ndim, T}, points, (length(points) ÷ ndim, ))
    else
        new_data = SVector{ndim, T}[SVector{ndim, T}(points[:, i]) for i in 1:npoints]
    end
    rasterize_points(new_data, dx)
end

Base.keys(r::Raster) = keys(r.pixels)
Base.values(r::Raster) = values(r.pixels)
Base.getindex(r::Raster, ind) = r.pixels[ind]
