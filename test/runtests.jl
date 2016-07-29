module Tests
using SelfFunctions
using Base.Test

type FirstType
  x::Int
  y::Float64
end

@selftype selffirst FirstType

@selftype selfsecond type SecondType
  a::String
  b::Symbol
end

abstract AbstractThirdType
@selftype selfthird type ThirdType{T} <: AbstractThirdType
  v::Vector{T}
end

"""
  I associate functions with FourthType.
"""
@selftype selffourth type FourthType
  d::Dict{Symbol,Int}
end

@selffirst function f1(z)
  x+y+z
end

@selfsecond f2(c) = string(a,b,c)

@selffirst @inline f3() = x-y

@selfsecond f4(c::String) = a
@selfsecond f4(c::Symbol) = b

const t1 = FirstType(1,2)
const t2 = SecondType("a",:b)
const t3 = ThirdType([Int,Float64,String,Symbol])

const a1 = @selffirst (z) -> (x+y)*z
const a2 = @selffirst function(z); (x+y)/z end
const a3 = @selffirst (z::Int) -> (x+y)^z

function namespace()
  @selffirst local f5() = x+1
  @selffirst global f6() = y+1
  return f5
end

macro m1(x)
  x == :x ? :y : :x
end
@selffirst f7() = @m1(x) + y

@selfthird f8(i) = v[i]

"""
  I associate keys to values in a FourthType's dictionary.
"""
@selffourth function f9(k,v)
  d[k] = v
end

@test f1(t1,3) == 6
@test f2(t2,'c') == "abc"
@test f3(t1) == -1
@test f4(t2,"c") == "a"
@test f4(t2,:c)  == :b
@test !isdefined(:f5)
@test namespace()(t1) == 2
@test f6(t1) == 3
@test f7(t1) == 4
@test f8(t3,2) == Float64

@test a1(t1,3) == 9
@test a2(t1,3) == 1
@test a3(t1,3) == 27

@test isa(t3, AbstractThirdType)
@test typeof(t3) != ThirdType && typeof(t3) <: ThirdType

macro doc_exists(x)
  :(!($startswith($string(@doc($x)), "No documentation found.")))
end

@test !@doc_exists(i_dont_exist)
@test @doc_exists(@doc)
@test @doc_exists(@selftype)
@test @doc_exists(@selffourth)
@test @doc_exists(f9)

for f in [f1,f2,f3,f4]
  @test isa(f, SelfFunctions.SelfFunction)
end

end
