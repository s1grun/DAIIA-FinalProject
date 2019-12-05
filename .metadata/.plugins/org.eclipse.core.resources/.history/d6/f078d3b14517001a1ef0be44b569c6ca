/***
* Name: Festival
* Author: sigrunarnasigurdardottir
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model Festival

/* Insert your model definition here */
global {
	point agentLocation <- {50, 50};
    int stage_color<-30;
    list<string> genre <- ["rock", "pop", "folks", "jazz"];
    
	init {
		
		
		int addDist <- 0;
		
		point storeLocation1 <- {25, 25};
		create Guests number: 10
		{
			//location <- {50 + addDist, 50 + addDist};
			//addDist <- addDist + 5;
		}
		
		create Stores number: 2 with: (type: "bar")
		{
			//location <- {10 + addDist, 10 + addDist};
			//addDist <- addDist + 10;
		}
				create Stores number: 2 with: (type: "restaurant")
		{
			//location <- {10 + addDist, 10 + addDist};
			//addDist <- addDist + 10;
		}
		list<Stores> bar <- Stores where (each.type="Bar");
    	list<Stores> restaurant <- Stores where (each.type="Restaurant");
    	
		create Ic number: 1 with: (location: agentLocation)
		{
			
		}
		
		
		loop i from:0 to:3{
			create Stage number: 1 with:(stage_color:rgb(rnd(255),rnd(255),rnd(255)),type:genre[i]);
		}
	
	}
	
//	action move (list<agent> movingGuest){
//		
//	}
	
}

species Guests skills:[moving, fipa]{
//	rgb guestColor <- #green;
	bool thirsty <- flip(0.5); //50% chance to be thirsty true;
	bool hungry <- flip(0.5);	//50% chance to be hungry true;
	//or use int statusFeeling
	int statusFeeling <- 0;    // var0 equals 0, 1 or 2; 0->nothing,1->thirsty,2->hungry
	int movingStatus <- 0; // 0-> do wander,1-> go to Ic,2-> go to bar/restaurant,3 -> go back
	point storeDestination <- nil; // To store the location of a store
	point returnBack <- rnd({0.0, 0.0, 0.0},{100.0,100.0,0.0});
	point original_location;
	
	float betterLightShow <- rnd(0.1, 1.0);
	float betterVisuals <- rnd(0.2, 1.0);
	float goodSoundSystem <- rnd(0.3, 1.0);
	float famous <- rnd (0.0, 1.0);
	float popMusic <- rnd(0.0, 1.0);
	float rockMusic <- rnd(0.0, 1.0);
	float folksMusic <- rnd(0.0, 1.0);
	float jazzMusic <- rnd(0.0, 1.0);
	Stage fav_stage;
	point guestLocation <- nil;
	float util<-0.0;
	list act_util_list <- [];
	int status <- 0;
	rgb my_color <- #blue;
	
	init{
		guestLocation<-location;
	}
	
	aspect default {
		if(movingStatus=0 or movingStatus=3){
			draw sphere(2) color:#green;
		}else if(movingStatus=1){
			draw sphere(2) color:#red;
		}else if(movingStatus=2){
			if(statusFeeling=1){
				draw sphere(2) color:#blue;
			}else{
				draw sphere(2) color:#yellow;
			}
			
		}
		
	}

	//point statusPoint <- nil;
	
//	reflex statusIdle when: statusPoint = nil 
//	{
//		do wander;
//	}
	
	reflex initalize when: statusFeeling = 0 and movingStatus =0 {
		
		do wander;
		if (flip(0.05)){
			statusFeeling <- rnd_choice([0.8,0.1,0.1]);
			original_location <- location;
			if statusFeeling !=0{
				movingStatus <- 1;
			}
			
		}
		
		
			
	}
	
	reflex goToIc when: statusFeeling != 0 and movingStatus =1
	{
		
		do goto target:agentLocation;
				
	}
	
	reflex atIc when: ((movingStatus=1) and (location = agentLocation)) {
		
		ask Ic {
			//myself.storeDestination <- self.store_location;
			if (myself.statusFeeling=1){
				myself.storeDestination <- one_of(self.bar);
//			 write  "go to "+myself.storeDestination;
			 
			}else if(myself.statusFeeling=2){
				myself.storeDestination <- one_of(self.restaurant);
//				 write  "go to "+myself.storeDestination;
				 
			}
 
		}
		movingStatus <- 2;	
		
	}
	
	reflex goToStore when: movingStatus = 2 and statusFeeling !=0{
		do goto target:storeDestination;
		
	}
	
	reflex inStore when: location=storeDestination and movingStatus =2{
		movingStatus <-3;
		statusFeeling <-0;
	}
	
	reflex returnback when: movingStatus =3{
		do goto target:original_location;
	}
	
	reflex inOriginal_location when: movingStatus =3 and location=original_location{
		 movingStatus <-0;
	}

	reflex goToStage when: !(empty(informs)) {
		loop msg over: informs{
//			message msg <- informs[0];
			if(msg.contents[0]='start'){
				Stage informingConcert <- Stage(agent(msg.sender));
//				write name+ " Receive inform from: " + informingConcert;
				string lightstr <- msg.contents[1];
				float light <- float(lightstr);
				string visualstr <- msg.contents[2];
				float visual <- float(visualstr);
				float sound <- float(msg.contents[3]);
				float famous1 <- float(msg.contents[4]);
				float rock <- float(msg.contents[5]);
				float pop <- float(msg.contents[6]);
				float folks <- float(msg.contents[7]);
				float jazz <- float(msg.contents[8]);
				
				
				do utility(light, visual, sound, famous1, rock, pop, folks, jazz, informingConcert);
				
				status<-1;
//				fav_stage.guestsList <+ self;
				my_color <- fav_stage.stage_color;
//				write name + act_util_list;
//				write name+ " Going to: " + fav_stage;
			}else{
//				write name +"reveice :"+msg.contents[0];
				status<-3;
				Stage sender <- Stage(agent(msg.sender));
				my_color <- #blue;
//				write act_util_list;
				remove [fav_stage,util] from:act_util_list;
//				write act_util_list;
				if(length(act_util_list)>1){
					util <- float(last(act_util_list)[1]);
					fav_stage <- last(act_util_list)[0];
					my_color <- fav_stage.stage_color;
					status <-1;
				}
				
				
			}	
		}
		
	}
	
	
	reflex goingToStage when: status=1 {
		do goto target:fav_stage;
	}
	
	
	reflex atStage when: fav_stage != nil and (location distance_to fav_stage) <5 and status=1{
		do wander;
		status<-2;
	}
	
	reflex dancing when: status=2 {
		do wander;

	}

	
	
	reflex goToMyLocation when: status=3 {
		do goto target:guestLocation;
		
	}
	
	reflex atMyLocation when: (location = guestLocation) {
		status <- 0;
	}
	
	
	
	action utility(float light, float visual, float sound, float famous1, float rock, float pop, float folks, float jazz, Stage sender) {
		float tmp <-  betterLightShow * light + betterVisuals * visual + goodSoundSystem * sound + famous * famous1 + rockMusic * rock + popMusic * pop + folksMusic * folks + jazzMusic * jazz;
//		if tmp > util{
//			util <- tmp;
//			fav_stage <- sender;
//		}
		act_util_list <+ [sender,tmp];
		act_util_list <- act_util_list sort_by (float(each[1]));
		util <- float(last(act_util_list)[1]);
		fav_stage <- last(act_util_list)[0];
		
	}
	
}

