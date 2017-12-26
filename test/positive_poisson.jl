using HurdleDMR
using FactCheck, GLM, Lasso, DataFrames
facts("PositivePoisson") do
λ0=3.4
xs = 1:10000
@time lp1=[logpdf(Poisson(λ0),x)::Float64 for x=xs]
@time lp2=[HurdleDMR.logpdf_approx(Poisson(λ0),x)::Float64 for x=xs]
@fact lp1 --> roughly(lp2)

@time lp1=[logpdf(PositivePoisson(λ0),x)::Float64 for x=xs]
@time lp2=[logpdf_exact(PositivePoisson(λ0),x)::Float64 for x=xs]
@fact lp1 --> roughly(lp2)

ηs=-10:0.1:10
@time μs=broadcast(η->linkinv(LogProductLogLink(),η),ηs)
@time ηscheck=broadcast(μ->linkfun(LogProductLogLink(),μ),μs)
@fact ηs --> roughly(ηscheck)

loglik(y, μ) = GLM.loglik_obs(PositivePoisson(λ0), y, μ, one(y), 0)

μs=1.01:0.1:1000
@time ηs=broadcast(μ->linkfun(LogProductLogLink(),μ),μs)
@time μscheck=broadcast(η->linkinv(LogProductLogLink(),η),ηs)
@fact μs --> roughly(μscheck)
#verify works for large μ
ys = round.(Int,μs) + 1.0
devresids = devresid.(PositivePoisson(λ0), ys, μs)
@fact all(isfinite,devresids) --> true
logliks = loglik.(ys, μs)
@fact all(isfinite,logliks) --> true
# i = findfirst(isinf,logliks)
# @enter GLM.loglik_obs(PositivePoisson(λ0), ys[i], μs[i], one(ys[i]), 0)

ys = ones(μs)
devresids1 = devresid.(PositivePoisson(λ0), ys, μs)
@fact all(isfinite,devresids1) --> true
logliks1 = loglik.(ys, μs)
@fact all(isfinite,logliks1) --> true

μsbig = big.(μs)
@time ηs=broadcast(μ->linkfun(LogProductLogLink(),μ),μsbig)
@time μscheck=broadcast(η->linkinv(LogProductLogLink(),η),ηs)
@fact μsbig --> roughly(μscheck)
#verify works for large μ
ysbig = round.(BigInt,μsbig) + 1.0
devresidsbig = devresid.(PositivePoisson(λ0), ysbig, μsbig)
@fact all(isfinite,devresidsbig) --> true
@fact devresids --> roughly(Float64.(devresidsbig))

logliksbig = loglik.(ysbig, μsbig)
@fact all(isfinite,logliksbig) --> true
@fact logliks --> roughly(Float64.(logliksbig))

ysbig = ones(μsbig)
devresidsbig1 = devresid.(PositivePoisson(λ0), ysbig, μsbig)
@fact all(isfinite,devresidsbig1) --> true
@fact devresids1 --> roughly(Float64.(devresidsbig1))
logliksbig1 = loglik.(ysbig, μsbig)
@fact all(isfinite,logliksbig1) --> true

# μs close to 1.0
μs=big.(collect(1.0+1e-10:1e-10:1.0+1000*1e-10))
@time ηs=broadcast(μ->linkfun(LogProductLogLink(),μ),μs)
@time μscheck=broadcast(η->linkinv(LogProductLogLink(),η),ηs)
@fact μs --> roughly(μscheck)
#verify works for large μ
ys = round.(BigInt,μs) + 1.0
devresidsbig = devresid.(PositivePoisson(λ0), ys, μs)
@fact all(isfinite,devresidsbig) --> true
logliksbig = loglik.(ys, μs)
@fact all(isfinite,logliksbig) --> true

ys = ones(μs)
devresidsbig = devresid.(PositivePoisson(λ0), ys, μs)
@fact all(isfinite,devresidsbig) --> true
logliks1 = loglik.(ys, μs)
@fact all(isfinite,logliks1) --> true

