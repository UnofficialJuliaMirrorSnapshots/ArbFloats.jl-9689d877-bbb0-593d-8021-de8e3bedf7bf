#=

prec=precision(midpt); # bits of significand (signficant radix-2 digits
prec, typeof(midpt)
# (57,ArbFloats.ArbFloat{57})

1 + round(Int,log2(ufp2(midpt))) -  round(Int,log2(ulp2(midpt)))
# 57

prec == (1 + round(Int,log2(ufp2(midpt))) -  round(Int,log2(ulp2(midpt))))
# true

=#



"""
   x.midpoint -> (significand, exponentOf2)
                  [0.5,1.0)     2^expo
   x.radius   -> (radial significand, radial exponentOf2)
"""
function frexp(x::ArfFloat{P}) where {P}
    exponentOf2 = x.exponentOf2
    significandOf = deepcopy(x)
    significandOf.exponentOf2 = 0
    return significandOf, exponentOf2
end

function ldexp(s::ArfFloat{P}, e::Int) where {P}
    z = deepcopy(s)
    z.exponentOf2 = e
    return z
end

function frexp(x::ArbFloat{P}) where {P}
    significandOf, exponentOf2 = frexp(ArfFloat{P}(x))
    return ArbFloat{P}(significandOf), exponentOf2
end

function ldexp(s::ArbFloat{P}, e::Int) where {P}
    z = deepcopy(s)
    z.exponentOf2 = e
    return z
end
ldexp(x::Tuple{ArbFloats.ArbFloat{P}, Int}) where {P} = ldexp(x[1],x[2])


#=


      gte_bits2digs(b_bits)    ~>  d_digits
      d_digits | d digits suffice to encode and recover b bits without error

      gte_digs2bits(d_digits)  ~>  b_bits
      b_bits |  b bits suffice to encode and recover d digits without error

      lte_bits2digs(b_bits)    ~>  c_digits
      c_digits | b bits are necessary encode and recover c digits without error

      lte_digs2bits(d_digits)  ~>  a_bits
      a_bits |  d digits are necessary encode and recover a bits without error

      lte_digs2bits( gte_bits2digs(b_bits  ) ) == b_bits
      lte_bits2digs( gte_digs2bits(d_digits) ) == d_digits

const log2_log10 = log(10,2)  # 0.3010299956639812 ~= log(2)/log(10)
const log10_log2 = log(2,10)  # 3.321928094887362  ~= log(10)/log(2)

lte_bits2digs(nbits::Int) = floor(Int, nbits * log2_log10)
lte_digs2bits(ndigs::Int) = floor(Int, ndigs * log10_log2)
=#

lte_bits2digs(nbits::Int) = floor( Int, nbits * 0.30102999566398125 ) # log(10,2) RoundUp
gte_bits2digs(nbits::Int)  = ceil( Int, nbits * 0.3010299956639812  ) # log(10,2) RoundDown
lte_digs2bits(ndigs::Int) = floor( Int, ndigs * 3.3219280948873626  ) # log(2,10) RoundUp
gte_digs2bits(ndigs::Int)  = ceil( Int, ndigs * 3.3219280948873617  ) # log(2,10) RoundDown




"""
logarithm_base(x)
"""
function log_base(x::Real, base::Int)
   z = if base == 2
           log2(x)
        elseif base == 10
           log10(x)
        else
           log(x) / log(base)
        end
   return z
end
log_base(x::ArbFloat{P}, base::Int) where {P} = ArbFloats.logbase(x,base)

#=
    position_first_place: the radix position of the most significant nonzero bit|digit

    pfp{T<:AbstractFloat}(x::T, base::Int=2)
    pfp{T<:AbstractFloat}(x::T)              == pfp(x,  2)  ==  pfp2{T<:AbstractFloat}(x::T)
    pfp{T<:AbstractFloat}(x::T, base=10)     == pfp(x, 10)  ==  pfp10{T<:AbstractFloat}(x::T)

    position_last_place: the radix position of the least significant nonzero bit|digit

    plp{T<:AbstractFloat}(x::T, base::Int=2)
    plp{T<:AbstractFloat}(x::T)              == p;p(x,  2)  ==  plp2{T<:AbstractFloat}(x::T)
    plp{T<:AbstractFloat}(x::T, base=10)     == plp(x, 10)  ==  p;p10{T<:AbstractFloat}(x::T)

    unit_first_place: the radix *value) of the most significant nonzero bit|digit

    pfp{T<:AbstractFloat}(x::T, base::Int=2)
    pfp{T<:AbstractFloat}(x::T)              == pfp(x,  2)  ==  pfp2{T<:AbstractFloat}(x::T)
    pfp{T<:AbstractFloat}(x::T, base=10)     == pfp(x, 10)  ==  pfp10{T<:AbstractFloat}(x::T)

    unit_last_place: the radix *value* of the least significant nonzero bit|digit

    plp{T<:AbstractFloat}(x::T, base::Int=2)
    plp{T<:AbstractFloat}(x::T)              == plp(x,  2)  ==  plp2{T<:AbstractFloat}(x::T)
    plp{T<:AbstractFloat}(x::T, base=10)     == plp(x, 10)  ==  plp10{T<:AbstractFloat}(x::T)

