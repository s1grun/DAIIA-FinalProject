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
		create Guests number: 20;

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
	float generous <- rnd(0.0,1.0);
	
	
	// predicates of getting a drink
	predicate thirsty_belief <- new_predicate("thirsty");
	predicate bar_location <- new_predicate("barLocation");
	predicate goToBar <- new_predicate("goToBar");
	predicate choose_bar <- new_predicate("choose_bar");
	predicate enjoy_beer <- new_predicate("enjoy_beer");
	predicate goBackStage <- new_predicate("goBackStage");
	
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
	
	//If the guest is thirsty the desire and belief to go to stage is removed also no friend is removed as belief, and we add a thirsty belief
	reflex default_action{
		if(flip(0.001) and thirsty= false){
			thirsty <- true;
			write name +" is thirsty!";
			guestLocation <- location;
			do remove_desire(goToStage);
			do remove_belief(goToStage);
			do remove_belief(no_friend);
			do add_belief(thirsty_belief);
		}
	} 
	
	//These are the rules for the thirsty belief and to enjoy beer and the desire for the rules.
	rule belief:thirsty_belief new_desire:goToBar strength:5.0;
	rule belief:enjoy_beer new_desire:goBackStage;
	
	//This is the get bar location with perceive
	perceive target: Stage where (each.type ="bar") in: distance {
    	focus id:"barLocation" var:location;
    	 
    }
    
    

    //Here's the plan to go to the bar and when guest are finished at the bar then the belief of thirsty is removed and a new belief is added to enjoy beer
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
	        	if(friend!=nil){
					ask friend{
						friend <- nil;
						myself.friend <- nil;
					}
				}
	        	do remove_belief(thirsty_belief);
	        	do remove_intention(goToBar, true); 
	        	do add_belief(enjoy_beer);
	       		color <-#blue;
	       		thirsty <- false;
	       		write name+" have beer";
	       		