# using JLD
# @load joinpath(Pkg.dir("HurdleDMR"),"test","data","degenerate_hurdle5_debug.jld")
# μs = broadcast(ηi -> inverselink(LogProductLogLink(), ηi)[1], η)
# dμdη = broadcast(ηi -> inverselink(LogProductLogLink(), ηi)[2], η)
# find(isinf,μs)
# find(isinf,dμdη)
# glmvar.(PositivePoisson(λ0),μ)
# j = findfirst(isinf,devresid.(PositivePoisson(λ0), y, μs))
# yi, μi = y[j], μs[j]
# yi, μi = big(yi), big(μi)
# devresid(Poisson(),yi,μi)
# devresid(PositivePoisson(),yi,μi)
# devresid(PositivePoisson(),yi,μi)
#
# using LambertW
# -2 * log(-lambertw(-exp(-μi)*μi))
# -2 * μi
# fun(μi) = log(-lambertw(-exp(-μi)*μi))
# fun2(μi) = -μi
# using Gadfly
# μs = big.(linspace(1.0,100.0,100))
# plot(layer(x=μs, y=fun.(μs), Geom.line, Theme(default_color="orange")),
#      layer(x=μs, y=fun2.(μs), Geom.line, Theme(default_color="blue")))
#
# λμ = HurdleDMR.λfn(μi)
# -2 * (log(μi) - λμ)
# -2 * (log(λμ/(1.0-exp(-λμ))) - λμ)
# -2 * log(λμ/(exp(λμ)-1.0))
# λy = HurdleDMR.λfn(yi)
# 2 * (y*(log(λy)-log(λμ)) - HurdleDMR.logexpm1(λy) + HurdleDMR.logexpm1(λμ))
# HurdleDMR.logexpm1(λy)
# log(λy)
# HurdleDMR.logexpm1(λμ)
# log(λμ)

# R benchmark
seed=12
nn=1000
b0=1.0
b1=-2.0
coefs0=[b0,b1]

# # uncomment code to generate R benchmark and save it to csv files
# using RCall
# R"if(!require(VGAM)){install.packages(\"VGAM\");library(VGAM)}"
# R"library(VGAM)"
# R"set.seed($seed)"
# R"pdata <- data.frame(x2 = runif(nn <- $nn))"
# R"pdata <- transform(pdata, lambda = exp($b0 + $b1 * x2))"
# R"pdata <- transform(pdata, y1 = rpospois(nn, lambda))"
# R"with(pdata, table(y1))"
# R"fit <- vglm(y1 ~ x2, pospoisson, data = pdata, trace = TRUE, crit = \"coef\")"
# print(R"summary(fit)")
# pdata=rcopy("pdata")
# coefsR=vec(rcopy(R"coef(fit, matrix = TRUE)"))
# coefsRdf = DataFrame(intercept=[coefsR[1]],x2=[coefsR[2]])
# writetable(joinpath(testfolder,"data","positive_poisson_pdata.csv"),pdata)
# writetable(joinpath(testfolder,"data","positive_poisson_coefsR.csv"),coefsRdf)

# load saved R benchmark
pdata=readtable(joinpath(testfolder,"data","positive_poisson_pdata.csv"))
coefsR=vec(convert(Matrix{Float64},readtable(joinpath(testfolder,"data","positive_poisson_coefsR.csv"))))

X=convert(Array{Float64,2},pdata[:,[:x2]])
Xwconst=[ones(size(X,1)) X]
y=convert(Array{Float64,1},pdata[:y1])

@time glmfit = fit(GeneralizedLinearModel,Xwconst,y,PositivePoisson(),LogProductLogLink())

# @time glmfit = fit(GeneralizedLinearModel,Xwconst,y,PositivePoisson(),LogProductLogLink();convTol=1e-2)
coefsGLM = coef(glmfit)
@fact coefsGLM --> roughly(coefsR;rtol=1e-7)
@fact coefsGLM --> roughly(coefs0;rtol=0.05)
# rdist(coefsGLM,coefsR)
# rdist(coefsGLM,coefs0)

# GammaLassoPath without actualy regularization
@time glpfit = fit(GammaLassoPath,X,y,PositivePoisson(),LogProductLogLink(); λ=[0.0])
coefsGLP = vec(coef(glpfit))
@fact coefsGLP --> roughly(coefsGLM)

# GammaLassoPath doing Lasso
@time lassofit = fit(GammaLassoPath,X,y,PositivePoisson(),LogProductLogLink(); γ=0.0)
coefsLasso = vec(coef(lassofit;select=:AICc))
@fact coefsLasso --> roughly(coefsGLM;rtol=0.02)
@fact coefsLasso --> roughly(coefs0;rtol=0.05)
# rdist(coefsLasso,coefsGLM)
# rdist(coefsLasso,coefs0)

# GammaLassoPath doing concave regularization
@time glpfit = fit(GammaLassoPath,X,y,PositivePoisson(),LogProductLogLink(); γ=10.0)
coefsGLP = vec(coef(glpfit;select=:AICc))
@fact coefsGLP --> roughly(coefsLasso;rtol=0.0002)
@fact coefsGLP --> roughly(coefs0;rtol=0.05)
# rdist(coefsGLP,coefsLasso)
# rdist(coefsGLP,coefs0)

