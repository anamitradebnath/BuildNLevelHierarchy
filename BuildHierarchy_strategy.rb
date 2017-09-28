
# A) class BuildHierarchy

# 1. have a class method to build the hierarchy
# 	question: can ruby class methods access ruby instance methods and instance variables?
# 2. user will have to create an object of this class
# 3. set the object with details of the hierarchy
# 	question: use metaprogramming to create methods such as object.level_n_name and object.level_n_list and object.level_n_relationship in the run time
# 4. call BuildHierarchy.build_hierarchy(pass the object here)
# 5. this should return a json structure
# 	question: how to create and return json structure. store this returned json object in component method's instance variable and then use in jbuilder file


# B) where to put the code?
# this BuildHierarchy class is like a helper class. so ideally it should be put into helper directory and included in the file wherever it is being used.

# C) first query: get all the networks. fetch network id
# 	second query: get all the releases by passing the build dep component id and network ids
# 	third query: get all the build deps, including components, versions, installables, install os-es, and releases (as release number is needed to establish the relationship with a release)

# check if class methods can be private

class BuildHierarchy
	attr_accessor :result, :input_array_sorted_by_level_no, :result_as_ruby_hash	
	attr_reader   :input

	# below is the format of each has of the input array. This is basically information that describes the object in each level 
	# and its relationship with the previous level
	# this shows an example of what all keys must be there in each level, values are just for example here
	@@expected_info_in_each_level_hash = {
								:level_no => 1,
								:level_name => 'networks',
								:level_list => [:network_obj1,:network_obj2, :network_obj3],
								:relationship_with_previous_level => "previous_level.id=this_level.network_id"
							}

	def initialize()
		puts "new object is being created"
		@input = nil
		@result = {:error => nil, :result => []}
		@input_array_sorted_by_level_no = []
		puts "@input is nil "
		puts "@result = " 
		p @result
		puts "coming out of constructor"
	end

	def set_hierarchy_details(input_array)		
		puts "inside set_hierarchy_details method."
		@input = input_array
		puts "setting instance variable, @input = " 
		p @input		
	end

	# returns a hash {:error => 'error message', :result => []}
	# if no error happens, :error will be nil when returned to the caller
	def self.build_hierarchy(obj)
		puts "inside build_hierarchy method"
		error_msg = nil
		validation_obj = nil
		# validate the input 
		validation_obj = BuildHierarchy.validate_input(obj)

		# if validation_obj.nil?
		# 	puts "something went wrong in validating input. aborting."
		# 	return
		# end
		puts "validation_obj = " 
		p validation_obj
		if validation_obj[:validation_status] == false
			puts "as validation of the input has failed, returning without building hierarcy."
			# set the @result instance variable of the object with error message
			if obj.class.to_s == 'BuildHierarchy'
				obj.result= {:error => validation_obj[:error_msg], :result => []}  
			else
				return {:error => validation_obj[:error_msg], :result => []}
			end

		else
			puts "Building the hierarcy now"
			BuildHierarchy.build_hierarchy_helper(obj)
			# BuildHierarchy.convert_ruby_hashed_result_to_json(obj)
		end
		puts "\n\n\t ---- back to build_hierarchy method. "
		obj.result[:result] = obj.result_as_ruby_hash
		puts "\tobj.result = " 
		p obj.result
		puts "########## Exiting BuildHierarchy now ##########"
		return obj.result
	end

	# this method actually builds the hierarchy
	# if something goes wrong, then obj.result is set as []
	# this method works on the sorted version of the input rather than the input directly
	def self.build_hierarchy_helper(obj)
		# algorithm:
		# 	start from the last index of the array, i.e. the deepest level and work towards the outermost level
		# 	get the parent_key and child_key that establishes the relationship between the previous level and itself (ie.child level), get :level_name
		# 	go to its previous level or parent level, get hold of the :level_list
		# 	for each item in the level list: 
		# 		add a new key as :level_name and initialize with emptry array
		# 		identify its children items by comparing the keys from both the levels, append to the array when found a match
		puts "\n\n\t******** inside build_hierarchy_helper method. this method creates the hierarchies ********"
		ref = obj.input_array_sorted_by_level_no # giving the array a shorter name for ease of use
		(ref.length-1).downto(1) do |i|			
			# extract some info from current child level
			child_level = ref[i]
			puts "------- current level = " + (i+1).to_s + ", name = " + child_level[:level_name] + " --------"
			puts "current level item = "
			p child_level
			rel = child_level[:relationship_with_previous_level]
			relationship_keys_hash = {:parent_key => nil, :child_key => nil}
			# get the relationship keys
			get_relationship_keys(rel, relationship_keys_hash)
			parent_key = relationship_keys_hash[:parent_key]
			child_key  = relationship_keys_hash[:child_key]
			puts "parent_key inside helper method = " + parent_key.to_s
			puts "child_key  inside helper method = " + child_key.to_s

			# start building the hierarchy in the parent level
			# set current level's parent level
			parent_level = ref[i-1]
			puts "parent_level = "
			p parent_level

			parent_level_list = parent_level[:level_list]
			puts "parent_level_list = "
			p parent_level_list
			new_hierarchy_name = child_level[:level_name]
			puts "new_hierarchy_name = " + new_hierarchy_name.to_s
			# for each item in the list, add the dependency key and initialize with an array
			puts " ++ modifying the parent level now ++ "
			parent_level_list.each do |parent_item|				
				parent_item[new_hierarchy_name] = []
				puts "......... parent_item = "
				p parent_item
				# now, loop throught each item in the child's level_list, compare the parent_key with child_key and append the child
				child_list = child_level[:level_list]
				puts "now iterating over child list to find out its children"
				puts "parent_item[parent_key] = " + parent_item[parent_key].to_s

				child_list.each do |child_item|
					puts "child_item[child_key] = " + child_item[child_key].to_s
					if child_item[child_key] == parent_item[parent_key]
						parent_item[new_hierarchy_name] << child_item
						puts "one child found, appending to the parent now"
						puts "parent_item "
						p parent_item
					end
				end # child_list.each
			end #parent_level_list.each

		end # (ref.length-1).downto(1) do
		puts "obj.input_array_sorted_by_level_no = "
		p obj.input_array_sorted_by_level_no
		puts "\n\n \t================="
		puts "\t only the first level's :level_list should have the whole hierarchy needed"
		obj.result_as_ruby_hash = obj.input_array_sorted_by_level_no[0][:level_list]
		puts "\t obj.result_as_ruby_hash = "
		p obj.result_as_ruby_hash

		puts "\n\t----exiting build_hierarchy_helper method ----"
	end # end of method self.build_hierarchy_helper(obj)


	# this method converts obj.result_as_ruby_hash into json format
	# the json format is then stored in 'result' and sent back to user/caller
	def self.convert_ruby_hashed_result_to_json(obj)
		puts "\n\n\t ----- inside convert_ruby_hashed_result_to_json method to conver result from ruby hash to json ----"
		# obj.result = obj.result_as_ruby_hash.as_json
		# puts "obj.result = "
		obj.result[result] = obj.result_as_ruby_hash.as_json
		puts "obj.result = "
		p obj.result
		puts "\t ----- exiting from convert_ruby_hashed_result_to_json -----"
	end



	# returns a validation object of the format: {:validation_status => validation_status, :error_msg => error_msg_hash[:error_msg]}
	# validation_status will be false if input was improper
	def self.validate_input(obj)			
		puts "***** Staring validating input *****"
		validation_status = true
		error_msg_hash = {:error_msg => nil}
		validation_status = BuildHierarchy.validate_input_class(obj, error_msg_hash) && 
							BuildHierarchy.validate_input_levels(obj, error_msg_hash) &&
							BuildHierarchy.validate_existance_of_all_keys(obj, error_msg_hash) &&
							BuildHierarchy.validate_relationship_between_levels(obj, error_msg_hash)
		
		if (validation_status == false)
			# puts "----- Input structure validation: Failure -----"
			# puts error_msg_hash[:error_msg]
			puts "overall input validation failed"
		else
			# puts "----- Input structure validation: Success -----"
			puts "overall input validation success"
		end
		puts "***** Done validating input *****"
		return {:validation_status => validation_status, :error_msg => error_msg_hash[:error_msg]}

	end

	# this method validates whether the input is an object of BuildHierarchy or not
	# returns true or false, and sets error_msg_hash with error message in case of an error
	def self.validate_input_class(obj, error_msg_hash)
		puts "\n\n\t----entering validate_input_class method to validate type of input----"
		status = true

		class_of_object = obj.class
		puts "\tclass_of_object = " + class_of_object.to_s
		if class_of_object.to_s != 'BuildHierarchy'
			msg = "wrong type of object passed; expecting object of type 'BuildHierarchy' only, received: " + class_of_object.to_s
			puts msg
			return BuildHierarchy.set_error_msg(error_msg_hash, msg)
			# error_msg_hash[:error_msg] = msg	
			# status = false
			# puts "\tinput type validation: failure"
			# puts "\t" + msg.to_s
		end
		puts "obj.input.class = " + obj.input.class.to_s
		if obj.input.class != [].class
			msg = "object does not have an array to process. use 'set_hierarchy_details' to set the object with an array "
			puts msg
			return BuildHierarchy.set_error_msg(error_msg_hash, msg)
		end
		puts "\tinput type validation: success"
		puts "\t----exiting validate_input_class method----"
		return status	
	end

	# this method validates whether the levels provided are sequential or not
	# note: this method will be called only if the input object is of type BuildHierarchy. so, the instance variables can be safely accessed here
	def self.validate_input_levels(obj, error_msg_hash)
		puts "\n\n\t----entering validate_input_levels method to validate levels in the input----"
		status = true
		input_array = obj.input
		puts "++input_array = ++"
		p input_array

		if input_array.nil?
			puts "input cannot be nil."
			return BuildHierarchy.set_error_msg(error_msg_hash, "input cannot be nil.")
			# error_msg_hash[:error_msg] = msg
			# status = false
			# puts "\tinput level validation: failure"
			# puts "\t" + msg.to_s
			# puts "\t----exiting validate_input_levels----"
			# return status			
		end

		if input_array.size <= 1			
			puts "\tinput level validation: failure"			
			return BuildHierarchy.set_error_msg(error_msg_hash, "not enough levels to build hierarcy; need at least two levels to build hierarcy")
		end
		
		# check if all the levels provided by ':level_no' key are sequential or not
		# value of ':level_no' cannot be negetive
		# algorithm: 
		# 	a) extract all the levels and store in an array   
		# 	b) sort them in ascending order
		# 	c) check if the lowest number is negetive number   
		# 	d) find if all the numbers are sequentially increasing numbers
		# 	e) there cannot be any duplicate numbers 
		
		# a)
		level_no_array = []		
		input_array.each do |each_level|
			puts "++++ each_level = ++++"
			p each_level
			if (each_level.class != {}.class or each_level[:level_no] == nil) or (each_level[:level_no].class != Fixnum)				
				msg = "input has to be array of hashes; level_no must be provided for each level and level number must be a number (Fixnum)"
				puts msg
				return BuildHierarchy.set_error_msg(error_msg_hash, msg)
			else
				level_no_array << each_level[:level_no]
			end			
		end		
		# b)
		level_no_array.sort!
		puts "     after sorting, level_no_array = "
		p level_no_array
		# c) 
		if level_no_array[0] < 1
			puts "level number cannot be negetive less than 1."
			return BuildHierarchy.set_error_msg(error_msg_hash, "level number cannot be negetive.")
			# msg = "level number cannot be negetive."
			# error_msg_hash[:error_msg] = msg
			# status = false
			# puts "\tinput level validation: failure"
			# puts "\t" + msg.to_s
			# return status
		end
		# d) and e)
		for i in 1..(level_no_array.length-1)
			if level_no_array[i] != level_no_array[i-1] + 1
				msg = "level numbers must be sequential, non-duplicate numbers (Fixnum)"
				puts msg
				return set_error_msg(error_msg_hash, msg)
			end
		end

		puts "\tinput level validation: success"				
		puts "\t----exiting validate_input_levels----"
		return status
	end


	# this method validates if each of the hashes in the input array contains all the expected keys
	# returns true or false, and sets error_msg_hash with error message in case of an error
	def self.validate_existance_of_all_keys(obj, error_msg_hash)
		puts "\n\n\t---- entering validate_existance_of_all_keys method to validate existance of all the level information ----"
		puts "@@expected_info_in_each_level_hash = "
		p @@expected_info_in_each_level_hash

		input_array = obj.input
		input_array.each do |each_level_hash_in_array|
			@@expected_info_in_each_level_hash.each_key do |key|
				if each_level_hash_in_array[key] == nil
					# check for special case: for level1, no relationship is needed
					if ! ((key == :relationship_with_previous_level) and (each_level_hash_in_array[:level_no] != nil and each_level_hash_in_array[:level_no] == 1))					
						msg = "missing information about '" + key.to_s + "' in the input, please try again with proper input"
						puts msg
						return set_error_msg(error_msg_hash, msg)
					end
				end
			end			
		end

		puts "\t----exiting validate_existance_of_all_keys ----"
		return true
	end


	# this method validates relationship between the levels
	# returns true or false, and sets error_msg_hash with error message in case of an error
	def self.validate_relationship_between_levels(obj, error_msg_hash)		
		# the array 'input_array_sorted_by_level_no' is built here.
		# this array is same as input array, but sorted by the level number in each item of input array
		# having this sorted array optimizes access to the hashed objects
		# algorithm to build the sorted array:
		# 		a) extract all the levels and store them in a temp array 
		# 		b) sort the temp array  
		# 		c) iterate over the temp array, fetch the whole item from input array and put into proper index in sorted array
		# note: no need to worry about duplicate numbers, or if level numbers are non-integers, as these checks are already been done
		puts "\n\n\t---- entering validate_relationship_between_levels method ----"
		input_array = obj.input
		temp_array = []		
		input_array.each do |each_level|
			temp_array << each_level[:level_no]
		end		
		# b)
		temp_array.sort!
		puts "after sorting, level_no_array = "
		p temp_array
		# c) 
		temp_array.each do |l_no|
			input_array.each do |each_item|
				if each_item[:level_no] == l_no
					obj.input_array_sorted_by_level_no << each_item
				end
			end
		end
		puts "input_array_sorted_by_level_no = "
		p obj.input_array_sorted_by_level_no

		# now, validate if the fields on which relationship is mentioned, are present in respective levels
		# algorithm:
		# 	a) starting with level2, find the value of :relationship_with_previous_level (=> "previous_level.id=this_level.network_id")
		# 		split the value by "=" and then split the value by "." to get previous level's and current level's relationship field
		# 	b) validate if objects from previous and current :level_list have those fields
		# :level_list => [:release_obj1, :release_obj2, :release_obj3],

		ref = obj.input_array_sorted_by_level_no  #giving it a shorter name for convenience		
		# a)
		for level in 1..(ref.length-1)
			puts "level = " + (level+1).to_s + ", level_name = " + ref[level][:level_name].to_s

			child_level_hash  = ref[level]
			parent_level_hash = ref[level-1]
			
			relationship_keys_hash = {:parent_key => nil, :child_key => nil}

			rel = child_level_hash[:relationship_with_previous_level]			
			BuildHierarchy.get_relationship_keys(rel, relationship_keys_hash)

			parent_key = relationship_keys_hash[:parent_key]
			child_key  = relationship_keys_hash[:child_key]
						

			# b) validating presence of the keys in respective level's :level_list
			child_level_list = Array(child_level_hash[:level_list]) # Array() is needed for single object case
			parent_level_list = Array(parent_level_hash[:level_list])
			# NOTE: preprocessing needs to be done to:   1) conver active record object to json    2) replace "\" with "" and ":" with => in the json structure
			if child_level_list[0] == nil or child_level_list[0][child_key] == nil or parent_level_list[0][parent_key] == nil
				msg = "cannot establish relationship between parent and child when child's level: " + (level+1).to_s
				puts msg
				return set_error_msg(error_msg_hash, msg)
			end

		end


		puts "\t---- exiting validate_relationship_between_levels method ----"
		return true
	end

	# this method sets the error_msg_hash with message passed
	# always returns 'false' which denotes that status of the valiation is false
	def self.set_error_msg(error_msg_hash, msg="")
		error_msg_hash[:error_msg] = msg
		return false
	end

	# this method extracts the relationship keys that relates one level to the other and puts those into the 
	# relationship_keys_hash properly.
	# first argument 'rel' is the relationship of a level, ex: :relationship_with_previous_level => "previous_level.id=this_level.network_id"
	def self.get_relationship_keys(rel, relationship_keys_hash)
		rel_array = rel.split("=")
		# puts "rel_array = "
		# p rel_array
		if rel_array[0].include?"previous_level"			
			relationship_keys_hash[:parent_key] = rel_array[0].split(".")[1]			
			relationship_keys_hash[:child_key]  = rel_array[1].split(".")[1]
		else
			relationship_keys_hash[:child_key]  = rel_array[0].split(".")[1]
			relationship_keys_hash[:parent_key] = rel_array[1].split(".")[1]
		end
		
		puts "parent_key = "
		p relationship_keys_hash[:parent_key] unless relationship_keys_hash[:parent_key].nil?
		puts "child_key  = " 
		p relationship_keys_hash[:child_key]  unless relationship_keys_hash[:child_key].nil?
	end

	
	
