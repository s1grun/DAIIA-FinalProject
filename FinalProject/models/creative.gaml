/***
* Name: Festival
* Author: sigrunarnasigurdardottir
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model creative

/* Insert your model definition here */
global {
	point centerLocation <- {50, 50};
//    int stage_color<-30;
    list<string> genre <- ["rock", "pop", "folks", "jazz"];
    list<string> guestTypes <- ["chill", "party", "tired", "drunk", "journalist"];
    list<Guests> tiredList <-[];
    list<Guests> partyList <-[];
    list<Guests> chillList <-[];
    list<Guests> drunkList <-[];
    list<Guests> journalistList <-[];
    float globalAngry <- 0.0;
    
	init {
		
		
//		int addDist <- 0;
		
		create Health_center with:(location:centerLocation);
		
		point storeLocation1 <- {25, 25};
		create Guests number: 50;
//		{
//			//location <- {50 + addDist, 50 + addDist};
//			//addDist <- addDist + 5;
//		}

		loop gu over:Guests{
			if(gu.gType="tired"){
				add gu to:tiredList;
			}else if(gu.gType="party"){
				add gu to:partyList;
			}else if(gu.gType = "chill"){
				add gu to:chillList;
			}else if(gu.gType="drunk"){
				add gu to:drunkList;
			}else if(gu.gType="journalist"){
				add gu to:journalistList;
			}
		}
		

		create Stage number: 2 with:(stage_color:#blue,type:"bar");
		
		create Stage number: 1 with:(stage_color:#yellow,type:"party");
		
		create Stage number: 1 with:(stage_color:#green,type:"concert");
	
	}
	
	
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
	float popMusic <- rnd(0.0, 1.0);
	float rockMusic <- rnd(0.0, 1.0);
	float folksMusic <- rnd(0.0, 1.0);
	float jazzMusic <- rnd(0.0, 1.0);
//	Stage fav_stage;
	point guestLocation <- nil;
	float util<-0.0;
	list act_util_list <- [];
	int status <- 0;
	rgb my_color <- #blue;
	string gType <- guestTypes[rnd(length(guestTypes) - 1)];
	Stage dest <-nil;
	list stage_list<-[];
	int movingStatus <- 0; // 0-> do wander,1-> go to stage,2-> at stage;
	int interaction <-0; //0->no interaction, 1->interact with someone.
	float generous <- rnd(0.0,1.0);
	Guests friend <- nil;
	float happy <- rnd(0.0,0.5);
	float sleepy <- rnd(0.0,0.5);
	float angry <- rnd(0.0,0.5);
	float partyMood <- rnd(0.0,0.5);
	string count;
	bool friend_frozen <-false;
	
	
	init{
		guestLocation<-location;
		if(gType="tired"){
			sleepy <- 0.5;
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

	//point statusPoint <- nil;
	
//	reflex statusIdle when: statusPoint = nil 
//	{
//		do wander;
//	}


	reflex getInfo when:!(empty(informs)){
		
		loop msg over: informs{
			Stage spot<- Stage(agent(msg.sender));
//			write msg.sender;
			if(msg.contents[0]="start"){
				add spot to:stage_list;
				if(flip(0.5) and movingStatus!=3 and  movingStatus!=4){
//					write friend;
//					write spot.type;
					if(friend != nil and spot.type="concert"){
						write name + " sending invite to friend " + friend;
						do start_conversation with: [to :: list(friend), protocol :: 'fipa-contract-net', performative :: 'inform', contents :: ['invitation',spot] ];
						dest<- spot;
						movingStatus <-1;	
					}else{
						dest<- spot;
						movingStatus <-1;
					}
				}

			}else if(msg.contents[0]="end"){
				remove spot from:stage_list;
				if(dest!=nil){
					if(dest=spot){
						if(length(stage_list) = 0){
							do wander;
						}else{
							dest<- stage_list[rnd(length(stage_list) - 1)];
						}
						
						if( movingStatus!=3 and  movingStatus!=4){
							movingStatus <-1;
						}
						
						remove self from: dest.guestsList;
					}
				}
			}else if (msg.contents[0]="invitation"){
				spot<-msg.contents[1];
				add spot to:stage_list;							
				dest<- spot;
				movingStatus <-1;
				write name +" going to concert with friend " + msg.sender;
			}
		}
			
	}
	
	reflex goToStage when:movingStatus=1{
		do goto target:dest;
		
	}
	
	reflex nearStage when: dest!=nil and distance_to(self,dest)<=7 and movingStatus=1{
		movingStatus <- 2;
		dest.guestsList <+ self;	
		if(friend != nil){
			ask friend {
//				write name + "is no longer friend with " + friend;
				myself.friend <- nil;
				self.friend <- nil;
			}
		}	
	}
	
	
	reflex atStage when: movingStatus=2 and friend=nil{
		do wander;
		
		
		if(gType="drunk"){
			ask Guests at_distance 3{
					if(self.gType="drunk"){
						if(flip(0.9)){
//							write myself.name +":drunk guy make friends with "+self.name+":drunk guy";
							myself.friend<- self;
							self.friend<- myself;
//							myself.happy<-myself.happy+0.1;
//							self.happy<-self.happy+0.1;
						}
					}else if(self.gType="journalist"){
						if(flip(0.3)){
							myself.friend<- self;
							self.friend<- myself;
//							write myself.name +":drunk guy interview with "+self.name+":journalist, jouranlist get angry and drunk guy get happy";
//							self.angry <- self.angry+0.1;
//							myself.happy<-myself.happy+0.1;
						}
					}else{
						if(self.happy>=0.5){
							myself.friend<- self;
							self.friend<- myself;
//							write myself.name + ":drunk guy meet "+ self.gType+" ";
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
				write "tired guy leave the "+dest.type;
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
	
	reflex outRage when: angry>1.5 and movingStatus=2{
		if friend != nil{
			if(friend.generous>0.5 and friend.gType!="gournalist"){
				ask friend{
//					self.friend_frozen<- true;
//					myself.friend_frozen <- true;
					movingStatus<-3;
					myself.movingStatus<-3;
					color <- #red;
					write name + " go to Health_center with grumpy guy:"+ myself.name;
					color <- #blue;
				}
				
			}
		}
	}
	
	reflex gotoHealthCenter when: movingStatus=3{
		Health_center hc<-one_of(Health_center);
		do goto target:hc;
		
		if( distance_to(location, hc.location) <5){
			movingStatus<-4;
		}
	}
	
	reflex atHealthCenter when: movingStatus=4{
		if(friend!=nil){
			ask friend{
				self.angry <-self.angry-0.1;
				self.sleepy <- self.sleepy+0.2;
				myself.angry <-0.0;
				myself.sleepy <-myself.sleepy+0.2;
				movingStatus<-1;
			}
		}
		movingStatus<-1;
	}
	
	reflex withFriend when: movingStatus=2 and friend!=nil {
		
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
						count <- "generous";
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
						count <- "happy";
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
						count <- "happy";
						
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
						count <- "happy";
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
						count <- "happy";
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
						count <- "generous";
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
						count <- "happy";
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
						count <- "happy";
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
//		globalAngry <- globalAngry+self.angry+friend.angry;
		friend<-nil;
	}
	
	
	
	
	



}

species Health_center{
	aspect default{
		draw rectangle(4, 4) color:#red;
	}
	
}


species Stage skills:[fipa]{
	int whenToStart<-1;
	int whenToEnd<-0;
	list<Guests> guestsList;
	bool ongoing <- false;
	string type;
	Guests guest;
	rgb stage_color;
	
	aspect { 
		
		draw rectangle(4, 4) color:stage_color;
		
		
	}
	
	
	reflex stageHostingConcert when: (time = whenToStart and ongoing=false)  {
		
			write name + ": "+type+" is starting soon";
			if(type="concert"){
				string concert_type<- genre[rnd(length(genre)-1)];
				write "concert type:"+ concert_type;
				do start_conversation with: [to :: list(Guests), protocol :: 'fipa-contract-net', performative :: 'inform', contents :: ['start',concert_type] ];
			}else{
				do start_conversation with: [to :: list(Guests), protocol :: 'fipa-contract-net', performative :: 'inform', contents :: ['start'] ];
			}
			whenToEnd <-int(time+20*rnd(10,20));
			ongoing <- true;
		
	}
	
	reflex calculateGlobalAngryLevel when: (ongoing = true) {
		globalAngry<-0.0;
		if(type="concert" or type="party" or type="bar"){
			loop g over: guestsList {
				globalAngry <- globalAngry + g.angry;
//				write "Guest angry value at concert" +g.angry;
				
			}
			if(globalAngry >= 1.0){
					color<-#black;
					write "The angry level is too high, concert ends now" + globalAngry;
					do start_conversation with: [to ::list(Guests), protocol :: 'fipa-contract-net', performative :: 'inform', contents :: ['end'] ];
					write name + ' end '+ type;
					whenToStart <- int(time+10*rnd(1,5));
					ongoing <- false; 
					color<-#blue;
				}
		}
	}
	
	reflex endConcert when: (time=whenToEnd) and ongoing = true{
		
		do start_conversation with: [to ::list(Guests), protocol :: 'fipa-contract-net', performative :: 'inform', contents :: ['end'] ];
		
		write name + 'end '+ type;
		whenToStart <- int(time+10*rnd(1,5));
		ongoing <- false;
		
	}
	
	
}

experiment creative type:gui{
	output{
		display map type: opengl {
			species Guests;
//			species Bar;

			species Stage;
			species Health_center;
			
			//graphics "env" {
        	//	draw cube(environment_size) color: #black empty: true;
        	//}
        
		}
		display chart_display refresh:every(10#cycles) {
             chart "Journalist vs. Chill" type: series size: {1, 0.5} position: {0, 0} {
                data "Happiness1" value: mean (journalistList collect each.happy) style: line color: #green;
             	data "Angry1" value: mean (journalistList collect each.angry) style: line color: #red;
             	data "Sleepy1" value: mean (journalistList collect each.sleepy) style: line color: #purple;
             	data "Generous1" value: mean (journalistList collect each.generous) style: line color: #orange;
             	data "Happiness2" value: mean (chillList collect each.happy) style: line color: #yellow;
             	data "Angry2" value: mean (chillList collect each.angry) style: line color: #gray;
             	data "Sleepy2" value: mean (chillList collect each.sleepy) style: line color: #black;
             	data "Generous2" value: mean (chillList collect each.generous) style: line color: #blue;
             	
        	}
             chart "Guests happiness" type: pie style: exploded size: {1, 0.5} position: {0, 0.5}{
           		data "Party guests happiness" value: partyList collect (each.happy) color: #magenta ;
           		data "Tired guests happiness" value: tiredList collect (each.happy) color: #blue ;
           		data "Chilled guests happiness" value: chillList collect (each.happy) color: #green ;
           		data "Drunk guests happiness" value: drunkList collect (each.happy) color: #orange ;
           		data "Journalist guests happiness" value: journalistList collect (each.happy) color: #red ;	
         	 }
         
 	
     }
         
	}

	
}