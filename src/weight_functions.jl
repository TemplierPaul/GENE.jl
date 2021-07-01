using Distances
import Base.exp


export weight_func, euclidean_dist, random_weight, debug_weight

function euclidean_dist(C1::Array{Float64}, C2::Array{Float64})
    Euclidean()(C1, C2)
end

function signed_euclidean_dist(C1::Array{Float64}, C2::Array{Float64})
    Euclidean()(C1, C2) -1
end

function random_weight(C1::Array{Float64}, C2::Array{Float64})
    rand(Float64)
end

function debug_weight(C1::Array{Float64}, C2::Array{Float64})
    println("DEBUG ", C1, " > ", C2)
    rand(Float64)
end

function exp(C1::Array{Float64}, C2::Array{Float64}; beta=1)
    exp(beta*(C1[1] - C2[1])^2) - exp(beta*(C1[2] - C2[2])^2)
end

function crossed_exp(C1::Array{Float64}, C2::Array{Float64}; beta=1)
    exp(beta*(C1[1] - C2[2])^2) - exp(beta*(C1[2] - C2[1])^2)
end

function exp_decay(C1::Array{Float64}, C2::Array{Float64})
    exp(-Euclidean()(C1, C2))
end

function signed_exp_decay(C1::Array{Float64}, C2::Array{Float64})
    2 * exp(-Euclidean()(C1, C2)) -1
end

function ratio_euclidean(C1::Array{Float64}, C2::Array{Float64})
    d = Euclidean()(C1, C2)
    diff = C1 - C2
    d * max(-1, min(1, diff[1]/diff[2]))
end

function product_euclidean(C1::Array{Float64}, C2::Array{Float64})
    d = Euclidean()(C1, C2)
    factor = prod(C1 - C2)
    d * max(-1, min(1, factor))
end

function scaled_product_euclidean(C1::Array{Float64}, C2::Array{Float64})
    d = Euclidean()(C1, C2)
    factor = prod(C1 - C2)
    d * max(-1, min(1, factor)) * 10
end

function signed_log(x)
    if x>0
        return log(x+1)
    elseif x<0
        return -log(-x+1)
    else
        return 0
    end
end

function signed_euclidean(C1::Array{Float64}, C2::Array{Float64})
    d = Euclidean()(C1, C2)
    d * signed_log(C1[end]-C2[end])
end

function grn(C1::Array{Float64}, C2::Array{Float64})
    d=0
    for i = 2:length(C2)
        delta = C1[1] - C2[i]
        factor = max(-1, min(1, delta))
        d = d + delta * exp(-abs(delta))
    end
    d *50
end


weight_func = Dict(
    "euclidean"=>euclidean_dist,
    "signed"=>signed_euclidean_dist,
    "random"=>random_weight,
    "debug"=>debug_weight,
    "exp"=>exp,
    "crossed_exp"=>crossed_exp,
    "exp_decay"=>exp_decay,
    "signed_exp_decay"=>signed_exp_decay,
    "ratio"=>ratio_euclidean,
    "product"=>product_euclidean,
    "scaled_product"=>scaled_product_euclidean,
    "signed_euclidean"=>signed_euclidean,
    "grn"=>grn
)
