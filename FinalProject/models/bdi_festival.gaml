/***
* Name: bdifestival
* Author: weng
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model bdifestival

/* Insert your model definition here */

global {

    list<string> guestTypes <- ["chill", "party", "tired", "drunk", "journalist"];
    
    
	init {
		

		
		point storeLocation1 <- {25, 25};
		create Guests number: 1;

		create Stage number: 3 with:(stage_color:#blue,type:"bar");
		
		create Stage number: 2 with:(stage_color:#yellow,type:"party");
		
		create Stage number: 2 with:(stage_color:#green,type:"concert");
	
	}
	

	
}





species Guests skills:[moving, fipa] control:simple_bdi{
	
	
	bool use_emotions_architecture <- true;
    bool use_personality <- true;
    
    

	bool thirsty <- false; 
	

	point guestLocation <- nil;
	string gType <- guestTypes[rnd(length(guestTypes) - 1)];
	Stage dest <-nil;
	list stage_list<-[];
	int movingStatus <- 0; // 0-> do wander,1-> go to Ic,2-> go to bar/restaurant,3 -> go back
	float distance <- 8.0;
	point target;
	
	Guests friend <- nil;
	float happy <- rnd(0.0,0.5);
	float sleepy <- rnd(0.0,0.5);
	float angry <- rnd(0.0,0.5);
	
	
	// predicates of getting a drink
	predicate bar_location <- new_predicate("barLocation");
	predicate goToBar <- new_predicate("goToBar");
	predicate choose_bar <- new_predicate("choose_bar");
	
	// predicates of going some events
	predicate targetLocation <- new_predicate("targetLocation");
	predicate goToStage <- new_predicate("goToStage");
	predicate choose_stage <- new_predicate("choose_stage");
	predicate enjoy_stage <- new_predicate("enjoy_stage");
	
	emotion joy <- new_emotion("joy");
	emotion satisfied <- new_emotion("satisfied");
		
	init{
		guestLocation<-location;
		if(flip(0.3)){
			do add_emotion(joy);
		}
		
	}
	
	aspect default {

		if(gType="drunk"){
			draw circle(2) color:#red;
		}else if(gType="party"){
			draw circle(2) color:#yellow;
		}else if(gType="chill"){
			draw circle(2) color:#green;
		}else if(gType="tired"){
			draw circle(2) color:#gray;
		}else if(gType="journalist"){
			draw circle(2) color:#blue;
		}
		
	}
	
	reflex default_action{
		if(flip(0.01) and thirsty= false){
			thirsty <- true;
			write name +" is thirsty!";
			
			do remove_desire(goToStage);
			do remove_belief(goToStage);
			do add_desire(goToBar);
		}
	} 
	
	
	
	
	
	perceive target: Stage where (each.type ="bar") in: distance {
    	focus id:"barLocation" var:location;
    	 
    }
    
    

    
    plan goToBar intention: goToBar finished_when: has_emotion(joy) {
	    color <-#darkred;
	    if (target = nil ) {
//	        target <- (shelter with_min_of (each.location distance_to location)).location;
	        do add_subintention(get_current_intention(),choose_bar, true);
        	do current_intention_on_hold();
	    } else  {
//	        do goto target: target on: road_network move_weights: current_weights recompute_path: false;
			do goto target: target;
			
	        if (target = location)  {
	        	write name +"go to the bar ";
	        	do remove_intention(goToBar, true); 
	       		color <-#blue;
	       		thirsty <- false;
	       		write name+" have beer";
//	        	do add_emotion(joy);
	        }
	        target <- nil;       
	    }
    }
    
	plan choose_bar intention: choose_bar instantaneous: true {
        list<point> bar_list <- get_beliefs_with_name("barLocation") collect (point(get_predicate(mental_state (each)).values["location_value"]));
//		write bar_list;
        if (empty(bar_list)) {
//        	write 'no bars';
            do remove_intention(goToBar, false); 
        } else {
            target <- (bar_list with_min_of (each distance_to self)).location;
//            write name+' go to the bar '+target;
        }
        do remove_intention(choose_bar, true); 
    }
    
    
    
    
    rule belief:goToStage new_desire:enjoy_stage strength:3.0;

    plan choose_stage intention: choose_stage instantaneous: true{
    	list<Stage> stages <- get_beliefs_with_name("targetLocation") collect (get_predicate(mental_state (each)).values["location_value"]);
		list<Stage> bar_list <- get_beliefs_with_name("barLocation") collect (get_predicate(mental_state (each)).values["location_value"]);
//		
//    	write name + "  "+ stages;
		if(sleepy>=0.5 or length(stages)=0){
			dest<- bar_list with_min_of (each distance_to self);
		}else{
			dest<- stages[rnd(length(stages)-1)]; 
		}

    	do remove_intention(choose_stage,true);
    }
    
    plan goto_stage intention:goToStage {
    	if(dest!=nil){
    		do goto target:dest;
    		if(location distance_to dest<5){
    			write name+ " go to "+dest;
    			dest <- nil;
    			do add_belief(goToStage);
    			do remove_intention(goToStage,true);
    		}
    	}else{
    		do add_subintention(get_current_intention(),choose_stage, true);
            do current_intention_on_hold();
    	}
    }
    
	plan enjoy_stage intention:enjoy_stage{
		do wander;
		do remove_intention(enjoy_stage,true);
	}



	reflex getInfo when:!(empty(informs)){
		loop msg over: informs{
			Stage spot<- Stage(agent(msg.sender));
			if(msg.contents[0]="start"){
				do add_belief(new_predicate("targetLocation",["location_value"::spot]));
				if(spot.type="bar"){
					do add_belief(new_predicate("barLocation",["location_value"::spot]));
				}
				add spot to:stage_list;
				if(flip(0.3) and thirsty = false){
//					write name+' go to '+ spot;
//					dest<- spot;
//					movingStatus <-1;
					do add_desire(goToStage);
				}

			}else if(msg.contents[0]="end"){
//				do add_belief(new_predicate("remove_location",["location_value"::spot]));
				do remove_belief(new_predicate("targetLocation",["location_value"::spot]));
				remove spot from:stage_list;
				if(dest!=nil){
					if(dest=spot){
//						dest<- stage_list[rnd(length(stage_list) - 1)];
//						
//						movingStatus <-1;
						do add_desire(goToStage);
					}
				}
			}
		}
			
	}
	
	reflex goToStage when:movingStatus=1{
		do goto target:dest;
		if(friend!=nil){
			ask friend{
			friend <- nil;
			myself.friend <- nil;
		}
		}
		
	}
	
	reflex nearStage when: dest!=nil and distance_to(self,dest)<=6 and movingStatus=1{
		movingStatus <- 2;
	}
	
	reflex atStage when: movingStatus=2 and friend=nil{
		do wander;
		
		if(gType="drunk"){
			ask Guests at_distance 3{
					if(self.gType="drunk"){
						if(flip(0.9)){
							myself.friend<- self;
							self.friend<- myself;

						}
					}else if(self.gType="journalist"){
						if(flip(0.3)){
							myself.friend<- self;
							self.friend<- myself;
						}
					}else{
						if(self.happy>=0.5){
							myself.friend<- self;
							self.friend<- myself;

						}
						
					}
					
				}
		}else if(gType="party"){
			if(dest.type="party"){
				ask Guests at_distance 3{
					if(self.gType="tired"){
						if(sleepy<=0.7 and flip(0.3)){
							myself.friend<- self;
							self.friend<- myself;
						}
					}else{
						if(flip(0.7)){
							myself.friend<- self;
							self.friend<- myself;
						}
					}
				}
			}else{
				ask Guests at_distance 3{
					if(flip(0.3)){
							myself.friend<- self;
							self.friend<- myself;
					}
				}
			}
		}else if(gType="chill"){
			ask Guests at_distance 3{
				if(self.gType="tired"){
					if(sleepy<=0.7 and flip(0.5)){
						myself.friend<- self;
						self.friend<- myself;
					}
				}else{
					if(flip(0.7)){
						myself.friend<- self;
						self.friend<- myself;
					}
				}
			}

			
		}else if(gType="tired"){
		
			if(length(Guests at_distance 3)>5 or sleepy>0.7){
				write "tired guy leave the "+ dest.type;
			}else{
				ask Guests at_distance 3{
					if(self.gType!="tired"){
						myself.friend<- self;
						self.friend<- myself;
					}
				}
			}
			
			
		}else if(gType="journalist"){
			ask Guests at_distance 3{
				if(self.gType!="tired"){
					if(flip(0.3) and sleepy<=0.7){
						myself.friend<- self;
						self.friend<- myself;
					}
				}else{
					if(flip(0.5)){
						myself.friend<- self;
						self.friend<- myself;
					}
				}
			}
		}
	}
	
	reflex withFriend when: movingStatus=2 and friend!=nil{
		
		if(dest.type="bar"){
			if(has_emotion(joy) and !has_emotion(satisfied)){
				ask friend{
					write name+ " buy "+myself.name+" a drink";
					do add_emotion(joy);
				}
				do add_emotion(satisfied);
			}
		}else{
			// ask friend to party
		}
		
		
	}



}













species Stage skills:[fipa]{
//	float betterLightShow <- rnd(0.0, 1.0);
//	float betterVisuals <- rnd(0.0, 1.0);
//	float goodSoundSystem <- rnd(0.0, 1.0);
//	float famous <- rnd (0.0, 1.0);
//	float popMusic <- rnd(0.0, 1.0);
//	float rockMusic <- rnd(0.0, 1.0);
//	float folksMusic <- rnd(0.0, 1.0);
//	float jazzMusic <- rnd(0.0, 1.0); 
//	string type1;
	int whenToStart<-1;
	int whenToEnd<-0;
//	list guestsList;
	bool ongoing <- false;
	string type;
	int beers <- rnd(1,20);
	rgb stage_color;
	
	aspect { 
		
		draw rectangle(4, 4) color:stage_color;
		
		
	}
	
	
	reflex stageHosting when: (time = whenToStart and ongoing=false )  {
		
			write name + ": "+type+" is starting soon";
			do start_conversation with: [to :: list(Guests), protocol :: 'fipa-contract-net', performative :: 'inform', contents :: ['start'] ];
			whenToEnd <-int(time+20*rnd(10,20));
			ongoing <- true;

		
	}
	
	reflex endStage when: (time=whenToEnd) and ongoing = true {
		
		do start_conversation with: [to ::list(Guests), protocol :: 'fipa-contract-net', performative :: 'inform', contents :: ['end'] ];
		
		write name + ' end '+ type;
		whenToStart <- int(time+10*rnd(1,5));
		ongoing <- false;
		
	}
	
	
}









experiment bdi type:gui{
	output{
		display map type: opengl {
			species Guests;
//			species Bar;

			species Stage;
			
        
		}

	}
}