end

# input_array = [{}, {}] # see below structure
# input_array = [1, 2, 3, 4, 5, "hello world"]
# input_array = nil
# input_array = [{:level_no => 1, :janian => 10}, {:level_no => 2, :janian => 20}, {:level_no => 3, :janian => 30}, {:level_no => 4, :janian => 40}]
input_array = [
	{
		:level_no => 1,
		:level_name => 'networks',
		:level_list => [
						{"id" => 1, "name" => "Network1", "number_inc" => 0}, {"id" => 2, "name" => "Network2", "number_inc" => 0},
						{"id" => 3, "name" => "Network3", "number_inc" => 0}
					   ],
		:relationship_with_previous_level => nil
	},
	{
		:level_no => 2,
		:level_name => 'releases',
		:level_list => [ {"id" => 1, "number" => 430, "number_inc" => 0, "release_type_id" => 1, "network_id" => 1}, 
						 {"id" => 2, "number" => 431, "number_inc" => 0, "release_type_id" => 1, "network_id" => 1},
						 {"id" => 3, "number" => 432, "number_inc" => 0, "release_type_id" => 1, "network_id" => 2},
						 {"id" => 4, "number" => 433, "number_inc" => 0, "release_type_id" => 1, "network_id" => 2}  
					    ],
		:relationship_with_previous_level => "previous_level.id=this_level.network_id"
	},
	{
		:level_no => 3,
		:level_name => 'build_dependencies',
		:level_list => [
						{"component" => "openssl", "version" => "1.1.0", "installOs" => "common", "release_id" => 2}, 
						{"component" => "openssl", "version" => "1.1.0", "installOs" => "alsi-6", "release_id" => 2},
						{"component" => "openssl", "version" => "1.1.0", "installOs" => "alsi-7", "release_id" => 2},
						{"component" => "devtools", "version" => "1.10", "installOs" => "alsi-7", "release_id" => 1},
						{"component" => "devtools", "version" => "1.10", "installOs" => "common", "release_id" => 1},
					   ],
		:relationship_with_previous_level => "previous_level.id=this_level.release_id"
	}	
]

