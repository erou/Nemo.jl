################################################################################
#
#  fmpz_mod_poly.jl : Flint fmpz_mod_poly (polynomials over Z/nZ, large modulus)
#
################################################################################

export FmpzModPolyRing, fmpz_mod_poly

################################################################################
#
#  Type and parent object methods
#
################################################################################

parent(a::fmpz_mod_poly) = a.parent

base_ring(R::FmpzModPolyRing) = R.base_ring

base_ring(a::fmpz_mod_poly) = base_ring(parent(a))

elem_type(::fmpz_mod_poly) = fmpz_mod_poly

elem_type(::FmpzModPolyRing) = fmpz_mod_poly

function check_parent(x::fmpz_mod_poly, y::fmpz_mod_poly)
  parent(x) != parent(y) && error("Parents must coincide")
  nothing
end

################################################################################
#
#  Basic manipulation
#
################################################################################

length(x::fmpz_mod_poly) = ccall((:fmpz_mod_poly_length, :libflint), Int,
                               (Ptr{fmpz_mod_poly}, ), &x)

degree(x::fmpz_mod_poly) = ccall((:fmpz_mod_poly_degree, :libflint), Int,
                               (Ptr{fmpz_mod_poly}, ), &x)

function coeff(x::fmpz_mod_poly, n::Int)
  (n < 0 || n > degree(x)) && throw(DomainError())
  z = fmpz()
  ccall((:fmpz_mod_poly_get_coeff_fmpz, :libflint), Void,
        (Ptr{fmpz}, Ptr{fmpz_mod_poly}, Int), &z, &x, n)
  return base_ring(x)(z)
end

zero(R::FmpzModPolyRing) = R(0)

one(R::FmpzModPolyRing) = R(1)

gen(R::FmpzModPolyRing) = R([fmpz(0), fmpz(1)])

isgen(a::fmpz_mod_poly) = (degree(a) == 1 &&
                              iszero(coeff(a,0)) && isone(coeff(a,1)))

iszero(a::fmpz_mod_poly) = Bool(ccall((:fmpz_mod_poly_is_zero, :libflint), Int32,
                              (Ptr{fmpz_mod_poly}, ), &a))

var(R::FmpzModPolyRing) = R.S

function deepcopy(a::fmpz_mod_poly)
  n = parent(a)._n
  z = fmpz_mod_poly(n, a)
  z.parent = a.parent
  return z
end

################################################################################
#
#  String I/O
#
################################################################################

function show(io::IO, x::fmpz_mod_poly)
   len = length(x)
   S = var(parent(x))

   if len == 0
      print(io, base_ring(x)(0))
   else
      for i = 1:len - 1
         c = coeff(x, len - i)
         bracket = needs_parentheses(c)
         if !iszero(c)
            if i != 1 && !is_negative(c)
               print(io, "+")
            end
            if !isone(c) && (c != -1 || show_minus_one(typeof(c)))
               if bracket
                  print(io, "(")
               end
               show(io, c)
               if bracket
                  print(io, ")")
               end
               print(io, "*")
            end
            if c == -1 && !show_minus_one(typeof(c))
               print(io, "-")
            end
            print(io, string(S))
            if len - i != 1
               print(io, "^")
               print(io, len - i)
            end
         end
      end
      c = coeff(x, 0)
      bracket = needs_parentheses(c)
      if !iszero(c)
         if len != 1 && !is_negative(c)
            print(io, "+")
         end
         if bracket
            print(io, "(")
         end
         show(io, c)
         if bracket
            print(io, ")")
         end
      end
   end
end

function show(io::IO, R::FmpzModPolyRing)
  print(io, "Univariate Polynomial Ring in ")
  print(io, string(var(R)))
  print(io, " over ")
  print(io, base_ring(R))
end

################################################################################
#
#  Canonicalization
#
################################################################################

canonical_unit(a::fmpz_mod_poly) = canonical_unit(lead(a))

################################################################################
#
#  Unary operations
#
################################################################################

function -(x::fmpz_mod_poly)
  z = parent(x)()
  ccall((:fmpz_mod_poly_neg, :libflint), Void,
          (Ptr{fmpz_mod_poly}, Ptr{fmpz_mod_poly}), &z, &x)
  return z
end

################################################################################
#
#   Binary operations
#
################################################################################

