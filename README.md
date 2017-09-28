# BuildNLevelHierarchy

This program takes different records as input whereas the inputs are related to each other by some way (you can declare how!), and creates a hierarchy depending on those relationships.

For example: a nation has states, a state has cities, a city has an area. There are 3 arrays present: all_nations, all_states, all_areas. One state will have information (FK) about which nation it belongs to. Similary, one area will have state FK in it. 

Input and Output structures are below:
Input:
{
		:level_no => 1,
		:level_name => 'countries',
		:level_list => [
						{"CountryId" => 1, "name" => "USA"},
						{"CountryId" => 2, "name" => "India"}
					   ],
		:relationship_with_previous_level => nil
	},
	{
		:level_no => 2,
		:level_name => 'states',
		:level_list => [ {"id" => 1, "name" => "Texas", "country_id" => 1}, 
						 {"id" => 2, "number" => "California", "country_id" => 1},						 
					    ],
		:relationship_with_previous_level => "previous_level.CountryId=this_level.country_id"
	},
	{
		:level_no => 3,
		:level_name => 'areas',
		:level_list => [
						{"id" => 1, "name" => "area1", state_id => 1}, 
						{"id" => 2, "name" => "area2", state_id => 1},
						{"id" => 3, "name" => "area3", state_id => 2}
						{"id" => 4, "name" => "area4", state_id => 2}
					   ],
		:relationship_with_previous_level => "previous_level.id=this_level.state_id"
	}	
]


output:
[
  {
    "CountryId": 1,
    "name": "USA",    
    "states": [
			      {
			        "id": 1,
			        "name": "Texas",
			        "areas": [
			        	{
			        		"id": 1,
			        		"name": "area1"
			        	},
			        	{
			        		"id": 2,
			        		"name": "area2"
			        	}
			        ]
			      },

			      {
			        "id": 2,
			        "name": "California",
			        "areas": [
			        	{
			        		"id": 1,
			        		"name": "area1"
			        	},
			        	{
			        		"id": 2,
			        		"name": "area2"
			        	}
			        ]
			      }
			   ]
  },
  {
    "CountryId": 2.
    ...
  }
]