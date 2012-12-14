module Test
using Meta

@assert !isexpr(5,  :(=))
@assert !isexpr(:x, :(=))
@assert !isexpr(:(x[3]), :(=))

@assert isexpr(:(x[3]),  :ref)
@assert isexpr(:(x[3]),  :ref, 2)
@assert !isexpr(:(x[3]), :ref, 3)

@assert isexpr(:(x[3]),  {:(=), :ref})
@assert !isexpr(:(f(3)), {:(=), :ref})
@assert isexpr(:(x[3]),  Set(:(=), :ref))
@assert !isexpr(:(f(3)), Set(:(=), :ref))

# show_sexpr and @sexpr: roundtrip
function roundtrip_test(ex)
    sexpr_code = sprint(show_sexpr, ex)
    ast = parse(sexpr_code)[1]
    @assert isexpr(ast, :macrocall, 2)
    @assert ast.args[1] == symbol("@sexpr")
    ex2 = eval(ast)
    
    @assert ex == ex2
end

ex = quote
    function show_sexpr_raw(io::IO, ex::Expr, indent::Int)
        inner = indent + sexpr_indent_width
        if (ex.head === :block); inter,post = (",\n"*" "^inner,"\n"*" "^indent)
        else                     inter, post = (", ", "")
        end
        
        print(io, '(')
        show_sexpr_raw(io, ex.head, inner)
        for arg in ex.args
            print(io, inter)
            show_sexpr_raw(io, arg, inner)
        end
        if length(ex.args) == 0; print(io, ",)")
        else print(io, post, ')')
        end
    end    
end
line = ex.args[2].args[2].args[1]
@assert isexpr(line, :line, 2)
line.args[2] = :test
show_sexpr(ex); println('\n')
roundtrip_test(ex)

ex2 = macroexpand(quote
    args[3] = :x
end)
show_sexpr(ex2)

end