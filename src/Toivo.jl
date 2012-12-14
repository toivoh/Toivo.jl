
module Toivo
using Base 
export quot, is_expr, @sexpr, show_sexpr
export @expect, split_fdef, @in
export get!, @get, @get!


# ---- Metaprogramming --------------------------------------------------------

quot(ex) = expr(:quote, ex)

is_expr(ex::Expr, head)          = ex.head === head
is_expr(ex::Expr, heads::Set)    = has(heads, ex.head)
is_expr(ex::Expr, heads::Vector) = contains(heads, ex.head)
is_expr(ex,       head)          = false
is_expr(ex,       head, n::Int)  = is_expr(ex, head) && length(ex.args) == n


# ---- show_sexpr: print an AST as an S-expression ----

show_sexpr(ex) = show_sexpr(OUTPUT_STREAM, ex)
show_sexpr(io::IO, ex) = (print(io, "@sexpr "); show_sexpr_raw(io, ex))

show_sexpr_raw(io::IO, ex) = show_sexpr_raw(io, ex, 0)
show_sexpr_raw(io::IO, ex, indent::Int) = show(io, ex)

const sexpr_indent_width = 2

function show_sexpr_raw(io::IO, ex::QuoteNode, indent::Int)
    inner = indent + sexpr_indent_width
    print(io, "(:quote, #QuoteNode\n", " "^inner)
    show_sexpr_raw(io, ex.value, inner)
    print(io, '\n', " "^indent, ')')
end
function show_sexpr_raw(io::IO, ex::Expr, indent::Int)
    inner = indent + sexpr_indent_width
    print(io, '(')
    show_sexpr_raw(io, ex.head, inner)
    for arg in ex.args
        print(io, ex.head === :block ? ",\n"*" "^inner : ", ")
        show_sexpr_raw(io, arg, inner)
    end
    if length(ex.args) == 0; print(io, ",)")
    else print(io, (ex.head === :block ? "\n"*" "^indent : ""), ')')
    end
end

# ---- @sexpr: make an AST from an S-expression ----

macro sexpr(ex)
    esc(sexpr_to_expr(ex))
end

sexpr_to_expr(ex) = quot(ex)
sexpr_to_expr(ex::QuoteNode) = ex
function sexpr_to_expr(ex::Expr)
    head, args = ex.head, ex.args
    if head === :tuple
        h = :( $(sexpr_to_expr(args[1]))::Symbol )
        expr(:call, :expr, h, {sexpr_to_expr(arg) for arg in args[2:end]}...)
    elseif head === :quote; ex
    else expr(:quote, ex)
    end
end


# ---- More stuff -------------------------------------------------------------

macro expect(pred)
    quote
        $(esc(pred)) ? nothing : error(
          $(string("expected: ", sprint(Base.show_unquoted, pred)", == true")))
    end
end

# Return the signature and body from a named method definition, either syntax.
# E.g. split_fdef( :( f(x) = x^2) ) == (:(f(x)), :(x^2))
function split_fdef(fdef::Expr)
    @expect (fdef.head == :function) || (fdef.head == :(=))
    @expect length(fdef.args) == 2
    signature, body = fdef.args
    @expect is_expr(signature, :call)
    @expect length(signature.args) >= 1
    (signature, body)
end
split_fdef(f::Any) = error("split_fdef: expected function definition, got\n$f")

macro in(mod, ex)
    quote
        $mod.eval($(expr(:quote,ex)))
    end
end

# todo: use ht_keyindex like get
get!(d::Associative, k, default) = has(d, k) ? d[k] : (d[k] = default)
macro get!(d, k, default)
    quote
        d, k = $(esc(d)), $(esc(k))
        has(d, k) ? d[k] : (d[k] = $(esc(default)))
    end
end
macro get(d, k, default)
    quote
        d, k = $(esc(d)), $(esc(k))
        has(d, k) ? d[k] : $(esc(default))
    end
end


end # module