=#

"""
position_first_place
determine the position of the most significant nonzero bit|digit
"""
function pfp(x::T, base::Int=2) where {T <: Real}
   z = 0 # if x==0.0
   if notzero(x)
       z = floor( Int, log_base(abs(x), base) )
   end
   return z
end
pfp(x::ArbFloat{P}, base::Int=2) where {P} =
    return iszero(x) ? 0 : floor( Int, log_base(abs(smartvalue(x)), base) )
"""
binary position_first_place
determine the position of the most significant nonzero bit
"""
pfp2(x::T) where {T <: Real} = (x==zero(T) ? 0 : floor( Int, log2(abs(x)) ))
pfp2(x::ArbFloat{P}) where {P} = (iszero(x) ? 0 : floor( Int, log2(abs(smartvalue(x))) ))
"""
decimal position_first_place
determine the position of the most significant nonzero digit
"""
pfp10(x::T) where {T <: Real} = (x==zero(T) ? 0 : floor( Int, log10(abs(x)) ))
pfp10(x::ArbFloat{P}) where {P} = (iszero(x) ? 0 : floor( Int, log10(abs(smartvalue(x))) ))

"""
ufp is unit_first_place
the float value given by a 1 at the position of
  the most significant nonzero bit|digit in _x_
"""
function ufp(x::AbstractFloat, base::Int=2)
   z = pfp(x, base)
   b = convert(Float64, base)
   return b^z
end
function ufp(x::ArbFloat{P}, base::Int=2) where {P}
   z = pfp(x, base)
   return Float64(base)^z
end
ufp(x::Integer, base::Int=2) = ufp(Float64(x), base)
"ufp2 is unit_first_place in base 2"
ufp2(x::T) where {T <: Real} = 2.0^pfp2(x)
ufp2(x::ArbFloat{P}) where {P} = 2.0^pfp2(x)
ufp2(x::Integer) = ufp2(Float64(x))
"ufp10 is unit_first_place in base 10"
ufp10(x::T) where {T <: Real} = 10.0^pfp10(x)
ufp10(x::ArbFloat{P}) where {P} = 10.0^pfp10(x)
ufp10(x::Integer) = ufp10(Float64(x))
"""
ulp   is unit_last_place
the float value given by a 1 at the position of
  the least significant nonzero bit|digit in _x_
"""
function ulp(x::Real, precision::Int, base::Int)
   unitfp  = base==2 ? ufp2(x) : (base==10 ? ufp10(x) : throw(DomainError()))
   twice_u = 2.0^(1-precision)
   return twice_u * unitfp
end
ulp(x::T, base::Int=2) where {T <: AbstractFloat}  =
    ulp(x, 1+Base.significand_bits(T), base)
ulp(x::ArbFloat{P}, base::Int=2) where {P}  =
    ulp(x, P, base)
ulp(x::Integer, base::Int=2) = ulp(Float64(x), base)

"""ulp2  is unit_last_place base 2"""
function ulp2(x::Real, precision::Int)
   unitfp  = ufp2(x)
   twice_u = 2.0^(1-precision)
   return (*)(promote(twice_u, unitfp)...)
end
function ulp2(x::ArbFloat{P}) where {P}
   unitfp  = ufp2(x)
   twice_u = 2.0^(1-P)
   return (*)(promote(twice_u, unitfp)...)
end
ulp2(x::T) where {T <: AbstractFloat}  = ulp2(x, 1+Base.significand_bits(T))
ulp2(x::Integer) = ulp2(Float64(x))

"""ulp10 is unit_last_place base 10"""
function ulp10(x::Real, bitprecision::Int)
    unit10fp = ufp10(x)
    digitprecision = lte_bits2digs(bitprecision)
    twice_u10 = 10.0^(1-digitprecision)
    return twice_u10 * unit10fp
end
function ulp10(x::ArbFloat{P}) where {P}
    unit10fp = ufp10(x)
    digitprecision = lte_bits2digs(P)
    twice_u10 = 10.0^(1-digitprecision)
    return twice_u10 * unit10fp
end
ulp10(x::T) where {T <: AbstractFloat} = ulp10( x, (1+Base.significand_bits(T)) )
ulp10(x::Integer) = ulp10(Float64(x))


function eps(::Type{T}) where {T <: ArbFloat}
    P = precision(T)
    return ldexp(one(T), 1-P)
end
function eps(x::ArbFloat{P}) where {P}
    a = eps(ArbFloat{P})
    return midpoint(abs(x)*a)
end   

# !!revisit!!
function nextfloat(x::ArbFloat{P}) where {P}
    m,r = midpoint_radius(x)
    e = eps(m)
    n = m
    i = 1
    while n == m
      n = midpoint(n + i*e)
      i += 1
    end
    return midpoint_radius(n, r)
end

# !!revisit!!
function prevfloat(x::ArbFloat{P}) where {P}
    m,r = midpoint_radius(x)
    e = eps(m)
    n = m
    i = 1
    while n == m
      n = midpoint(n - i*e)
      i += 1
    end
    return midpoint_radius(n, r)
end