function +(x::fmpz_mod_poly, y::fmpz_mod_poly)
  check_parent(x,y)
  z = parent(x)()
  ccall((:fmpz_mod_poly_add, :libflint), Void, 
          (Ptr{fmpz_mod_poly}, Ptr{fmpz_mod_poly},  Ptr{fmpz_mod_poly}), 
               &z, &x, &y)
  return z
end

function -(x::fmpz_mod_poly, y::fmpz_mod_poly)
  check_parent(x,y)
  z = parent(x)()
  ccall((:fmpz_mod_poly_sub, :libflint), Void, 
          (Ptr{fmpz_mod_poly}, Ptr{fmpz_mod_poly}, Ptr{fmpz_mod_poly}), 
              &z, &x, &y)
  return z
end

function *(x::fmpz_mod_poly, y::fmpz_mod_poly)
  check_parent(x,y)
  z = parent(x)()
  ccall((:fmpz_mod_poly_mul, :libflint), Void, 
          (Ptr{fmpz_mod_poly}, Ptr{fmpz_mod_poly},  Ptr{fmpz_mod_poly}), 
              &z, &x, &y)
  return z
end

###############################################################################
#
#  Ad hoc binary operations
#
###############################################################################

function *(x::fmpz_mod_poly, y::fmpz)
  z = parent(x)()
  ccall((:fmpz_mod_poly_scalar_mul_fmpz, :libflint), Void,
          (Ptr{fmpz_mod_poly}, Ptr{fmpz_mod_poly}, Ptr{fmpz}), &z, &x, &y)
  return z
end

*(x::fmpz, y::fmpz_mod_poly) = y*x

*(x::fmpz_mod_poly, y::Integer) = x*fmpz(y)

*(x::Integer, y::fmpz_mod_poly) = y*x

function *(x::fmpz_mod_poly, y::Residue{fmpz})
  (base_ring(x) != parent(y)) && error("Must have same parent")
  return x*y.data
end

*(x::Residue{fmpz}, y::fmpz_mod_poly) = y*x

function +(x::fmpz_mod_poly, y::Int)
  z = parent(x)()
  ccall((:fmpz_mod_poly_add_si, :libflint), Void,
    (Ptr{fmpz_mod_poly}, Ptr{fmpz_mod_poly}, Int), &z, &x, y)
  return z
end

+(x::Int, y::fmpz_mod_poly) = +(y, x)

function +(x::fmpz_mod_poly, y::fmpz)
  z = parent(x)()
  ccall((:fmpz_mod_poly_add_fmpz, :libflint), Void,
    (Ptr{fmpz_mod_poly}, Ptr{fmpz_mod_poly}, Ptr{fmpz}), &z, &x, &y)
  return z
end

+(x::fmpz, y::fmpz_mod_poly) = y + x

+(x::fmpz_mod_poly, y::Integer) = x + fmpz(y)

+(x::Integer, y::fmpz_mod_poly) = fmpz(y) + x 

function +(x::fmpz_mod_poly, y::Residue{fmpz})
  (base_ring(x) != parent(y)) && error("Elements must have same parent")
  return x + y.data
end

+(x::Residue{fmpz}, y::fmpz_mod_poly) = y + x

function -(x::fmpz_mod_poly, y::Int)
  z = parent(x)()
  ccall((:fmpz_mod_poly_sub_si, :libflint), Void,
    (Ptr{fmpz_mod_poly}, Ptr{fmpz_mod_poly}, Int), &z, &x, y)
  return z
end

function -(x::Int, y::fmpz_mod_poly)
  z = parent(y)()
  ccall((:fmpz_mod_poly_si_sub, :libflint), Void,
    (Ptr{fmpz_mod_poly}, Int, Ptr{fmpz_mod_poly}), &z, x, &y)
  return z
end

function -(x::fmpz_mod_poly, y::fmpz)
  z = parent(x)()
  ccall((:fmpz_mod_poly_sub_fmpz, :libflint), Void,
    (Ptr{fmpz_mod_poly}, Ptr{fmpz_mod_poly}, Ptr{fmpz}), &z, &x, &y)
  return z
end