# # problematic case 1
# X = [6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 6.693264063357201 5.354611250685761 5.354611250685761 5.354611250685761 5.354611250685761 5.354611250685761 5.354611250685761 5.354611250685761 5.354611250685761 5.354611250685761 5.354611250685761 5.354611250685761 5.354611250685761 5.354611250685761 5.354611250685761 5.354611250685761 5.354611250685761 5.354611250685761 5.354611250685761 5.354611250685761 5.354611250685761 5.354611250685761 5.354611250685761 5.354611250685761 5.354611250685761 5.354611250685761 5.354611250685761 5.354611250685761 5.354611250685761 5.354611250685761 5.354611250685761 5.354611250685761 5.354611250685761 5.354611250685761 5.354611250685761 5.354611250685761 5.354611250685761 5.354611250685761 5.354611250685761 5.354611250685761 5.354611250685761 5.354611250685761 5.354611250685761 4.015958438014321 4.015958438014321 4.015958438014321 4.015958438014321 4.015958438014321 4.015958438014321 4.015958438014321 4.015958438014321 4.015958438014321 2.6773056253428806 2.6773056253428806 2.6773056253428806 2.6773056253428806 1.3386528126714403 1.3386528126714403 1.3386528126714403 1.3386528126714403]'
# y = [1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,2.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,2.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0]
# yalt = [3.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,2.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,2.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0]
# y = [1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,2.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,2.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0]
# y=ones(size(X,1))
# y[end]=1
# problem1fit = fit(LassoPath,X,y,Binomial();verbose=true,naivealgorithm=true)
# problem1fit = fit(GeneralizedLinearModel,X,y,Poisson();verbose=true)
#
# problem1fit = fit(GammaLassoPath,X,y,Poisson();γ=0.0,verbose=true,naivealgorithm=false)
# problem1fit.m.pp
# m=[]
# problem1fit=[]
# (obj,objold,path,f,newcoef,oldcoef,b0,oldb0,b0diff,coefdiff,scratchmu,cd,r,α,curλ)=(0,0,[],0,[],[],0,0,0,[],[],[],[],0,0)
# try
#   problem1fit = fit(GammaLassoPath,X,y,PositivePoisson();γ=0.0,verbose=true,naivealgorithm=false)
# catch e
#   if typeof(e) == Lasso.ConvergenceException
#     (obj,objold,path,f,newcoef,oldcoef,b0,oldb0,b0diff,coefdiff,scratchmu,cd,r,α,curλ) = e.debugvars
#     m = path.m
#     error(e.msg)
#     nothing
#   else
#     e
#   end
# end
# coef(problem1fit)
# newcoef==oldcoef
# b0diff
# coefdiff
# newcoef
# oldcoef
# newcoef-oldcoef
# scratchmu
# m.rr.devresid
# sum(m.rr.devresid)
# println(m.rr.var)
# cd
# m.rr.mu
# m.pp.oldy
# deviance(m)
# fieldnames(path.m.pp)
# curλ
# b0=-3.67186085318965
# newcoef.coef[1]=-0.08566741748972534
#
# rnew = deepcopy(m.rr)
# pnew = deepcopy(m.pp)
# newmu = Lasso.linpred!(scratchmu, pnew, newcoef, b0)
# updateμ!(rnew, newmu)
# devnew = deviance(rnew)
# curλ*Lasso.P(α, newcoef, pnew.ω)
# objnew = devnew/2 + curλ*Lasso.P(α, newcoef, pnew.ω)
#
# rold = deepcopy(m.rr)
# pold = deepcopy(m.pp)
# oldmu = Lasso.linpred!(scratchmu, pold, oldcoef, oldb0)
# updateμ!(rold, oldmu)
# devold = deviance(rold)
# objold = devold/2 + curλ*Lasso.P(α, oldcoef, pold.ω)
#
# devnew==devold
# curλ*Lasso.P(α, oldcoef, pold.ω) > curλ*Lasso.P(α, newcoef, pnew.ω)
# objnew > objold
# # step-halving failure zoomin
# function devf(b0,newcoef,m,cd,f)
#   T = eltype(y)
#   m=deepcopy(m)
#   newcoef=deepcopy(newcoef)
#   b0=deepcopy(b0)
#   cd=deepcopy(cd)
#   r=m.rr
#   p=m.pp
#   for icoef = 1:nnz(newcoef)
#       oldcoefval = icoef > nnz(oldcoef) ? zero(T) : oldcoef.coef[icoef]
#       newcoef.coef[icoef] = oldcoefval+f*(coefdiff.coef[icoef])
#   end
#   b0 = oldb0+f*b0diff
#   updateμ!(r, Lasso.linpred!(scratchmu, cd, newcoef, b0))
#   dev = deviance(r)
#   curλ*Lasso.P(α, newcoef, cd.ω)
#   obj = dev/2 + curλ*Lasso.P(α, newcoef, cd.ω)
# end
# using Gadfly
# Δf=f*1
# fs=-100f:Δf:100f
# devfs=map(f->devf(b0,newcoef,m,cd,f),fs)
# plot(layer(x=fs,y=devfs,Geom.line),layer(x=[0],y=[objold],Geom.point))
# r.var
# #
#
# fieldnames(newcoef)
# size(newcoef)
#
# # problematic case 2
#
# using Lasso, StatsBase
# X=[3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 3.461994189597978 2.7695953516783822 2.7695953516783822 2.7695953516783822 2.7695953516783822 2.7695953516783822 2.7695953516783822 2.7695953516783822 2.7695953516783822 2.7695953516783822 2.7695953516783822 2.7695953516783822 2.7695953516783822 2.7695953516783822 2.7695953516783822 2.7695953516783822 2.7695953516783822 2.7695953516783822 2.7695953516783822 2.7695953516783822 2.7695953516783822 2.7695953516783822 2.7695953516783822 2.7695953516783822 2.7695953516783822 2.7695953516783822 2.7695953516783822 2.7695953516783822 2.7695953516783822 2.7695953516783822 2.7695953516783822 2.0771965137587864 2.0771965137587864 2.0771965137587864 2.0771965137587864 2.0771965137587864 2.0771965137587864 2.0771965137587864 1.3847976758391911 1.3847976758391911 1.3847976758391911 1.3847976758391911 1.3847976758391911 1.3847976758391911 1.3847976758391911 1.3847976758391911 1.3847976758391911 1.3847976758391911 1.3847976758391911 1.3847976758391911 1.3847976758391911 1.3847976758391911 1.3847976758391911 1.3847976758391911 1.3847976758391911 1.3847976758391911 0.6923988379195956 0.6923988379195956 0.6923988379195956 0.6923988379195956 0.6923988379195956 0.6923988379195956 0.6923988379195956 0.6923988379195956 0.6923988379195956 0.6923988379195956 0.6923988379195956 0.6923988379195956 0.6923988379195956 0.6923988379195956 0.6923988379195956 0.6923988379195956 0.6923988379195956 0.6923988379195956 0.6923988379195956 0.6923988379195956 0.6923988379195956 0.6923988379195956 0.6923988379195956 0.6923988379195956 0.6923988379195956]'
# Xwconst=[ones(X) X]
# y=[1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,2.0,2.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,2.0,1.0,2.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,2.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,2.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0,1.0]
# sum(y.!=1.0)
# summarystats(y)
# std(y)
# problem2fit = fit(GeneralizedLinearModel,Xwconst,y,Poisson();verbose=true)
# problem2fit = fit(GeneralizedLinearModel,ones(X),y,Poisson();verbose=true)
# problem2fit = fit(LassoPath,X,y,Poisson();verbose=true,λ=[0.0])
# problem2fit = fit(LassoPath,X,y,Poisson();verbose=true,λ=[0.0],dofit=false)
# problem2fit = fit(LassoPath,X,y,Poisson();verbose=true)
# intercept=true
# n=length(y)
# T=eltype(X)
# d=Poisson()
# l=canonicallink(d)
# wts=ones(T, length(y))
# wts .*= convert(T, 1/sum(wts))
# offset=similar(y, 0)
# irls_tol =1e-7
# nullmodel = fit(GeneralizedLinearModel, ones(T, n, ifelse(intercept, 1, 0)), y, d, l;
#                     wts=wts, offset=offset, convTol=irls_tol)
# problem2fit = fit(GeneralizedLinearModel,ones(X),y,Poisson();verbose=true,convTol=irls_tol)
# problem2fit = fit(GeneralizedLinearModel,ones(X),y,Poisson();verbose=true,convTol=irls_tol,dofit=false)
#
# problem2fit = fit(GammaLassoPath,X,y,Poisson();γ=0.0,verbose=true)
# problem2fit = fit(LassoPath,ones(X),y,Poisson();verbose=true,intercept=false)


end
