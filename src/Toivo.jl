
module Toivo
using Base 
export @show, @expect, quot, is_expr, split_fdef, @in, @sexpr, show_sexpr

macro expect(pred)
    quote
        $pred ? nothing : error(
          $(string("expected: ", sprint(Base.show_unquoted, pred)", == true")))
    end
end

quot(ex) = expr(:quote, ex)

is_expr(ex, head::Symbol) = (isa(ex, Expr) && (ex.head == head))
is_expr(ex, head::Symbol, n::Int) = is_expr(ex, head) && length(ex.args) == n

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

macro sexpr(ex)
    esc(sexpr_to_expr(ex))
end

sexpr_to_expr(ex) = expr(:quote, ex)
sexpr_to_expr(ex::QuoteNode) = ex
function sexpr_to_expr(ex::Expr)
    head, args = ex.head, ex.args
    if head === :tuple
        h = sexpr_to_head(args[1])
        expr(:call, :expr, h, {sexpr_to_expr(arg) for arg in args[2:end]}...)
    elseif head === :quote; ex
    else expr(:quote, ex)
    end
end

sexpr_to_head(ex::Symbol) = expr(:quote, ex)
sexpr_to_head(ex::QuoteNode) = ex
function sexpr_to_head(ex)
    if is_expr(ex, :quote, 1); ex
    else error("@sexpr: Cannot interpret $ex as a head")
    end
end


# ---- show_sexpr: print an AST as an S-expression ----

show_sexpr(ex) = show_sexpr(OUTPUT_STREAM, ex)
show_sexpr(io::IO, ex) = show_sexpr(io, ex, 0)
show_sexpr(io::IO, ex, indent::Int) = show(io, ex)

const sexpr_indent_width = 2

function show_sexpr(io::IO, ex::Expr, indent::Int)
    inner = indent + sexpr_indent_width
    if (ex.head === :block) inter, post = (",\n"*" "^inner, "\n"*" "^indent)
    else inter, post = (", ", "")
    end

    print(io, '(')
    show_sexpr(io, ex.head, inner)
    for arg in ex.args
        print(io, inter)
        show_sexpr(io, arg, inner)
    end
    if length(ex.args) == 0; print(io, ",)")
    else print(io, post, ')')
    end
end

end # module
