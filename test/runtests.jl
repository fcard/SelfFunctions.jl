module Tests
using SelfFunctions
using Base.Test

type MyFirstType
  x::Int
  y::Float64
end

@selftype selffirst MyFirstType

@selftype selfsecond type MySecondType
  a::String
  b::Symbol
end

@selffirst function f1(z)
  x+y+z
end

@selfsecond f2(c) = string(a,b,c)

@selffirst @inline f3() = x-y

@selfsecond f4(c::String) = a
@selfsecond f4(c::Symbol) = b

const t1 = MyFirstType(1,2)
const t2 = MySecondType("a",:b)

const a1 = @selffirst (z) -> (x+y)*z
const a2 = @selffirst function(z); (x+y)/z end
const a3 = @selffirst (z::Int) -> (x+y)^z

function namespace()
  @selffirst local f5() = x+1
  @selffirst global f6() = y+1
  return f5
end



@test f1(t1,3) == 6
@test f2(t2,'c') == "abc"
@test f3(t1) == -1
@test f4(t2,"c") == "a"
@test f4(t2,:c)  == :b
@test !isdefined(:f5)
@test namespace()(t1) == 2
@test f6(t1) == 3

@test a1(t1,3) == 9
@test a2(t1,3) == 1
@test a3(t1,3) == 27

for f in [f1,f2,f3,f4]
  @test isa(f, SelfFunctions.SelfFunction)
end

end