function -(x::fmpz, y::fmpz_mod_poly)
  z = parent(y)()
  ccall((:fmpz_mod_poly_fmpz_sub, :libflint), Void,
    (Ptr{fmpz_mod_poly}, Ptr{fmpz}, Ptr{fmpz_mod_poly}), &z, &x, &y)
  return z
end

-(x::fmpz_mod_poly, y::Integer) = x - fmpz(y)

-(x::Integer, y::fmpz_mod_poly) = fmpz(x) - y

function -(x::fmpz_mod_poly, y::Residue{fmpz})
  (base_ring(x) != parent(y)) && error("Elements must have same parent")
  return x - y.data
end

function -(x::Residue{fmpz}, y::fmpz_mod_poly)
   (parent(x) != base_ring(y)) && error("Elements must have same parent")
   return x.data - y
end

################################################################################
#
#  Powering
#
################################################################################

function ^(x::fmpz_mod_poly, y::Int)
  y < 0 && throw(DomainError())
  z = parent(x)()
  ccall((:fmpz_mod_poly_pow, :libflint), Void,
          (Ptr{fmpz_mod_poly}, Ptr{fmpz_mod_poly}, Int), &z, &x, y)
  return z
end

################################################################################
#
#  Comparison
#
################################################################################

function ==(x::fmpz_mod_poly, y::fmpz_mod_poly)
  check_parent(x, y)
  return Bool(ccall((:fmpz_mod_poly_equal, :libflint), Int32,
             (Ptr{fmpz_mod_poly}, Ptr{fmpz_mod_poly}), &x, &y))
end

################################################################################
#
#  Ad hoc comparisons
#
################################################################################

function ==(x::fmpz_mod_poly, y::Residue{fmpz})
  base_ring(x) != parent(y) && error("Incompatible base rings in comparison")
  if length(x) > 1
     return false
  elseif length(x) == 1 
     u = fmpz()
     ccall((:fmpz_mod_poly_get_coeff_fmpz, :libflint), Void, 
            (Ptr{fmpz}, Ptr{fmpz_mod_poly}, Int), &u, &x, 0)
     return u == y
  else
    return y == 0
  end 
end

==(x::Residue{fmpz}, y::fmpz_mod_poly) = y == x

################################################################################
#
#  Truncation
#
################################################################################

function truncate(a::fmpz_mod_poly, n::Int)
  n < 0 && throw(DomainError())

  z = deepcopy(a)
   
  if length(z) <= n
    return z
  end

  ccall((:fmpz_mod_poly_truncate, :libflint), Void,
          (Ptr{fmpz_mod_poly}, Int), &z, n)
  return z
end

function mullow(x::fmpz_mod_poly, y::fmpz_mod_poly, n::Int)
  check_parent(x, y)
  n < 0 && throw(DomainError())

  z = parent(x)()
  ccall((:fmpz_mod_poly_mullow, :libflint), Void,
          (Ptr{fmpz_mod_poly}, Ptr{fmpz_mod_poly}, Ptr{fmpz_mod_poly}, Int), 
                &z, &x, &y, n)
  return z
end

###############################################################################
#
#   Reversal
#
###############################################################################

function reverse(x::fmpz_mod_poly, len::Int)
  len < 0 && throw(DomainError())
  z = parent(x)()
  ccall((:fmpz_mod_poly_reverse, :libflint), Void,
          (Ptr{fmpz_mod_poly}, Ptr{fmpz_mod_poly}, Int), &z, &x, len)
  return z
end

###############################################################################
#
#   Shifting
#
###############################################################################

function shift_left(x::fmpz_mod_poly, len::Int)
  len < 0 && throw(DomainError())
  z = parent(x)()
  ccall((:fmpz_mod_poly_shift_left, :libflint), Void,
          (Ptr{fmpz_mod_poly}, Ptr{fmpz_mod_poly}, Int), &z, &x, len)
  return z
end

function shift_right(x::fmpz_mod_poly, len::Int)
  len < 0 && throw(DomainError())
  z = parent(x)()
  ccall((:fmpz_mod_poly_shift_right, :libflint), Void,
            (Ptr{fmpz_mod_poly}, Ptr{fmpz_mod_poly}, Int), &z, &x, len)
  return z
end

###############################################################################
#
#   Exact division
#
###############################################################################