//	        	do add_emotion(joy);
	        }
	        target <- nil;       
	    }
    }
    
    //Here is the plan to choose a bar, the guest has a list of bar locations and the guest will select the bar with the closest distance
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
    
    //After the guest has finished the beer at the bar he will have a new plan and belief to go to stage
    plan goBackStage intention:goBackStage{
    	dest<-guestLocation;
    	do goto target:dest;
    		if(location distance_to dest<5){
    			write name+ " go to "+dest;
//    			dest <- nil;
    			do add_belief(goToStage);
    			do remove_belief(enjoy_beer);
    			do remove_intention(goBackStage,true);
    		}
    }
    
    
    
    //If a guest has the belief to go to stage then the guest will have a new desire to enjoy stage
    rule belief:goToStage new_desire:enjoy_stage strength:3.0;
	
	//Then the guest have the plan to choose a stage and the guest will choose the stage with the shortest distance
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
    
    //After the guest has chosen a stage he will have a new plan to go to that stage
    plan goto_stage intention:goToStage {
    	do add_subintention(get_current_intention(),choose_stage, true);
        do current_intention_on_hold();
    	if(dest!=nil){
    		do goto target:dest;
    		if(location distance_to dest<5){
    			write name+ " go to "+dest;
    			
    			if(friend!=nil){
					ask friend{
						friend <- nil;
						myself.friend <- nil;
					}
				}
    			do add_belief(goToStage);
    			do remove_intention(goToStage,true);
    		}
//    	}else{
//    		
    	}
    }
    
    //When the guest has arrived at the stage his plan is to enjoy the stage/concert
    //If we have a friend then we will interact with that friend
	plan enjoy_stage intention:enjoy_stage{
		do wander;
		do remove_intention(enjoy_stage,true);
		if(friend=nil){
			do add_belief(no_friend);
		}else{
			
			do remove_belief(no_friend);
			do add_desire(interact_with_friend);
		}
	}
	
	predicate make_friends <- new_predicate("make_friends");
	predicate no_friend <- new_predicate("no_friend");
	predicate interact_with_friend <- new_predicate("interact_with_friend");
	
	rule belief:no_friend new_desire:make_friends;
	
	//If we have the belief of no friend then we will have the desire to make friends
	//After making a new friend we will remove the belief of no friend.
	plan make_friends intention:make_friends{
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
//		write "make friends 1111111111111";
		do remove_intention(make_friends, true);
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
//					dest <- nil;
					do remove_belief(goToStage);
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
	
//	reflex goToStage when:movingStatus=1{
//		do goto target:dest;
//		
//		
//	}
//	
//	reflex nearStage when: dest!=nil and distance_to(self,dest)<=6 and movingStatus=1{
//		movingStatus <- 2;
//	}
	
//	reflex atStage when: movingStatus=2 and friend=nil{
//		do wander;
//		
//		
//	}
	
	plan withFriend intention: interact_with_friend{
//		write "interact with friends 1111111111111";
		color<-#gray;
		do remove_intention(interact_with_friend,true);
		if(friend!= nil){
			
		
		if(dest.type="bar"){
			if(has_emotion(joy) and !has_emotion(satisfied) and friend!=nil){
				ask friend{
					write name+ " buy "+myself.name+" a drink 111111111111111111";
					do add_emotion(joy);
				}
				do add_emotion(satisfied);
			}
		}else{
			if(gType="drunk"){
			if(friend.gType="party" or friend.gType="chill"){
					if(generous > 0.25 and angry < 0.5){
						write gType + " is feeling generous and buys " + friend.gType + " a drink";
						self.happy <- self.happy+0.2;
						self.angry <- self.angry-0.2;
						self.generous <- self.generous+0.2;
						self.sleepy <- self.sleepy+0.1;
						friend.happy <- friend.happy+0.1;
						friend.angry <- friend.angry-0.2;
						friend.generous <- friend.generous+0.2;
						friend.sleepy <- friend.sleepy+0.1;
						
					}
					else if(angry > 0.2 and generous < 0.2){
						write gType + " is feeling angry when he meets " + friend.gType;
						self.happy <- self.happy-0.3;
						self.angry <- self.angry+0.3;
						self.generous <- self.generous-0.2;
						self.sleepy <- self.sleepy+0.2;
						friend.angry <- friend.angry+0.5;
						friend.happy <- friend.happy-0.2;
						friend.generous <- friend.generous-0.2;
						friend.sleepy <- friend.sleepy+0.2;
					}
					else if(happy > 0.2){
						write gType + " is feeling happy and chats with " + friend.gType;
						self.happy <- self.happy+0.2;
						self.angry <- self.angry-0.3;
						self.generous <- self.generous+0.1;
						self.sleepy <- self.sleepy-0.2;
						friend.happy <- friend.happy+0.1;
						friend.angry <- friend.angry-0.3;
						friend.generous <- friend.generous+0.1;
						self.sleepy <- self.sleepy-0.2;
						
					}
			}
		}else if(gType="party"){
//			if(friend.gType){
					if(angry > 0.2 and happy < 0.2 and sleepy < 0.5){
						write gType + " is angry and does not want to hangout with his friend " + friend.gType;
						self.angry <- self.angry+0.2;
						self.happy <- self.happy-0.2;
						self.generous <- self.generous-0.2;
						self.sleepy <- self.sleepy+0.1;
						friend.angry <- friend.angry+0.2;
						friend.happy <- friend.happy-0.2;
						friend.generous <- friend.generous-0.2;	
						friend.sleepy <- friend.sleepy+0.1;
					} 
					else if(happy > 0.2 and sleepy < 0.5) {
						write gType + " is happy with his friend " + friend.gType;
						self.angry <- self.angry-0.3;
						self.happy <- self.happy+0.2;
						self.generous <- self.generous+0.2;
						self.sleepy <- self.sleepy-0.1;
						friend.angry <- friend.angry-0.3;
						friend.happy <- friend.happy+0.2;
						friend.generous <- friend.generous+0.2;
						friend.sleepy <- friend.sleepy-0.1;
						
						
					} 
					else if(sleepy > 0.5){
						write gType + " is feeling sleepy and says goodbye to his friend " + friend.gType;
						self.happy <- self.happy-0.1;
						self.angry <- self.angry+0.1;
						self.generous <- self.generous+0.1;
						self.sleepy <- self.sleepy+0.2;
						friend.happy <- friend.happy-0.1;
						friend.angry <- friend.angry+0.1;
						friend.generous <- friend.generous-0.1;
						friend.sleepy <- friend.sleepy-0.1;
//						do die();
//			}
					}
		}else if(gType="chill"){
			if(friend.gType="journalist"){
				if(sleepy > 0.3){
					write gType + " is feeling too tired to be interviewd by " + friend.gType;
					self.happy <- self.happy-0.2;
					self.angry <- self.angry-0.3;
					self.generous <- self.generous-0.1;
					self.sleepy <- self.sleepy+0.3;
					friend.happy <- friend.happy-0.2;
					friend.angry <- friend.angry+0.3;
					friend.generous <- friend.generous-0.1;
					friend.sleepy <- friend.sleepy-0.1;
						if(happy > 0.15 and angry < 0.2 and generous < 0.2){
						write gType + " is feeling happy and is interviewed by " + friend.gType;
						self.happy <- self.happy+0.2;
						self.angry <- self.angry-0.3;
						self.generous <- self.generous+0.1;
						self.sleepy <- self.sleepy-0.1;
						friend.happy <- friend.happy+0.2;
						friend.angry <- friend.angry-0.3;
						friend.generous <- friend.generous+0.1;
						friend.sleepy <- friend.sleepy-0.1;
						
						}
						else if(angry > 0.2 and generous < 0.2){
							write gType + " is feeling angry and does not want to be interviewed by " + friend.gType;
							self.happy <- self.happy-0.2;
							self.angry <- self.angry+0.2;
							self.generous <- self.generous-0.1;
							self.sleepy <- self.sleepy+0.1;
							friend.happy <- friend.happy-0.2;
							friend.angry <- friend.angry+0.3;
							friend.generous <- friend.generous-0.1;
							friend.sleepy <- friend.sleepy+0.1;
						}
						else if(generous > 0.2){
							write gType + " is feeling generous and is interviewed by " + friend.gType;
							self.happy <- self.happy+0.2;
							self.angry <- self.angry-0.2;
							self.generous <- self.generous+0.3;
							self.sleepy <- self.sleepy-0.1;
							friend.happy <- friend.happy+0.2;
							friend.angry <- friend.angry-0.3;
							friend.generous <- friend.generous+0.1;
							friend.sleepy <- friend.sleepy-0.1;
						
						}
				}
			}else if(friend.gType="party" or friend.gType="drunk"){
					if(happy > 0.15 and angry < 0.2 and generous < 0.2){
						write gType + " is feeling happy and chills with " + friend.gType;
						self.happy <- self.happy+0.2;
						self.angry <- self.angry-0.3;
						self.generous <- self.generous+0.1;
						self.sleepy <- self.sleepy-0.1;
						friend.happy <- friend.happy+0.1;
						friend.angry <- friend.angry-0.3;
						friend.generous <- friend.generous+0.1;
						friend.sleepy <- friend.sleepy-0.1;
						
					}
					else if(angry > 0.2 and generous < 0.2){
						write gType + " is feeling angry and does not want to chill with " + friend.gType;
						self.happy <- self.happy-0.2;
						self.angry <- self.angry+0.2;
						self.generous <- self.generous-0.1;
						self.sleepy <- self.sleepy+0.1;
						friend.happy <- friend.happy-0.2;
						friend.angry <- friend.angry+0.3;
						friend.generous <- friend.generous-0.1;
						friend.sleepy <- friend.sleepy+0.1;
					}
					else if(generous > 0.2){
						write gType + " is feeling generous and gives " + friend.gType + " a hug";
						self.happy <- self.happy+0.2;
						self.angry <- self.angry-0.2;
						self.generous <- self.generous+0.3;
						self.sleepy <- self.sleepy-0.1;
						friend.happy <- friend.happy+0.2;
						friend.angry <- friend.angry-0.2;
						friend.generous <- friend.generous+0.1;
						friend.sleepy <- friend.sleepy-0.1;
						
					}
			}
			
		}else if(gType="tired"){
			if(friend.gType="tired"){
					if(sleepy < 0.25 and happy > 0.15 and angry < 0.2){
						write gType + " is hanging out with another " + friend.gType;
						self.sleepy <- self.sleepy+0.4;
						self.happy <- self.happy+0.1;
						self.angry <- self.angry-0.1;
						self.generous <- self.generous+0.1;
						friend.sleepy <- friend.sleepy+0.4;
						friend.happy <- friend.happy+0.1;
						friend.angry <- friend.angry-0.1;
						friend.generous <- friend.generous+0.1;
						
					}
					else if(angry > 0.2){
						write gType + " is angry and unfriends " + friend.gType;
						self.sleepy <- self.sleepy+0.5;
						self.happy <- self.happy-0.4;
						self.angry <- self.angry+0.4;
						self.generous <- self.generous-0.1;
						friend.sleepy <- friend.sleepy+0.5;
						friend.happy <- friend.happy-0.4;
						friend.angry <- friend.angry+0.4;
						friend.generous <- friend.generous-0.1;
						friend <- nil;
					}
			}
			
		}else if(gType="journalist"){
			if(friend.gType="tired"){
					if(happy > 0.15 and sleepy < 0.2){
						write gType + " takes an interview with " + friend.gType;
						self.sleepy <- self.sleepy+0.3;
						self.happy <- self.happy+0.2;
						self.angry <- self.angry-0.15;
						self.generous <- self.generous+0.1;
						friend.sleepy <- self.sleepy+0.3;
						friend.happy <- friend.happy+0.2;
						friend.angry <- friend.angry-0.15;
						friend.generous <- friend.generous+0.1;
						
					}
					else if(angry > 0.2 and friend.sleepy > 0.3){
						write gType + " is too angry to interview such a sleepy person " + friend.gType;
						self.sleepy <- self.sleepy+0.1;
						self.happy <- self.happy-0.2;
						self.angry <- self.angry+0.2;
						self.generous <- self.generous-0.1;
						friend.sleepy <- self.sleepy+0.1;
						friend.happy <- friend.happy-0.2;
						friend.angry <- friend.angry+0.2;
						friend.generous <- friend.generous-0.1;
					}
			}
			
		}
			
		}
		
		
		
//		do add_belief(goToStage);
	}
	color<-#blue;
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


