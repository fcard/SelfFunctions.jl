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

@test f1(t1,3) == 6
@test f2(t2,'c') == "abc"
@test f3(t1) == -1
@test f4(t2,"c") == "a"
@test f4(t2,:c)  == :b

for f in [f1,f2,f3,f4]
  @test isa(f, SelfFunctions.SelfFunction)
end

end