function divexact(x::fmpz_mod_poly, y::fmpz_mod_poly)
  check_parent(x, y)
  iszero(y) && throw(DivideError())
  q = parent(x)()
  r = parent(x)()
  ccall((:fmpz_mod_poly_divrem, :libflint), Void, 
        (Ptr{fmpz_mod_poly}, Ptr{fmpz_mod_poly}, Ptr{fmpz_mod_poly}, Ptr{fmpz_mod_poly}), 
               &q, &r, &x, &y)
  return q
end

################################################################################
#
#  Ad hoc exact division
#
################################################################################

function divexact(x::fmpz_mod_poly, y::Residue{fmpz})
  base_ring(x) != parent(y) && error("Elements must have same parent")
  iszero(y) && throw(DivideError())
  q = parent(x)()
  ccall((:fmpz_mod_poly_scalar_div_fmpz, :libflint), Void, 
          (Ptr{fmpz_mod_poly}, Ptr{fmpz_mod_poly}, Ptr{fmpz}), 
               &q, &x, &y.data)
  return q
end

################################################################################
#
#  Division with remainder
#
################################################################################

function divrem(x::fmpz_mod_poly, y::fmpz_mod_poly)
  check_parent(x,y)
  iszero(y) && throw(DivideError()) 
  q = parent(x)()
  r = parent(x)()
  ccall((:fmpz_mod_poly_divrem, :libflint), Void,
        (Ptr{fmpz_mod_poly}, Ptr{fmpz_mod_poly}, Ptr{fmpz_mod_poly}, Ptr{fmpz_mod_poly}),
          &q, &r, &x, &y)
  return q, r
end

################################################################################
#
#  Remainder
#
################################################################################

function rem(x::fmpz_mod_poly, y::fmpz_mod_poly)
  check_parent(x,y)
  iszero(y) && throw(DivideError()) 
  z = parent(x)()
  ccall((:fmpz_mod_poly_rem, :libflint), Void,
          (Ptr{fmpz_mod_poly}, Ptr{fmpz_mod_poly}, Ptr{fmpz_mod_poly}), &z, &x, &y)
  return z
end

mod(x::fmpz_mod_poly, y::fmpz_mod_poly) = rem(x,y)

################################################################################
#
#  GCD 
#
################################################################################

function gcd(x::fmpz_mod_poly, y::fmpz_mod_poly)
  check_parent(x, y)
  z = parent(x)()
  ccall((:fmpz_mod_poly_gcd, :libflint), Void,
          (Ptr{fmpz_mod_poly}, Ptr{fmpz_mod_poly}, Ptr{fmpz_mod_poly}), 
              &z, &x, &y)
  return z
end 

function gcdx(x::fmpz_mod_poly, y::fmpz_mod_poly)
  check_parent(x, y)
  g = parent(x)()
  s = parent(x)()
  t = parent(x)()
  ccall((:fmpz_mod_poly_xgcd, :libflint), Void,
          (Ptr{fmpz_mod_poly}, Ptr{fmpz_mod_poly}, Ptr{fmpz_mod_poly},
           Ptr{fmpz_mod_poly}, Ptr{fmpz_mod_poly}), &g, &s, &t, &x, &y)
  return g, s, t
end

function gcdinv(x::fmpz_mod_poly, y::fmpz_mod_poly)
  check_parent(x,y)
  length(y) <= 1 && error("Length of second argument must be >= 2")
  g = parent(x)()
  s = parent(x)()
  ccall((:fmpz_mod_poly_gcdinv, :libflint), Void,
          (Ptr{fmpz_mod_poly}, Ptr{fmpz_mod_poly}, Ptr{fmpz_mod_poly}, Ptr{fmpz_mod_poly}),
          &g, &s, &x, &y)
  return g, s
end 

################################################################################
#
#  Modular arithmetic
#
################################################################################

function invmod(x::fmpz_mod_poly, y::fmpz_mod_poly)
  length(y) == 0 && error("Second argument must not be 0")
  check_parent(x, y)
  if length(y) == 1 
    return parent(x)(inv(eval(x, coeff(y, 0))))
  end
  z = parent(x)()
  r = ccall((:fmpz_mod_poly_invmod, :libflint), Int32,
            (Ptr{fmpz_mod_poly}, Ptr{fmpz_mod_poly}, Ptr{fmpz_mod_poly}),
               &z, &x, &y)
  r == 0 ? error("Impossible inverse in invmod") : return z
