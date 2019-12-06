/***
* Name: Festival
* Author: sigrunarnasigurdardottir
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model Festival

/* Insert your model definition here */
global {
//	point agentLocation <- {50, 50};
//    int stage_color<-30;
//    list<string> genre <- ["rock", "pop", "folks", "jazz"];
    list<string> guestTypes <- ["chill", "party", "bored", "drunk", "journalist"];
    
	init {
		
		
//		int addDist <- 0;
		
		point storeLocation1 <- {25, 25};
		create Guests number: 1;
//		{
//			//location <- {50 + addDist, 50 + addDist};
//			//addDist <- addDist + 5;
//		}
		


//		
		
//		loop i from:0 to:3{
//			create Stage number: 1 with:(stage_color:rgb(rnd(255),rnd(255),rnd(255)),type:);
//		}
		create Stage number: 2 with:(stage_color:#blue,type:"bar");
		
		create Stage number: 1 with:(stage_color:#yellow,type:"party");
		
		create Stage number: 1 with:(stage_color:#green,type:"concert");
	
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
	
	point storeDestination <- nil; // To store the location of a store
	point returnBack <- rnd({0.0, 0.0, 0.0},{100.0,100.0,0.0});
	point original_location;
	
//	float betterLightShow <- rnd(0.1, 1.0);
//	float betterVisuals <- rnd(0.2, 1.0);
//	float goodSoundSystem <- rnd(0.3, 1.0);
//	float famous <- rnd (0.0, 1.0);
//	float popMusic <- rnd(0.0, 1.0);
//	float rockMusic <- rnd(0.0, 1.0);
//	float folksMusic <- rnd(0.0, 1.0);
//	float jazzMusic <- rnd(0.0, 1.0);
//	Stage fav_stage;
	point guestLocation <- nil;
	float util<-0.0;
	list act_util_list <- [];
	int status <- 0;
	rgb my_color <- #blue;
	string gType <- guestTypes[rnd(length(guestTypes) - 1)];
	point dest <-nil;
	list stage_list<-[];
	int movingStatus <- 0; // 0-> do wander,1-> go to Ic,2-> go to bar/restaurant,3 -> go back
	
	init{
		guestLocation<-location;
		
	}
	
	aspect default {
//		if(movingStatus=0 or movingStatus=3){
//			draw sphere(2) color:#green;
//		}else if(movingStatus=1){
//			draw sphere(2) color:#red;
//		}else if(movingStatus=2){
//			if(statusFeeling=1){
//				draw sphere(2) color:#blue;
//			}else{
//				draw sphere(2) color:#yellow;
//			}
//			
//		}
		if(gType="drunk"){
			draw circle(2) color:#red;
		}else if(gType="party"){
			draw circle(2) color:#yellow;
		}else if(gType="chill"){
			draw circle(2) color:#green;
		}else if(gType="bored"){
			draw circle(2) color:#gray;
		}else if(gType="journalist"){
			draw circle(2) color:#blue;
		}
		
	}

	//point statusPoint <- nil;
	
//	reflex statusIdle when: statusPoint = nil 
//	{
//		do wander;
//	}


	reflex getInfo when:!(empty(informs)){
		loop msg over: informs{
			Stage spot<- Stage(agent(msg.sender));
			if(msg.contents[0]="start"){
				add spot to:stage_list;
				if(flip(0.5)){
					dest<- spot;
					movingStatus <-1;
				}

			}else if(msg.contents[0]="end"){
				remove spot from:stage_list;
				if(dest!=nil){
					if(dest=spot){
						dest<- stage_list[rnd(length(stage_list) - 1)];
						
						movingStatus <-1;
					}
				}
			}
		}
			
	}
	
	reflex goToStage when:movingStatus=1{
		do goto target:dest;
	}
	
	reflex nearStage when: dest!=nil and distance_to(self,dest)<=10 and movingStatus=1{
		movingStatus <- 2;
	}
	
	reflex atStage when: movingStatus=2{
		do wander;
	}
	
	
	
	
	

	
	reflex inOriginal_location when: movingStatus =3 and location=original_location{
		 movingStatus <-0;
	}


}

//species Bar skills:[fipa]{
////	string type;
//	int startHH <- 1;
//	int endHH <- 0;
//	bool happyHour <- false;
//	string type <- "bar";
//
//	aspect default {
//		draw rectangle(4, 4) color: #yellow;
//	}
//	
//	reflex happyHour when: (time = startHH) and (happyHour = false) {
//		write name + " Happy hour is starting!";
//		do start_conversation with: [to :: list(Guests), protocol :: 'fipa-contract-net', performative :: 'inform', contents :: ['start', type]];
//		endHH <-int(time+200);
//		happyHour <- true;
//	}
//	
//	reflex endHappyHour when: (time = endHH) and (happyHour = true) {
//		do start_conversation with: [to ::list(Guests), protocol :: 'fipa-contract-net', performative :: 'inform', contents :: ['end', type] ];
//		write name + ' Happy hour has ended';
//		startHH <- int(time+30*rnd(2,3));
//		happyHour <- false;
//	}
//}
//
//species RaveParty skills:[fipa]{
//	int startRP <- 1;
//	int endRP <- 0;
//	bool raveParty <- false;
//	string type <- "party";
//	
//	aspect default {
//		draw rectangle(4, 4) color: #black;
//	}
//	
//	reflex ravePart when: (time = startRP) and (raveParty = false) {
//		write name + " Rave Party is starting";
//		do start_conversation with: [to :: list(Guests), protocol :: 'fipa-contract-net', performative :: 'inform', contents :: ['start']];
//		endRP <-int(time+10*rnd(10,20));
//		raveParty <- true;
//	}
//	
//	reflex endHappyHour when: (time = endRP) and (raveParty = true) {
//		do start_conversation with: [to ::list(Guests), protocol :: 'fipa-contract-net', performative :: 'inform', contents :: ['end'] ];
//		write name + ' Happy hour has ended';
//		endRP <- int(time+10*rnd(1,5));
//		raveParty <- false;
//	}
//}




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
	
	rgb stage_color;
	
	aspect { 
		
		draw rectangle(4, 4) color:stage_color;
		
		
	}
	
//	init{
//		if(type1="pop"){
//			popMusic <- 0.9;
//			rockMusic <- 0.0;
//			folksMusic <- 0.0;
//			jazzMusic <- 0.0;
//		}else if(type1="rock"){
//			popMusic <- 0.0;
//			rockMusic <- 0.9;
//			folksMusic <- 0.0;
//			jazzMusic <- 0.0;
//		}else if(type1="folks"){
//			popMusic <- 0.0;
//			rockMusic <- 0.0;
//			folksMusic <- 0.9;
//			jazzMusic <- 0.0;
//		}else if(type1="jazz"){
//			popMusic <- 0.0;
//			rockMusic <- 0.0;
//			folksMusic <- 0.0;
//			jazzMusic <- 0.9;
//		}
//	}
//	
	
	reflex stageHostingConcert when: (time = whenToStart and ongoing=false)  {
		
//		if (flip(0.2)){
//			betterLightShow <- rnd(0.0, 1.0);
//	 		betterVisuals <- rnd(0.0, 1.0);
//			goodSoundSystem <- rnd(0.0, 1.0);
//			famous <- rnd (0.0, 1.0);
			write name + ": "+type+" is starting soon";
			do start_conversation with: [to :: list(Guests), protocol :: 'fipa-contract-net', performative :: 'inform', contents :: ['start'] ];
			whenToEnd <-int(time+20*rnd(10,20));
			ongoing <- true;
//		}
		
	}
	
	reflex endConcert when: (time=whenToEnd) and ongoing = true{
		
		do start_conversation with: [to ::list(Guests), protocol :: 'fipa-contract-net', performative :: 'inform', contents :: ['end'] ];
		
		write name + 'end '+ type;
		whenToStart <- int(time+10*rnd(1,5));
		ongoing <- false;
		
	}
	
	
}

experiment festival type:gui{
	output{
		display map type: opengl {
			species Guests;
//			species Bar;

			species Stage;
			
			//graphics "env" {
        	//	draw cube(environment_size) color: #black empty: true;
        	//}
        
		}
//		display chart {
//			chart "How often guests get thirsty" {
//				data "thirsty guests" value: length (Guests where (each.statusFeeling = 1));
//			}
//		}
	}
}