species Stores {
	string type;
	

	aspect default {
		draw rectangle(4, 4) color: (type = "bar")? #blue : #yellow;
	}
}

species Ic {
	list bar;
	list restaurant;
	init{
		ask agents of_species Stores{
			if (self.type = "bar"){
				add location to: myself.bar;
			}
			if (self.type = "restaurant"){
				add location to: myself.restaurant;
			}
			
			
//			write location;
		}
		//write store_location;
	}
	aspect default {
		draw rectangle(4, 4) color:#red;
		
	}
	
//	action returnStoreLocation (int statusOfGuest) {
//		return 1;
//	}
//	
//	point Guests;
	
//	reflex get_store when: Guests != nil 
//	{
//		do goto target
//	}
//	ask Stores at_distance Guests{
//		
//	}
}


species Stage skills:[fipa]{
	float betterLightShow <- rnd(0.0, 1.0);
	float betterVisuals <- rnd(0.0, 1.0);
	float goodSoundSystem <- rnd(0.0, 1.0);
	float famous <- rnd (0.0, 1.0);
	float popMusic <- rnd(0.0, 1.0);
	float rockMusic <- rnd(0.0, 1.0);
	float folksMusic <- rnd(0.0, 1.0);
	float jazzMusic <- rnd(0.0, 1.0); 
	string type;
	int whenToStart<-1;
	int whenToEnd<-0;
//	list guestsList;
	bool ongoing <- false;
	
	rgb stage_color;
	
	aspect { 
		
		draw cube(4) color:stage_color;
		
		
	}
	
	init{
		if(type="pop"){
			popMusic <- 0.9;
			rockMusic <- 0.0;
			folksMusic <- 0.0;
			jazzMusic <- 0.0;
		}else if(type="rock"){
			popMusic <- 0.0;
			rockMusic <- 0.9;
			folksMusic <- 0.0;
			jazzMusic <- 0.0;
		}else if(type="folks"){
			popMusic <- 0.0;
			rockMusic <- 0.0;
			folksMusic <- 0.9;
			jazzMusic <- 0.0;
		}else if(type="jazz"){
			popMusic <- 0.0;
			rockMusic <- 0.0;
			folksMusic <- 0.0;
			jazzMusic <- 0.9;
		}
	}
	
	
	reflex stageHostingConcert when: (time = whenToStart and ongoing=false)  {
		
//		if (flip(0.2)){
			betterLightShow <- rnd(0.0, 1.0);
	 		betterVisuals <- rnd(0.0, 1.0);
			goodSoundSystem <- rnd(0.0, 1.0);
			famous <- rnd (0.0, 1.0);
			write name + ": concert is starting soon";
			do start_conversation with: [to :: list(Guests), protocol :: 'fipa-contract-net', performative :: 'inform', contents :: ['start', betterLightShow, betterVisuals, goodSoundSystem, famous, rockMusic, popMusic, folksMusic, jazzMusic] ];
			whenToEnd <-int(time+10*rnd(10,20));
			ongoing <- true;
//		}
		
	}
	
	reflex endConcert when: (time=whenToEnd) and ongoing = true{
		
		do start_conversation with: [to ::list(Guests), protocol :: 'fipa-contract-net', performative :: 'inform', contents :: ['end'] ];
		
		write name + ' eeeeeeeeeend concert';
		whenToStart <- int(time+10*rnd(1,5));
		ongoing <- false;
		
	}
	
	
}

experiment festival type:gui{
	output{
		display map type: opengl {
			species Guests;
			species Stores;
			species Ic;
			species Stage;
			
			//graphics "env" {
        	//	draw cube(environment_size) color: #black empty: true;
        	//}
        
		}
		display chart {
			chart "How often guests get thirsty" {
				data "thirsty guests" value: length (Guests where (each.statusFeeling = 1));
			}
		}
	}
}