end

function mulmod(x::fmpz_mod_poly, y::fmpz_mod_poly, z::fmpz_mod_poly)
  check_parent(x, y)
  check_parent(y, z)
  w = parent(x)()
  ccall((:fmpz_mod_poly_mulmod, :libflint), Void,
        (Ptr{fmpz_mod_poly}, Ptr{fmpz_mod_poly}, Ptr{fmpz_mod_poly}, Ptr{fmpz_mod_poly}),
        &w, &x, &y, &z)
  return w
end

function powmod(x::fmpz_mod_poly, e::Int, y::fmpz_mod_poly)
  e < 0 && error("Exponent must be positive")
  z = parent(x)()
  ccall((:fmpz_mod_poly_powmod_ui_binexp, :libflint), Void,
  (Ptr{fmpz_mod_poly}, Ptr{fmpz_mod_poly}, Int, Ptr{fmpz_mod_poly}), &z, &x, e, &y)
  return z
end

function powmod(x::fmpz_mod_poly, e::fmpz, y::fmpz_mod_poly)
  e < 0 && error("Exponent must be positive")
  z = parent(x)()
  ccall((:fmpz_mod_poly_powmod_fmpz_binexp, :libflint), Void,
        (Ptr{fmpz_mod_poly}, Ptr{fmpz_mod_poly}, Ptr{fmpz}, Ptr{fmpz_mod_poly}), 
            &z, &x, &e, &y)
  return z
end

################################################################################
#
#  Resultant
#
################################################################################

function resultant(x::fmpz_mod_poly, y::fmpz_mod_poly)
  check_parent(x,y)
  z = parent(x)()
  r = fmpz()
  ccall((:fmpz_mod_poly_resultant, :libflint), Void,
          (Ptr{fmpz}, Ptr{fmpz_mod_poly}, Ptr{fmpz_mod_poly}), &r, &x, &y)
  return base_ring(x)(r)
end

################################################################################
#
#  Evaluation
#
################################################################################

function evaluate(x::fmpz_mod_poly, y::Residue{fmpz})
  base_ring(x) != parent(y) && error("Elements must have same parent")
  z = fmpz()
  ccall((:fmpz_mod_poly_evaluate_fmpz, :libflint), Void,
              (Ptr{fmpz}, Ptr{fmpz_mod_poly}, Ptr{fmpz}), &z, &x, &(y.data))
  return parent(y)(z)
end

################################################################################
#
#  Derivative
#
################################################################################

function derivative(x::fmpz_mod_poly)
  z = parent(x)()
  ccall((:fmpz_mod_poly_derivative, :libflint), Void,
        (Ptr{fmpz_mod_poly}, Ptr{fmpz_mod_poly}), &z, &x)
  return z
end

###############################################################################
#
#   Integral
#
###############################################################################

function integral(x::fmpz_mod_poly)
   len = length(x)
   v = Array(Residue{fmpz}, len + 1)
   v[1] = zero(base_ring(x))
   for i = 1:len
      v[i + 1] = divexact(coeff(x, i - 1), base_ring(x)(i))
   end
   return parent(x)(v)
end

################################################################################
#
#  Composition
#
################################################################################

function compose(x::fmpz_mod_poly, y::fmpz_mod_poly)
  check_parent(x,y)
  z = parent(x)()
  ccall((:fmpz_mod_poly_compose, :libflint), Void,
          (Ptr{fmpz_mod_poly}, Ptr{fmpz_mod_poly}, Ptr{fmpz_mod_poly}), 
               &z, &x, &y)
  return z
end

################################################################################
#
#  Lifting
#
################################################################################

function lift(x::FmpzPolyRing, y::fmpz_mod_poly)
   z = fmpz_poly()
   ccall((:fmpz_mod_poly_get_fmpz_poly, :libflint), Void,
          (Ptr{fmpz_poly}, Ptr{fmpz_mod_poly}), &z, &y)
   z.parent = x
  return z
end

################################################################################
#
#  Irreducibility
#
################################################################################

function isirreducible(x::fmpz_mod_poly)
  return Bool(ccall((:fmpz_mod_poly_is_irreducible, :libflint), Int32,
          (Ptr{fmpz_mod_poly}, ), &x))
