GLFW.WindowHint(GLFW.FLOATING, 1)
function reversekv(dict::AbstractDict{K,V}; print = false) where {K,V}
	vkdict = [x[2].=>x[1] for x in dict]
	if print == true
		println.(vkdict)
	end
	return OrderedDict{V,K}(vkdict)
end
df(x) = DataFrame(x)
df(xs...) = DataFrame(xs...)
function transposed(arr::AbstractArray)
	try
        @cast arr[j,i] := arr[i,j]
        arr2 = arr |> df |> Array
    catch
        arr2 = permutedims(arr[:,1])
        for i = 2:size(arr,2)
            arr2 = vcat(arr2, permutedims(arr[:,i]))
        end
    end
    return arr2
end
import Base.convert
function convert(::Type{T}, arr::Array{T,1}) where {T<:Number}
    if size(arr,1) > 1
        return T.(arr)
    end
    return T(arr[1])
end
function convert(::Type{Array{T}}, t::T) where {T<:Number}
    return [t]
end
function convert(::Type{T}, arr::Array{T,1}) where {T<:AbstractString}
    if size(arr,1) > 1
        return T.(arr)
    end
    return T(arr[1])
end
convert(::Type{String}, i::Int) = "$i"
function convert(::Type{String}, f::T) where T<:Union{Float16,Float32,Float64}
	"$f"
end
function varcall(name::String,body::Any)
    name=Symbol(name)
    @eval (($name) = ($body))
end
function tryint(number)
    return (try
        Int64(number)
    catch
        number
    end)
end
function tryfloat(number)
    return (try
        Float64(number)
    catch
        number
    end)
end
function tryfloat32(number)
    return (try
        Float32(number)
    catch
        number
    end)
end
function steprange(arr::AbstractArray{T,1}; step = 1) where {T<:Integer}
    notseq = 0
    min_value = arr[1]
    max_value = arr[end]
    @assert max_value > min_value
    for i in 1:size(arr,1)
        if i == 1
            step = arr[i+1] - arr[i]
            continue
        end
        if arr[i]-arr[i-1] != step
            notseq = 1
        end
        if i == size(arr,1)
            break
        end
    end
    if notseq == 0
        return StepRange(min_value,step,max_value)
    end
    throw(ErrorException("cannot make this into a step range"))
end
function unitrange(arr::AbstractArray{T,1}) where {T<:Integer}
    notseq = 0
    min_value = arr[1]
    max_value = arr[end]
    @assert max_value > min_value
    for i in 1:size(arr,1)
        if i == 1
            step = arr[i+1] - arr[i]
            continue
        end
        if arr[i]-arr[i-1] != 1
            notseq = 1
        end
        if i == size(arr,1)
            break
        end
    end
    if notseq == 0
        return UnitRange(min_value,max_value)
    end
    throw(ErrorException("cannot make this into a unit range"))
end
function splatrange(range)
    return [(range)...]
end
function splatranges(ranges...)
    splattedrange = []

    for range in ranges
        splattedrange = vcat(splattedrange, splatrange(range))
    end

    return eval([Int64.(splattedrange)...])
end
∑(x) = sum(x)
(D::Dict)(i::Int) = Dict([keys(D)...][i] => [values(D)...][i])
(D::OrderedDict)(i::Int) = OrderedDict([keys(D)...][i] => [values(D)...][i])
(D::Dict)(is::AbstractVector{Int}) = Dict([([keys(D)...][i],[values(D)...][i]) for i in is])
(D::OrderedDict)(is::AbstractVector{Int}) = OrderedDict([([keys(D)...][i],[values(D)...][i]) for i in is])
(D::Dict)(is::Int...) = D([is...])
(D::OrderedDict)(is::Int...) = D([is...])
(D::Dict)(is::AbstractRange{Int}) = D([is...])
(D::OrderedDict)(is::AbstractRange{Int}) = D([is...])
(D::Dict)(is::AbstractRange{Int}...) = D([(is...)...])
(D::OrderedDict)(is::AbstractRange{Int}...) = D([(is...)...])
function (D::AbstractDict)(is...)
    indices = []
    for i in is
        if typeof(i) <: Union{AbstractRange{Int},AbstractArray{Int}}
            for j in i
                push!(indices, j)
            end
        elseif typeof(i) <: Int
            push!(indices, i)
        else
            error("could not index this, arguments must be Ints, ranges of Ints, arrays of Ints, or a combo of those")
        end
    end
    return D(indices...)
end
function gluearray(arr::AbstractArray{T,N}) where {T,N}
	temparr = copy(arr)
	if T <: Vector{M} where M
		return @cast temparr[i,j] := temparr[i][j]
	elseif T <: Vector{Vector{Vector{M}}} where M
		@cast temparr[i,j] := temparr[i][j]
		temparr = temparr |> combinedims
		return Array{Array{M},4}(temparr)
	end
	temparr = gluearray(temparr)
	if N == 3
		try
			temparr = temparr[:,:,:]
		catch
			@show temparr
		end
	elseif N == 4
		try
			temparr = temparr[:,:,:,:]
		catch
			try
				temparr = temparr[:,:,:]
			catch
				@show temparr
			end
		end
	end
	return temparr
end
function gluearray2(arr::AbstractArray)
	temparr = copy(arr)
	try
        @cast temparr[i,j] := temparr[i][j]
        @cast temparr[i,j,k,g] := temparr[i,j][k,g]
    catch
        try
            @cast temparr[i,j,k] := temparr[i][j,k]
        catch

        end
    end
    try
        @cast temparr[i,j] := temparr[i][j]
        @cast temparr[i,j,k,g] := temparr[i,j][k,g]
    catch
        try
            @cast temparr[i,j,k] := temparr[i][j,k]
        catch

        end
    end
    return temparr
end
_g(arr::AbstractArray) = try
	    gluearray(arr)
	catch
	    try
	        gluearray2(arr)
	    catch
			arr
	    end
end
_v(arr::AbstractArray) = reverse(arr; dims = 1)
_h(arr::AbstractArray) = reverse(arr; dims = 2)
_t(arr::AbstractArray) = transposed(arr)