obj = BuildHierarchy.new
obj.set_hierarchy_details(input_array)
output = BuildHierarchy.build_hierarchy(obj)


# output = BuildHierarchy.build_hierarchy("hello world")
puts "output = "
p output
# BuildHierarchy.build_hierarchy([10, 10])
# BuildHierarchy.build_hierarchy({:hello => 10})
# BuildHierarchy.build_hierarchy(100)






# input to set_hierarchy_details method, called as obj.set_hierarchy_details([input_array_whose_each_item_is_a_hash_of_level_details])
# [
# 	{
# 		:level_no => 1,
# 		:level_name => 'networks',
# 		:level_list => [network_obj1, network_obj2, network_obj3],
# 		:relationship_with_previous_level => nil
# 	},
# 	{
# 		:level_no => 2,
# 		:level_name => 'releases',
# 		:level_list => [release_obj1, release_obj2, release_obj3],
# 		:relationship_with_previous_level => "previous_level.id=this_level.network_id"
# 	},
# 	{
# 		:level_no => 3,
# 		:level_name => 'build_dependencies',
# 		:level_list => [build_dependency_obj1, build_dependency_obj2, build_dependency_obj3],
# 		:relationship_with_previous_level => "previous_level.release_id=this_level.id"
# 	}

# ]


# # output:
# [
# 	{
# 		"name : 'abcd'", "description: 'yahoo' ", "releases" : [ {"name" : "r1", "number" : 10, "build_dependencies" : [{"version" : 1.0, "installos" : 'alsi'}] }, { } ]
# 	},
# 	{

# 	}
# ]