end

################################################################################
#
#  Squarefree testing
#
################################################################################

function issquarefree(x::fmpz_mod_poly)
  return Bool(ccall((:fmpz_mod_poly_is_squarefree, :libflint), Int32, 
      (Ptr{fmpz_mod_poly}, ), &x))
end

################################################################################
#
#  Factorization
#
################################################################################

function factor(x::fmpz_mod_poly)
  fac = fmpz_mod_poly_factor(parent(x)._n)
  ccall((:fmpz_mod_poly_factor, :libflint), UInt,
          (Ptr{fmpz_mod_poly_factor}, Ptr{fmpz_mod_poly}), &fac, &x)
  res = Array(Tuple{fmpz_mod_poly, Int}, fac._num)
  for i in 1:fac._num
    f = parent(x)()
    ccall((:fmpz_mod_poly_factor_get_fmpz_mod_poly, :libflint), Void,
         (Ptr{fmpz_mod_poly}, Ptr{fmpz_mod_poly_factor}, Int), &f, &fac, i - 1)
    e = unsafe_load(fac.exp, i)
    res[i] = (f, e)
  end
  return res 
end  

function factor_squarefree(x::fmpz_mod_poly)
  fac = fmpz_mod_poly_factor(parent(x)._n)
  ccall((:fmpz_mod_poly_factor_squarefree, :libflint), UInt,
          (Ptr{fmpz_mod_poly_factor}, Ptr{fmpz_mod_poly}), &fac, &x)
  res = Array(Tuple{fmpz_mod_poly, Int}, fac._num)
  for i in 1:fac._num
    f = parent(x)()
    ccall((:fmpz_mod_poly_factor_get_fmpz_mod_poly, :libflint), Void,
         (Ptr{fmpz_mod_poly}, Ptr{fmpz_mod_poly_factor}, Int), &f, &fac, i - 1)
    e = unsafe_load(fac.exp, i)
    res[i] = (f, e)
  end
  return res 
end  

function factor_distinct_deg(x::fmpz_mod_poly)
  !issquarefree(x) && error("Polynomial must be squarefree")
  degs = Array(Int, degree(x))
  degss = [ pointer(degs) ]
  fac = fmpz_mod_poly_factor(parent(x)._n)
  ccall((:fmpz_mod_poly_factor_distinct_deg, :libflint), UInt,
          (Ptr{fmpz_mod_poly_factor}, Ptr{fmpz_mod_poly}, Ptr{Ptr{Int}}),
          &fac, &x, degss)
  res = Array(Tuple{fmpz_mod_poly, Int}, fac._num)
  for i in 1:fac._num
    f = parent(x)()
    ccall((:fmpz_mod_poly_factor_get_fmpz_mod_poly, :libflint), Void,
         (Ptr{fmpz_mod_poly}, Ptr{fmpz_mod_poly_factor}, Int), &f, &fac, i - 1)
    res[i] = (f, degs[i])
  end
  return res 
end  

function factor_shape(x::fmpz_mod_poly)
  res = Array(Int, degree(x))
  res2 = Array(Int, degree(x))
  res3 = Array(Tuple{Int, Int}, degree(x))
  k = 1
  fill!(res, 0)
  square_fac = factor_squarefree(x)
  for (f, i) in square_fac
    discdeg = factor_distinct_deg(f)
    for (g, j) in discdeg
      num = div(degree(g), j)
      res[j] += num*i
      res2[k] = j
      k += 1
    end
  end
  resize!(res2, k - 1)
  res2 = unique(res2)
  resize!(res3, length(res2))
  for j in 1:length(res2)
    res3[j] = (res2[j], res[res2[j]])
  end
  return res3
end  

################################################################################
#
#  Unsafe functions
#
################################################################################

function setcoeff!(x::fmpz_mod_poly, n::Int, y::UInt)
  ccall((:fmpz_mod_poly_set_coeff_ui, :libflint), Void, 
                   (Ptr{fmpz_mod_poly}, Int, UInt), &x, n, y)
end

function setcoeff!(x::fmpz_mod_poly, n::Int, y::Int)
  ccall((:fmpz_mod_poly_set_coeff_ui, :libflint), Void, 
                   (Ptr{fmpz_mod_poly}, Int, UInt), &x, n, mod(y, x._n))
