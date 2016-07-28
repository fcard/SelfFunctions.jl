module SelfFunctions
export @selftype

immutable SelfFunction{F <: Function}
  name::Symbol
  typ::DataType
  f::F
end
Base.show(io::IO, sf::SelfFunction) = print(io, "$(sf.name) (self function of type $(sf.typ))")
@inline (sf::SelfFunction)(args...) = sf.f(args...)

const selfimpl_code = string(gensym())

@inline selfcall(f::SelfFunction, t, args...) = f.f(t, args...)
@inline selfcall(f, t, args...) = f(args...)

macro selftype(maker_macro, typname::Symbol)
  esc(generate_selfmacro(maker_macro, :(fieldnames($typname)), typname))
end

macro selftype(maker_macro, typedef::Expr)
  const fields = map(fieldname, filter(isfield, typedef.args[3].args))
  const tname  = typename(typedef)
  esc(quote
    $typedef
    $(generate_selfmacro(maker_macro, fields, tname))
  end)
end

function generate_selfmacro(name, fields, tname)
  @gensym self fname fimpl iname typ
  quote
    macro $(name)(funcdef)
      const $typ   = Symbol($(string(tname)))
      const $self  = gensym("self")
      const $fname = $funcname(funcdef)
      const $iname = Symbol("$($fname)_selfimpl_$($selfimpl_code)")
      const $fimpl = $funcimpl(funcdef, $fields, $iname, $self, $typ)
      $(esc)(quote
        if $length($methods($($fimpl))) == 1
          const $($fname) = $($SelfFunction)(Symbol($(string($fname))), $($tname), $($iname))
        end
      end)
    end
  end
end

fieldname(arg::Expr)   = arg.args[1]
fieldname(arg::Symbol) = arg

isfield(arg::Expr)   = arg.head == :(::)
isfield(arg::Symbol) = true
isfield(x) = false

typename(def::Expr) = def.args[2]
funcname(def::Expr) = def.head == :macrocall? funcname(def.args[2]) : def.args[1].args[1]

function funcimpl(def, fields, nname, self, typ)
  const (addmeta, fdef) = function_meta(def)
  const (sig, body) = fdef.args
  const (name,args) = [sig.args[1], sig.args[2:end]]
  const nbody = format_calls(body, fields, self)
  const nargs = [:($self::$typ);args]
  const nsig  = :($nname($(nargs...)))
  addmeta(Expr(:function, nsig, nbody))
end

function function_meta(def::Expr)
  const meta = []
  while def.head == :macrocall
    unshift!(meta, def.args[1])
    def = def.args[2]
  end
  function addmeta(ndef)
    for m in meta
      ndef = Expr(:macrocall, m, ndef)
    end
    return ndef
  end
  return (addmeta, def)
end

function format_calls(body, fields, self)
  nbody = Expr(body.head)
  nbody.args = map(redef_call(self, fields), body.args)
  nbody
end

function redef_call(self, fields)
  function rcall(x::Expr)
     if x.head == :call
       :($selfcall($(rcall(x.args[1])), $self, $(map(rcall, x.args[2:end])...)))
     elseif x.head == :.
       x
     elseif x.head == :quote
       rcall_quoted(x)
     elseif x.head in [:(=), :function] && length(x.args) > 1
       Expr(x.head, x.args[1], rcall(x.args[2]))
     else
       Expr(x.head, map(rcall, x.args)...)
     end
  end
  rcall(x::Symbol) = x in fields? :($(self).$(x)) : x
  rcall(x::QuoteNode) = rcall_quoted(x)
  rcall(x) = x

  function rcall_quoted(x::Expr, depth)
    walkin(d) = Expr(x.head, map(y->rcall_quoted(y,d), x.args)...)

    if x.head == :quote
      walkin(depth+1)
    elseif x.head == :$
      if depth == 1
        Expr(:$, rcall(x.args[1]))
      else
        walkin(depth-1)
      end
    else
      walkin(depth)
    end
  end
  rcall_quoted(x::QuoteNode,depth) = QuoteNode(rcall_quoted(x.value, depth+1))
  rcall_quoted(x,depth) = x
  rcall_quoted(x) = rcall_quoted(x,0)

  return rcall
end

end