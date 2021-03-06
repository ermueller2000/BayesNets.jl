let
	bn = BayesNet(
			[BayesNetNode(:A, BINARY_DOMAIN, CPDs.Bernoulli()),
					BayesNetNode(:B, BINARY_DOMAIN, CPDs.Bernoulli([:A],
						                                          Dict(
						                                          	Dict(:A=>true)=>0.1,
						                                          	Dict(:A=>false)=>0.2,
						                                          	   )
						                                         )
					            ),
					],
			[(:A,:B)]
		)

	# TODO: make this test more rigorous
	assignments = BayesNets.assignment_dicts(bn, [:A, :B])
	@test assignments ==
			[Dict{Symbol,Any}(:B=>false,:A=>false),
			 Dict{Symbol,Any}(:B=>false,:A=>true),
			 Dict{Symbol,Any}(:B=>true,:A=>false),
			 Dict{Symbol,Any}(:B=>true,:A=>true)]

	# TODO: make this test more rigorous
	@test BayesNets.discrete_parameter_dict(
				BayesNets.assignment_dicts(bn, [:A]),
				[0.2, 0.8, 0.4, 0.6], 2
				) ==
		Dict(Dict{Symbol,Any}(:A=>false)=>[0.2,0.8],
			 Dict{Symbol,Any}(:A=>true)=>[0.4,0.6])
end

let
	# read a sample .XDSL BN file
	# NOTE: these are generated by Genie / Smile
	#       See Smile.jl
	# Success -> Forecast

	bn = readxdsl(Pkg.dir("BayesNets", "test", "sample_bn.xdsl"))

	@test sort!(names(bn)) == [:Forecast, :Success]
	@test isempty(parents(bn, :Success))
	@test sort!(parents(bn, :Forecast)) == [:Success]
	@test isvalid(bn)

	@test isapprox(prob(bn, Dict(:Success=>1, :Forecast=>1)), 0.2*0.4)
	@test isapprox(prob(bn, Dict(:Success=>1, :Forecast=>2)), 0.2*0.4)
	@test isapprox(prob(bn, Dict(:Success=>1, :Forecast=>3)), 0.2*0.2)
	@test isapprox(prob(bn, Dict(:Success=>2, :Forecast=>1)), 0.8*0.1)
	@test isapprox(prob(bn, Dict(:Success=>2, :Forecast=>2)), 0.8*0.3)
	@test isapprox(prob(bn, Dict(:Success=>2, :Forecast=>3)), 0.8*0.6)


end

let
	# read a sample .XDSL BN file with a domain comprised of strings
	# NOTE: these are generated by Genie / Smile
	#       See Smile.jl
	# Degree -> Job -> Life

	bn = readxdsl(Pkg.dir("BayesNets", "test", "sample_bn_str.xdsl"))

	@test sort!(parents(bn,:Life))==[:Degree, :Job]
	@test isvalid(bn)
	@test isempty(parents(bn,:Degree))
	
	assignments=BayesNets.assignment_dicts(bn,[:Degree,:Life,:Job])
	@test assignments == 
			[Dict{Symbol,Any}(:Job=>"InNOut",:Degree=>"Masters",:Life=>"Happy4")
			 Dict{Symbol,Any}(:Job=>"InNOut",:Degree=>"PhD",:Life=>"Happy4")    
			 Dict{Symbol,Any}(:Job=>"InNOut",:Degree=>"Masters",:Life=>"Sad5")  
			 Dict{Symbol,Any}(:Job=>"InNOut",:Degree=>"PhD",:Life=>"Sad5")      
			 Dict{Symbol,Any}(:Job=>"NASA",:Degree=>"Masters",:Life=>"Happy4")  
			 Dict{Symbol,Any}(:Job=>"NASA",:Degree=>"PhD",:Life=>"Happy4")      
			 Dict{Symbol,Any}(:Job=>"NASA",:Degree=>"Masters",:Life=>"Sad5")    
			 Dict{Symbol,Any}(:Job=>"NASA",:Degree=>"PhD",:Life=>"Sad5")]	

end