end

function setcoeff!(x::fmpz_mod_poly, n::Int, y::fmpz)
  ccall((:fmpz_mod_poly_set_coeff_fmpz, :libflint), Void, 
                   (Ptr{fmpz_mod_poly}, Int, Ptr{fmpz}), &x, n, &y)
end

function setcoeff!(x::fmpz_mod_poly, n::Int, y::Integer)
  setcoeff!(x, n, fmpz(y))
end
  
function setcoeff!(x::fmpz_mod_poly, n::Int, y::Residue{fmpz})
  setcoeff!(x, n, y.data)
end

function add!(z::fmpz_mod_poly, x::fmpz_mod_poly, y::fmpz_mod_poly)
  ccall((:fmpz_mod_poly_add, :libflint), Void, 
     (Ptr{fmpz_mod_poly}, Ptr{fmpz_mod_poly},  Ptr{fmpz_mod_poly}), &z, &x, &y)
end

function addeq!(z::fmpz_mod_poly, y::fmpz_mod_poly)
  ccall((:fmpz_mod_poly_add, :libflint), Void, 
     (Ptr{fmpz_mod_poly}, Ptr{fmpz_mod_poly},  Ptr{fmpz_mod_poly}), &z, &z, &y)
end

function sub!(z::fmpz_mod_poly, x::fmpz_mod_poly, y::fmpz_mod_poly)
  ccall((:fmpz_mod_poly_sub, :libflint), Void, 
     (Ptr{fmpz_mod_poly}, Ptr{fmpz_mod_poly},  Ptr{fmpz_mod_poly}), &z, &x, &y)
end

function mul!(z::fmpz_mod_poly, x::fmpz_mod_poly, y::fmpz_mod_poly)
  ccall((:fmpz_mod_poly_mul, :libflint), Void, 
     (Ptr{fmpz_mod_poly}, Ptr{fmpz_mod_poly},  Ptr{fmpz_mod_poly}), &z, &x, &y)
end

################################################################################
#
#  Promotion rules
#
################################################################################

Base.promote_rule{V <: Integer}(::Type{fmpz_mod_poly}, ::Type{V}) = fmpz_mod_poly

Base.promote_rule(::Type{fmpz_mod_poly}, ::Type{fmpz}) = fmpz_mod_poly

################################################################################
#
#  Parent object call overloads
#
################################################################################

function Base.call(R::FmpzModPolyRing)
  z = fmpz_mod_poly(R._n)
  z.parent = R
  return z
end

function Base.call(R::FmpzModPolyRing, x::fmpz)
  z = fmpz_mod_poly(R._n, x)
  z.parent = R
  return z
end

function Base.call(R::FmpzModPolyRing, x::Integer)
  z = fmpz_mod_poly(R._n, fmpz(x))
  z.parent = R
  return z
end

function Base.call(R::FmpzModPolyRing, x::Residue{fmpz})
  base_ring(R) != parent(x) && error("Wrong parents")
  z = fmpz_mod_poly(R._n, x.data)
  z.parent = R
  return z
end

function Base.call(R::FmpzModPolyRing, arr::Array{fmpz, 1})
  z = fmpz_mod_poly(R._n, arr)
  z.parent = R
  return z
end

function Base.call(R::FmpzModPolyRing, arr::Array{Residue{fmpz}, 1})
  if length(arr) > 0
     (base_ring(R) != parent(arr[1])) && error("Wrong parents")
  end
  z = fmpz_mod_poly(R._n, arr)
  z.parent = R
  return z
end

function Base.call(R::FmpzModPolyRing, x::fmpz_poly)
  z = fmpz_mod_poly(R._n, x)
  z.parent = R
  return z
end

function Base.call(R::FmpzModPolyRing, f::fmpz_mod_poly)
   parent(f) != R && error("Unable to coerce polynomial")
   return f
end

################################################################################
#
#  Polynomial ring constructor
#
################################################################################

function PolynomialRing(R::ResidueRing{fmpz}, s::String)
   if modulus(R) <= fmpz(typemax(UInt))
      parent_obj = NmodPolyRing(R, symbol(s))
   else
      parent_obj = FmpzModPolyRing(R, symbol(s))
   end

   return parent_obj, parent_obj([R(0), R(1)])
end